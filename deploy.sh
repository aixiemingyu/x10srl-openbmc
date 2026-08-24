#!/bin/bash
# X10SRL OpenBMC 部署脚本

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR=$(pwd)
OPENBMC_DIR="$HOME/openbmc"

echo -e "${BLUE}"
echo "=================================================="
echo "  X10SRL OpenBMC 部署向导"
echo "=================================================="
echo -e "${NC}"
echo ""
echo "项目目录: $PROJECT_DIR"
echo "OpenBMC 将安装到: $OPENBMC_DIR"
echo ""

# 检查是否在 Windows 环境
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    echo -e "${YELLOW}检测到 Windows 环境${NC}"
    echo ""
    echo "OpenBMC 编译需要 Linux 环境。您有以下选择："
    echo ""
    echo "1. 使用 WSL2 (Windows Subsystem for Linux)"
    echo "   - 安装 Ubuntu WSL2"
    echo "   - 将此项目复制到 WSL2 环境"
    echo "   - 在 WSL2 中运行此脚本"
    echo ""
    echo "2. 使用虚拟机"
    echo "   - 安装 VirtualBox 或 VMware"
    echo "   - 创建 Ubuntu 22.04 虚拟机"
    echo "   - 至少分配: 4核CPU, 8GB RAM, 100GB磁盘"
    echo "   - 将项目复制到虚拟机中"
    echo ""
    echo "3. 使用 Docker"
    echo "   - 使用 crops/poky Docker 镜像"
    echo "   - 挂载项目目录"
    echo ""
    echo -e "${GREEN}推荐步骤:${NC}"
    echo ""
    echo "# 在 WSL2 Ubuntu 中执行:"
    echo "cd /mnt/c/Users/eason/Downloads/openbmc-x10srl"
    echo "./deploy.sh"
    echo ""
    exit 0
fi

# Linux 环境检查
echo -e "${YELLOW}1. 检查系统依赖...${NC}"

MISSING_DEPS=""
for cmd in git wget tar python3 gcc make; do
    if ! command -v $cmd &>/dev/null; then
        MISSING_DEPS="$MISSING_DEPS $cmd"
    fi
done

if [ -n "$MISSING_DEPS" ]; then
    echo -e "${RED}缺少依赖:$MISSING_DEPS${NC}"
    echo ""
    echo "安装依赖命令 (Ubuntu/Debian):"
    echo ""
    cat << 'EOF'
sudo apt-get update
sudo apt-get install -y git build-essential python3 python3-distutils \
    gawk wget diffstat unzip texinfo gcc chrpath socat cpio \
    python3-pip python3-pexpect xz-utils debianutils iputils-ping \
    python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 \
    xterm python3-subunit mesa-common-dev zstd liblz4-tool
EOF
    echo ""
    read -p "是否立即安装? (yes/no): " INSTALL_DEPS
    if [ "$INSTALL_DEPS" == "yes" ]; then
        sudo apt-get update
        sudo apt-get install -y git build-essential python3 python3-distutils \
            gawk wget diffstat unzip texinfo gcc chrpath socat cpio \
            python3-pip python3-pexpect xz-utils debianutils iputils-ping \
            python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 \
            xterm python3-subunit mesa-common-dev zstd liblz4-tool
    else
        exit 1
    fi
fi

echo -e "${GREEN}依赖检查通过 ✓${NC}"
echo ""

# 检查磁盘空间
echo -e "${YELLOW}2. 检查磁盘空间...${NC}"
AVAILABLE=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')

if [ $AVAILABLE -lt 50 ]; then
    echo -e "${RED}警告: 可用空间不足 50GB (当前: ${AVAILABLE}GB)${NC}"
    read -p "是否继续? (yes/no): " CONTINUE
    if [ "$CONTINUE" != "yes" ]; then
        exit 1
    fi
else
    echo -e "${GREEN}磁盘空间充足: ${AVAILABLE}GB ✓${NC}"
fi
echo ""

# 下载 OpenBMC
echo -e "${YELLOW}3. 准备 OpenBMC 源码...${NC}"

if [ -d "$OPENBMC_DIR" ]; then
    echo "OpenBMC 目录已存在"
    read -p "是否更新? (yes/no): " UPDATE
    if [ "$UPDATE" == "yes" ]; then
        cd "$OPENBMC_DIR"
        git pull
    fi
else
    echo "克隆 OpenBMC..."
    git clone https://github.com/openbmc/openbmc.git "$OPENBMC_DIR"
fi

echo -e "${GREEN}OpenBMC 准备完成 ✓${NC}"
echo ""

# 复制配置层
echo -e "${YELLOW}4. 安装 X10SRL 配置层...${NC}"

if [ ! -d "$PROJECT_DIR/meta-supermicro-x10srl" ]; then
    echo -e "${RED}错误: 找不到 meta-supermicro-x10srl 目录${NC}"
    exit 1
fi

cp -r "$PROJECT_DIR/meta-supermicro-x10srl" "$OPENBMC_DIR/"
echo -e "${GREEN}配置层安装完成 ✓${NC}"
echo ""

# 设置编译环境
echo -e "${YELLOW}5. 配置编译环境...${NC}"

cd "$OPENBMC_DIR"
. setup x10srl

if ! grep -q "meta-supermicro-x10srl" conf/bblayers.conf; then
    echo 'BBLAYERS += "${BSPDIR}/meta-supermicro-x10srl"' >> conf/bblayers.conf
fi

CPU_CORES=$(nproc)
if ! grep -q "BB_NUMBER_THREADS" conf/local.conf; then
    echo "BB_NUMBER_THREADS = \"$CPU_CORES\"" >> conf/local.conf
    echo "PARALLEL_MAKE = \"-j $CPU_CORES\"" >> conf/local.conf
fi

echo -e "${GREEN}编译环境配置完成 ✓${NC}"
echo "使用 $CPU_CORES 个CPU核心进行并行编译"
echo ""

# 开始编译
echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  准备编译固件${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""
echo -e "${YELLOW}注意事项:${NC}"
echo "• 首次编译需要 2-4 小时"
echo "• 会下载约 10GB 源码包"
echo "• 编译目录约占用 40-50GB"
echo "• 编译过程中请勿关闭终端"
echo ""

read -p "确认开始编译? (yes/no): " START_BUILD

if [ "$START_BUILD" != "yes" ]; then
    echo ""
    echo "编译已取消。稍后可以手动编译:"
    echo "  cd $OPENBMC_DIR"
    echo "  . setup x10srl"
    echo "  bitbake obmc-phosphor-image"
    exit 0
fi

echo ""
echo -e "${GREEN}开始编译 OpenBMC 固件...${NC}"
echo ""

bitbake obmc-phosphor-image

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=================================================${NC}"
    echo -e "${GREEN}  ✓ 固件编译成功！${NC}"
    echo -e "${GREEN}=================================================${NC}"
    echo ""
    echo "固件位置:"
    echo "  $OPENBMC_DIR/build/tmp/deploy/images/x10srl/obmc-phosphor-image-x10srl.static.mtd"
    echo ""

    # 复制固件到项目目录
    mkdir -p "$PROJECT_DIR/firmware"
    cp "$OPENBMC_DIR/build/tmp/deploy/images/x10srl/obmc-phosphor-image-x10srl.static.mtd" \
       "$PROJECT_DIR/firmware/x10srl-openbmc-$(date +%Y%m%d).mtd"

    echo "固件已复制到:"
    echo "  $PROJECT_DIR/firmware/x10srl-openbmc-$(date +%Y%m%d).mtd"
    echo ""

    # 显示后续步骤
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${BLUE}  后续步骤${NC}"
    echo -e "${BLUE}=================================================${NC}"
    echo ""
    echo "1. 备份当前 BMC 固件:"
    echo "   cd $PROJECT_DIR"
    echo "   ./backup-bmc.sh -i <BMC_IP>"
    echo ""
    echo "2. 刷写新固件:"
    echo "   ./flash-firmware.sh -f firmware/x10srl-openbmc-$(date +%Y%m%d).mtd -m network -i <BMC_IP>"
    echo ""
    echo "3. 测试验证:"
    echo "   ./test-system.sh"
    echo "   ./test-ipmi.sh <BMC_IP>"
    echo ""

else
    echo ""
    echo -e "${RED}编译失败${NC}"
    echo "请查看错误日志"
    exit 1
fi

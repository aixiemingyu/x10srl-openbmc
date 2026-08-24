#!/bin/bash
# X10SRL OpenBMC 完整部署脚本

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

OPENBMC_DIR="$HOME/openbmc"
PROJECT_DIR=$(pwd)

show_banner() {
    echo -e "${BLUE}"
    echo "=================================================="
    echo "  X10SRL OpenBMC 完整部署向导"
    echo "=================================================="
    echo -e "${NC}"
}

check_dependencies() {
    echo -e "${YELLOW}检查系统依赖...${NC}"

    MISSING_DEPS=""

    for cmd in git wget tar python3 gcc make; do
        if ! command -v $cmd &>/dev/null; then
            MISSING_DEPS="$MISSING_DEPS $cmd"
        fi
    done

    if [ -n "$MISSING_DEPS" ]; then
        echo -e "${RED}缺少依赖:$MISSING_DEPS${NC}"
        echo ""
        echo "请先安装依赖 (Ubuntu/Debian):"
        echo "  sudo apt-get update"
        echo "  sudo apt-get install -y git build-essential python3 python3-distutils \\"
        echo "    gawk wget git diffstat unzip texinfo gcc chrpath socat cpio \\"
        echo "    python3-pip python3-pexpect xz-utils debianutils iputils-ping \\"
        echo "    python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 \\"
        echo "    xterm python3-subunit mesa-common-dev zstd liblz4-tool"
        exit 1
    fi

    echo -e "${GREEN}依赖检查通过 ✓${NC}"
    echo ""
}

check_disk_space() {
    echo -e "${YELLOW}检查磁盘空间...${NC}"

    AVAILABLE=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')

    if [ $AVAILABLE -lt 50 ]; then
        echo -e "${RED}警告: 可用空间不足 50GB (当前: ${AVAILABLE}GB)${NC}"
        echo "OpenBMC 编译需要大量磁盘空间"
        read -p "是否继续? (yes/no): " CONTINUE
        if [ "$CONTINUE" != "yes" ]; then
            exit 1
        fi
    else
        echo -e "${GREEN}磁盘空间充足: ${AVAILABLE}GB ✓${NC}"
    fi
    echo ""
}

clone_openbmc() {
    echo -e "${YELLOW}下载 OpenBMC 源码...${NC}"

    if [ -d "$OPENBMC_DIR" ]; then
        echo "OpenBMC 目录已存在: $OPENBMC_DIR"
        read -p "是否更新? (yes/no): " UPDATE
        if [ "$UPDATE" == "yes" ]; then
            cd "$OPENBMC_DIR"
            git pull
            cd "$PROJECT_DIR"
        fi
    else
        git clone https://github.com/openbmc/openbmc.git "$OPENBMC_DIR"
        echo -e "${GREEN}OpenBMC 下载完成 ✓${NC}"
    fi
    echo ""
}

copy_machine_layer() {
    echo -e "${YELLOW}复制机器配置层...${NC}"

    if [ ! -d "meta-supermicro-x10srl" ]; then
        echo -e "${RED}错误: 找不到 meta-supermicro-x10srl 目录${NC}"
        exit 1
    fi

    cp -r meta-supermicro-x10srl "$OPENBMC_DIR/"
    echo -e "${GREEN}机器配置层复制完成 ✓${NC}"
    echo ""
}

setup_build_env() {
    echo -e "${YELLOW}设置编译环境...${NC}"

    cd "$OPENBMC_DIR"

    # 初始化环境
    . setup x10srl

    # 添加层
    if ! grep -q "meta-supermicro-x10srl" conf/bblayers.conf; then
        echo 'BBLAYERS += "${BSPDIR}/meta-supermicro-x10srl"' >> conf/bblayers.conf
    fi

    # 设置并行编译
    CPU_CORES=$(nproc)
    if ! grep -q "BB_NUMBER_THREADS" conf/local.conf; then
        echo "BB_NUMBER_THREADS = \"$CPU_CORES\"" >> conf/local.conf
        echo "PARALLEL_MAKE = \"-j $CPU_CORES\"" >> conf/local.conf
    fi

    echo -e "${GREEN}编译环境设置完成 ✓${NC}"
    echo ""

    cd "$PROJECT_DIR"
}

build_firmware() {
    echo -e "${YELLOW}开始编译固件...${NC}"
    echo ""
    echo -e "${BLUE}注意: 首次编译可能需要数小时${NC}"
    echo -e "${BLUE}编译过程中会下载大量源码包${NC}"
    echo ""

    read -p "确认开始编译? (yes/no): " START_BUILD
    if [ "$START_BUILD" != "yes" ]; then
        echo "已取消编译"
        echo ""
        echo "稍后可以手动编译:"
        echo "  cd $OPENBMC_DIR"
        echo "  . setup x10srl"
        echo "  bitbake obmc-phosphor-image"
        exit 0
    fi

    cd "$OPENBMC_DIR"
    . setup x10srl

    echo ""
    echo -e "${GREEN}开始编译...${NC}"
    bitbake obmc-phosphor-image

    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}=================================================${NC}"
        echo -e "${GREEN}  固件编译成功！${NC}"
        echo -e "${GREEN}=================================================${NC}"
        echo ""
        echo "固件位置:"
        echo "  $OPENBMC_DIR/build/tmp/deploy/images/x10srl/obmc-phosphor-image-x10srl.static.mtd"
        echo ""
    else
        echo ""
        echo -e "${RED}编译失败${NC}"
        echo "请查看错误日志并尝试:"
        echo "  bitbake -c cleanall <failed-package>"
        echo "  bitbake obmc-phosphor-image"
        exit 1
    fi

    cd "$PROJECT_DIR"
}

show_next_steps() {
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${BLUE}  后续步骤${NC}"
    echo -e "${BLUE}=================================================${NC}"
    echo ""
    echo "1. 备份当前 BMC 固件:"
    echo "   ./backup-bmc.sh -i <BMC_IP>"
    echo ""
    echo "2. 测试新固件 (可选):"
    echo "   可以先在虚拟环境或测试机器上验证"
    echo ""
    echo "3. 刷写新固件:"
    echo "   ./flash-firmware.sh -f <固件路径> -m network -i <BMC_IP>"
    echo ""
    echo "   固件路径:"
    echo "   $OPENBMC_DIR/build/tmp/deploy/images/x10srl/obmc-phosphor-image-x10srl.static.mtd"
    echo ""
    echo "4. 等待 BMC 重启 (约 2-3 分钟)"
    echo ""
    echo "5. 验证新固件:"
    echo "   ./test-system.sh"
    echo "   ./test-ipmi.sh <BMC_IP>"
    echo ""
    echo "6. 监控 BMC 状态:"
    echo "   ./monitor-bmc.sh -i <BMC_IP>"
    echo ""
    echo -e "${YELLOW}重要提示:${NC}"
    echo "- 刷写前务必备份原始固件"
    echo "- 刷写过程中请勿断电"
    echo "- 建议先在测试环境验证"
    echo ""
}

# 主流程
main() {
    show_banner

    echo "此脚本将:"
    echo "  1. 检查系统依赖"
    echo "  2. 下载 OpenBMC 源码"
    echo "  3. 复制 X10SRL 配置层"
    echo "  4. 设置编译环境"
    echo "  5. 编译固件"
    echo ""

    read -p "确认继续? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "已取消"
        exit 0
    fi

    echo ""

    # 执行步骤
    check_dependencies
    check_disk_space
    clone_openbmc
    copy_machine_layer
    setup_build_env
    build_firmware
    show_next_steps

    echo -e "${GREEN}部署完成！${NC}"
}

# 运行主流程
main

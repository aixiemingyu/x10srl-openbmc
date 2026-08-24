#!/bin/bash
# X10SRL OpenBMC 快速编译脚本

set -e

echo "========================================="
echo "X10SRL OpenBMC 编译脚本"
echo "========================================="

# 检查是否在 OpenBMC 源码目录
if [ ! -f "setup" ]; then
    echo "错误: 请在 OpenBMC 源码根目录运行此脚本"
    exit 1
fi

# 检查 meta-supermicro-x10srl 是否存在
if [ ! -d "meta-supermicro-x10srl" ]; then
    echo "错误: 找不到 meta-supermicro-x10srl 层"
    echo "请将 meta-supermicro-x10srl 目录复制到当前目录"
    exit 1
fi

# 设置环境
echo "正在设置编译环境..."
. setup x10srl

# 检查并添加层到 bblayers.conf
if ! grep -q "meta-supermicro-x10srl" conf/bblayers.conf; then
    echo "添加 meta-supermicro-x10srl 层..."
    echo 'BBLAYERS += "${BSPDIR}/meta-supermicro-x10srl"' >> conf/bblayers.conf
fi

# 可选: 设置并行编译
CPU_CORES=$(nproc)
echo "检测到 $CPU_CORES 个CPU核心"

if ! grep -q "BB_NUMBER_THREADS" conf/local.conf; then
    echo "BB_NUMBER_THREADS = \"$CPU_CORES\"" >> conf/local.conf
    echo "PARALLEL_MAKE = \"-j $CPU_CORES\"" >> conf/local.conf
fi

# 显示编译信息
echo ""
echo "========================================="
echo "开始编译 X10SRL OpenBMC 固件"
echo "机器: x10srl"
echo "镜像: obmc-phosphor-image"
echo "并行度: $CPU_CORES"
echo "========================================="
echo ""
echo "注意: 首次编译可能需要数小时"
echo "建议准备至少 50GB 磁盘空间"
echo ""

read -p "按回车继续编译，或 Ctrl+C 取消..."

# 开始编译
bitbake obmc-phosphor-image

# 编译完成
echo ""
echo "========================================="
echo "编译完成!"
echo "========================================="
echo ""
echo "固件位置:"
echo "  build/tmp/deploy/images/x10srl/obmc-phosphor-image-x10srl.static.mtd"
echo ""
echo "可以使用以下命令刷写:"
echo "  flashcp -v obmc-phosphor-image-x10srl.static.mtd /dev/mtd0"
echo ""

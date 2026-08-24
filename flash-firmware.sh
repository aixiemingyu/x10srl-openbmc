#!/bin/bash
# X10SRL 固件刷写脚本

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FIRMWARE_FILE=""
BMC_IP=""
METHOD=""

show_usage() {
    echo "X10SRL OpenBMC 固件刷写工具"
    echo ""
    echo "用法:"
    echo "  $0 -f <固件文件> -m <方法> [-i <BMC_IP>]"
    echo ""
    echo "参数:"
    echo "  -f    固件文件路径"
    echo "  -m    刷写方法: network | local | webui"
    echo "  -i    BMC IP地址 (network方法必需)"
    echo ""
    echo "示例:"
    echo "  网络刷写: $0 -f firmware.mtd -m network -i 192.168.1.100"
    echo "  本地刷写: $0 -f firmware.mtd -m local"
    echo ""
}

while getopts "f:m:i:h" opt; do
    case $opt in
        f) FIRMWARE_FILE="$OPTARG" ;;
        m) METHOD="$OPTARG" ;;
        i) BMC_IP="$OPTARG" ;;
        h) show_usage; exit 0 ;;
        *) show_usage; exit 1 ;;
    esac
done

if [ -z "$FIRMWARE_FILE" ] || [ -z "$METHOD" ]; then
    show_usage
    exit 1
fi

if [ ! -f "$FIRMWARE_FILE" ]; then
    echo -e "${RED}错误: 固件文件不存在: $FIRMWARE_FILE${NC}"
    exit 1
fi

FIRMWARE_SIZE=$(stat -c%s "$FIRMWARE_FILE")
FIRMWARE_SIZE_MB=$((FIRMWARE_SIZE / 1024 / 1024))

echo "======================================"
echo "X10SRL 固件刷写工具"
echo "======================================"
echo "固件文件: $FIRMWARE_FILE"
echo "文件大小: ${FIRMWARE_SIZE_MB}MB"
echo "刷写方法: $METHOD"
echo "======================================"
echo ""

# 网络刷写
if [ "$METHOD" == "network" ]; then
    if [ -z "$BMC_IP" ]; then
        echo -e "${RED}错误: 网络刷写需要指定BMC IP地址${NC}"
        exit 1
    fi

    echo "目标BMC: $BMC_IP"
    echo ""
    echo -e "${YELLOW}警告: 刷写过程中请勿断电或中断连接！${NC}"
    echo -e "${YELLOW}建议先备份当前固件！${NC}"
    echo ""
    read -p "确认继续? (yes/no): " CONFIRM

    if [ "$CONFIRM" != "yes" ]; then
        echo "已取消"
        exit 0
    fi

    echo ""
    echo "步骤1: 连接BMC..."
    if ! ping -c 1 -W 2 $BMC_IP &>/dev/null; then
        echo -e "${RED}错误: 无法连接到BMC${NC}"
        exit 1
    fi
    echo -e "${GREEN}连接成功${NC}"

    echo ""
    echo "步骤2: 上传固件..."
    if ! scp "$FIRMWARE_FILE" root@$BMC_IP:/tmp/firmware.mtd; then
        echo -e "${RED}错误: 固件上传失败${NC}"
        exit 1
    fi
    echo -e "${GREEN}上传完成${NC}"

    echo ""
    echo "步骤3: 刷写固件..."
    ssh root@$BMC_IP << 'EOF'
        echo "开始刷写..."
        if flashcp -v /tmp/firmware.mtd /dev/mtd0; then
            echo "刷写完成"
            rm -f /tmp/firmware.mtd
            echo "10秒后重启..."
            sleep 10
            reboot
        else
            echo "刷写失败"
            exit 1
        fi
EOF

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}固件刷写成功！${NC}"
        echo "BMC正在重启，大约需要2-3分钟..."
        echo "请等待BMC重启后重新连接"
    else
        echo -e "${RED}固件刷写失败${NC}"
        exit 1
    fi

# 本地刷写（在BMC上执行）
elif [ "$METHOD" == "local" ]; then
    if [ ! -c /dev/mtd0 ]; then
        echo -e "${RED}错误: 未检测到MTD设备，请在BMC上运行此脚本${NC}"
        exit 1
    fi

    echo -e "${YELLOW}警告: 即将刷写本机固件！${NC}"
    echo -e "${YELLOW}确保固件文件正确，否则可能导致系统无法启动！${NC}"
    echo ""
    read -p "确认继续? (yes/no): " CONFIRM

    if [ "$CONFIRM" != "yes" ]; then
        echo "已取消"
        exit 0
    fi

    echo ""
    echo "备份当前固件到 /tmp/backup.mtd ..."
    if dd if=/dev/mtd0 of=/tmp/backup.mtd bs=1M; then
        echo -e "${GREEN}备份完成${NC}"
    else
        echo -e "${RED}备份失败，已取消刷写${NC}"
        exit 1
    fi

    echo ""
    echo "开始刷写固件..."
    if flashcp -v "$FIRMWARE_FILE" /dev/mtd0; then
        echo -e "${GREEN}刷写成功！${NC}"
        echo ""
        read -p "立即重启? (yes/no): " REBOOT
        if [ "$REBOOT" == "yes" ]; then
            reboot
        fi
    else
        echo -e "${RED}刷写失败${NC}"
        echo "尝试恢复备份..."
        flashcp -v /tmp/backup.mtd /dev/mtd0
        exit 1
    fi

# Web界面说明
elif [ "$METHOD" == "webui" ]; then
    echo "通过Web界面刷写固件："
    echo ""
    echo "1. 在浏览器中访问 BMC Web 界面"
    echo "   https://<BMC_IP>"
    echo ""
    echo "2. 使用管理员账户登录"
    echo "   默认用户名: root"
    echo "   默认密码: 0penBmc"
    echo ""
    echo "3. 导航到固件更新页面"
    echo "   通常在: Settings -> Firmware"
    echo ""
    echo "4. 选择固件文件并上传"
    echo "   文件: $FIRMWARE_FILE"
    echo ""
    echo "5. 等待上传和刷写完成"
    echo "   通常需要5-10分钟"
    echo ""
    echo "6. 系统会自动重启"
    echo ""

else
    echo -e "${RED}错误: 未知的刷写方法: $METHOD${NC}"
    echo "支持的方法: network, local, webui"
    exit 1
fi

echo ""
echo "======================================"
echo "刷写流程完成"
echo "======================================"

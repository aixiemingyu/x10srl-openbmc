#!/bin/bash
# 比较当前 BMC 固件与新固件的差异

if [ $# -lt 2 ]; then
    echo "用法: $0 <BMC_IP> <新固件文件>"
    echo "示例: $0 192.168.1.100 new-firmware.mtd"
    exit 1
fi

BMC_IP=$1
NEW_FIRMWARE=$2
TEMP_DIR=$(mktemp -d)

echo "======================================"
echo "固件比较工具"
echo "======================================"
echo "BMC IP: $BMC_IP"
echo "新固件: $NEW_FIRMWARE"
echo "======================================"
echo ""

# 1. 下载当前固件
echo "1. 下载当前 BMC 固件..."
if ssh root@$BMC_IP "dd if=/dev/mtd0 bs=1M" > "$TEMP_DIR/current.mtd" 2>/dev/null; then
    echo "   当前固件下载完成"
else
    echo "   下载失败"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# 2. 比较文件大小
echo ""
echo "2. 比较文件大小"
CURRENT_SIZE=$(stat -c%s "$TEMP_DIR/current.mtd")
NEW_SIZE=$(stat -c%s "$NEW_FIRMWARE")
CURRENT_MB=$((CURRENT_SIZE / 1024 / 1024))
NEW_MB=$((NEW_SIZE / 1024 / 1024))

echo "   当前固件: ${CURRENT_MB}MB"
echo "   新固件:   ${NEW_MB}MB"

if [ $CURRENT_SIZE -eq $NEW_SIZE ]; then
    echo "   大小相同 ✓"
else
    echo "   大小不同 (差异: $((NEW_SIZE - CURRENT_SIZE)) 字节)"
fi

# 3. 计算校验和
echo ""
echo "3. 计算校验和"
CURRENT_SHA=$(sha256sum "$TEMP_DIR/current.mtd" | cut -d' ' -f1)
NEW_SHA=$(sha256sum "$NEW_FIRMWARE" | cut -d' ' -f1)

echo "   当前固件: $CURRENT_SHA"
echo "   新固件:   $NEW_SHA"

if [ "$CURRENT_SHA" == "$NEW_SHA" ]; then
    echo "   固件相同，无需更新"
    rm -rf "$TEMP_DIR"
    exit 0
else
    echo "   固件不同，建议更新"
fi

# 4. 尝试提取版本信息
echo ""
echo "4. 版本信息"
echo "   当前版本:"
ssh root@$BMC_IP "cat /etc/os-release" 2>/dev/null | grep -E "VERSION|BUILD" | sed 's/^/     /'

# 5. 建议
echo ""
echo "======================================"
echo "建议"
echo "======================================"
echo "固件内容已改变，建议："
echo "1. 备份当前配置:"
echo "   ./backup-bmc.sh -i $BMC_IP"
echo ""
echo "2. 刷写新固件:"
echo "   ./flash-firmware.sh -f $NEW_FIRMWARE -m network -i $BMC_IP"
echo ""
echo "3. 刷写后测试:"
echo "   ./test-system.sh"
echo "   ./test-ipmi.sh $BMC_IP"
echo ""

# 清理
rm -rf "$TEMP_DIR"

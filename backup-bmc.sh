#!/bin/bash
# X10SRL OpenBMC 备份脚本

BMC_IP=""
BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

show_usage() {
    echo "X10SRL OpenBMC 备份工具"
    echo ""
    echo "用法:"
    echo "  $0 -i <BMC_IP> [-d <备份目录>]"
    echo ""
    echo "参数:"
    echo "  -i    BMC IP地址"
    echo "  -d    备份目录 (默认: backups)"
    echo ""
    echo "示例:"
    echo "  $0 -i 192.168.1.100"
    echo ""
}

while getopts "i:d:h" opt; do
    case $opt in
        i) BMC_IP="$OPTARG" ;;
        d) BACKUP_DIR="$OPTARG" ;;
        h) show_usage; exit 0 ;;
        *) show_usage; exit 1 ;;
    esac
done

if [ -z "$BMC_IP" ]; then
    show_usage
    exit 1
fi

mkdir -p "$BACKUP_DIR"
BACKUP_PATH="$BACKUP_DIR/x10srl_backup_${TIMESTAMP}"
mkdir -p "$BACKUP_PATH"

echo "======================================"
echo "X10SRL OpenBMC 备份工具"
echo "======================================"
echo "BMC IP: $BMC_IP"
echo "备份目录: $BACKUP_PATH"
echo "======================================"
echo ""

# 1. 备份固件
echo "1. 备份 BMC 固件..."
if ssh root@$BMC_IP "dd if=/dev/mtd0 bs=1M" > "$BACKUP_PATH/firmware.mtd" 2>/dev/null; then
    SIZE=$(du -h "$BACKUP_PATH/firmware.mtd" | cut -f1)
    echo "   固件备份完成: $SIZE"
else
    echo "   固件备份失败"
fi
echo ""

# 2. 备份配置
echo "2. 备份系统配置..."
ssh root@$BMC_IP "tar czf - /etc" > "$BACKUP_PATH/etc.tar.gz" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   配置备份完成"
else
    echo "   配置备份失败"
fi
echo ""

# 3. 备份网络配置
echo "3. 备份网络配置..."
ssh root@$BMC_IP "cat /etc/systemd/network/*.network" > "$BACKUP_PATH/network.conf" 2>/dev/null
echo "   网络配置已保存"
echo ""

# 4. 导出 IPMI 配置
echo "4. 导出 IPMI 配置..."
ipmitool -I lanplus -H $BMC_IP -U root -P 0penBmc lan print 1 > "$BACKUP_PATH/ipmi_lan.txt" 2>/dev/null
ipmitool -I lanplus -H $BMC_IP -U root -P 0penBmc user list 1 > "$BACKUP_PATH/ipmi_users.txt" 2>/dev/null
echo "   IPMI配置已导出"
echo ""

# 5. 备份 FRU 数据
echo "5. 备份 FRU 数据..."
ipmitool -I lanplus -H $BMC_IP -U root -P 0penBmc fru print > "$BACKUP_PATH/fru.txt" 2>/dev/null
echo "   FRU数据已保存"
echo ""

# 6. 备份传感器配置
echo "6. 备份传感器配置..."
ipmitool -I lanplus -H $BMC_IP -U root -P 0penBmc sensor list > "$BACKUP_PATH/sensors.txt" 2>/dev/null
ipmitool -I lanplus -H $BMC_IP -U root -P 0penBmc sdr list full > "$BACKUP_PATH/sdr.txt" 2>/dev/null
echo "   传感器配置已保存"
echo ""

# 7. 导出系统信息
echo "7. 导出系统信息..."
ssh root@$BMC_IP "uname -a" > "$BACKUP_PATH/system_info.txt" 2>/dev/null
ssh root@$BMC_IP "cat /etc/os-release" >> "$BACKUP_PATH/system_info.txt" 2>/dev/null
ssh root@$BMC_IP "ip addr" >> "$BACKUP_PATH/system_info.txt" 2>/dev/null
echo "   系统信息已导出"
echo ""

# 8. 备份 SEL 日志
echo "8. 备份 SEL 日志..."
ipmitool -I lanplus -H $BMC_IP -U root -P 0penBmc sel list > "$BACKUP_PATH/sel.txt" 2>/dev/null
ssh root@$BMC_IP "journalctl -b" > "$BACKUP_PATH/journal.log" 2>/dev/null
echo "   日志已备份"
echo ""

# 9. 创建备份清单
echo "9. 创建备份清单..."
cat > "$BACKUP_PATH/README.txt" << EOF
X10SRL OpenBMC 备份
==================

备份时间: $(date)
BMC IP: $BMC_IP

备份内容:
---------
- firmware.mtd       : BMC固件完整备份
- etc.tar.gz         : /etc 目录配置文件
- network.conf       : 网络配置
- ipmi_lan.txt       : IPMI LAN配置
- ipmi_users.txt     : IPMI用户列表
- fru.txt            : FRU数据
- sensors.txt        : 传感器列表
- sdr.txt            : SDR记录
- sel.txt            : SEL事件日志
- journal.log        : 系统日志
- system_info.txt    : 系统信息

恢复说明:
---------
1. 恢复固件:
   ./flash-firmware.sh -f firmware.mtd -m network -i <BMC_IP>

2. 恢复配置:
   scp etc.tar.gz root@<BMC_IP>:/tmp/
   ssh root@<BMC_IP> "cd / && tar xzf /tmp/etc.tar.gz"

3. 恢复网络配置:
   scp network.conf root@<BMC_IP>:/etc/systemd/network/
   ssh root@<BMC_IP> "systemctl restart systemd-networkd"
EOF

echo "   备份清单已创建"
echo ""

# 10. 计算校验和
echo "10. 计算校验和..."
cd "$BACKUP_PATH"
sha256sum * > checksums.txt 2>/dev/null
cd - >/dev/null
echo "   校验和已生成"
echo ""

# 显示备份摘要
echo "======================================"
echo "备份完成！"
echo "======================================"
echo "备份位置: $BACKUP_PATH"
echo ""
echo "文件列表:"
ls -lh "$BACKUP_PATH" | tail -n +2 | awk '{printf "  %-20s %s\n", $9, $5}'
echo ""

TOTAL_SIZE=$(du -sh "$BACKUP_PATH" | cut -f1)
echo "总大小: $TOTAL_SIZE"
echo ""
echo "建议将备份保存到安全位置！"

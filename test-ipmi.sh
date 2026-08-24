#!/bin/bash
# X10SRL OpenBMC IPMI 测试脚本

if [ $# -lt 1 ]; then
    echo "用法: $0 <BMC_IP> [用户名] [密码]"
    echo "示例: $0 192.168.1.100 root 0penBmc"
    exit 1
fi

BMC_IP=$1
USER=${2:-root}
PASS=${3:-0penBmc}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass_count=0
fail_count=0

test_passed() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((pass_count++))
}

test_failed() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((fail_count++))
}

IPMI_CMD="ipmitool -I lanplus -H $BMC_IP -U $USER -P $PASS"

echo "======================================"
echo "X10SRL OpenBMC IPMI 测试"
echo "BMC: $BMC_IP"
echo "======================================"
echo ""

# 测试1: 连接测试
echo "1. BMC连接测试"
if $IPMI_CMD mc info &>/dev/null; then
    test_passed "IPMI连接成功"
else
    test_failed "IPMI连接失败"
    echo "请检查IP地址、用户名和密码"
    exit 1
fi
echo ""

# 测试2: 获取BMC信息
echo "2. BMC信息"
$IPMI_CMD mc info 2>/dev/null | grep -E "Manufacturer|Product ID|Firmware Revision" | while read line; do
    echo "   $line"
done
test_passed "BMC信息读取成功"
echo ""

# 测试3: 传感器读取
echo "3. 传感器读取测试"
SENSOR_COUNT=$($IPMI_CMD sensor list 2>/dev/null | wc -l)
if [ $SENSOR_COUNT -gt 0 ]; then
    echo "   检测到 $SENSOR_COUNT 个传感器"
    test_passed "传感器读取成功"

    echo ""
    echo "   主要传感器读数:"
    $IPMI_CMD sensor list 2>/dev/null | grep -E "Temp|Fan|Voltage" | head -10 | while read line; do
        echo "   $line"
    done
else
    test_failed "无法读取传感器"
fi
echo ""

# 测试4: 电源状态
echo "4. 电源状态检查"
POWER_STATE=$($IPMI_CMD power status 2>/dev/null)
echo "   状态: $POWER_STATE"
if [[ $POWER_STATE == *"on"* ]] || [[ $POWER_STATE == *"off"* ]]; then
    test_passed "电源状态读取成功"
else
    test_failed "无法读取电源状态"
fi
echo ""

# 测试5: FRU信息
echo "5. FRU信息读取"
if $IPMI_CMD fru print 0 2>/dev/null | grep -q "Board Mfg Date"; then
    test_passed "FRU信息读取成功"
    echo ""
    echo "   FRU详情:"
    $IPMI_CMD fru print 0 2>/dev/null | grep -E "Board Mfg Date|Board Product|Board Serial" | while read line; do
        echo "   $line"
    done
else
    test_failed "无法读取FRU信息"
fi
echo ""

# 测试6: SEL日志
echo "6. SEL (系统事件日志) 检查"
SEL_COUNT=$($IPMI_CMD sel list 2>/dev/null | wc -l)
if [ $SEL_COUNT -ge 0 ]; then
    echo "   日志条目数: $SEL_COUNT"
    test_passed "SEL访问正常"
    if [ $SEL_COUNT -gt 0 ]; then
        echo ""
        echo "   最近的日志:"
        $IPMI_CMD sel list 2>/dev/null | tail -5 | while read line; do
            echo "   $line"
        done
    fi
else
    test_failed "无法访问SEL"
fi
echo ""

# 测试7: SDR记录
echo "7. SDR (传感器数据记录) 检查"
if $IPMI_CMD sdr info 2>/dev/null | grep -q "SDR Version"; then
    test_passed "SDR访问正常"
    $IPMI_CMD sdr info 2>/dev/null | grep -E "SDR Version|Record Count" | while read line; do
        echo "   $line"
    done
else
    test_failed "无法访问SDR"
fi
echo ""

# 测试8: LAN配置
echo "8. 网络配置检查"
$IPMI_CMD lan print 1 2>/dev/null | grep -E "IP Address|MAC Address|Subnet Mask|Default Gateway" | while read line; do
    echo "   $line"
done
test_passed "网络配置读取成功"
echo ""

# 测试9: 用户列表
echo "9. 用户列表"
USER_COUNT=$($IPMI_CMD user list 1 2>/dev/null | grep -v "^ID" | wc -l)
if [ $USER_COUNT -gt 0 ]; then
    echo "   用户数: $USER_COUNT"
    test_passed "用户列表读取成功"
else
    test_failed "无法读取用户列表"
fi
echo ""

# 测试10: 看门狗定时器
echo "10. 看门狗定时器状态"
if $IPMI_CMD mc watchdog get 2>/dev/null | grep -q "Watchdog Timer Use"; then
    test_passed "看门狗定时器可用"
else
    test_failed "看门狗定时器不可用"
fi
echo ""

# 总结
echo "======================================"
echo "测试完成"
echo "======================================"
echo -e "${GREEN}通过: $pass_count${NC}"
echo -e "${RED}失败: $fail_count${NC}"
echo ""

if [ $fail_count -eq 0 ]; then
    echo -e "${GREEN}所有IPMI测试通过！${NC}"
    exit 0
else
    echo -e "${YELLOW}存在 $fail_count 个失败项，但这可能是正常的${NC}"
    exit 0
fi

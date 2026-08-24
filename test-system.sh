#!/bin/bash
# X10SRL OpenBMC 测试脚本

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

test_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo "======================================"
echo "X10SRL OpenBMC 系统测试"
echo "======================================"
echo ""

# 测试1: 检查系统信息
echo "1. 系统信息检查"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "   OS: $NAME $VERSION"
    test_passed "系统信息正常"
else
    test_failed "无法读取系统信息"
fi
echo ""

# 测试2: 检查内核版本
echo "2. 内核版本检查"
KERNEL=$(uname -r)
echo "   内核: $KERNEL"
if [[ $KERNEL == *"aspeed"* ]]; then
    test_passed "ASPEED内核已加载"
else
    test_warning "未检测到ASPEED特定内核"
fi
echo ""

# 测试3: 检查网络接口
echo "3. 网络接口检查"
for iface in eth0 eth1; do
    if ip link show $iface &>/dev/null; then
        IP=$(ip -4 addr show $iface | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "未配置")
        echo "   $iface: $IP"
        test_passed "$iface 存在"
    else
        test_failed "$iface 不存在"
    fi
done
echo ""

# 测试4: 检查I2C总线
echo "4. I2C总线检查"
I2C_COUNT=$(ls /dev/i2c-* 2>/dev/null | wc -l)
if [ $I2C_COUNT -gt 0 ]; then
    echo "   检测到 $I2C_COUNT 个I2C总线"
    test_passed "I2C总线可用"
else
    test_failed "未检测到I2C总线"
fi
echo ""

# 测试5: 检查温度传感器
echo "5. 温度传感器检查"
SENSOR_FOUND=0
for sensor in /sys/class/hwmon/hwmon*/temp*_input; do
    if [ -f "$sensor" ]; then
        TEMP=$(($(cat $sensor) / 1000))
        SENSOR_NAME=$(basename $(dirname $sensor))
        echo "   $SENSOR_NAME: ${TEMP}°C"
        SENSOR_FOUND=1
    fi
done

if [ $SENSOR_FOUND -eq 1 ]; then
    test_passed "温度传感器工作正常"
else
    test_warning "未检测到温度传感器"
fi
echo ""

# 测试6: 检查风扇
echo "6. 风扇状态检查"
FAN_FOUND=0
for fan in /sys/class/hwmon/hwmon*/fan*_input; do
    if [ -f "$fan" ]; then
        RPM=$(cat $fan)
        FAN_NAME=$(basename $fan)
        echo "   $FAN_NAME: ${RPM} RPM"
        FAN_FOUND=1
    fi
done

if [ $FAN_FOUND -eq 1 ]; then
    test_passed "风扇监控正常"
else
    test_warning "未检测到风扇"
fi
echo ""

# 测试7: 检查LED
echo "7. LED检查"
LED_COUNT=0
for led in /sys/class/leds/*/brightness; do
    if [ -f "$led" ]; then
        LED_NAME=$(basename $(dirname $led))
        LED_STATE=$(cat $led)
        echo "   $LED_NAME: $LED_STATE"
        ((LED_COUNT++))
    fi
done

if [ $LED_COUNT -gt 0 ]; then
    test_passed "检测到 $LED_COUNT 个LED"
else
    test_warning "未检测到LED"
fi
echo ""

# 测试8: 检查IPMI服务
echo "8. IPMI服务检查"
for service in phosphor-ipmi-host phosphor-ipmi-net; do
    if systemctl is-active --quiet $service 2>/dev/null; then
        test_passed "$service 正在运行"
    else
        test_failed "$service 未运行"
    fi
done
echo ""

# 测试9: 检查D-Bus服务
echo "9. D-Bus服务检查"
if systemctl is-active --quiet dbus 2>/dev/null; then
    test_passed "D-Bus服务正常"
else
    test_failed "D-Bus服务异常"
fi
echo ""

# 测试10: 检查phosphor服务
echo "10. Phosphor核心服务检查"
PHOSPHOR_SERVICES=(
    "xyz.openbmc_project.Inventory.Manager"
    "xyz.openbmc_project.ObjectMapper"
    "xyz.openbmc_project.Settings"
)

for service in "${PHOSPHOR_SERVICES[@]}"; do
    if busctl list | grep -q "$service" 2>/dev/null; then
        test_passed "$service"
    else
        test_warning "$service 未找到"
    fi
done
echo ""

# 测试11: 检查存储
echo "11. 存储空间检查"
df -h / | tail -1 | while read fs size used avail use mount; do
    echo "   根分区: $used / $size ($use 已使用)"
    USE_NUM=${use%\%}
    if [ $USE_NUM -lt 80 ]; then
        test_passed "存储空间充足"
    else
        test_warning "存储空间不足"
    fi
done
echo ""

# 测试12: 检查内存
echo "12. 内存检查"
MEM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
MEM_USED=$(free -m | awk '/^Mem:/{print $3}')
MEM_FREE=$(free -m | awk '/^Mem:/{print $4}')
echo "   总内存: ${MEM_TOTAL}MB"
echo "   已使用: ${MEM_USED}MB"
echo "   可用: ${MEM_FREE}MB"
if [ $MEM_FREE -gt 50 ]; then
    test_passed "内存充足"
else
    test_warning "内存较少"
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
    echo -e "${GREEN}所有关键测试通过！${NC}"
    exit 0
else
    echo -e "${RED}存在 $fail_count 个失败项${NC}"
    exit 1
fi

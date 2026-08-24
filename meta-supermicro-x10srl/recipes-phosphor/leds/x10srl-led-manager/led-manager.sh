#!/bin/bash
# X10SRL LED Manager
# 管理系统状态LED和识别LED

LED_IDENTIFY="/sys/class/leds/identify/brightness"
LED_STATUS="/sys/class/leds/status/brightness"

# LED状态
LED_OFF=0
LED_ON=1
LED_BLINK=2

set_led() {
    local led=$1
    local state=$2

    if [ -f "$led" ]; then
        echo "$state" > "$led"
    fi
}

blink_led() {
    local led=$1
    local interval=${2:-500}

    if [ -f "${led%/*}/trigger" ]; then
        echo "timer" > "${led%/*}/trigger"
        echo "$interval" > "${led%/*}/delay_on"
        echo "$interval" > "${led%/*}/delay_off"
    fi
}

# 监控BMC状态
while true; do
    # 检查系统服务状态
    if systemctl is-active --quiet phosphor-ipmi-host.service && \
       systemctl is-active --quiet phosphor-net-ipmid.service; then
        # 系统正常运行 - 状态LED常亮
        set_led "$LED_STATUS" "$LED_ON"
    else
        # 系统异常 - 状态LED闪烁
        blink_led "$LED_STATUS" 250
    fi

    # 检查识别模式
    IDENTIFY_STATE=$(busctl get-property xyz.openbmc_project.LED.GroupManager \
        /xyz/openbmc_project/led/groups/enclosure_identify \
        xyz.openbmc_project.Led.Group Asserted 2>/dev/null | awk '{print $2}')

    if [ "$IDENTIFY_STATE" == "true" ]; then
        # 识别模式 - LED闪烁
        blink_led "$LED_IDENTIFY" 1000
    else
        # 正常模式 - LED关闭
        set_led "$LED_IDENTIFY" "$LED_OFF"
    fi

    sleep 5
done

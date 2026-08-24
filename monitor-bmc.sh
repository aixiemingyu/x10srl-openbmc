#!/bin/bash
# 监控 BMC 状态的脚本

BMC_IP=""
INTERVAL=60
LOG_FILE="bmc_monitor.log"

show_usage() {
    echo "X10SRL OpenBMC 监控工具"
    echo ""
    echo "用法:"
    echo "  $0 -i <BMC_IP> [-t <间隔秒数>] [-l <日志文件>]"
    echo ""
    echo "参数:"
    echo "  -i    BMC IP地址"
    echo "  -t    监控间隔 (默认: 60秒)"
    echo "  -l    日志文件 (默认: bmc_monitor.log)"
    echo ""
}

while getopts "i:t:l:h" opt; do
    case $opt in
        i) BMC_IP="$OPTARG" ;;
        t) INTERVAL="$OPTARG" ;;
        l) LOG_FILE="$OPTARG" ;;
        h) show_usage; exit 0 ;;
        *) show_usage; exit 1 ;;
    esac
done

if [ -z "$BMC_IP" ]; then
    show_usage
    exit 1
fi

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_ping() {
    if ping -c 1 -W 2 $BMC_IP &>/dev/null; then
        return 0
    else
        return 1
    fi
}

check_ipmi() {
    if ipmitool -I lanplus -H $BMC_IP -U root -P 0penBmc mc info &>/dev/null; then
        return 0
    else
        return 1
    fi
}

get_sensor_data() {
    ipmitool -I lanplus -H $BMC_IP -U root -P 0penBmc sensor list 2>/dev/null | \
        grep -E "Temp|Fan" | head -5
}

log_message "=== 开始监控 BMC: $BMC_IP ==="
log_message "监控间隔: ${INTERVAL}秒"

while true; do
    # 检查连通性
    if check_ping; then
        PING_STATUS="OK"
    else
        PING_STATUS="FAIL"
        log_message "警告: BMC无法ping通"
    fi

    # 检查 IPMI
    if check_ipmi; then
        IPMI_STATUS="OK"

        # 获取传感器数据
        log_message "--- 传感器状态 ---"
        get_sensor_data | while read line; do
            log_message "  $line"
        done
    else
        IPMI_STATUS="FAIL"
        log_message "警告: IPMI服务无响应"
    fi

    log_message "状态: PING=$PING_STATUS IPMI=$IPMI_STATUS"
    log_message ""

    sleep $INTERVAL
done

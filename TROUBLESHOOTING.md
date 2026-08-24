# X10SRL OpenBMC 故障排除指南

## 常见问题及解决方案

### 1. 编译问题

#### 问题: bitbake 编译失败
```
ERROR: Task xxx failed
```

**解决方案:**
```bash
# 清理特定包
bitbake -c cleanall <package-name>

# 清理临时文件
rm -rf tmp/

# 重新初始化环境
. setup x10srl

# 重新编译
bitbake obmc-phosphor-image
```

#### 问题: 缺少依赖
```
ERROR: Nothing PROVIDES 'xxx'
```

**解决方案:**
```bash
# 检查 layer 是否正确添加
bitbake-layers show-layers

# 添加缺失的 layer
bitbake-layers add-layer ../meta-xxx

# 更新层索引
bitbake-layers show-recipes
```

#### 问题: 磁盘空间不足
```
ERROR: No space left on device
```

**解决方案:**
```bash
# 清理下载缓存
rm -rf downloads/*

# 清理 sstate 缓存
rm -rf sstate-cache/*

# 清理临时文件
rm -rf tmp/

# 清理旧的构建
rm -rf build/tmp/deploy/images/*/
```

### 2. 网络问题

#### 问题: BMC 无法获取 IP 地址

**检查步骤:**
```bash
# 1. 检查网络接口状态
ip link show eth0

# 2. 检查 DHCP 客户端
systemctl status systemd-networkd

# 3. 查看网络日志
journalctl -u systemd-networkd -f

# 4. 手动配置静态IP
ip addr add 192.168.1.100/24 dev eth0
ip link set eth0 up
ip route add default via 192.168.1.1
```

**永久配置静态IP:**

编辑 `/etc/systemd/network/00-bmc-eth0.network`:
```ini
[Match]
Name=eth0

[Network]
Address=192.168.1.100/24
Gateway=192.168.1.1
DNS=8.8.8.8
```

重启网络服务:
```bash
systemctl restart systemd-networkd
```

#### 问题: SSH 无法连接

**检查步骤:**
```bash
# 1. 检查 SSH 服务
systemctl status sshd

# 2. 检查防火墙
iptables -L

# 3. 检查 SSH 配置
cat /etc/ssh/sshd_config

# 4. 重启 SSH 服务
systemctl restart sshd
```

### 3. IPMI 问题

#### 问题: ipmitool 无法连接

**检查步骤:**
```bash
# 1. 检查 IPMI 服务状态
systemctl status phosphor-ipmi-net
systemctl status phosphor-ipmi-host

# 2. 重启 IPMI 服务
systemctl restart phosphor-ipmi-net
systemctl restart phosphor-ipmi-host

# 3. 检查网络端口
netstat -tulpn | grep 623

# 4. 检查 IPMI 配置
ipmitool lan print 1
```

**从外部测试:**
```bash
# 测试连接
ipmitool -I lanplus -H <BMC_IP> -U root -P 0penBmc mc info

# 测试传感器
ipmitool -I lanplus -H <BMC_IP> -U root -P 0penBmc sensor list

# 测试电源控制
ipmitool -I lanplus -H <BMC_IP> -U root -P 0penBmc power status
```

#### 问题: 传感器读数为 0 或 na

**检查步骤:**
```bash
# 1. 检查 I2C 设备
i2cdetect -l
i2cdetect -y 7  # 扫描 I2C 总线 7

# 2. 检查传感器驱动
lsmod | grep lm75

# 3. 手动读取传感器
cat /sys/class/hwmon/hwmon*/temp*_input

# 4. 检查传感器配置
cat /usr/share/entity-manager/configurations/x10srl-baseboard.json
```

**修复方案:**
```bash
# 重新加载 I2C 驱动
modprobe -r i2c-aspeed
modprobe i2c-aspeed

# 重启传感器服务
systemctl restart xyz.openbmc_project.Hwmon*.service
```

### 4. 风扇问题

#### 问题: 风扇全速运转

**检查步骤:**
```bash
# 1. 检查风扇控制服务
systemctl status phosphor-pid-control

# 2. 查看风扇转速
cat /sys/class/hwmon/hwmon*/fan*_input

# 3. 查看 PWM 设置
cat /sys/class/hwmon/hwmon*/pwm*

# 4. 检查风扇配置
cat /usr/share/swampd/config.json
```

**手动控制风扇:**
```bash
# 设置风扇为手动模式
echo 1 > /sys/class/hwmon/hwmon0/pwm1_enable

# 设置风扇速度 (0-255)
echo 128 > /sys/class/hwmon/hwmon0/pwm1  # 50% 速度
echo 64 > /sys/class/hwmon/hwmon0/pwm1   # 25% 速度
echo 255 > /sys/class/hwmon/hwmon0/pwm1  # 100% 速度

# 恢复自动模式
echo 2 > /sys/class/hwmon/hwmon0/pwm1_enable
```

### 5. 固件刷写问题

#### 问题: 刷写后无法启动

**恢复步骤:**

**方法1: 使用备份固件 (如果有)**
```bash
# 使用编程器刷写备份固件
flashrom -p ch341a_spi -w backup.bin
```

**方法2: 通过串口进入 U-Boot**
```
# 连接串口，上电时按任意键进入 U-Boot
# 设置网络
setenv ipaddr 192.168.1.100
setenv serverip 192.168.1.10
saveenv

# 通过 TFTP 下载固件
tftp 0x80000000 firmware.mtd

# 刷写固件
sf probe
sf erase 0 0x2000000
sf write 0x80000000 0 0x2000000

# 重启
reset
```

#### 问题: 刷写卡在某个百分比

**解决方案:**
```bash
# 1. 不要中断，等待至少 30 分钟

# 2. 如果确实卡住，尝试重启
reboot

# 3. 检查 MTD 设备
cat /proc/mtd

# 4. 使用不同的刷写方法
dd if=firmware.mtd of=/dev/mtd0 bs=4096
```

### 6. 性能问题

#### 问题: BMC 响应缓慢

**诊断步骤:**
```bash
# 1. 检查 CPU 使用率
top

# 2. 检查内存使用
free -m

# 3. 检查磁盘 I/O
iostat

# 4. 检查系统负载
uptime

# 5. 查看系统日志
journalctl -p err -b
```

**优化方案:**
```bash
# 1. 停止不必要的服务
systemctl stop xyz.openbmc_project.xxx

# 2. 清理日志
journalctl --vacuum-size=10M

# 3. 重启 BMC
reboot
```

### 7. 串口调试

#### 连接串口

**硬件连接:**
- 波特率: 115200
- 数据位: 8
- 停止位: 1
- 校验: 无
- 流控: 无

**使用 minicom:**
```bash
minicom -D /dev/ttyUSB0 -b 115200
```

**使用 screen:**
```bash
screen /dev/ttyUSB0 115200
```

**查看启动日志:**
```
# 在串口中可以看到完整的启动过程
# U-Boot 输出
# 内核启动
# systemd 服务启动
```

### 8. D-Bus 问题

#### 问题: D-Bus 服务无法启动

**检查步骤:**
```bash
# 1. 检查 D-Bus 服务
systemctl status dbus

# 2. 查看 D-Bus 对象
busctl tree xyz.openbmc_project

# 3. 查看特定服务
busctl introspect xyz.openbmc_project.Inventory.Manager \
    /xyz/openbmc_project/inventory

# 4. 监控 D-Bus 消息
dbus-monitor --system
```

**重启 D-Bus 相关服务:**
```bash
systemctl restart dbus
systemctl restart xyz.openbmc_project.*
```

### 9. Web 界面问题

#### 问题: 无法访问 Web 界面

**检查步骤:**
```bash
# 1. 检查 Web 服务
systemctl status bmcweb

# 2. 检查端口
netstat -tulpn | grep 443

# 3. 查看日志
journalctl -u bmcweb -f

# 4. 重启 Web 服务
systemctl restart bmcweb
```

**临时启用 HTTP (调试用):**
```bash
# 编辑 bmcweb 配置
vi /etc/bmcweb/bmcweb.conf

# 重启服务
systemctl restart bmcweb
```

### 10. 权限问题

#### 问题: root 密码错误

**通过串口重置密码:**
```bash
# 1. 串口登录 (可能需要单用户模式)

# 2. 重置密码
passwd root

# 3. 或者直接修改
echo 'root:0penBmc' | chpasswd
```

### 11. GPIO 问题

#### 问题: LED 或按钮不工作

**检查 GPIO:**
```bash
# 查看 GPIO 列表
cat /sys/kernel/debug/gpio

# 导出 GPIO
echo 0 > /sys/class/gpio/export

# 设置方向
echo out > /sys/class/gpio/gpio0/direction

# 设置值
echo 1 > /sys/class/gpio/gpio0/value

# 读取值
cat /sys/class/gpio/gpio0/value
```

### 12. 更新后的验证清单

刷写新固件后，按顺序检查:

```bash
# 1. 等待 BMC 启动 (约 2-3 分钟)
ping <BMC_IP>

# 2. 检查 SSH
ssh root@<BMC_IP>

# 3. 运行系统测试
./test-system.sh

# 4. 运行 IPMI 测试
./test-ipmi.sh <BMC_IP>

# 5. 检查版本信息
cat /etc/os-release

# 6. 检查所有服务
systemctl --failed

# 7. 检查日志错误
journalctl -p err -b
```

## 获取帮助

如果以上方法都无法解决问题：

1. **收集日志信息:**
```bash
# 导出完整日志
journalctl -b > /tmp/boot.log

# 导出 dmesg
dmesg > /tmp/dmesg.log

# 系统信息
uname -a > /tmp/sysinfo.txt
```

2. **查阅文档:**
   - OpenBMC 官方文档: https://github.com/openbmc/docs
   - OpenBMC Discord: https://discord.gg/69Km47zH98

3. **提交问题:**
   - GitHub Issues: https://github.com/openbmc/openbmc/issues
   - 邮件列表: openbmc@lists.ozlabs.org

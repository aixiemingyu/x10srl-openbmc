# X10SRL OpenBMC 适配说明

## 项目概述

这是为 Supermicro X10SRL-F 主板适配的 OpenBMC 固件配置。

## 硬件规格

- **主板**: Supermicro X10SRL-F
- **BMC 芯片**: ASPEED AST2400
- **内存**: 512MB DDR3
- **闪存**: 32MB SPI Flash
- **网络**: 2个网口 (1个专用BMC + 1个共享)
- **传感器**: LM75温度传感器, ADC电压监控
- **风扇**: 支持最多5个PWM风扇

## 目录结构

```
openbmc-x10srl/
└── meta-supermicro-x10srl/
    ├── conf/
    │   ├── layer.conf                    # Layer配置
    │   └── machine/
    │       └── x10srl.conf               # 机器配置
    ├── recipes-kernel/
    │   └── linux/
    │       ├── linux-aspeed_%.bbappend   # 内核配置追加
    │       └── linux-aspeed/
    │           └── x10srl.dts            # 设备树
    └── recipes-phosphor/
        └── configuration/
            ├── x10srl-config.bb          # 配置包
            └── x10srl-config/
                ├── x10srl-baseboard.json      # 基板配置
                ├── x10srl-ipmi-fru.json       # FRU配置
                └── x10srl-ipmi-sensors.json   # 传感器配置
```

## 编译步骤

### 1. 准备环境

```bash
# 安装依赖 (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y git build-essential python3 python3-distutils \
    gawk wget git diffstat unzip texinfo gcc chrpath socat cpio \
    python3-pip python3-pexpect xz-utils debianutils iputils-ping \
    python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 \
    xterm python3-subunit mesa-common-dev zstd liblz4-tool
```

### 2. 下载 OpenBMC 源码

```bash
git clone https://github.com/openbmc/openbmc.git
cd openbmc
```

### 3. 复制配置层

```bash
# 将 meta-supermicro-x10srl 目录复制到 OpenBMC 源码树
cp -r /path/to/openbmc-x10srl/meta-supermicro-x10srl ./meta-supermicro-x10srl
```

### 4. 设置编译环境

```bash
# 初始化环境
. setup x10srl

# 添加自定义层到 bblayers.conf
echo 'BBLAYERS += "${BSPDIR}/meta-supermicro-x10srl"' >> conf/bblayers.conf
```

### 5. 开始编译

```bash
# 编译完整固件镜像 (需要数小时)
bitbake obmc-phosphor-image
```

编译完成后，固件位于：
```
build/tmp/deploy/images/x10srl/obmc-phosphor-image-x10srl.static.mtd
```

## 刷写固件

### 方法1: 通过网络刷写 (推荐)

如果当前BMC还能正常工作：

```bash
# 通过SCP上传固件
scp obmc-phosphor-image-x10srl.static.mtd root@<BMC_IP>:/tmp/

# SSH登录BMC
ssh root@<BMC_IP>

# 刷写固件
flashcp -v /tmp/obmc-phosphor-image-x10srl.static.mtd /dev/mtd0

# 重启
reboot
```

### 方法2: 通过编程器刷写

使用外置SPI编程器 (如CH341A):

1. 断电并拆下主板
2. 找到BMC的SPI Flash芯片 (通常是Winbond W25Q256 或类似)
3. 使用编程器读取原始固件作为备份
4. 刷写新固件
5. 装回主板并上电测试

**警告**: 刷写前务必备份原始固件！

### 方法3: 通过BMC Web界面

1. 登录当前BMC的Web界面
2. 找到固件更新页面
3. 上传 `obmc-phosphor-image-x10srl.static.mtd`
4. 等待更新完成并重启

## 首次启动

### 默认登录信息

- **用户名**: root
- **密码**: 0penBmc (注意是数字0)
- **网络**: DHCP自动获取IP，或使用默认IP

### 访问方式

1. **Web界面**: https://<BMC_IP>
2. **SSH**: `ssh root@<BMC_IP>`
3. **IPMI**: `ipmitool -I lanplus -H <BMC_IP> -U root -P 0penBmc sensor list`

## 配置说明

### 传感器配置

传感器定义在 `x10srl-ipmi-sensors.json`:
- CPU温度 (LM75 @ 0x48)
- 系统温度 (LM75 @ 0x49)
- 电压监控 (12V, 5V, 3.3V, VBAT)
- 风扇转速 (4个风扇)

### GPIO配置

LED和按钮在设备树 `x10srl.dts` 中定义：
- LED_IDENTIFY (GPIO A0)
- LED_STATUS (GPIO A1)

### 网络配置

- **eth0**: 专用BMC网口 (RGMII)
- **eth1**: 共享网口 (NCSI)

## 调试

### 串口调试

连接到BMC的调试串口 (UART5):
- 波特率: 115200
- 数据位: 8
- 停止位: 1
- 校验: 无

### 查看日志

```bash
# 系统日志
journalctl -f

# BMC服务状态
systemctl status phosphor-*
```

### 常见问题

**问题1**: 编译失败
- 解决: 确保所有依赖已安装，使用 `bitbake -c cleanall <package>` 清理后重试

**问题2**: 网络不通
- 解决: 检查网络配置，确保设备树中MAC配置正确

**问题3**: 传感器读数为0
- 解决: 检查I2C总线地址是否正确，使用 `i2cdetect` 扫描设备

## 进一步定制

### 修改GPIO映射

编辑 `x10srl.dts` 中的 gpio 和 leds 节点。

### 添加传感器

在 `x10srl-baseboard.json` 中添加新的传感器定义。

### 修改风扇控制策略

配置 `phosphor-fan-control` 服务的JSON配置文件。

## 参考资料

- [OpenBMC官方文档](https://github.com/openbmc/docs)
- [ASPEED AST2400数据手册](https://www.aspeedtech.com/products.php?fPath=20&rId=376)
- [Yocto Project文档](https://docs.yoctoproject.org/)

## 许可证

本配置遵循 Apache-2.0 许可证。

## 贡献

欢迎提交问题和改进建议！

---
创建日期: 2026-08-24
适配固件来源: x10srl-f-ipmi.bin (32MB)

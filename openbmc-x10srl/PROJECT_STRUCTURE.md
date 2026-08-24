# X10SRL OpenBMC 项目结构

```
openbmc-x10srl/
├── meta-supermicro-x10srl/          # OpenBMC 机器层
│   ├── conf/
│   │   ├── layer.conf               # Layer 配置
│   │   ├── machine/
│   │   │   ├── x10srl.conf          # 机器定义
│   │   │   └── x10srl-image.inc     # 镜像配置
│   │   └── local.conf.sample        # 本地配置示例
│   │
│   ├── recipes-kernel/
│   │   └── linux/
│   │       ├── linux-aspeed_%.bbappend       # 内核配置
│   │       └── linux-aspeed/
│   │           └── x10srl.dts                # 设备树
│   │
│   ├── recipes-phosphor/
│   │   ├── configuration/
│   │   │   ├── x10srl-config.bb              # 配置包
│   │   │   └── x10srl-config/
│   │   │       ├── x10srl-baseboard.json     # 基板配置
│   │   │       ├── x10srl-ipmi-fru.json      # FRU 配置
│   │   │       └── x10srl-ipmi-sensors.json  # 传感器映射
│   │   │
│   │   ├── ipmi/
│   │   │   ├── phosphor-ipmi-host_%.bbappend
│   │   │   └── phosphor-ipmi-host/
│   │   │       ├── ipmi-whitelist.conf       # IPMI 命令白名单
│   │   │       └── channel_config.json       # 通道配置
│   │   │
│   │   ├── leds/
│   │   │   ├── x10srl-led-manager.bb
│   │   │   └── x10srl-led-manager/
│   │   │       ├── led-manager.sh            # LED 管理脚本
│   │   │       └── led-manager.service       # Systemd 服务
│   │   │
│   │   ├── fans/
│   │   │   ├── phosphor-pid-control_%.bbappend
│   │   │   └── phosphor-pid-control/
│   │   │       └── config.json               # 风扇控制配置
│   │   │
│   │   └── x86-power-control/
│   │       ├── x86-power-control_%.bbappend
│   │       └── x86-power-control/
│   │           └── power-config.json         # 电源控制配置
│   │
│   └── recipes-core/
│       └── systemd/
│           ├── systemd-conf_%.bbappend
│           └── systemd-conf/
│               ├── 00-bmc-eth0.network       # eth0 网络配置
│               └── 00-bmc-eth1.network       # eth1 网络配置
│
├── 脚本工具/
│   ├── deploy.sh                    # 完整部署脚本
│   ├── build.sh                     # 编译脚本
│   ├── flash-firmware.sh            # 固件刷写工具
│   ├── backup-bmc.sh                # BMC 备份工具
│   ├── compare-firmware.sh          # 固件比较工具
│   ├── test-system.sh               # 系统测试脚本
│   ├── test-ipmi.sh                 # IPMI 测试脚本
│   └── monitor-bmc.sh               # BMC 监控工具
│
└── 文档/
    ├── README.md                    # 主文档
    ├── 快速开始.md                  # 快速入门
    ├── TROUBLESHOOTING.md           # 故障排除
    ├── CHANGELOG.md                 # 更新日志
    └── PROJECT_STRUCTURE.md         # 本文件
```

## 配置文件说明

### 设备树 (DTS)
**文件**: `recipes-kernel/linux/linux-aspeed/x10srl.dts`

定义硬件资源:
- CPU 和内存配置
- I2C 总线和设备
- GPIO 映射
- SPI Flash 布局
- PWM 风扇控制
- UART 串口
- 网络接口 (MAC)
- KCS IPMI 接口

### 机器配置
**文件**: `conf/machine/x10srl.conf`

定义机器特性:
- BMC 芯片型号 (AST2400)
- 闪存大小 (32MB)
- U-Boot 配置
- 内核设备树
- OpenBMC 功能特性
- 虚拟包提供者

### 传感器配置
**文件**: `recipes-phosphor/configuration/x10srl-config/x10srl-baseboard.json`

定义传感器:
- 温度传感器 (LM75)
  - CPU 温度
  - 系统温度
- 电压传感器 (ADC)
  - 12V, 5V, 3.3V
  - VBAT 电池电压
- 阈值设置
  - 临界值
  - 警告值

### IPMI 传感器映射
**文件**: `recipes-phosphor/configuration/x10srl-config/x10srl-ipmi-sensors.json`

映射 D-Bus 传感器到 IPMI SDR:
- 传感器 ID
- 传感器类型
- 读取类型
- 单位转换
- D-Bus 路径

### FRU 配置
**文件**: `recipes-phosphor/configuration/x10srl-config/x10srl-ipmi-fru.json`

定义 FRU 设备:
- I2C 总线和地址
- EEPROM 类型
- 设备名称

### 风扇控制配置
**文件**: `recipes-phosphor/fans/phosphor-pid-control/config.json`

PID 控制算法:
- 传感器输入
- 控制区域
- PID 参数
- 阶梯式控制曲线
- 故障保护设置

### 电源控制配置
**文件**: `recipes-phosphor/x86-power-control/x86-power-control/power-config.json`

GPIO 映射:
- 电源按钮
- 重置按钮
- 电源状态
- 电源输出
- 重置输出
- 时序参数

### 网络配置
**文件**: `recipes-core/systemd/systemd-conf/00-bmc-eth*.network`

systemd-networkd 配置:
- DHCP 设置
- 静态 IP (可选)
- DNS 配置
- NTP 配置
- MTU 设置

### IPMI 白名单
**文件**: `recipes-phosphor/ipmi/phosphor-ipmi-host/ipmi-whitelist.conf`

允许的 IPMI 命令:
- Chassis 命令
- Sensor/Event 命令
- App 命令
- Storage 命令
- Transport 命令
- OEM 命令

## 编译产物

编译完成后在 `build/tmp/deploy/images/x10srl/` 目录:

```
obmc-phosphor-image-x10srl.static.mtd         # 完整固件镜像
obmc-phosphor-image-x10srl.static.mtd.tar     # 固件归档
u-boot.bin                                     # U-Boot 引导加载器
fitImage-x10srl.bin                            # 内核 + 设备树
manifest-x10srl.txt                            # 包清单
```

## Yocto 层依赖

```
meta-supermicro-x10srl
  ├── depends on: meta-aspeed
  ├── depends on: meta-openembedded/meta-oe
  ├── depends on: meta-openembedded/meta-networking
  └── depends on: meta-phosphor
```

## D-Bus 接口

OpenBMC 使用 D-Bus 进行进程间通信:

```
xyz.openbmc_project.Inventory.Manager          # 硬件清单
xyz.openbmc_project.ObjectMapper               # 对象映射器
xyz.openbmc_project.Sensor.Value               # 传感器值
xyz.openbmc_project.Control.FanPwm             # 风扇控制
xyz.openbmc_project.State.Host                 # 主机状态
xyz.openbmc_project.State.Chassis              # 机箱状态
xyz.openbmc_project.State.BMC                  # BMC 状态
xyz.openbmc_project.Network                    # 网络管理
xyz.openbmc_project.User.Manager               # 用户管理
```

## Systemd 服务

主要系统服务:

```
phosphor-ipmi-host.service                     # IPMI 主机接口
phosphor-ipmi-net.service                      # IPMI 网络接口
xyz.openbmc_project.Hwmon@.service             # 硬件监控
xyz.openbmc_project.FanCtl.service             # 风扇控制
xyz.openbmc_project.LED.*.service              # LED 控制
x86-power-control.service                      # 电源控制
bmcweb.service                                 # Web 服务器
phosphor-discover-system-state.service         # 系统状态发现
```

## 开发工作流

1. **修改配置**: 编辑 `meta-supermicro-x10srl/` 下的配置文件
2. **清理包**: `bitbake -c cleanall <package>`
3. **重新编译**: `bitbake obmc-phosphor-image`
4. **提取固件**: 从 `build/tmp/deploy/images/x10srl/`
5. **刷写测试**: 使用 `flash-firmware.sh`
6. **验证功能**: 使用 `test-*.sh` 脚本

## 调试技巧

- **查看构建日志**: `build/tmp/work/x10srl/*/temp/log.do_*`
- **进入开发 shell**: `bitbake -c devshell <package>`
- **查看包依赖**: `bitbake -g obmc-phosphor-image`
- **查看配置**: `bitbake -e <package> | grep ^VARIABLE=`

## 贡献指南

修改建议:
1. Fork 项目
2. 创建特性分支
3. 提交变更
4. 发起 Pull Request

## 许可证

本项目遵循 Apache-2.0 许可证

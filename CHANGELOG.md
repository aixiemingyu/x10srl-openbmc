# X10SRL OpenBMC 项目更新日志

## [1.0.0] - 2026-08-24

### 新增功能
- ✅ 基础 OpenBMC 机器层配置
- ✅ ASPEED AST2400 设备树支持
- ✅ 温度传感器支持 (LM75)
- ✅ 电压监控 (ADC)
- ✅ 风扇控制 (PWM)
- ✅ IPMI 完整支持
- ✅ 网络配置 (双网口)
- ✅ LED 管理
- ✅ x86 电源控制
- ✅ FRU 数据管理
- ✅ SEL 事件日志

### 配置文件
- 设备树: `x10srl.dts`
- 机器配置: `x10srl.conf`
- 传感器配置: `x10srl-baseboard.json`
- IPMI 传感器映射: `x10srl-ipmi-sensors.json`
- FRU 配置: `x10srl-ipmi-fru.json`
- 风扇控制: PID 控制算法
- 电源控制: GPIO 映射
- 网络配置: systemd-networkd

### 工具脚本
- `build.sh` - 自动编译脚本
- `flash-firmware.sh` - 固件刷写工具
- `test-system.sh` - 系统测试脚本
- `test-ipmi.sh` - IPMI 测试脚本
- `backup-bmc.sh` - BMC 备份工具
- `monitor-bmc.sh` - BMC 监控工具

### 文档
- `README.md` - 详细说明文档
- `快速开始.md` - 快速入门指南
- `TROUBLESHOOTING.md` - 故障排除指南
- `CHANGELOG.md` - 更新日志

### 硬件支持
- CPU: Intel Xeon E5-2600 v3/v4
- BMC: ASPEED AST2400
- 内存: 512MB DDR3
- 闪存: 32MB SPI Flash
- 网络: 2x Gigabit Ethernet
- I2C: 14 个总线
- PWM: 5 个风扇通道
- GPIO: LED、按钮、电源控制

### 已知问题
- GPIO 映射需要根据实际硬件调整
- 部分传感器可能需要微调阈值
- VR (Voltage Regulator) 监控待完善

### 待完成
- [ ] SOL (Serial Over LAN) 配置
- [ ] Redfish API 完整测试
- [ ] KVM-over-IP 支持
- [ ] 虚拟媒体支持
- [ ] 更多 OEM IPMI 命令
- [ ] SNMP 支持
- [ ] LDAP/AD 认证

### 参考
基于以下版本开发:
- OpenBMC: master branch
- Linux Kernel: 5.15+
- U-Boot: v2021.10+
- Yocto: kirkstone/langdale

### 贡献者
- 初始适配: 基于 x10srl-f-ipmi.bin 固件分析

### 许可证
Apache-2.0

---

## 版本规划

### v1.1.0 (计划中)
- GPIO 完整映射
- 所有传感器验证
- SOL 支持
- 更多测试用例

### v1.2.0 (计划中)
- Redfish 完整支持
- Web UI 增强
- 性能优化
- 安全加固

### v2.0.0 (计划中)
- KVM-over-IP
- 虚拟媒体
- 固件更新回滚
- A/B 分区支持

# Supermicro X10SRL-F OpenBMC

**⚠️ EXPERIMENTAL - NOT HARDWARE VERIFIED ⚠️**

This is a **skeleton/starting-point** OpenBMC port for the Supermicro X10SRL-F motherboard with AST2400 BMC. It has **NOT** been tested on actual hardware and should be considered a development baseline only.

## Hardware

- **Board**: Supermicro X10SRL-F (Single socket LGA2011-3)
- **BMC**: ASPEED AST2400
- **Flash**: 32MB SPI NOR
- **Network**: Dual Ethernet (NCSI + dedicated)
- **Memory**: Conservative 256MB configured (actual may be 512MB - verify before use)

## Status

### ✅ What Works (In Theory)
- Builds successfully with OpenBMC mainline
- Basic AST2400 peripherals configured (UART, I2C, SPI, GPIO, ADC, PWM)
- Standard OpenBMC infrastructure (Redfish, IPMI, Web UI)

### ⚠️ What Needs Verification/Work
- **Device Tree**: GPIO, I2C sensor addresses, fan channels are **PLACEHOLDERS**
  - Need extraction from Supermicro GPL source (X10_GPL_Release_20150819.tar.gz)
  - LED GPIOs are guesses
  - Temperature sensor addresses are generic defaults
  - Fan tachometer mappings untested
  
- **Memory Size**: Configured conservatively at 256MB
  - Actual hardware may have 512MB
  - Verify before increasing

- **Power Control**: `power-config.json` needs GPIO pin verification
  
- **Sensor Configuration**: IPMI sensor mappings are minimal
  
- **FRU Data**: EEPROM location and format unverified

### ❌ Not Tested
- **NOTHING HAS BEEN TESTED ON REAL HARDWARE**
- Initial boot
- Network connectivity
- SOL (Serial-over-LAN)
- KVM/Virtual Media
- Power control
- Fan control
- Sensor readings

## ⚠️ CRITICAL WARNINGS ⚠️

### DO NOT Flash Over Existing BMC Firmware
**NEVER** perform an in-band flash (from the host OS) that overwrites the entire BMC chip on a working system. This will:
- Permanently brick your BMC if this firmware doesn't work
- Lose vendor-specific calibration data
- Void your ability to use vendor firmware features

### Safe Testing Methods
1. **External Programmer**: Use a dedicated SPI programmer to flash a backup chip
2. **Recovery Mode**: Only test if you have BMC recovery procedures
3. **Lab Board**: Test on a spare/sacrificial board first

### Backup First
Before ANY testing:
```bash
# Backup existing BMC firmware (if accessible)
flashrom -p linux_spi:dev=/dev/spidev0.0 -r backup-original.bin
# Keep this file safe!
```

## Build Instructions

```bash
# Clone OpenBMC
git clone https://github.com/openbmc/openbmc
cd openbmc

# Add this layer
git clone https://github.com/aixiemingyu/x10srl-openbmc meta-supermicro-x10srl

# Setup environment
. setup x10srl

# Build (takes 2-4 hours)
bitbake obmc-phosphor-image
```

The output image will be in:
```
tmp/deploy/images/x10srl/obmc-phosphor-image-x10srl.static.mtd
```

## Development Roadmap

### Phase 1: Hardware Verification (CURRENT)
- [ ] Extract actual GPIO mappings from GPL source
- [ ] Verify I2C sensor addresses
- [ ] Confirm memory size
- [ ] Map fan tachometer channels
- [ ] Test basic boot on hardware

### Phase 2: Core Functionality
- [ ] Power control (power on/off/reset)
- [ ] Sensor readings (temps, voltages, fans)
- [ ] Fan control (manual and auto)
- [ ] SOL console access

### Phase 3: Advanced Features
- [ ] KVM/Virtual Media
- [ ] Redfish API
- [ ] IPMI compatibility
- [ ] BMC configuration preservation

## Contributing

**Hardware owners needed!** If you have a X10SRL-F board:

1. **DO NOT flash this onto your working BMC** without external programming capability
2. Test in a safe environment with recovery options
3. Report findings (boot logs, sensor readings, GPIO states)
4. Help extract correct hardware mappings from GPL source

## References

- [Supermicro X10SRL-F Product Page](https://www.supermicro.com/products/motherboard/Xeon/C600/X10SRL-F.cfm)
- [Supermicro GPL Source](https://www.supermicro.com/wdl/GPL/SMT/X10_GPL_Release_20150819.tar.gz) (516MB)
- [OpenBMC Documentation](https://github.com/openbmc/docs)
- [ASPEED AST2400 Datasheet](https://github.com/openbmc/linux/tree/dev-6.10/arch/arm/boot/dts/aspeed)

## License

This OpenBMC port follows OpenBMC project licensing (Apache-2.0, GPL-2.0, etc.)

## Disclaimer

**USE AT YOUR OWN RISK**. This firmware is experimental and may:
- Fail to boot
- Damage hardware (unlikely but possible)
- Brick your BMC
- Cause data loss

The authors assume NO responsibility for any damage or data loss.

---

**Status**: Pre-alpha / Skeleton  
**Last Updated**: 2026-08-26  
**Maintainer**: Community (seeking hardware testers)

# Supermicro X10SRL-F OpenBMC (Skeleton)

**⚠️ SKELETON PORT - MINIMAL VERIFIED HARDWARE ONLY ⚠️**

This is a **skeleton/starting-point** OpenBMC port for the Supermicro X10SRL-F motherboard. Only SoC-level facts have been included. Board-specific hardware (GPIO, sensors, fans) is **NOT configured** and requires hardware access to verify.

## Hardware

- **Board**: Supermicro X10SRL-F (Single socket LGA2011-3)
- **BMC SoC**: ASPEED AST2400
- **Flash**: 32MB SPI NOR
- **Network**: Dual Ethernet (presumed NCSI + dedicated)
- **Memory**: 128MB configured (conservative - verify from U-Boot output)

## What's Actually in the Device Tree

### ✅ Confirmed (Safe to Enable)
- **AST2400 SoC** - from product documentation
- **32MB flash** - from product specs
- **128MB DRAM** - conservative estimate pending U-Boot verification
- **KCS3 @ 0xca2** - Supermicro standard convention
- **UART5 console** - standard BMC console
- **Dual network** - typical for AST2400 BMC

### ❌ Explicitly Disabled (Unknown/Unverified)
- **All I2C buses** - no device addresses known
- **All GPIO pins** - no pin assignments known
- **ADC channels** - no sensor mapping known
- **PWM/Fan control** - no tachometer channels known
- **LEDs** - GPIO pins unknown
- **Power control buttons** - GPIO pins unknown

### ⚠️ Needs Verification
- **Memory size** - need actual U-Boot output (could be 256MB or 512MB)
- **Network PHY type** - need U-Boot PHY detection (RMII vs RGMII)
- **I2C device tree** - need `ipmitool sdr elist` + `i2cdetect` output
- **GPIO assignments** - need vendor BMC `/sys/class/gpio` analysis
- **Fan channels** - need hardware testing or vendor driver analysis

## Status

This is **NOT a working BMC firmware**. It will:
- ✅ Boot to console
- ✅ Provide UART access
- ✅ Enable basic network (if PHY type is correct)
- ❌ NOT control power (GPIO unknown)
- ❌ NOT read sensors (I2C disabled)
- ❌ NOT control fans (PWM disabled)
- ❌ NOT provide full IPMI functionality

## Getting Real Hardware Info

### Required Information Sources

#### 1. Vendor U-Boot Output (CRITICAL)
Connect to BMC serial console during boot:
```
U-Boot 20xx.xx (Build date)
DRAM: XXX MB
...
PHY: detected RMII/RGMII
```
**Provides:** Memory size, network PHY type

#### 2. IPMI SDR List (from running host)
```bash
ipmitool -I lanplus -H <bmc-ip> -U ADMIN sdr elist full
```
**Provides:** Sensor list (NOT pin assignments, just presence)

#### 3. Vendor BMC Analysis (if accessible)
```bash
# From BMC serial console or SSH
dmesg | grep -i "i2c\|gpio\|pwm"
cat /proc/meminfo
ls /sys/class/gpio/
i2cdetect -y 0  # For each I2C bus 0-13
```
**Provides:** Active I2C addresses, GPIO usage, memory size

#### 4. Vendor Firmware Binary Analysis
```bash
strings BMC_X10AST2400-32M.bin | grep -i "BoardID\|KCS\|PWM\|GPIO"
strings GPL_modules/*.ko | grep -i "x10srl"
```
**Provides:** Possible hints (not definitive)

### What NOT to Do
- ❌ Don't guess I2C sensor addresses
- ❌ Don't enable all I2C buses "just in case"
- ❌ Don't set GPIO pin names without verification
- ❌ Don't configure GPIOs as outputs (can conflict with power sequencing)
- ❌ Don't copy configs from different boards

## Development Roadmap

### Phase 0: Information Gathering (CURRENT)
- [ ] Obtain U-Boot console output (memory, PHY type)
- [ ] Extract IPMI sensor list from running system
- [ ] Analyze vendor BMC if accessible
- [ ] Search for similar X10-series OpenBMC ports

### Phase 1: Basic Boot
- [ ] Verify memory size and update DTS
- [ ] Confirm network PHY type
- [ ] Test basic boot to console
- [ ] Verify flash layout doesn't corrupt vendor partitions

### Phase 2: I2C and Sensors (requires hardware)
- [ ] Map I2C buses to physical devices
- [ ] Identify FRU EEPROM location
- [ ] Map temperature sensors
- [ ] Enable only verified I2C buses

### Phase 3: Power Control (requires hardware + GPIO testing)
- [ ] Identify power button GPIO
- [ ] Identify reset button GPIO
- [ ] Identify power LED GPIO
- [ ] Test power on/off/reset sequences safely

### Phase 4: Fan Control (requires hardware + testing)
- [ ] Identify PWM channels to fan headers
- [ ] Identify tachometer inputs
- [ ] Create safe fan control policy
- [ ] Test without overheating

## Why So Minimal?

**"编得过也不等于这块板" - Compiles != Works on this board**

Previous OpenBMC ports that guessed hardware:
- Bricked BMCs by driving wrong GPIOs
- Caused power sequencing conflicts
- Failed to boot due to wrong memory size
- Corrupted vendor calibration data

This skeleton approach:
- Can't damage hardware (nothing is driven)
- Won't conflict with vendor firmware
- Provides a safe base for hardware discovery
- Makes testing requirements explicit

## References

- [Supermicro X10SRL-F](https://www.supermicro.com/products/motherboard/Xeon/C600/X10SRL-F.cfm)
- [GPL Source (516MB)](https://www.supermicro.com/wdl/GPL/SMT/X10_GPL_Release_20150819.tar.gz)
- [OpenBMC AST2400 Examples](https://github.com/openbmc/linux/tree/dev-6.10/arch/arm/boot/dts/aspeed)

## Contributing

**This port needs hardware owners.**

If you have an X10SRL-F:
1. **DO NOT flash this onto your BMC yet** - it's incomplete
2. Collect the information listed above (U-Boot, IPMI, i2cdetect)
3. Share outputs in an issue or pull request
4. Help verify each subsystem incrementally

## License

Apache-2.0 / GPL-2.0 (following OpenBMC project)

## Version

**0.1.0-skeleton** - Minimal DTS with only confirmed SoC facts  
**Last Updated**: 2026-08-26  
**Status**: Information gathering phase

# X10SRL-F Hardware Configuration Analysis Status

## GPL Source Analysis Results

### What We Found:
1. **Kernel**: Linux 2.6.28.9 (pre-device-tree era)
2. **Platform**: Generic AST2400 code in `arch/arm/mach-ast2300/`
3. **Configuration**: `platform_x10` build config (confirms AST2400, enables drivers)
4. **Factory XML**: Only IPMI configuration (users, network, alerts) - no hardware mapping

### What's Missing (Not in GPL Package):
- **Board-specific GPIO mappings** (power control, LEDs, buttons)
- **I2C sensor addresses** (temperature sensors, voltage monitors)
- **Fan tachometer channel assignments**
- **Memory size** (256MB vs 512MB)
- **Specific hardware initialization code**

## Why This Information is Missing

Supermicro's GPL release contains:
- ✅ Generic kernel and drivers
- ✅ Build configuration
- ✅ Open source components (web server, libraries)
- ❌ Board-specific hardware mappings (likely proprietary)
- ❌ IPMI sensor SDR data
- ❌ FRU data structures

The X10-specific configuration appears to be in **closed-source IPMI firmware**, not the GPL-covered kernel.

## Options Going Forward

### Option 1: Reverse Engineer from Hardware (RECOMMENDED)
**If you have physical access to an X10SRL-F board:**
- Boot with vendor BMC firmware
- Use `ipmitool sdr list` to get sensor addresses
- Use `ipmitool fru print` to get hardware layout
- Check `/sys/class/gpio/` for GPIO usage
- Check `i2cdetect` output for I2C devices
- Monitor power button behavior to find GPIO pins

**Tools needed:**
```bash
ipmitool sdr list full
ipmitool fru print 0
i2cdetect -y 0  # Check each I2C bus
cat /proc/meminfo  # Get real memory size
```

### Option 2: Use Similar Board as Template
Find an OpenBMC port for a similar Supermicro AST2400 board:
- X10DRi, X11SSL, or other X10/X11 series
- Copy their device tree as a starting point
- Adjust for single-socket layout

**Known similar boards:**
- `meta-supermicro` in OpenBMC has some X11 boards
- AST2400-based Supermicro boards in mainline

### Option 3: Start with Minimal Safe Configuration (CURRENT)
Keep the conservative skeleton we have:
- ✅ Basic peripherals enabled (UART, network, I2C buses)
- ✅ No specific GPIO/sensor assignments
- ✅ Conservative 256MB memory
- ✅ Clear "PLACEHOLDER" warnings

**This allows:**
- Building and basic boot testing
- Incremental hardware discovery
- Community contributions from hardware owners

### Option 4: Contact Supermicro
Request board schematics or hardware documentation for open source development.
Unlikely to succeed, but worth trying.

## Recommendations

### Short Term (Now):
1. **Keep current conservative device tree**
   - It will boot (if hardware is compatible)
   - UART console will work for debugging
   - Basic I2C/network should function

2. **Document what needs verification**
   - Update README with "Hardware Testing Needed" section
   - Create a checklist for first-boot testing
   - Add instructions for gathering hardware info

3. **Create hardware discovery script**
   - Script to run on first boot that logs:
     - Memory size
     - I2C device scan
     - GPIO state
     - Sensor readings (if accessible)

### Long Term (With Hardware Access):
1. Boot with vendor firmware
2. Collect all hardware information via IPMI tools
3. Map vendor sensor numbers to physical I2C addresses
4. Test GPIO pins systematically
5. Update device tree with real mappings
6. Verify each subsystem individually

## Current Device Tree Status

### What's Correct:
- Memory layout structure (just size is conservative)
- I2C bus enablement (all 14 buses)
- UART5 console (standard for BMC)
- Dual network (NCSI + dedicated)
- SPI flash layout (32MB, standard OpenBMC layout)

### What's Unknown:
- LED GPIO pins (A0, A1 are guesses)
- Temperature sensor addresses (0x48, 0x49 are generic defaults)
- Fan tachometer channels (0-4 is typical but unverified)
- FRU EEPROM location (i2c0@0x50 is common but unverified)
- Actual memory size (256MB vs 512MB)

## Decision Point

**Choose one:**

### A. Wait for hardware access
- Don't compile/release until verified
- Find someone with X10SRL-F hardware
- Test systematically before going public

### B. Release as experimental skeleton
- Keep current conservative config
- Add prominent warnings (done)
- Call for community hardware testing
- Expect initial version won't fully work

### C. Clone similar board
- Find closest X10 OpenBMC port
- Copy their DTS as starting point
- Mark as "based on X10xxx, untested on X10SRL"

## My Recommendation

**Go with Option B (Current Approach):**
1. The current device tree is conservative and safe
2. README clearly states it's unverified
3. It provides a starting point for hardware owners
4. Risk is minimized (won't damage hardware)
5. Community can contribute real data

**But do NOT build/release until:**
1. Add hardware discovery documentation
2. Create first-boot testing checklist
3. Add script to collect hardware info
4. Update README with "How to Help" section

Would you like me to:
1. Create a hardware discovery script for first boot?
2. Add detailed testing documentation?
3. Find a similar X10 board to use as reference?
4. Something else?

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://aspeed-bmc-supermicro-x10srl.dts"

do_configure:prepend() {
    # Copy device tree file to kernel source
    install -m 0644 ${WORKDIR}/aspeed-bmc-supermicro-x10srl.dts ${S}/arch/arm/boot/dts/aspeed/

    # Add device tree to Makefile if not already present
    if ! grep -q "aspeed-bmc-supermicro-x10srl.dtb" ${S}/arch/arm/boot/dts/aspeed/Makefile; then
        sed -i '/dtb-$(CONFIG_ARCH_ASPEED) += \\/a \\taspeed-bmc-supermicro-x10srl.dtb \\' ${S}/arch/arm/boot/dts/aspeed/Makefile
    fi
}

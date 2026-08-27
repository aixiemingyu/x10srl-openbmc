FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://aspeed-bmc-supermicro-x10srl.dts"

# Current Yocto unpacks file:// sources into UNPACKDIR (${WORKDIR}/sources),
# not WORKDIR. Copy the out-of-tree DTS into the shared kernel tree after
# patches so KERNEL_DEVICETREE can find it.
do_patch:append() {
    dts="${UNPACKDIR}/aspeed-bmc-supermicro-x10srl.dts"
    if [ ! -f "${dts}" ]; then
        dts="${WORKDIR}/aspeed-bmc-supermicro-x10srl.dts"
    fi
    if [ ! -f "${dts}" ]; then
        bbfatal "x10srl DTS not found in UNPACKDIR or WORKDIR"
    fi
    install -D -m 0644 "${dts}" ${S}/arch/arm/boot/dts/aspeed/aspeed-bmc-supermicro-x10srl.dts

    if ! grep -q "aspeed-bmc-supermicro-x10srl.dtb" ${S}/arch/arm/boot/dts/aspeed/Makefile; then
        echo "dtb-\$(CONFIG_ARCH_ASPEED) += aspeed-bmc-supermicro-x10srl.dtb" >> ${S}/arch/arm/boot/dts/aspeed/Makefile
    fi
}

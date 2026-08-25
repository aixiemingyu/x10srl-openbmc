FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://aspeed-bmc-supermicro-x10srl.dts"

do_configure:prepend() {
    install -m 0644 ${WORKDIR}/aspeed-bmc-supermicro-x10srl.dts ${S}/arch/arm/boot/dts/aspeed/
}

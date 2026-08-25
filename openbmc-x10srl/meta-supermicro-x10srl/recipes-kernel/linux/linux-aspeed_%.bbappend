FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://aspeed-bmc-supermicro-x10srl.dts"

do_compile:prepend() {
    cp ${WORKDIR}/aspeed-bmc-supermicro-x10srl.dts ${S}/arch/arm/boot/dts/aspeed/
}

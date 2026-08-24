FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://x10srl.dts"

do_install:append() {
    install -d ${D}/boot/dts
    install -m 0644 ${WORKDIR}/x10srl.dts ${D}/boot/dts/aspeed-bmc-supermicro-x10srl.dts
}

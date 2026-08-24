FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://00-bmc-eth0.network \
    file://00-bmc-eth1.network \
    "

FILES:${PN} += " \
    ${sysconfdir}/systemd/network/00-bmc-eth0.network \
    ${sysconfdir}/systemd/network/00-bmc-eth1.network \
    "

do_install:append() {
    install -d ${D}${sysconfdir}/systemd/network
    install -m 0644 ${WORKDIR}/00-bmc-eth0.network \
        ${D}${sysconfdir}/systemd/network/
    install -m 0644 ${WORKDIR}/00-bmc-eth1.network \
        ${D}${sysconfdir}/systemd/network/
}

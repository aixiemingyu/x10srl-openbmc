FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://power-config.json"

FILES:${PN} += "${datadir}/x86-power-control/power-config.json"

do_install:append() {
    install -d ${D}${datadir}/x86-power-control
    install -m 0644 ${WORKDIR}/power-config.json \
        ${D}${datadir}/x86-power-control/power-config.json
}

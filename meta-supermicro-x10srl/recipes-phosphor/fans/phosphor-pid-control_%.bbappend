FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://config.json"

FILES:${PN} += "${datadir}/swampd/config.json"

do_install:append() {
    install -d ${D}${datadir}/swampd
    install -m 0644 ${WORKDIR}/config.json \
        ${D}${datadir}/swampd/config.json
}

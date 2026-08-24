FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://ipmi-whitelist.conf \
    file://channel_config.json \
    "

do_install:append() {
    install -d ${D}${sysconfdir}/ipmi
    install -m 0644 ${WORKDIR}/ipmi-whitelist.conf ${D}${sysconfdir}/ipmi/
    install -m 0644 ${WORKDIR}/channel_config.json ${D}${datadir}/ipmi-providers/
}

FILES:${PN} += " \
    ${sysconfdir}/ipmi/ipmi-whitelist.conf \
    ${datadir}/ipmi-providers/channel_config.json \
    "

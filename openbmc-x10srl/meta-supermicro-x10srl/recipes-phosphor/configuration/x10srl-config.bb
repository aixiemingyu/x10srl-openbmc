SUMMARY = "X10SRL Hardware Configuration"
PR = "r1"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit allarch

SRC_URI = " \
    file://x10srl-baseboard.json \
    file://x10srl-ipmi-fru.json \
    file://x10srl-ipmi-sensors.json \
    "

FILES:${PN}-dev = " \
    ${datadir}/entity-manager/configurations/x10srl-baseboard.json \
    ${datadir}/ipmi-providers/x10srl-ipmi-fru.json \
    ${datadir}/ipmi-providers/x10srl-ipmi-sensors.json \
    "

do_install() {
    install -d ${D}${datadir}/entity-manager/configurations
    install -m 0644 -D ${WORKDIR}/x10srl-baseboard.json \
        ${D}${datadir}/entity-manager/configurations/x10srl-baseboard.json

    install -d ${D}${datadir}/ipmi-providers
    install -m 0644 -D ${WORKDIR}/x10srl-ipmi-fru.json \
        ${D}${datadir}/ipmi-providers/x10srl-ipmi-fru.json
    install -m 0644 -D ${WORKDIR}/x10srl-ipmi-sensors.json \
        ${D}${datadir}/ipmi-providers/x10srl-ipmi-sensors.json
}

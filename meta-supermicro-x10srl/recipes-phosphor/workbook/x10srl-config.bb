SUMMARY = "X10SRL Hardware Configuration"
DESCRIPTION = "Hardware configuration for Supermicro X10SRL-F board"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"
PR = "r1"

inherit obmc-phosphor-systemd
inherit allarch

PROVIDES += "virtual/obmc-system-mgmt"
RPROVIDES:${PN} += "virtual-obmc-system-mgmt"

SRC_URI = " \
    file://x10srl.json \
    "

S = "${WORKDIR}"

do_install() {
    install -d ${D}${datadir}/${PN}
    install -m 0644 ${WORKDIR}/x10srl.json ${D}${datadir}/${PN}/
}

FILES:${PN} += "${datadir}/${PN}/x10srl.json"

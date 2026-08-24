SUMMARY = "X10SRL Hardware Configuration"
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

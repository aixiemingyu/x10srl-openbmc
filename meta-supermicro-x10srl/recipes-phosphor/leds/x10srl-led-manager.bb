SUMMARY = "X10SRL System LED Manager"
DESCRIPTION = "Manage system LEDs for X10SRL"
PR = "r1"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd

RDEPENDS:${PN} += "bash"

SRC_URI = "file://led-manager.sh \
           file://led-manager.service"

S = "${UNPACKDIR}"

do_install() {
    install -d ${D}${sbindir}
    install -m 0755 ${UNPACKDIR}/led-manager.sh ${D}${sbindir}/led-manager.sh

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/led-manager.service ${D}${systemd_system_unitdir}/
}

SYSTEMD_SERVICE:${PN} = "led-manager.service"

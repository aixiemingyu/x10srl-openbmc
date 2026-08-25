FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://aspeed-bmc-supermicro-x10srl.dts"

do_patch:append() {
    for DTB in "${KERNEL_DEVICETREE}"; do
        DT=`basename ${DTB} .dtb`
        if [ -r "${UNPACKDIR}/${DT}.dts" ]; then
            cp ${UNPACKDIR}/${DT}.dts \
                ${STAGING_KERNEL_DIR}/arch/${ARCH}/boot/dts/aspeed/
        fi
    done
}

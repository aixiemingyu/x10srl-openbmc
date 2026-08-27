FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Compile-time allowlist only. Do not install channel_config.json here;
# that file belongs to phosphor-ipmi-config.
SRC_URI += "file://ipmi-whitelist.conf"
WHITELIST_CONF = "${UNPACKDIR}/ipmi-whitelist.conf"

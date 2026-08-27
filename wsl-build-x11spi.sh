#!/bin/bash
set -eo pipefail
export HOME=/home/eason
export USER=eason
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export BBSERVER="${BBSERVER:-}"

LOG=/home/eason/openbmc-build/bitbake-x11spi.log
OBMC=/home/eason/openbmc-build/openbmc
cd "$OBMC"

# Separate dir from x10srl (which uses ./build)
. ./setup x11spi build-x11spi

mkdir -p /home/eason/openbmc-downloads /home/eason/openbmc-sstate-cache

if ! grep -q 'X11SPI_LOCAL_TWEAKS' conf/local.conf; then
  cat >> conf/local.conf << 'EOF'

# X11SPI_LOCAL_TWEAKS
BB_NUMBER_THREADS = "6"
PARALLEL_MAKE = "-j 6"
INHERIT += "rm_work"
DL_DIR = "/home/eason/openbmc-downloads"
SSTATE_DIR = "/home/eason/openbmc-sstate-cache"
# 32MB NOR is tight (openbmc#4045 ~500KB over). Keep bmcweb/webui-vue.
IMAGE_FEATURES:remove = "obmc-ikvm obmc-devtools obmc-user-mgmt-ldap"
EOF
fi

echo "PWD=$(pwd)"
echo "MACHINE=$(grep '^MACHINE' conf/local.conf | head -n 1)"
echo "==== starting x11spi bitbake $(date -Iseconds) ====" | tee "$LOG"
set -o pipefail
bitbake obmc-phosphor-image 2>&1 | tee -a "$LOG"
echo "==== bitbake exit $? $(date -Iseconds) ====" | tee -a "$LOG"

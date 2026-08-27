#!/bin/bash
set -eo pipefail
export HOME=/home/eason
export USER=eason
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export BBSERVER="${BBSERVER:-}"

LAYER_SRC=/mnt/c/Users/eason/Downloads/openbmc-x10srl/meta-supermicro-x10srl
OBMC=/home/eason/openbmc-build/openbmc

rm -rf "$OBMC/meta-supermicro-x10srl"
cp -a "$LAYER_SRC" "$OBMC/meta-supermicro-x10srl"
find "$OBMC/meta-supermicro-x10srl" -type f \( \
  -name '*.conf' -o -name '*.inc' -o -name '*.bb' -o -name '*.bbappend' \
  -o -name '*.dts' -o -name '*.json' -o -name '*.sample' \
\) -exec sed -i 's/\r$//' {} +

echo "==== layer machine files ===="
ls -la "$OBMC/meta-supermicro-x10srl/conf/machine"

cd "$OBMC"
echo "==== running setup x10srl ===="
# TEMPLATECONF is more reliable than OpenBMC machine registry
export TEMPLATECONF=meta-supermicro-x10srl/conf/templates/default
. ./openbmc-env

mkdir -p /home/eason/openbmc-downloads /home/eason/openbmc-sstate-cache

if ! grep -q 'BB_NUMBER_THREADS' conf/local.conf; then
  cat >> conf/local.conf << 'EOF'

BB_NUMBER_THREADS = "6"
PARALLEL_MAKE = "-j 6"
INHERIT += "rm_work"
DL_DIR = "/home/eason/openbmc-downloads"
SSTATE_DIR = "/home/eason/openbmc-sstate-cache"
EOF
fi

echo SETUP_OK
pwd
echo "==== local.conf tail ===="
tail -20 conf/local.conf
echo "==== bblayers ===="
cat conf/bblayers.conf

#!/bin/bash
export HOME=/home/eason
export USER=eason
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export BBSERVER="${BBSERVER:-}"
LOG=/home/eason/openbmc-build/bitbake.log
LAYER_SRC=/mnt/c/Users/eason/Downloads/openbmc-x10srl/meta-supermicro-x10srl
OBMC=/home/eason/openbmc-build/openbmc
LOCK="$OBMC/build/bitbake.lock"

mkdir -p "$OBMC/meta-supermicro-x10srl"
cp -a "$LAYER_SRC/." "$OBMC/meta-supermicro-x10srl/"
find "$OBMC/meta-supermicro-x10srl" -type f \( \
  -name '*.conf' -o -name '*.inc' -o -name '*.bb' -o -name '*.bbappend' \
  -o -name '*.dts' -o -name '*.json' -o -name '*.sample' \
\) -exec sed -i 's/\r$//' {} +

cd "$OBMC"
export TEMPLATECONF=meta-supermicro-x10srl/conf/templates/default
. ./openbmc-env

# Another bitbake may still be draining in-flight tasks after linux-aspeed failed.
for i in $(seq 1 180); do
  if [ ! -e "$LOCK" ]; then
    break
  fi
  if ! pgrep -f 'bitbake obmc-phosphor-image' >/dev/null 2>&1; then
    rm -f "$LOCK" "$OBMC/build/bitbake.sock" 2>/dev/null || true
    break
  fi
  echo "==== waiting for previous bitbake to exit ($i) $(date -Iseconds) ====" | tee -a "$LOG"
  sleep 20
done

echo "==== resume bitbake $(date -Iseconds) ====" | tee -a "$LOG"
bitbake obmc-phosphor-image 2>&1 | tee -a "$LOG"
echo "==== bitbake finished $(date -Iseconds) ====" | tee -a "$LOG"

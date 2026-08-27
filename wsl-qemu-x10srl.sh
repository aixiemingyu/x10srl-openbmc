#!/bin/bash
export HOME=/home/eason
export USER=eason
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export BBSERVER="${BBSERVER:-}"
export DISPLAY=
SERIAL=/home/eason/openbmc-build/qemu-serial.log
PIDF=/home/eason/openbmc-build/qemu-x10srl.pid
IMG=/home/eason/openbmc-build/openbmc/build/tmp/deploy/images/x10srl/obmc-phosphor-image-x10srl.static.mtd
QEMU=/home/eason/openbmc-build/openbmc/build/tmp/work/x86_64-linux/qemu-helper-native/1.0/recipe-sysroot-native/usr/bin/qemu-system-arm
NATIVE=/home/eason/openbmc-build/openbmc/build/tmp/work/x86_64-linux/qemu-helper-native/1.0/recipe-sysroot-native

if [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF")" 2>/dev/null; then
  kill "$(cat "$PIDF")" 2>/dev/null || true
  sleep 1
fi

pkill -f 'qemu-system-arm -net nic,netdev=net0' 2>/dev/null || true
: > "$SERIAL"
export LD_LIBRARY_PATH="$NATIVE/usr/lib:$NATIVE/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# display none + serial file: stdin EOF must not kill the VM
# setsid: survive SIGHUP when the parent WSL session exits
setsid "$QEMU" \
  -net nic,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp:0.0.0.0:2222-:22,hostfwd=tcp:0.0.0.0:2323-:23,hostfwd=tcp:0.0.0.0:2443-:443,hostfwd=tcp:0.0.0.0:8080-:80 \
  -drive file="$IMG",if=mtd,format=raw \
  -machine palmetto-bmc \
  -m 512 \
  -snapshot \
  -display none \
  -serial tcp:0.0.0.0:2200,server,nowait \
  -serial null \
  -monitor none \
  -action watchdog=none \
  </dev/null >/home/eason/openbmc-build/qemu-stderr.log 2>&1 &
echo $! > "$PIDF"
# setsid child may be the session leader; wait until qemu-system-arm exists
sleep 1
QP=$(pgrep -n -f 'qemu-system-arm -net nic,netdev=net0' || true)
if [ -n "$QP" ]; then
  echo "$QP" > "$PIDF"
fi
echo "QEMU_PID=$(cat "$PIDF")"
sleep 2
if kill -0 "$(cat "$PIDF")" 2>/dev/null; then
  echo QEMU_RUNNING
else
  echo QEMU_DIED
  cat /home/eason/openbmc-build/qemu-stderr.log
fi

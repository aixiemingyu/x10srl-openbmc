#!/bin/bash
export HOME=/home/eason
export USER=eason
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export BBSERVER="${BBSERVER:-}"
LOG=/home/eason/openbmc-build/bitbake.log
cd /home/eason/openbmc-build/openbmc
export TEMPLATECONF=meta-supermicro-x10srl/conf/templates/default
. ./openbmc-env
echo "==== starting bitbake $(date -Iseconds) ====" | tee "$LOG"
bitbake obmc-phosphor-image 2>&1 | tee -a "$LOG"
echo "==== bitbake exit $? $(date -Iseconds) ====" | tee -a "$LOG"

#!/bin/bash
export HOME=/home/eason
export USER=eason
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export BBSERVER="${BBSERVER:-}"
cd /home/eason/openbmc-build/openbmc
export TEMPLATECONF=meta-supermicro-x10srl/conf/templates/default
. ./openbmc-env
echo "==== bitbake parse ===="
bitbake -p
echo PARSE_OK

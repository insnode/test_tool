#!/bin/bash
pdir=$(cd -P $(dirname $0); pwd)
cd $pdir
set -e
modprobe msr
chmod +x *
./cli << EOF
l memory
view memory
geteccinfo
q
q
EOF

#!/bin/bash
# set -e
pdir=$(cd -P $(dirname $0); pwd)
cd $pdir
echo "EquipMentModeFlag 1" > memset.ini
./memtest_config.sh
./uniCfg -w EnableBiosSsaRMTonFCB:1
./uniCfg -w RankMargin:0
./uniCfg -w EnableBiosSsaRMT:1
./uniCfg -w BiosSsaPerBitMargining:1
./uniCfg -w BiosSsaDebugMessages:5
./uniCfg -w SysDbgLevel:1
#ipmitool chassis power cycle
echo "finished..."

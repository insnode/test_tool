#!/bin/bash
A=$(free  | grep -i mem | awk '{print $7}')
B=0.08
C=`echo "scale=0; $A * $B"| bc | awk -F "[.]" '{print $1}'` 
D=`lscpu | grep  "^CPU(s):"|awk '{print $2}'`
#stress -c $D --vm 10 --vm-bytes ${C}K --vm-keep -t 28800 >/root/Desktop/stresslog/stress.log
stress -c $D --vm 10 --vm-bytes ${C}K --vm-keep -d 1 --hdd-bytes 5G -t 28800 >/root/Desktop/stresslog/stress.log

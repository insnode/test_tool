#!/bin/bash
lsblk > /root/Desktop/stresslog/hdd.log && 
sleep 5
lspci |grep -i eth >/root/Desktop/stresslog/eth.log && 
sleep 5
dmidecode -t memory >/root/Desktop/stresslog/mem.log && 
sleep 5
lscpu >/root/Desktop/stresslog/cpu.log && 
sleep 5
lspci >/root/Desktop/stresslog/lspci.log

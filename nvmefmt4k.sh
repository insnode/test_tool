#!/bin/bash
#nvme format /dev/nvmexnx -n 1 -l 2

nvme=$(lsblk|grep ^nvme|awk '{print $1}')
for n in $nvme
do
    echo "formatting $n device"
    line=$(nvme id-ns -H /dev/$n | grep "^LBA" |  grep "Data Size: 4096 bytes" | grep "Metadata Size: 0   bytes" )
    [ "$?" -ne "0" ] && { echo "Error: The LBA Format specified is not supported."; exit 1; }
    num=$(echo $line | awk -F ' ' '{print $3}')
    # echo $num
    nvme format /dev/$n -n 1 -l $num
    [ "$?" -ne "0" ] && exit 1
done
nvme list
exit 0
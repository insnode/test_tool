```bash
需要从以下两个方面优化（以ubuntu系统为例）：
一、使用numactl运行程序，将程序绑定在指定的CPU上
    1. 安装numactl
        sudo apt install numactl
    2. 用numactl运行程序，将程序运行在node1上
        numactl -N 1 -m 1 command args ...
二、配置RAID驱动参数，设置中断处理CPU
    1. 重新配置RAID驱动
        # 卸载驱动（不同的RAID驱动不一样，需要注意）
        rmmod megaraid_sas
        或者 rmmod mpt3sas
        # 用指定参数加载驱动
        modprobe megaraid_sas msix_vectors=40 smp_affinity_enable=0
        或者 modprobe mpt3sas max_msix_vectors=40 smp_affinity_enable=0
    2. 将中断处理程序绑定在指定的CPU核心上
        # 停用irqbalance
        systemctl stop irqbalance.service
        systemctl disable irqbalance.service
        # 将中断处理程序绑定到node1的40个核心上
        ./set_affinity.sh

如何查看RAID驱动：
1. 使用命令lspci查看设备对应的slot，如下：
    0000:01:00.0 RAID bus controller: Broadcom / LSI MegaRAID SAS-3 3108 [Invader] (rev 02)
    前面的0000:01:00.0即为slot编号
2. 使用命令lspci -s 0000:01:00.0 -vvv查看使用的驱动名称，如下：
    ......
    Kernel driver in use: megaraid_sas
    ......
    可以看出驱动名称为megaraid_sas

如何实现自动加载RAID驱动时携带参数
1. 在/etc/modprobe.d下新建config文件，如megaraid_sas.conf
2. 编辑文件，内容如下：
    options megaraid_sas msix_vectors=40 smp_affinity_enable=0
    或者 options mpt3sas max_msix_vectors=40 smp_affinity_enable=0
3. 更新ramdisk（不同的系统有不同的命令）
    update-initramfs

set_affinity.sh是如何工作的，如何调整
1. set_affinity.sh通过遍历所有中断进行查找，使用了驱动相关的名字。
    通过cat /proc/interrupts看出哪些中断属于RAID，如
    112:  ...... ITS-MSI 524365 Edge      megasas12-msix77
    可以看出megasas开头的属于RAID卡
2. 修改set_affinity.sh中的匹配规则
    temp_intf=`ls /proc/irq/**/megasas*`
    将megasas改成上面对应的字符串

注意：
卸载驱动前需要先RAID下的磁盘umount。


[root@localhost ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: enP1p5s0f0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether f0:41:c8:c3:3b:92 brd ff:ff:ff:ff:ff:ff
3: enP1p5s0f1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether f0:41:c8:c3:3b:93 brd ff:ff:ff:ff:ff:ff
    inet 192.168.3.28/24 brd 192.168.3.255 scope global dynamic noprefixroute enP1p5s0f1
       valid_lft 83865sec preferred_lft 83865sec
    inet6 fe80::f241:c8ff:fec3:3b93/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
4: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 1000
    link/ether f0:41:c8:c2:45:41 brd ff:ff:ff:ff:ff:ff
[root@localhost ~]# pwd
/root
[root@localhost ~]# ls
1                auto_mount.sh  fio.fio  mergerfs                          -R          satalocalext2_18thrd_1600g_recsize_1m_sep  test_iozone3.sh  vdbench50407.zip
anaconda-ks.cfg  -b             iozone3  mergerfs-2.32.6-1.el7.x86_64.rpm  report.xls  satalocalext2_36thrd_1600g_recsize_1m_sep  vdbench          -w

#!/bin/bash

FILESIZE=1600g
RECSIZE=1m
THREADS=18
OUTPUTFILE=""
#SLEEP_DURATION=7200

I=0
FILES=""

while [ $I -lt 64 ]
do
    FILES=$FILES" ""/mnt/data1/k${I} /mnt/data2/k${I} /mnt/data3/k${I}"
   #FILES=$FILES" ""/mnt/data/k${I}"
   # FILES=$FILES" ""/pool/k${I}"

   I=$((I + 1))
done

#echo $FILES

while true
do
    OUTPUTFILE="satalocalext2_${THREADS}thrd_${FILESIZE}_recsize_${RECSIZE}_sep"
    echo "Reading and Writing test starting ..." >> $OUTPUTFILE
    /root/iozone3/src/current/iozone -r ${RECSIZE} -s $FILESIZE -t $THREADS -F $FILES -i 1 -w -R -b report.xls -c -C -+k -+n -e >> $OUTPUTFILE
    echo "Reading and Writing test Finished ..." >> $OUTPUTFILE
    echo " " >> $OUTPUTFILE
#    sleep 2
done
~

NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda           8:0    0  14.6T  0 disk 
└─sda1        8:1    0  14.6T  0 part /mnt/data1
sdb           8:16   0  14.6T  0 disk 
└─sdb1        8:17   0  14.6T  0 part /mnt/data2
sdc           8:32   0  14.6T  0 disk 
└─sdc1        8:33   0  14.6T  0 part /mnt/data3
nvme0n1     259:0    0   477G  0 disk 
├─nvme0n1p1 259:1    0   600M  0 part /boot/efi
├─nvme0n1p2 259:2    0     1G  0 part /boot
└─nvme0n1p3 259:3    0 475.4G  0 part 
  ├─rl-root 253:0    0    70G  0 lvm  /
  ├─rl-swap 253:1    0  26.5G  0 lvm  [SWAP]
  └─rl-home 253:2    0 378.9G  0 lvm  /home





```

```bash
[root@localhost ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: enP1p5s0f0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether f0:41:c8:c3:3b:92 brd ff:ff:ff:ff:ff:ff
3: enP1p5s0f1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether f0:41:c8:c3:3b:93 brd ff:ff:ff:ff:ff:ff
    inet 192.168.3.28/24 brd 192.168.3.255 scope global dynamic noprefixroute enP1p5s0f1
       valid_lft 83537sec preferred_lft 83537sec
    inet6 fe80::f241:c8ff:fec3:3b93/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
4: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 1000
    link/ether f0:41:c8:c2:45:41 brd ff:ff:ff:ff:ff:ff
[root@localhost ~]# ls
1                auto_mount.sh  fio.fio  mergerfs                          -R          satalocalext2_18thrd_1600g_recsize_1m_sep  test_iozone3.sh  vdbench50407.zip
anaconda-ks.cfg  -b             iozone3  mergerfs-2.32.6-1.el7.x86_64.rpm  report.xls  satalocalext2_36thrd_1600g_recsize_1m_sep  vdbench          -w
[root@localhost ~]# cat test_iozone3.sh
#!/bin/bash

FILESIZE=1600g
RECSIZE=1m
THREADS=18
OUTPUTFILE=""
#SLEEP_DURATION=7200

I=0
FILES=""

while [ $I -lt 64 ]
do
    FILES=$FILES" ""/mnt/data1/k${I} /mnt/data2/k${I} /mnt/data3/k${I}"
   #FILES=$FILES" ""/mnt/data/k${I}"
   # FILES=$FILES" ""/pool/k${I}"

   I=$((I + 1))
done

#echo $FILES

while true
do
    OUTPUTFILE="satalocalext2_${THREADS}thrd_${FILESIZE}_recsize_${RECSIZE}_sep"
    echo "Reading and Writing test starting ..." >> $OUTPUTFILE
    /root/iozone3/src/current/iozone -r ${RECSIZE} -s $FILESIZE -t $THREADS -F $FILES -i 1 -w -R -b report.xls -c -C -+k -+n -e >> $OUTPUTFILE
    echo "Reading and Writing test Finished ..." >> $OUTPUTFILE
    echo " " >> $OUTPUTFILE
#    sleep 2
done
[root@localhost ~]#
```


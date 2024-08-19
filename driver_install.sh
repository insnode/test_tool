#通用加载驱动脚本
FILEPATH=$(cd "$(dirname "$0")"; pwd)  #该脚本所在目录
if [ ! -z "$(uname -a | grep "aarch64")" ]  #检测机型
then
    MACHINE="ARM"
elif [ ! -z "$(uname -a | grep "x86_64")" ]
then
    MACHINE="X86"
else
    exit 1
fi

DIRVER_NAME=(host_edma_drv 
            host_cdev_drv 
            host_kbox_drv 
            host_veth_drv)   #驱动数组

NUM1=${#DIRVER_NAME[*]}   #数组长度
for ((i=0; i<$NUM1 ; i++))
do  
    if [ -z "$(lsmod | grep "${DIRVER_NAME[i]}")" ]
    then
        echo "${DIRVER_NAME[i]} 未安装,即将加载"
        insmod $FILEPATH/$MACHINE/${DIRVER_NAME[i]}.ko
        if [ "$?" != 0 ] ; then
            echo "驱动${DIRVER_NAME[i]}加载失败"
            status=($i)  #错误标志
        fi
    fi
done

for ((i=0; i<$NUM1 ; i++))
do  
    if [ ! -z "$(lsmod | grep "${DIRVER_NAME[i]}")" ]
    then
        echo "${DIRVER_NAME[i]} 已加载"
    else
        echo "${DIRVER_NAME[i]} 加载失败"
    fi
done

if [ ! -z $status ]
then
    # 任意驱动加载失败，返回错误信息
    exit 1
else
    exit 0
fi
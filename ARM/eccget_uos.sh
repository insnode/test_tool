machine=$(uname -m)               #判断机型，选择工具目录
if [ "$machine" = "aarch64" ]; then
    toolpath="ARM"
else
    toolpath="X86"
fi
path=`pwd`
result=`echo $path | grep "${toolpath}"`      #判断当前路径
if [[ "$result" == "" ]] ; then
    cd $path/PLAN/test_tools/$toolpath
fi
./eccget_uos ${1} ${2} ${3}
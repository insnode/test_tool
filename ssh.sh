#!/bin/bash

## 用法: auto_ssh root密码 root@10.71.162.232 "ls"  10.71.162.232

## $1 用户名和IP
## $2 执行的shell命令
## $3 密码
## $4 IP
## spawn bash -c "ssh $user \"$cmd\""

user=$2
cmd=$3
user_pwd=$1
IP=$4

ssh-keygen -f ~/.ssh/known_hosts -R $IP

expect<< END


spawn bash -c "ssh $user \"$cmd\""

set timeout -1
expect {
    "continue" {
        send "yes\n"
		expect "*assword:" { send "$user_pwd\n"}
    }

    "assword" {
        send "$user_pwd\n"
    }
}

expect eof

catch wait result
exit [lindex \$result 3]

END
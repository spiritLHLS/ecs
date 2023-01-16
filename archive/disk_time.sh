#!/bin/bash
# by https://github.com/spiritLHLS/ecs

# 检测所有硬盘通电时长
disk_list=$(ls /dev/sd* /dev/vd* /dev/hd* | grep -v [0-9])

#检测smartctl是否安装
if ! command -v smartctl &> /dev/null
then
    echo "smartctl not found, installing smartctl..."
    if [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
        yum install smartmontools -y
    elif [ -f /etc/debian_version ]; then
        apt-get install smartmontools -y
    elif [ -f /etc/fedora-release ]; then
        dnf install smartmontools -y
    elif [ -f /etc/arch-release ]; then
        pacman -S smartmontools -y
    elif [ -f /etc/alpine-release ]; then
        apk add smartmontools
    else
        echo "Unsupported distribution, please install smartctl manually"
        exit 1
    fi
fi

for disk_dev in $disk_list
do
    smart_info=$(smartctl -a $disk_dev)
    # 检测是否支持power on hours
    if echo "$smart_info" | grep -q "Power_On_Hours" ; then
        power_on_hours=$(echo "$smart_info" | grep "Power_On_Hours" | awk '{print $10}')
        echo "$disk_dev Power on hours: $power_on_hours"
    else
        echo "$disk_dev does not support Power on hours"
    fi
done




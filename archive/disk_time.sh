#!/bin/bash
# by https://github.com/spiritLHLS/ecs

# 检测所有硬盘
disk_list=$(ls /dev/sd*)
if [ -d "/dev/vd*" ]; then
   disk_list="$disk_list $(ls /dev/vd*)"
fi
if [ -d "/dev/hd*" ]; then
   disk_list="$disk_list $(ls /dev/hd*)"
fi

#检测smartctl是否安装
if ! command -v smartctl &> /dev/null
then
    echo "smartctl not found, installing smartctl..."
    if [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
        yum install smartmontools -y
    elif [ -f /etc/debian_version ]; then
        apt-get install smartmontools -y
    elif [ -f /etc/fedora-release ]; then
        dnf install smart -y
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
    smart_info=$(smartctl -i $disk_dev)
    vendor=$(echo "$smart_info" | grep "Vendor" | awk '{print $2}')
    echo "Disk: $disk_dev"
    echo "Vendor: $vendor"
    smart_info=$(smartctl -a $disk_dev)
    vendor=""
    if [ $vendor == "ATA" ]; then
        #ATA硬盘
        if echo "$smart_info" | grep -q "Power_On_Hours" ; then
            power_on_hours=$(echo "$smart_info" | grep "Power_On_Hours" | awk '{print $10}')
            echo "Power_On_Hours: $power_on_hours"
        else
            echo "Power_On_Hours not supported"
        fi
        if echo "$smart_info" | grep -q "Reallocated_Sector_Ct" ; then
            reallocated_sector=$(echo "$smart_info" | grep "Reallocated_Sector_Ct" | awk '{print $10}')
            echo "Reallocated_Sector_Ct: $reallocated_sector"
        else
            echo "Reallocated_Sector_Ct not supported"
        fi
        if echo "$smart_info" | grep -q "Temperature_Celsius" ; then
            temperature=$(echo "$smart_info" | grep "Temperature_Celsius" | awk '{print $10}')
            echo "Temperature_Celsius: $temperature"
        else
            echo "Temperature_Celsius not supported"
        fi
    elif [ $vendor == "SATA" ]; then
        #SATA硬盘
        if echo "$smart_info" | grep -q "Power_On_Hours" ; then
            power_on_hours=$(echo "$smart_info" | grep "Power_On_Hours" | awk '{print $10}')
            echo "Power_On_Hours: $power_on_hours"
        else
            echo "Power_On_Hours not supported"
        fi
        if echo "$smart_info" | grep -q "Reallocated_Sector_Ct" ; then
            reallocated_sector=$(echo "$smart_info" | grep "Reallocated_Sector_Ct" | awk '{print $10}')
            echo "Reallocated_Sector_Ct: $reallocated_sector"
        else
            echo "Reallocated_Sector_Ct not supported"
        fi
        if echo "$smart_info" | grep -q "Temperature_Celsius" ; then
            temperature=$(echo "$smart_info" | grep "Temperature_Celsius" | awk '{print $10}')
            echo "Temperature_Celsius: $temperature"
        else
            echo "Temperature_Celsius not supported"
        fi
    else
        #其他硬盘
        echo "Other vendor SMART attributes"
    fi
    echo ""
done



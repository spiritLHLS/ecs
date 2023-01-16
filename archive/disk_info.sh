#!/bin/bash
# by https://github.com/spiritLHLS/ecs

# 检测所有盘
disk_list=""
if ls -d /dev/sd* > /dev/null 2>&1; then
    disk_list="$disk_list $(ls /dev/sd*)"
fi
if ls -d /dev/vd* > /dev/null 2>&1; then
    disk_list="$disk_list $(ls /dev/vd*)"
fi
if ls -d /dev/hd* > /dev/null 2>&1; then
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
clear
# echo $disk_list
for disk_dev in $disk_list
do
    smart_info=$(smartctl -i $disk_dev)
    vendor=$(echo "$smart_info" | grep "Vendor" | awk '{print $2}')
    if [[ -z "$vendor" ]]; then
        vendor="UNKNOWN"
    fi
    echo "盘路径: $disk_dev"
    echo "供应商: $vendor"
    smart_info=$(smartctl -a $disk_dev)
    if echo "$smart_info" | grep -q "Power_On_Hours" ; then
        power_on_hours=$(echo "$smart_info" | grep "Power_On_Hours" | awk '{print $10}')
        echo "通电时长(越高越好): $power_on_hours"
    # else
    #     echo "通电时长(越高越好)不可检测"
    fi
    if echo "$smart_info" | grep -q "Power_Cycle_Count" ; then
        power_cycle_count=$(echo "$smart_info" | grep "Power_Cycle_Count" | awk '{print $10}')
        echo "电源循环次数(越少越好): $power_cycle_count"
    # else
    #     echo "电源循环次数(越少越好)不可检测"
    fi
    if echo "$smart_info" | grep -q "Raw_Read_Error_Rate" ; then
        raw_read_error_rate=$(echo "$smart_info" | grep "Raw_Read_Error_Rate" | awk '{print $10}')
        echo "读取错误率(越低越好): $raw_read_error_rate"
    # else
    #     echo "读取错误率(越低越好)不可检测"
    fi
    if echo "$smart_info" | grep -q "Reallocated_Event_Count" ; then
        reallocated_event=$(echo "$smart_info" | grep "Reallocated_Event_Count" | awk '{print $10}')
        echo "错误率(越低越好): $reallocated_event"
    # else
    #     echo "错误率(越低越好)不可检测"
    fi
    if echo "$smart_info" | grep -q "Uncorrectable_Error_Cnt" ; then
        uncorrectable_error=$(echo "$smart_info" | grep "Uncorrectable_Error_Cnt" | awk '{print $10}')
        echo "不能纠正的错误数(越低越好): $uncorrectable_error"
    # else
    #     echo "不能纠正的错误数(越低越好)不可检测"
    fi
    if echo "$smart_info" | grep -q "Spin_Up_Time" ; then
        spin_up_time=$(echo "$smart_info" | grep "Spin_Up_Time" | awk '{print $10}')
        echo "磁盘启动时间(越短越好): $spin_up_time"
    # else
    #     echo "磁盘启动时间(越短越好)不可检测"
    fi
    if echo "$smart_info" | grep -q "Start_Stop_Count" ; then
        start_stop_count=$(echo "$smart_info" | grep "Start_Stop_Count" | awk '{print $10}')
        echo "磁盘启动停止次数(越少越好): $start_stop_count"
    # else
    #     echo "磁盘启动停止次数(越少越好)不可检测"
    fi
    if echo "$smart_info" | grep -q "Reallocated_Sector_Ct" ; then
        reallocated_sector=$(echo "$smart_info" | grep "Reallocated_Sector_Ct" | awk '{print $10}')
        echo "重定位扇区数(越低越好): $reallocated_sector"
    # else
    #     echo "重定位扇区数(越低越好)不可检测"
    fi
    if echo "$smart_info" | grep -q "Current_Pending_Sector" ; then
        pending_sector=$(echo "$smart_info" | grep "Current_Pending_Sector" | awk '{print $10}')
        echo "当前待处理扇区数(越低越好): $pending_sector"
    # else
    #     echo "当前待处理扇区数(越低越好)不可检测"
    fi
    if echo "$smart_info" | grep -q "Temperature_Celsius" ; then
        temperature=$(echo "$smart_info" | grep "Temperature_Celsius" | awk '{print $10}')
        echo "温度: $temperature"
    # else
    #     echo "温度不可检测"
    fi
    echo "-------------------"
done



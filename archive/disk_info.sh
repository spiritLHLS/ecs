#!/bin/bash
# by https://github.com/spiritLHLS/ecs
# by spiritlhls
# 2023.01.17
next() {
    echo "-------------------"
}
# 翻译
translate_type() {
    if [[ $1 == "Pre-fail" ]]; then
        echo "正常"
    elif [[ $1 == "Old_age" ]]; then
        echo "老化"
    else
        echo "其他"
    fi
}
check_smart_info() {
    if echo "$smart_info" | grep -q "$1"; then
        value=$(echo "$smart_info" | grep "$1" | awk '{print $10}')
        type=$(echo "$smart_info" | grep "$1" | awk '{print $7}')
        type=$(translate_type $type)
        echo "[$type] $2: $value"
    fi
}
# 检测所有硬盘
disk_list=""
if ls -d /dev/sd* >/dev/null 2>&1; then
    disk_list="$disk_list $(ls /dev/sd*)"
fi
if ls -d /dev/hd* >/dev/null 2>&1; then
    disk_list="$disk_list $(ls /dev/nvme*)"
fi
if ls -d /dev/hd* >/dev/null 2>&1; then
    disk_list="$disk_list $(ls /dev/hd*)"
fi
if ls -d /dev/vd* >/dev/null 2>&1; then
    disk_list="$disk_list $(ls /dev/mmcblk*)"
fi
# if ls -d /dev/vd* > /dev/null 2>&1; then
#     disk_list="$disk_list $(ls /dev/vd*)"
# fi
#检测smartctl是否安装
if ! command -v smartctl &>/dev/null; then
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
echo "标注老化的属性的数值过大或过小很可能是硬盘出问题了"
echo "当然是正常还是老化只是参考，一切基于smartctl的判断结果"
next
# echo $disk_list
for disk_dev in $disk_list; do
    smart_info=$(smartctl -i $disk_dev)
    vendor=$(echo "$smart_info" | grep "Vendor" | awk '{print $2}')
    if [[ -z "$vendor" ]]; then
        vendor="UNKNOWN"
    fi
    echo "盘路径: $disk_dev"
    echo "供应商: $vendor"
    smart_info=$(smartctl -a $disk_dev)
    check_smart_info "Power_On_Hours" "通电时长(越低越好)"
    check_smart_info "Power_Cycle_Count" "电源开关次数(越少越好)"
    check_smart_info "Spin_Up_Time" "启动时间(越短越好)"
    check_smart_info "Start_Stop_Count" "启动停止次数(越少越好)"
    check_smart_info "Spin_Retry_Count" "磁盘启动时重试次数(越低越好)"
    check_smart_info "Current_Pending_Sector" "当前待处理扇区数(越低越好)"
    check_smart_info "Runtime_Bad_Block" "运行坏块数量(越少越好)"
    check_smart_info "Raw_Read_Error_Rate" "读取错误率(越低越好)"
    check_smart_info "Command_Timeout" "命令执行超时数(越少越好)"
    check_smart_info "Reallocated_Event_Count" "重定位事件数(越低越好)"
    check_smart_info "Reallocated_Sector_Ct" "重定位扇区数(越低越好)"
    check_smart_info "Seek_Error_Rate" "检索错误率(越低越好)"
    check_smart_info "End-to-End_Error" "端到端错误(越少越好)"
    check_smart_info "Program_Fail_Count_Chip" "编程失败数(越低越好)"
    check_smart_info "Erase_Fail_Count_Chip" "擦除失败数(越低越好)"
    check_smart_info "High_Fly_Writes" "飞行高度错误数(越少越好)"
    check_smart_info "Temperature_Celsius" "盘面温度(不高就行)"
    check_smart_info "Airflow_Temperature_Cel" "空气温度(不高就行)"
    check_smart_info "Hardware_ECC_Recovered" "硬件纠正错误数(越少越好)"
    check_smart_info "G-Sense_Error_Rate" "加速度错误率(越低越好)"
    check_smart_info "Head_Flying_Hours" "盘头飞行时长(太高了不好)"
    check_smart_info "Power-Off_Retract_Count" "盘头电源关闭时的回缩数(越低越好)"
    check_smart_info "Uncorrectable_Error_Cnt" "在线模式下不能纠正的错误数(越低越好)"
    check_smart_info "Offline_Uncorrectable" "离线模式下不能纠正的错误数(越低越好)"
    check_smart_info "Reported_Uncorrect" "已报告但未纠正的错误数(越少越好)"
    check_smart_info "Used_Rsvd_Blk_Cnt_Chip" "已使用的预留块数(越低越好)"
    check_smart_info "Total_LBAs_Written" "已写入LBA总数(太高了不好)"
    check_smart_info "Total_LBAs_Read" "已读取LBA总数(太高了不好)"
    if echo "$smart_info" | grep -q "No Errors Logged"; then
        echo "本次检查本盘正常"
    else
        echo "本次检查本盘存在问题，请使用以下命令"
        echo "smartctl -a 盘路径"
        echo "查看日志，如果供应商是QEMU请忽略本盘的检测结果"
    fi
    next
done

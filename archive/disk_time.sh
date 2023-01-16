#!/bin/bash
# by https://github.com/spiritLHLS/ecs

# 检测所有硬盘通电时长

# 获取所有硬盘设备文件
disk_list=$(ls /dev/sd* | grep -v [0-9])

# 循环检测每个硬盘
for disk_dev in $disk_list
do
  # 使用smartctl命令查询硬盘信息
  power_on_hours=$(smartctl -A $disk_dev | grep "Power_On_Hours" | awk '{print $10}')
  
  # 输出硬盘通电时长
  echo "$disk_dev Power on hours: $power_on_hours"
done


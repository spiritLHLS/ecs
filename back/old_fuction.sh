
# lmc999_script(){
#     cd /root >/dev/null 2>&1
#     echo -e "-------------TikTok解锁--感谢lmc999加密脚本及fscarmen PR--------------"
#     local Ftmpresult=$(curl $useNIC --user-agent "${UA_Browser}" -s --max-time 10 "https://www.tiktok.com/")

#     if [[ "$Ftmpresult" = "curl"* ]]; then
#         _red "\r Tiktok Region:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}"
#         return
#     fi

#     local FRegion=$(echo $Ftmpresult | grep '"region":' | sed 's/.*"region"//' | cut -f2 -d'"')
#     if [ -n "$FRegion" ]; then
#         _green "\r Tiktok Region:\t\t${Font_Green}【${FRegion}】${Font_Suffix}"
#         return
#     fi

#     local STmpresult=$(curl $useNIC --user-agent "${UA_Browser}" -sL --max-time 10 -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9" -H "Accept-Encoding: gzip" -H "Accept-Language: en" "https://www.tiktok.com" | gunzip 2>/dev/null)
#     local SRegion=$(echo $STmpresult | grep '"region":' | sed 's/.*"region"//' | cut -f2 -d'"')
#     if [ -n "$SRegion" ]; then
#         _yellow "\r Tiktok Region:\t\t${Font_Yellow}【${SRegion}】(可能为IDC IP)${Font_Suffix}"
#         return
#     else
#         _red "\r Tiktok Region:\t\t${Font_Red}Failed${Font_Suffix}"
#         return
#     fi
# }

# function UnlockTiktokTest() {
#     cd /root >/dev/null 2>&1
#     echo -e "----------------TikTok解锁--感谢superbench的开源脚本------------------"
# 	local result=$(curl --user-agent "${BrowserUA}" -fsSL --max-time 10 "https://www.tiktok.com/" 2>&1);
#     if [[ "$result" != "curl"* ]]; then
#         result="$(echo ${result} | grep 'region' | awk -F 'region":"' '{print $2}' | awk -F '"' '{print $1}')";
# 		if [ -n "$result" ]; then
# 			if [[ "$result" == "The #TikTokTraditions"* ]] || [[ "$result" == "This LIVE isn't available"* ]]; then
# 				echo -e " TikTok               : ${RED}No${PLAIN}" | tee -a $log
# 			else
# 				echo -e " TikTok               : ${GREEN}Yes (Region: ${result})${PLAIN}" | tee -a $log
# 			fi
# 		else
# 			echo -e " TikTok               : ${RED}Failed${PLAIN}" | tee -a $log
# 			return
# 		fi
#     else
# 		echo -e " TikTok               : ${RED}Network connection failed${PLAIN}" | tee -a $log
# 	fi
# }

# fscarmen_port_script(){
#     echo -e "-----------------测端口开通--感谢fscarmen开源及PR----------------------"
#     IP_4=$(curl -s4m5 https://api.ipify.org)
#     sleep 0.5
#     if [ -n "$IP_4" ]; then
#     PORT4=(22 80 443 8080)
#     for i in ${PORT4[@]}; do
#         bash <(curl -s4SL https://cdn.spiritlhl.workers.dev/https://raw.githubusercontent.com/fscarmen/tools/main/check_port.sh) $WAN_4:$i > PORT4_$i
#         sed -i "1,5 d; s/状态/$i/g" PORT4_$i
#         cut -f 1 PORT4_$i > PORT4_${i}_1
#         cut -f 2,3  PORT4_$i > PORT4_${i}_2
#     done
#     paste PORT4_${PORT4[0]}_1 PORT4_${PORT4[1]}_1 PORT4_${PORT4[2]}_1 PORT4_${PORT4[3]} > PORT4_RESULT
#     _blue " IPv4 端口开通情况 "
#     cat PORT4_RESULT
#     rm -f PORT4_*
#     else _red " VPS 没有 IPv4 "
#     fi
# }

# SystemInfo_GetLoadAverage() {
#     local Var_LoadAverage="$(cat /proc/loadavg)"
#     LBench_Result_LoadAverage_1min="$(echo ${Var_LoadAverage} | awk '{print $1}')"
#     LBench_Result_LoadAverage_5min="$(echo ${Var_LoadAverage} | awk '{print $2}')"
#     LBench_Result_LoadAverage_15min="$(echo ${Var_LoadAverage} | awk '{print $3}')"
# }

# SystemInfo_GetUptime() {
#     local ut="$(cat /proc/uptime | awk '{printf "%d\n",$1}')"
#     local ut_day="$(echo $result | awk -v ut="$ut" '{printf "%d\n",ut/86400}')"
#     local ut_hour="$(echo $result | awk -v ut="$ut" -v ut_day="$ut_day" '{printf "%d\n",(ut-(86400*ut_day))/3600}')"
#     local ut_minute="$(echo $result | awk -v ut="$ut" -v ut_day="$ut_day" -v ut_hour="$ut_hour" '{printf "%d\n",(ut-(86400*ut_day)-(3600*ut_hour))/60}')"
#     local ut_second="$(echo $result | awk -v ut="$ut" -v ut_day="$ut_day" -v ut_hour="$ut_hour" -v ut_minute="$ut_minute" '{printf "%d\n",(ut-(86400*ut_day)-(3600*ut_hour)-(60*ut_minute))}')"
#     LBench_Result_SystemInfo_Uptime_Day="$ut_day"
#     LBench_Result_SystemInfo_Uptime_Hour="$ut_hour"
#     LBench_Result_SystemInfo_Uptime_Minute="$ut_minute"
#     LBench_Result_SystemInfo_Uptime_Second="$ut_second"
# }


# SystemInfo_GetDiskStat() {
#     LBench_Result_DiskRootPath="$(df -x tmpfs / | awk "NR>1" | sed ":a;N;s/\\n//g;ta" | awk '{print $1}')"
#     local Var_DiskTotalSpace_KB="$(df -x tmpfs / | grep -oE "[0-9]{4,}" | awk 'NR==1 {print $1}')"
#     LBench_Result_DiskTotal_KB="${Var_DiskTotalSpace_KB}"
#     LBench_Result_DiskTotal_MB="$(echo ${Var_DiskTotalSpace_KB} | awk '{printf "%.2f\n",$1/1000}')"
#     LBench_Result_DiskTotal_GB="$(echo ${Var_DiskTotalSpace_KB} | awk '{printf "%.2f\n",$1/1000000}')"
#     LBench_Result_DiskTotal_TB="$(echo ${Var_DiskTotalSpace_KB} | awk '{printf "%.2f\n",$1/1000000000}')"
#     local Var_DiskUsedSpace_KB="$(df -x tmpfs / | grep -oE "[0-9]{4,}" | awk 'NR==2 {print $1}')"
#     LBench_Result_DiskUsed_KB="${Var_DiskUsedSpace_KB}"
#     LBench_Result_DiskUsed_MB="$(echo ${LBench_Result_DiskUsed_KB} | awk '{printf "%.2f\n",$1/1000}')"
#     LBench_Result_DiskUsed_GB="$(echo ${LBench_Result_DiskUsed_KB} | awk '{printf "%.2f\n",$1/1000000}')"
#     LBench_Result_DiskUsed_TB="$(echo ${LBench_Result_DiskUsed_KB} | awk '{printf "%.2f\n",$1/1000000000}')"
#     local Var_DiskFreeSpace_KB="$(df -x tmpfs / | grep -oE "[0-9]{4,}" | awk 'NR==3 {print $1}')"
#     LBench_Result_DiskFree_KB="${Var_DiskFreeSpace_KB}"
#     LBench_Result_DiskFree_MB="$(echo ${LBench_Result_DiskFree_KB} | awk '{printf "%.2f\n",$1/1000}')"
#     LBench_Result_DiskFree_GB="$(echo ${LBench_Result_DiskFree_KB} | awk '{printf "%.2f\n",$1/1000000}')"
#     LBench_Result_DiskFree_TB="$(echo ${LBench_Result_DiskFree_KB} | awk '{printf "%.2f\n",$1/1000000000}')"
# }

# SystemInfo_GetNetworkInfo() {
#     local Result_IPV4="$(curl --user-agent "${UA_LemonBench}" --connect-timeout 10 -fsL4 https://lemonbench-api.ilemonrain.com/ipapi/ipapi.php)"
#     local Result_IPV6="$(curl --user-agent "${UA_LemonBench}" --connect-timeout 10 -fsL6 https://lemonbench-api.ilemonrain.com/ipapi/ipapi.php)"
#     if [ "${Result_IPV4}" != "" ] && [ "${Result_IPV6}" = "" ]; then
#         LBench_Result_NetworkStat="ipv4only"
#     elif [ "${Result_IPV4}" = "" ] && [ "${Result_IPV6}" != "" ]; then
#         LBench_Result_NetworkStat="ipv6only"
#     elif [ "${Result_IPV4}" != "" ] && [ "${Result_IPV6}" != "" ]; then
#         LBench_Result_NetworkStat="dualstack"
#     else
#         LBench_Result_NetworkStat="unknown"
#     fi
#     if [ "${LBench_Result_NetworkStat}" = "ipv4only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
#         IPAPI_IPV4_ip="$(PharseJSON "${Result_IPV4}" "data.ip")"
#         local IPAPI_IPV4_country_name="$(PharseJSON "${Result_IPV4}" "data.country")"
#         local IPAPI_IPV4_region_name="$(PharseJSON "${Result_IPV4}" "data.province")"
#         local IPAPI_IPV4_city_name="$(PharseJSON "${Result_IPV4}" "data.city")"
#         IPAPI_IPV4_location="${IPAPI_IPV4_country_name} ${IPAPI_IPV4_region_name} ${IPAPI_IPV4_city_name}"
#         IPAPI_IPV4_country_code="$(PharseJSON "${Result_IPV4}" "data.country_code")"
#         IPAPI_IPV4_asn="$(PharseJSON "${Result_IPV4}" "data.asn.number")"
#         IPAPI_IPV4_organization="$(PharseJSON "${Result_IPV4}" "data.asn.desc")"
#     fi
#     if [ "${LBench_Result_NetworkStat}" = "ipv6only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
#         IPAPI_IPV6_ip="$(PharseJSON "${Result_IPV6}" "data.ip")"
#         local IPAPI_IPV6_country_name="$(PharseJSON "${Result_IPV6}" "data.country")"
#         local IPAPI_IPV6_region_name="$(PharseJSON "${Result_IPV6}" "data.province")"
#         local IPAPI_IPV6_city_name="$(PharseJSON "${Result_IPV6}" "data.city")"
#         IPAPI_IPV6_location="${IPAPI_IPV6_country_name} ${IPAPI_IPV6_region_name} ${IPAPI_IPV6_city_name}"
#         IPAPI_IPV6_country_code="$(PharseJSON "${Result_IPV6}" "data.country_code")"
#         IPAPI_IPV6_asn="$(PharseJSON "${Result_IPV6}" "data.asn.number")"
#         IPAPI_IPV6_organization="$(PharseJSON "${Result_IPV6}" "data.asn.desc")"
#     fi
#     if [ "${LBench_Result_NetworkStat}" = "unknown" ]; then
#         IPAPI_IPV4_ip="-"
#         IPAPI_IPV4_location="-"
#         IPAPI_IPV4_country_code="-"
#         IPAPI_IPV4_asn="-"
#         IPAPI_IPV4_organization="-"
#         IPAPI_IPV6_ip="-"
#         IPAPI_IPV6_location="-"
#         IPAPI_IPV6_country_code="-"
#         IPAPI_IPV6_asn="-"
#         IPAPI_IPV6_organization="-"
#     fi
# }


# Function_GetSystemInfo() {
#     clear
#     echo -e "${Msg_Info}LemonBench Server Test Toolkit Build ${BuildTime}"
#     echo -e "${Msg_Info}SystemInfo - Collecting System Information ..."
#     Check_Virtwhat
#     echo -e "${Msg_Info}Collecting CPU Info ..."
#     SystemInfo_GetCPUInfo
#     SystemInfo_GetLoadAverage
#     SystemInfo_GetSystemBit
#     SystemInfo_GetCPUStat
#     echo -e "${Msg_Info}Collecting Memory Info ..."
#     SystemInfo_GetMemInfo
#     echo -e "${Msg_Info}Collecting Virtualization Info ..."
#     SystemInfo_GetVirtType
#     echo -e "${Msg_Info}Collecting System Info ..."
#     SystemInfo_GetUptime
#     SystemInfo_GetKernelVersion
#     echo -e "${Msg_Info}Collecting OS Release Info ..."
#     SystemInfo_GetOSRelease
#     echo -e "${Msg_Info}Collecting Disk Info ..."
#     SystemInfo_GetDiskStat
#     echo -e "${Msg_Info}Collecting Network Info ..."
#     SystemInfo_GetNetworkCCMethod
#     SystemInfo_GetNetworkInfo
#     echo -e "${Msg_Info}Starting Test ..."
#     clear
# }

# Function_ShowSystemInfo() {
#     echo -e "\n ${Font_Yellow}-> System Information${Font_Suffix}\n"
#     if [ "${Var_OSReleaseVersion_Codename}" != "" ]; then
#         echo -e " ${Font_Yellow}OS Release:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_OSReleaseFullName}${Font_Suffix}"
#     else
#         echo -e " ${Font_Yellow}OS Release:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_OSReleaseFullName}${Font_Suffix}"
#     fi
#     if [ "${Flag_DymanicCPUFreqDetected}" = "1" ]; then
#         echo -e " ${Font_Yellow}CPU Model:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_CPUModelName}${Font_Suffix}  ${Font_White}${LBench_Result_CPUFreqMinGHz}~${LBench_Result_CPUFreqMaxGHz}${Font_Suffix}${Font_SkyBlue} GHz${Font_Suffix}"
#     elif [ "${Flag_DymanicCPUFreqDetected}" = "0" ]; then
#         echo -e " ${Font_Yellow}CPU Model:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_CPUModelName}  ${LBench_Result_CPUFreqGHz} GHz${Font_Suffix}"
#     fi
#     if [ "${LBench_Result_CPUCacheSize}" != "" ]; then
#         echo -e " ${Font_Yellow}CPU Cache Size:${Font_Suffix}\t${Font_SkyBlue}${LBench_Result_CPUCacheSize}${Font_Suffix}"
#     else
#         echo -e " ${Font_Yellow}CPU Cache Size:${Font_Suffix}\t${Font_SkyBlue}None${Font_Suffix}"
#     fi
#     # CPU数量 分支判断
#     if [ "${LBench_Result_CPUIsPhysical}" = "1" ]; then
#         # 如果只存在1个物理CPU (单路物理服务器)
#         if [ "${LBench_Result_CPUPhysicalNumber}" -eq "1" ]; then
#             echo -e " ${Font_Yellow}CPU Number:${Font_Suffix}\t\t${LBench_Result_CPUPhysicalNumber} ${Font_SkyBlue}Physical CPU${Font_Suffix}, ${LBench_Result_CPUCoreNumber} ${Font_SkyBlue}Cores${Font_Suffix}, ${LBench_Result_CPUThreadNumber} ${Font_SkyBlue}Threads${Font_Suffix}"
#         # 存在多个CPU, 继续深入分析检测 (多路物理服务器)
#         elif [ "${LBench_Result_CPUPhysicalNumber}" -ge "2" ]; then
#             echo -e " ${Font_Yellow}CPU Number:${Font_Suffix}\t\t${LBench_Result_CPUPhysicalNumber} ${Font_SkyBlue}Physical CPU(s)${Font_Suffix}, ${LBench_Result_CPUCoreNumber} ${Font_SkyBlue}Cores/CPU${Font_Suffix}, ${LBench_Result_CPUSiblingsNumber} ${Font_SkyBlue}Threads/CPU${Font_Suffix} (Total ${Font_SkyBlue}${LBench_Result_CPUTotalCoreNumber}${Font_Suffix} Cores, ${Font_SkyBlue}${LBench_Result_CPUProcessorNumber}${Font_Suffix} Threads)"
#         # 针对树莓派等特殊情况做出检测优化
#         elif [ "${LBench_Result_CPUThreadNumber}" = "0" ] && [ "${LBench_Result_CPUProcessorNumber} " -ge "1" ]; then
#              echo -e " ${Font_Yellow}CPU Number:${Font_Suffix}\t\t${LBench_Result_CPUProcessorNumber} ${Font_SkyBlue}Cores${Font_Suffix}"
#         fi
#         if [ "${LBench_Result_CPUVirtualization}" = "1" ]; then
#             echo -e " ${Font_Yellow}VirtReady:${Font_Suffix}\t\t${Font_SkyBlue}Yes${Font_Suffix} ${Font_SkyBlue}(Based on${Font_Suffix} ${LBench_Result_CPUVirtualizationType}${Font_SkyBlue})${Font_Suffix}"
#         else
#             echo -e " ${Font_Yellow}VirtReady:${Font_Suffix}\t\t${Font_SkyRed}No${Font_Suffix}"
#         fi
#     elif [ "${Var_VirtType}" = "openvz" ]; then
#         echo -e " ${Font_Yellow}CPU Number:${Font_Suffix}\t\t${LBench_Result_CPUThreadNumber} ${Font_SkyBlue}vCPU${Font_Suffix} (${LBench_Result_CPUCoreNumber} ${Font_SkyBlue}Host Core/Thread${Font_Suffix})"
#     else
#         if [ "${LBench_Result_CPUVirtualization}" = "2" ]; then
#             echo -e " ${Font_Yellow}CPU Number:${Font_Suffix}\t\t${LBench_Result_CPUThreadNumber} ${Font_SkyBlue}vCPU${Font_Suffix}"
#             echo -e " ${Font_Yellow}VirtReady:${Font_Suffix}\t\t${Font_SkyBlue}Yes${Font_Suffix} ${Font_SkyBlue}(Nested Virtualization)${Font_Suffix}"
#         else
#             echo -e " ${Font_Yellow}CPU Number:${Font_Suffix}\t\t${LBench_Result_CPUThreadNumber} ${Font_SkyBlue}vCPU${Font_Suffix}"
#         fi
#     fi
#     echo -e " ${Font_Yellow}Virt Type:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_VirtType}${Font_Suffix}"
#     # 内存使用率 分支判断
#     if [ "${LBench_Result_MemoryUsed_KB}" -lt "1024" ] && [ "${LBench_Result_MemoryTotal_KB}" -lt "1048576" ]; then
#         LBench_Result_Memory="${LBench_Result_MemoryUsed_KB} KB / ${LBench_Result_MemoryTotal_MB} MB"
#         echo -e " ${Font_Yellow}Memory Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryUsed_MB} KB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_MemoryTotal_MB} MB${Font_Suffix}"
#     elif [ "${LBench_Result_MemoryUsed_KB}" -lt "1048576" ] && [ "${LBench_Result_MemoryTotal_KB}" -lt "1048576" ]; then
#         LBench_Result_Memory="${LBench_Result_MemoryUsed_MB} MB / ${LBench_Result_MemoryTotal_MB} MB"
#         echo -e " ${Font_Yellow}Memory Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_MemoryTotal_MB} MB${Font_Suffix}"
#     elif [ "${LBench_Result_MemoryUsed_KB}" -lt "1048576" ] && [ "${LBench_Result_MemoryTotal_KB}" -lt "1073741824" ]; then
#         LBench_Result_Memory="${LBench_Result_MemoryUsed_MB} MB / ${LBench_Result_MemoryTotal_GB} GB"
#         echo -e " ${Font_Yellow}Memory Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_MemoryTotal_GB} GB${Font_Suffix}"
#     else
#         LBench_Result_Memory="${LBench_Result_MemoryUsed_GB} GB / ${LBench_Result_MemoryTotal_GB} GB"
#         echo -e " ${Font_Yellow}Memory Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryUsed_GB} GB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_MemoryTotal_GB} GB${Font_Suffix}"
#     fi
#     # Swap使用率 分支判断
#     if [ "${LBench_Result_SwapTotal_KB}" -eq "0" ]; then
#         LBench_Result_Swap="[ No Swapfile / Swap partition ]"
#         echo -e " ${Font_Yellow}Swap Usage:${Font_Suffix}\t\t${Font_SkyBlue}[ No Swapfile/Swap Partition ]${Font_Suffix}"
#     elif [ "${LBench_Result_SwapUsed_KB}" -lt "1024" ] && [ "${LBench_Result_SwapTotal_KB}" -lt "1048576" ]; then
#         LBench_Result_Swap="${LBench_Result_SwapUsed_KB} KB / ${LBench_Result_SwapTotal_MB} MB"
#         echo -e " ${Font_Yellow}Swap Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_KB} KB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_MB} MB${Font_Suffix}"
#     elif [ "${LBench_Result_SwapUsed_KB}" -lt "1024" ] && [ "${LBench_Result_SwapTotal_KB}" -lt "1073741824" ]; then
#         LBench_Result_Swap="${LBench_Result_SwapUsed_KB} KB / ${LBench_Result_SwapTotal_GB} GB"
#         echo -e " ${Font_Yellow}Swap Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_KB} KB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_GB} GB${Font_Suffix}"
#     elif [ "${LBench_Result_SwapUsed_KB}" -lt "1048576" ] && [ "${LBench_Result_SwapTotal_KB}" -lt "1048576" ]; then
#         LBench_Result_Swap="${LBench_Result_SwapUsed_MB} MB / ${LBench_Result_SwapTotal_MB} MB"
#         echo -e " ${Font_Yellow}Swap Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_MB} MB${Font_Suffix}"
#     elif [ "${LBench_Result_SwapUsed_KB}" -lt "1048576" ] && [ "${LBench_Result_SwapTotal_KB}" -lt "1073741824" ]; then
#         LBench_Result_Swap="${LBench_Result_SwapUsed_MB} MB / ${LBench_Result_SwapTotal_GB} GB"
#         echo -e " ${Font_Yellow}Swap Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_GB} GB${Font_Suffix}"
#     else
#         LBench_Result_Swap="${LBench_Result_SwapUsed_GB} GB / ${LBench_Result_SwapTotal_GB} GB"
#         echo -e " ${Font_Yellow}Swap Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_GB} GB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_GB} GB${Font_Suffix}"
#     fi
#     # 启动磁盘
#     echo -e " ${Font_Yellow}Boot Device:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskRootPath}${Font_Suffix}"
#     # 磁盘使用率 分支判断
#     if [ "${LBench_Result_DiskUsed_KB}" -lt "1000000" ]; then
#         LBench_Result_Disk="${LBench_Result_DiskUsed_MB} MB / ${LBench_Result_DiskTotal_MB} MB"
#         echo -e " ${Font_Yellow}Disk Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_MB} MB${Font_Suffix}"
#     elif [ "${LBench_Result_DiskUsed_KB}" -lt "1000000" ] && [ "${LBench_Result_DiskTotal_KB}" -lt "1000000000" ]; then
#         LBench_Result_Disk="${LBench_Result_DiskUsed_MB} MB / ${LBench_Result_DiskTotal_GB} GB"
#         echo -e " ${Font_Yellow}Disk Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_GB} GB${Font_Suffix}"
#     elif [ "${LBench_Result_DiskUsed_KB}" -lt "1000000000" ] && [ "${LBench_Result_DiskTotal_KB}" -lt "1000000000" ]; then
#         LBench_Result_Disk="${LBench_Result_DiskUsed_GB} GB / ${LBench_Result_DiskTotal_GB} GB"
#         echo -e " ${Font_Yellow}Disk Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_GB} GB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_GB} GB${Font_Suffix}"
#     elif [ "${LBench_Result_DiskUsed_KB}" -lt "1000000000" ] && [ "${LBench_Result_DiskTotal_KB}" -ge "1000000000" ]; then
#         LBench_Result_Disk="${LBench_Result_DiskUsed_GB} GB / ${LBench_Result_DiskTotal_TB} TB"
#         echo -e " ${Font_Yellow}Disk Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_GB} GB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_TB} TB${Font_Suffix}"
#     else
#         LBench_Result_Disk="${LBench_Result_DiskUsed_TB} TB / ${LBench_Result_DiskTotal_TB} TB"
#         echo -e " ${Font_Yellow}Disk Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_TB} TB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_TB} TB${Font_Suffix}"
#     fi
#     # CPU状态
#     echo -e " ${Font_Yellow}CPU Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_CPUStat_UsedAll}% used${Font_Suffix}, ${Font_SkyBlue}${LBench_Result_CPUStat_iowait}% iowait${Font_Suffix}, ${Font_SkyBlue}${LBench_Result_CPUStat_steal}% steal${Font_Suffix}"
#     # 系统负载
#     echo -e " ${Font_Yellow}Load (1/5/15min):${Font_Suffix}\t${Font_SkyBlue}${LBench_Result_LoadAverage_1min} ${LBench_Result_LoadAverage_5min} ${LBench_Result_LoadAverage_15min} ${Font_Suffix}"
#     # 系统开机时间
#     echo -e " ${Font_Yellow}Uptime:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SystemInfo_Uptime_Day} Days, ${LBench_Result_SystemInfo_Uptime_Hour} Hours, ${LBench_Result_SystemInfo_Uptime_Minute} Minutes, ${LBench_Result_SystemInfo_Uptime_Second} Seconds${Font_Suffix}"
#     # 内核版本
#     echo -e " ${Font_Yellow}Kernel Version:${Font_Suffix}\t${Font_SkyBlue}${LBench_Result_KernelVersion}${Font_Suffix}"
#     # 网络拥塞控制方式
#     echo -e " ${Font_Yellow}Network CC Method:${Font_Suffix}\t${Font_SkyBlue}${LBench_Result_NetworkCCMethod}${Font_Suffix}"
#     # 执行完成, 标记FLAG
#     LBench_Flag_FinishSystemInfo="1"
# }

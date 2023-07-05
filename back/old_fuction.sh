# SystemInfo_GetCPUInfo() {
#     mkdir -p ${WorkDir}/data >/dev/null 2>&1
#     if [ -f "/proc/cpuinfo" ]; then
#         cat /proc/cpuinfo >${WorkDir}/data/cpuinfo
#         local ReadCPUInfo="cat ${WorkDir}/data/cpuinfo"
#         LBench_Result_CPUModelName="$($ReadCPUInfo | awk -F ': ' '/model name/{print $2}' | sort -u)"
#         local CPUFreqCount="$($ReadCPUInfo | awk -F ': ' '/cpu MHz/{print $2}' | sort -run | wc -l)"
#         if [ "${CPUFreqCount}" -ge "2" ]; then
#             local CPUFreqArray="$(cat /proc/cpuinfo | awk -F ': ' '/cpu MHz/{print $2}' | sort -run)"
#             local CPUFreq_Min="$(echo "$CPUFreqArray" | grep -oE '[0-9]+.[0-9]{3}' | awk 'BEGIN {min = 2147483647} {if ($1+0 < min+0) min=$1} END {print min}')"
#             local CPUFreq_Max="$(echo "$CPUFreqArray" | grep -oE '[0-9]+.[0-9]{3}' | awk 'BEGIN {max = 0} {if ($1+0 > max+0) max=$1} END {print max}')"
#             LBench_Result_CPUFreqMinGHz="$(echo $CPUFreq_Min | awk '{printf "%.2f\n",$1/1000}')"
#             LBench_Result_CPUFreqMaxGHz="$(echo $CPUFreq_Max | awk '{printf "%.2f\n",$1/1000}')"
#             Flag_DymanicCPUFreqDetected="1"
#         else
#             LBench_Result_CPUFreqMHz="$($ReadCPUInfo | awk -F ': ' '/cpu MHz/{print $2}' | sort -u)"
#             LBench_Result_CPUFreqGHz="$(echo $LBench_Result_CPUFreqMHz | awk '{printf "%.2f\n",$1/1000}')"
#             Flag_DymanicCPUFreqDetected="0"
#         fi
#         LBench_Result_CPUCacheSize="$($ReadCPUInfo | awk -F ': ' '/cache size/{print $2}' | sort -u)"
#         LBench_Result_CPUPhysicalNumber="$($ReadCPUInfo | awk -F ': ' '/physical id/{print $2}' | sort -u | wc -l)"
#         LBench_Result_CPUCoreNumber="$($ReadCPUInfo | awk -F ': ' '/cpu cores/{print $2}' | sort -u)"
#         LBench_Result_CPUThreadNumber="$($ReadCPUInfo | awk -F ': ' '/cores/{print $2}' | wc -l)"
#         LBench_Result_CPUProcessorNumber="$($ReadCPUInfo | awk -F ': ' '/processor/{print $2}' | wc -l)"
#         LBench_Result_CPUSiblingsNumber="$($ReadCPUInfo | awk -F ': ' '/siblings/{print $2}' | sort -u)"
#         LBench_Result_CPUTotalCoreNumber="$($ReadCPUInfo | awk -F ': ' '/physical id/&&/0/{print $2}' | wc -l)"
        
#         # 虚拟化能力检测
#         SystemInfo_GetVirtType
#         if [ "${Var_VirtType}" = "dedicated" ] || [ "${Var_VirtType}" = "wsl" ]; then
#             LBench_Result_CPUIsPhysical="1"
#             local VirtCheck="$(cat /proc/cpuinfo | grep -oE 'vmx|svm' | uniq)"
#             if [ "${VirtCheck}" != "" ]; then
#                 LBench_Result_CPUVirtualization="1"
#                 local VirtualizationType="$(lscpu | awk /Virtualization:/'{print $2}')"
#                 LBench_Result_CPUVirtualizationType="${VirtualizationType}"
#             else
#                 LBench_Result_CPUVirtualization="0"
#             fi
#         elif [ "${Var_VirtType}" = "kvm" ] || [ "${Var_VirtType}" = "hyperv" ] || [ "${Var_VirtType}" = "microsoft" ] || [ "${Var_VirtType}" = "vmware" ]; then
#             LBench_Result_CPUIsPhysical="0"
#             local VirtCheck="$(cat /proc/cpuinfo | grep -oE 'vmx|svm' | uniq)"
#             if [ "${VirtCheck}" = "vmx" ] || [ "${VirtCheck}" = "svm" ]; then
#                 LBench_Result_CPUVirtualization="2"
#                 local VirtualizationType="$(lscpu | awk /Virtualization:/'{print $2}')"
#                 LBench_Result_CPUVirtualizationType="${VirtualizationType}"
#             else
#                 LBench_Result_CPUVirtualization="0"
#             fi        
#         else
#             LBench_Result_CPUIsPhysical="0"
#         fi
#     else
#         $sysctl_path -a >${WorkDir}/data/sysctl_info
#         local ReadCPUInfo="cat ${WorkDir}/data/sysctl_info"
#         LBench_Result_CPUModelName="$($ReadCPUInfo 2>/dev/null | awk -F ': ' '/hw.model/{print $2}' | sort -u)"
#         LBench_Result_CPUFreqMHz="$($ReadCPUInfo 2>/dev/null | awk -F ': ' '/dev.cpu.0.freq/{print $2}')"
#         LBench_Result_CPUCacheSize="$($ReadCPUInfo 2>/dev/null | awk -F ': ' '/hw.cacheconfig/{print $2}')"
#         LBench_Result_CPUFreqGHz="$(echo $LBench_Result_CPUFreqMHz | awk '{printf "%.2f\n",$1/1000}')"
#         LBench_Result_CPUPhysicalNumber="$($ReadCPUInfo 2>/dev/null | awk -F ': ' '/hw.physicalcpu/{print $2}')"
#         LBench_Result_CPUCoreNumber="$($ReadCPUInfo 2>/dev/null | awk -F ': ' '/hw.ncpu/{print $2}')"
#         LBench_Result_CPUThreadNumber="$($ReadCPUInfo 2>/dev/null | awk -F ': ' '/hw.ncpu/{print $2}')"
#         LBench_Result_CPUProcessorNumber="$($ReadCPUInfo 2>/dev/null | awk -F ': ' '/hw.ncpu/{print $2}')"
#         LBench_Result_CPUSiblingsNumber="$($ReadCPUInfo 2>/dev/null | awk -F ': ' '/hw.smt/{print $2}')"
#         LBench_Result_CPUTotalCoreNumber="$($ReadCPUInfo 2>/dev/null | awk -F ': ' '/hw.ncpu/{print $2}')"

#         # 虚拟化能力检测
#         SystemInfo_GetVirtType
#         if [ "${Var_VirtType}" = "dedicated" ] || [ "${Var_VirtType}" = "wsl" ]; then
#             LBench_Result_CPUIsPhysical="1"
#             local VirtCheck="$($sysctl_path -a | grep -E 'hw.vmx|hw.svm' | uniq)"
#             if [ "${VirtCheck}" != "" ]; then
#                 LBench_Result_CPUVirtualization="1"
#                 LBench_Result_CPUVirtualizationType="Native"
#             else
#                 LBench_Result_CPUVirtualization="0"
#             fi
#         elif [ "${Var_VirtType}" = "kvm" ] || [ "${Var_VirtType}" = "hyperv" ] || [ "${Var_VirtType}" = "microsoft" ] || [ "${Var_VirtType}" = "vmware" ]; then
#             LBench_Result_CPUIsPhysical="0"
#             local VirtCheck="$($sysctl_path -a | grep -E 'hw.vmx|hw.svm' | uniq)"
#             if [ "${VirtCheck}" != "" ]; then
#                 LBench_Result_CPUVirtualization="2"
#                 LBench_Result_CPUVirtualizationType="${Var_VirtType}"
#             else
#                 LBench_Result_CPUVirtualization="0"
#             fi
#         else
#             LBench_Result_CPUIsPhysical="0"
#         fi
#     fi
# }

# get_longest_first_element() {
#     # 获取一个列表中最长的元素 - 信息最多的
#     local list=("$@")
#     local longest_element="${list[0]}"
#     for element in "${list[@]}"; do
#         if [[ ${#element} -gt ${#longest_element} ]]; then
#             longest_element=$element
#         fi
#     done
#     echo "$longest_element"
# }

# isvalidipv4()
# {
#     local ipaddr=$1
#     local stat=1
#     if [[ $ipaddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
#         OIFS=$IFS
#         IFS='.'
#         ipaddr=($ipaddr)
#         IFS=$OIFS
#         [[ ${ipaddr[0]} -le 255 && ${ipaddr[1]} -le 255 \
#             && ${ipaddr[2]} -le 255 && ${ipaddr[3]} -le 255 ]]
#         stat=$?
#     fi
#     return $stat
# }

# openai_script(){
#     cd $myvar >/dev/null 2>&1
#     echo -e "---------OpenAi解锁--感谢missuo的OpenAI-Checker项目本人修改优化---------"
#     output=$(bash <(curl -Ls "${cdn_success_url}https://raw.githubusercontent.com/spiritLHLS/OpenAI-Checker/main/openai.sh"))
#     output=$(echo "$output" | grep -v '^Your IPv[46]: [0-9a-fA-F:.]* -')
#     output=$(echo "$output" | grep -v '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\|[0-9a-fA-F][0-9a-fA-F:]*:[0-9a-fA-F][0-9a-fA-F:]*:[0-9a-fA-F][0-9a-fA-F:]*:[0-9a-fA-F][0-9a-fA-F:]*:[0-9a-fA-F][0-9a-fA-F:]*:[0-9a-fA-F][0-9a-fA-F:]*:[0-9a-fA-F][0-9a-fA-F:]*')
#     output=$(echo "$output" | grep -v '::')
#     output=$(echo "$output" | grep -v '^-------------------------------------')
#     output=$(echo "$output" | sed '1,/\[IPv4\]/d')
#     echo "[IPv4]"
#     echo "$output"
# }


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

# =============== 检查 JSON Query 组件 ===============
# Check_JSONQuery() {
#     # 判断 jq 命令是否存在
#     if ! command -v jq > /dev/null; then
#         # 获取系统位数
#         SystemInfo_GetSystemBit
#         # 获取操作系统版本
#         SystemInfo_GetOSRelease
#         # 根据系统位数设置下载地址
#         local DownloadSrc
#         if [ -z "${LBench_Result_SystemBit_Short}" ] || [ "${LBench_Result_SystemBit_Short}" != "amd64" ] || [ "${LBench_Result_SystemBit_Short}" != "i386" ]; then
#             DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/JSONQuery/jq-i386.tar.gz"
#         else
#             DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/JSONQuery/jq-${LBench_Result_SystemBit_Short}.tar.gz"
#             # local DownloadSrc="https://raw.githubusercontent.com/LemonBench/LemonBench/master/Resources/JSONQuery/jq-amd64.tar.gz"
#             # local DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/jq/1.6/amd64/jq.tar.gz"
#             # local DownloadSrc="https://raw.githubusercontent.com/LemonBench/LemonBench/master/Resources/JSONQuery/jq-i386.tar.gz"
#             # local DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/jq/1.6/i386/jq.tar.gz"
#         fi
#         mkdir -p ${WorkDir}/
#         echo -e "${Msg_Warning}JSON Query Module not found, Installing ..."
#         echo -e "${Msg_Info}Installing Dependency ..."
#         if [[ "${Var_OSRelease}" =~ ^(centos|rhel|almalinux)$ ]]; then
#             yum install -y epel-release
#             if [ $? -ne 0 ]; then
#                 if [ "$(grep -Ei 'centos|almalinux' /etc/os-release | awk -F'=' '{print $2}')" == "AlmaLinux" ]; then
#                     cd /etc/yum.repos.d/
#                     sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/AlmaLinux-*
#                     sed -i 's|#baseurl=https://repo.almalinux.org/|baseurl=https://vault.almalinux.org/|g' /etc/yum.repos.d/AlmaLinux-*
#                     yum makecache
#                 else
#                     cd /etc/yum.repos.d/
#                     sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
#                     sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
#                     yum makecache
#                 fi
#                 if [ $? -ne 0 ]; then
#                     yum -y update && yum install -y epel-release
#                 fi
#             fi
#             yum install -y tar
#             yum install -y jq
#         elif [[ "${Var_OSRelease}" =~ ^debian$ ]]; then
#             ! apt-get update && apt-get --fix-broken install -y && apt-get update
#             ! apt-get install -y jq && apt-get --fix-broken install -y && apt-get install jq -y
#             if [ $? -ne 0 ]; then
#                 ! apt-get install -y jq && apt-get --fix-broken install -y && apt-get install jq -y --force-yes
#             fi
#             if [ $? -ne 0 ]; then
#                 ! apt-get install -y jq && apt-get --fix-broken install -y && apt-get install jq -y --allow
#             fi
#         elif [[ "${Var_OSRelease}" =~ ^ubuntu$ ]]; then
#             ! apt-get update && apt-get --fix-broken install -y && apt-get update
#             ! apt-get install -y jq && apt-get --fix-broken install -y && apt-get install jq -y
#             if [ $? -ne 0 ]; then
#                 ! apt-get install -y jq && apt-get --fix-broken install -y && apt-get install jq -y --allow-unauthenticated
#             fi
#         elif [ "${Var_OSRelease}" = "fedora" ]; then
#             dnf install -y jq
#         elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
#             apk update
#             apk add jq
#         elif [ "${Var_OSRelease}" = "arch" ]; then
#             pacman -Sy --needed --noconfirm jq
#         else
#             apk update
#             apk add wget unzip curl
#             echo -e "${Msg_Info}Downloading Json Query Module ..."
#             curl --user-agent "${UA_LemonBench}" ${DownloadSrc} -o ${WorkDir}/jq.tar.gz
#             echo -e "${Msg_Info}Installing JSON Query Module ..."
#             tar xvf ${WorkDir}/jq.tar.gz
#             mv ${WorkDir}/jq /usr/bin/jq
#             chmod +x /usr/bin/jq
#             echo -e "${Msg_Info}Cleaning up ..."
#             rm -rf ${WorkDir}/jq.tar.gz
#         fi
#     fi
#     # 二次检测
#     if [ ! -f "/usr/bin/jq" ]; then
#         echo -e "JSON Query Moudle install Failure! Try Restart Bench or Manually install it! (/usr/bin/jq)"
#         exit 1
#     fi
# }

# cnlatency() {    
#     ipaddr=$(getent ahostsv4 $1 | grep STREAM | head -n 1 | cut -d ' ' -f 1)
# 	if isvalidipv4 "$ipaddr"; then
# 		host=$2
# 		retry=1
# 		rtt=999	
# 		while [[ "$retry" < 4 ]] ; do
# 			echo -en "\r\033[0K [$3 of $4] : $host ($ipaddr) attemp #$retry"
# 			rtt=$(ping -c1 -w1 $ipaddr | sed -nE 's/.*time=([0-9.]+).*/\1/p')				
# 			if [[ -z "$rtt" ]]; then
# 				rtt=999
# 				retry=$((retry+1))
# 				continue
# 			fi
# 			[[ "$rtt" < 1 ]] && rtt=1
# 			int=${rtt%.*}
# 			if [[ "$int" -gt 999 || "$int" -eq 0 ]]; then
# 				rtt=999
# 				break
# 			fi
# 			rtt=$(printf "%.0f" $rtt)
# 			rtt=$(printf "%03d" $rtt)
# 			break
# 		done
# 		result="${rtt}ms : $host , $ipaddr"
# 		CHINALIST[${#CHINALIST[@]}]=$result		
# 	fi
# }

# # https://github.com/xsidc/zbench/blob/master/ZPing-CN.py
# # https://ipasn.com/bench.sh
# chinaping() {
#     # start=$(date +%s)
#     # echostyle "++ China Latency Test"
#     echo "-------------------延迟测试--感谢ipasn开源本人整理---------------------" | tee -a $LOG
#     declare -a LIST
#     LIST[${#LIST[@]}]="ec2.cn-north-1.amazonaws.com.cn•北京, Amazon Cloud"
#     LIST[${#LIST[@]}]="ec2.cn-northwest-1.amazonaws.com.cn•宁夏, Amazon Cloud"
#     LIST[${#LIST[@]}]="bss.bd.baidubce.com•河北保定, Baidu Cloud"
#     LIST[${#LIST[@]}]="bss.bj.baidubce.com•北京, Baidu Cloud"
#     LIST[${#LIST[@]}]="feitsui-bjs-1251417183.cos-website.ap-beijing.myqcloud.com•北京, Tencent Cloud"
#     LIST[${#LIST[@]}]="feitsui-bjs-1251417183.cos-website.ap-chengdu.myqcloud.com•四川成都, Tencent Cloud"
#     LIST[${#LIST[@]}]="feitsui-bjs-1251417183.cos-website.ap-chongqing.myqcloud.com•重庆, Tencent Cloud"
#     LIST[${#LIST[@]}]="feitsui-bjs-1251417183.cos-website.ap-guangzhou.myqcloud.com•广东广州, Tencent Cloud"
#     LIST[${#LIST[@]}]="feitsui-bjs-1251417183.cos-website.ap-nanjing.myqcloud.com•江苏南京, Tencent Cloud"
#     LIST[${#LIST[@]}]="feitsui-bjs-1251417183.cos-website.ap-shanghai.myqcloud.com•上海, Tencent Cloud"
#     LIST[${#LIST[@]}]="feitsui-bjs-fsi-1251417183.cos-website.ap-beijing-fsi.myqcloud.com•北京金融, Tencent Cloud"
#     LIST[${#LIST[@]}]="feitsui-bjs.cn-bj.ufileos.com•北京, UCloud"
#     LIST[${#LIST[@]}]="feitsui-can.cn-gd.ufileos.com•广东广州, UCloud"
#     LIST[${#LIST[@]}]="feitsui-can.obs-website.cn-south-1.myhuaweicloud.com•广东广州, Huawei Cloud"
#     LIST[${#LIST[@]}]="bss.gz.baidubce.com•广东广州, Baidu Cloud"
#     LIST[${#LIST[@]}]="feitsui-kwe1.obs-website.cn-southwest-2.myhuaweicloud.com•贵州贵阳, Huawei Cloud"
#     LIST[${#LIST[@]}]="feitsui-pek1.obs-website.cn-north-1.myhuaweicloud.com•北京1, Huawei Cloud"
#     LIST[${#LIST[@]}]="feitsui-pek4.obs-website.cn-north-4.myhuaweicloud.com•北京2, Huawei Cloud"
#     LIST[${#LIST[@]}]="feitsui-sha-fsi-1251417183.cos-website.ap-shanghai-fsi.myqcloud.com•上海金融, Tencent Cloud"
#     LIST[${#LIST[@]}]="feitsui-sha1.obs-website.cn-east-3.myhuaweicloud.com•上海1, Huawei Cloud"
#     LIST[${#LIST[@]}]="feitsui-sha2.cn-sh2.ufileos.com•上海2, UCloud"
#     LIST[${#LIST[@]}]="feitsui-sha2.obs-website.cn-east-2.myhuaweicloud.com•上海2, Huawei Cloud"
#     LIST[${#LIST[@]}]="bss.fsh.baidubce.com•上海, Baidu Cloud"
#     LIST[${#LIST[@]}]="bss.su.baidubce.com•江苏苏州, Baidu Cloud"
#     LIST[${#LIST[@]}]="feitsui-szx-fsi-1251417183.cos-website.ap-shenzhen-fsi.myqcloud.com•广东深圳金融, Tencent Cloud"
#     LIST[${#LIST[@]}]="feitsui-ucb.obs-website.cn-north-9.myhuaweicloud.com•内蒙古乌兰察布, Huawei Cloud"
#     LIST[${#LIST[@]}]="bss.fwh.baidubce.com•湖北武汉, Baidu Cloud"
#     LIST[${#LIST[@]}]="ks3-cn-beijing.ksyuncs.com•北京, Kingsoft Cloud"
#     LIST[${#LIST[@]}]="ks3-cn-guangzhou.ksyuncs.com•广东广州, Kingsoft Cloud"
#     LIST[${#LIST[@]}]="ks3-cn-shanghai.ksyuncs.com•上海, Kingsoft Cloud"
#     LIST[${#LIST[@]}]="ks3-gov-beijing.ksyuncs.com•北京政府, Kingsoft Cloud"
#     LIST[${#LIST[@]}]="ks3-jr-beijing.ksyuncs.com•北京金融, Kingsoft Cloud"
#     LIST[${#LIST[@]}]="ks3-jr-shanghai.ksyuncs.com•上海金融, Kingsoft Cloud"
#     LIST[${#LIST[@]}]="oss-cn-beijing.aliyuncs.com•北京, Alibaba Cloud"
#     LIST[${#LIST[@]}]="oss-cn-chengdu.aliyuncs.com•四川成都, Alibaba Cloud"
#     LIST[${#LIST[@]}]="oss-cn-guangzhou.aliyuncs.com•广东广州, Alibaba Cloud"
#     LIST[${#LIST[@]}]="oss-cn-hangzhou.aliyuncs.com•浙江杭州, Alibaba Cloud"
#     LIST[${#LIST[@]}]="oss-cn-heyuan.aliyuncs.com•广东河源, Alibaba Cloud"
#     LIST[${#LIST[@]}]="oss-cn-huhehaote.aliyuncs.com•内蒙古呼和浩特, Alibaba Cloud"
#     LIST[${#LIST[@]}]="oss-cn-nanjing.aliyuncs.com•江苏南京, Alibaba Cloud"
#     LIST[${#LIST[@]}]="oss-cn-qingdao.aliyuncs.com•山东青岛, Alibaba Cloud"
#     LIST[${#LIST[@]}]="oss-cn-shanghai.aliyuncs.com•上海, Alibaba Cloud"
#     LIST[${#LIST[@]}]="oss-cn-shenzhen.aliyuncs.com•广东深圳, Alibaba Cloud"
#     LIST[${#LIST[@]}]="oss-cn-wulanchabu.aliyuncs.com•内蒙古乌兰察布, Alibaba Cloud"
#     LIST[${#LIST[@]}]="oss-cn-zhangjiakou.aliyuncs.com•河北张家口, Alibaba Cloud"
#     IFS=$'\n' LIST=($(shuf <<<"${LIST[*]}"))
#     unset IFS
#     INDEX=0
#     TOTAL=${#LIST[@]}
#     for arr in "${LIST[@]}"
#     do
#         INDEX=$(( $INDEX + 1 ))
# 		param1=$( awk '{split($0, val, "•"); print val[1]}' <<< $arr )
# 		param2=$( awk '{split($0, val, "•"); print val[2]}' <<< $arr )
#         cnlatency "$param1" "$param2" "${INDEX}" "${TOTAL}"
#     done
#     IFS=$'\n' SORTED=($(sort <<<"${CHINALIST[*]}"))
#     unset IFS
#     echo -e "\r\033[0K"
#     for arr in "${SORTED[@]}"
#     do
#         echo " $arr" | tee -a $LOG
#     done
# }

# ping_script(){
#     pre_check
#     start_time=$(date +%s)
#     clear
#     print_intro
#     chinaping
#     end_script
# }

# check_time_zone(){
#     current_timezone=$(date +%Z)
#     accurate_time=$(TZ=UTC date +"%Y-%m-%d %H:%M:%S")
#     system_time=$(date +"%Y-%m-%d %H:%M:%S")
#     accurate_timestamp=$(date -d "$accurate_time" +%s)
#     system_timestamp=$(date -d "$system_time" +%s)
#     time_diff=$((accurate_timestamp - system_timestamp))
#     if [ $time_diff -gt 180 ] || [ $time_diff -lt -180 ]; then
#         _yellow "The system time differs from the accurate time of the time zone by more than 180 seconds, performing time correction..."
#         date -s "$accurate_time"
#         _green "Time has been corrected to: $(date +"%Y-%m-%d %H:%M:%S")"
#     else
#         _green "The system time differs from the accurate time of the time zone within 180 seconds, no correction is needed."
#     fi
# }

#     echo -e "${GREEN}7.${PLAIN} 全国网络延迟测试(平均运行1分钟)"
    
    
#     7) ping_script ; break ;;

# echo=echo
# for cmd in echo /bin/echo; do
#     $cmd >/dev/null 2>&1 || continue

#     if ! $cmd -e "" | grep -qE '^-e'; then
#         echo=$cmd
#         break
#     fi
# done


# checkssh() {
# 	for i in "${CMD[@]}"; do
# 		SYS="$i" && [[ -n $SYS ]] && break
# 	done
# 	for ((int=0; int<${#REGEX[@]}; int++)); do
# 		[[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
# 	done
# 	echo "开启22端口中，以便于测试IP是否被阻断"
# 	sshport=22
# 	[[ ! -f /etc/ssh/sshd_config ]] && sudo ${PACKAGE_UPDATE[int]} && sudo ${PACKAGE_INSTALL[int]} openssh-server
# 	[[ -z $(type -P curl) ]] && sudo ${PACKAGE_UPDATE[int]} && sudo ${PACKAGE_INSTALL[int]} curl
# 	sudo sed -i "s/^#\?Port.*/Port $sshport/g" /etc/ssh/sshd_config;
# 	sudo service ssh restart >/dev/null 2>&1  # 某些VPS系统的ssh服务名称为ssh，以防无法重启服务导致无法立刻使用密码登录
#     sudo systemctl restart sshd >/dev/null 2>&1 # Arch Linux没有使用init.d
#     sudo systemctl restart ssh >/dev/null 2>&1
# 	sudo service sshd restart >/dev/null 2>&1
# 	echo "开启22端口完毕"
# }

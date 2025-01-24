        # disk_total_size=0
        # disk_used_size=0
        # for size in "${disk_size1[@]}"; do
        #     size_gb=$(expr $size / 1024 / 1024)  # 转换为GB单位
        #     disk_total_size=$(expr $disk_total_size + $size_gb)  # 总大小累加
        # done
        # for size in "${disk_size2[@]}"; do
        #     size_gb=$(expr $size / 1024 / 1024)  # 转换为GB单位
        #     disk_used_size=$(expr $disk_used_size + $size_gb)  # 已用空间累加
        # done

# check_dmidecode(){
#     ${PACKAGE_INSTALL[int]} dmidecode
#     if [ $? -ne 0 ]; then
#         if command -v apt-get > /dev/null 2>&1; then
#             echo "Retrying with additional options..."
#             apt-get update && apt-get --fix-broken install -y
#             apt-get install -y dmidecode --force-yes
#             if [ $? -ne 0 ]; then
#                 apt-get update && apt-get --fix-broken install -y
#                 apt-get install -y dmidecode --allow
#                 if [ $? -ne 0 ]; then
#                     apt-get update && apt-get --fix-broken install -y
#                     apt-get install -y dmidecode -y --allow-unauthenticated
#                 fi
#             fi
#         fi
#     fi   
# }

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

# check_stun() {
#     _yellow "checking stun"
#     if ! command -v stun >/dev/null 2>&1; then
#         _yellow "Installing stun"
#         ${PACKAGE_INSTALL[int]} stun-client >/dev/null 2>&1
#     fi
# }

# checkpystun() {
#     _yellow "checking pystun"
#     local python_command
#     local pip_command
#     if command -v python3 >/dev/null 2>&1; then
#         python_command="python3"
#         pip_command="pip3"
#         _blue "$($python_command --version 2>&1)"
#     elif command -v python >/dev/null 2>&1; then
#         python_command="python"
#         pip_command="pip"
#         _blue "$($python_command --version 2>&1)"
#     else
#         _yellow "installing python3"
#         ${PACKAGE_INSTALL[int]} python3
#         if command -v python3 >/dev/null 2>&1; then
#             python_command="python3"
#             pip_command="pip3"
#             _blue "$($python_command --version 2>&1)"
#         elif command -v python >/dev/null 2>&1; then
#             python_command="python"
#             pip_command="pip"
#             _blue "$($python_command --version 2>&1)"
#         else
#             _yellow "installing python"
#             ${PACKAGE_INSTALL[int]} python
#             if command -v python3 >/dev/null 2>&1; then
#                 python_command="python3"
#                 pip_command="pip3"
#                 _blue "$($python_command --version 2>&1)"
#             elif command -v python >/dev/null 2>&1; then
#                 python_command="python"
#                 pip_command="pip"
#                 _blue "$($python_command --version 2>&1)"
#             else
#                 return
#             fi
#         fi
#     fi
#     if [[ $python_command == "python3" ]]; then
#         checkpip 3
#         if ! command -v pystun3 >/dev/null 2>&1; then
#             _yellow "Installing pystun3"
#             if ! "$pip_command" install -q pystun3 >/dev/null 2>&1; then
#                 "$pip_command" install -q pystun3
#                 if [ $? -ne 0 ]; then
#                     "$pip_command" install -q pystun3 --break-system-packages
#                 fi
#             fi
#         fi
#     fi
#     if [[ $python_command == "python" ]]; then
#         checkpip
#         if [[ $($python_command --version 2>&1) == Python\ 2* ]]; then
#             _yellow "Installing pystun"
#             if ! "$pip_command" install -q pystun >/dev/null 2>&1; then
#                 "$pip_command" install -q pystun
#                 if [ $? -ne 0 ]; then
#                     "$pip_command" install -q pystun --break-system-packages
#                 fi
#             fi
#         fi
#     fi
# }

# cloudflare() {
#     local status=0
#     local context1
#     rm -rf /tmp/ip_quality_cloudflare_risk
#     for ((i = 1; i <= 100; i++)); do
#         context1=$(curl -sL -m 10 "https://cf-threat.sukkaw.com/hello.json?threat=$i")
#         if [ "$en_status" = true ]; then
#             if [[ "$context1" != *"pong!"* ]]; then
#                 echo "Cloudflare threat scores higher than 10 are crawlers or spammers, higher than 40 have serious bad behavior (e.g., botnets, etc.), and values are generally no greater than 60" >>/tmp/ip_quality_cloudflare_risk
#                 echo "Cloudflare threatens to score: $i" >>/tmp/ip_quality_cloudflare_risk
#                 local status=1
#                 break
#             fi
#         else
#             if [[ "$context1" != *"pong!"* ]]; then
#                 echo "Cloudflare威胁得分高于10为爬虫或垃圾邮件发送者,高于40有严重不良行为(如僵尸网络等),数值一般不会大于60" >>/tmp/ip_quality_cloudflare_risk
#                 echo "Cloudflare威胁得分：$i" >>/tmp/ip_quality_cloudflare_risk
#                 local status=1
#                 break
#             fi
#         fi
#     done
#     if [[ $i == 100 && $status == 0 ]]; then
#         if [ "$en_status" = true ]; then
#             echo "Cloudflare Threat Score (0 for low risk): 0" >>/tmp/ip_quality_cloudflare_risk
#         else
#             echo "Cloudflare威胁得分(0为低风险): 0" >>/tmp/ip_quality_cloudflare_risk
#         fi
#     fi
# }

# cloudflare() {
#     local status=0
#     local context1
#     rm -rf /tmp/ip_quality_cloudflare_risk
#     for ((i = 1; i <= 100; i++)); do
#         context1=$(curl -sL -m 10 "https://cf-threat.sukkaw.com/hello.json?threat=$i")
#         if [[ "$context1" != *"pong!"* ]]; then
#             echo "Cloudflare威胁得分高于10为爬虫或垃圾邮件发送者,高于40有严重不良行为(如僵尸网络等),数值一般不会大于60" >>/tmp/ip_quality_cloudflare_risk
#             echo "Cloudflare威胁得分：$i" >>/tmp/ip_quality_cloudflare_risk
#             local status=1
#             break
#         fi
#     done
#     if [[ $i == 100 && $status == 0 ]]; then
#         echo "Cloudflare威胁得分(0为低风险): 0" >>/tmp/ip_quality_cloudflare_risk
#     fi
# }


# # ipinfo数据库 ①
# ipinfo() {
#     rm -rf /tmp/ip_quality_ipinfo*
#     local ip="$1"
#     local output=$(curl -sL -m 10 -v "https://ipinfo.io/widget/demo/${ip}" -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36" -H "Referer: https://ipinfo.io" 2>/dev/null)
#     local temp_output=$(echo "$output" | sed -e '/^*/d' -e '/^>/d' -e '/^  CApath/d')
#     local type_output=$(echo "$temp_output" | awk -F'"type":' '{print $2}' | awk -F'"' '{print $2}' | sed '/^\s*$/d')
#     local asn_type=$(echo "$type_output" | sed -n '1p')
#     local company_type=$(echo "$type_output" | sed -n '2p')
#     local vpn=$(echo "$temp_output" | grep -o '"vpn": .*,' | cut -d' ' -f2 | tr -d '",')
#     local proxy=$(echo "$temp_output" | grep -o '"proxy": .*,' | cut -d' ' -f2 | tr -d '",')
#     local tor=$(echo "$temp_output" | grep -o '"tor": .*,' | cut -d' ' -f2 | tr -d '",')
#     local relay=$(echo "$temp_output" | grep -o '"relay": .*,' | cut -d' ' -f2 | tr -d '",')
#     local hosting=$(echo "$temp_output" | grep -o '"hosting": .*,' | cut -d' ' -f2 | tr -d '",')
#     echo "$asn_type" >/tmp/ip_quality_ipinfo_usage_type
#     echo "$company_type" >/tmp/ip_quality_ipinfo_company_type
#     echo "$vpn" >/tmp/ip_quality_ipinfo_vpn
#     echo "$proxy" >/tmp/ip_quality_ipinfo_proxy
#     echo "$tor" >/tmp/ip_quality_ipinfo_tor
#     echo "$relay" >/tmp/ip_quality_ipinfo_icloud_relay
#     echo "$hosting" >/tmp/ip_quality_ipinfo_hosting
# }

# # scamalytics数据库 ②
# scamalytics_ipv4() {
#     local ip="$1"
#     rm -rf /tmp/ip_quality_scamalytics_ipv4*
#     local context=$(curl -sL -H "Referer: https://scamalytics.com" -m 10 "https://scamalytics.com/ip/$ip")
#     if [[ "$?" -ne 0 ]]; then
#         return
#     fi
#     local temp1=$(echo "$context" | grep -oP '(?<=>Fraud Score: )[^<]+')
#     # 欺诈分数
#     if [ -n "$temp1" ]; then
#         echo "$temp1" >>/tmp/ip_quality_scamalytics_ipv4_score
#     else
#         return
#     fi
#     local temp2=$(echo "$context" | grep -oP '(?<=<div).*?(?=</div>)' | tail -n 6)
#     local nlist=("vpn" "tor" "datacenter" "public_proxy" "web_proxy" "search_engine_robot")
#     local status_t2
#     for element in $temp2; do
#         if echo "$element" | grep -q "score" >/dev/null 2>&1; then
#             status_t2=1
#             break
#         else
#             status_t2=2
#             break
#         fi
#     done
#     local i=0
#     if ! [ "$status_t2" -eq 1 ]; then
#         while read -r temp3; do
#             if [[ -n "$temp3" ]]; then
#                 echo "${temp3#*>}" >>/tmp/ip_quality_scamalytics_ipv4_${nlist[$i]}
#                 i=$((i + 1))
#             fi
#         done <<<"$(echo "$temp2" | sed 's/<[^>]*>//g' | sed 's/^[[:blank:]]*//g')"
#     fi
# }

# # scamalytics数据库 ②
# scamalytics_ipv6() {
#     local ip="$1"
#     rm -rf /tmp/ip_quality_scamalytics_ipv6*
#     local context=$(curl -sL -H "Referer: https://scamalytics.com" -m 10 "https://scamalytics.com/ip/$ip")
#     if [[ "$?" -ne 0 ]]; then
#         return
#     fi
#     local temp1=$(echo "$context" | grep -oP '(?<=>Fraud Score: )[^<]+')
#     # 欺诈分数
#     if [ -n "$temp1" ]; then
#         echo "$temp1" >>/tmp/ip_quality_scamalytics_ipv6_score
#     else
#         return
#     fi
#     local temp2=$(echo "$context" | grep -oP '(?<=<div).*?(?=</div>)' | tail -n 6)
#     local nlist=("vpn" "tor" "datacenter" "public_proxy" "web_proxy" "search_engine_robot")
#     local status_t2
#     for element in $temp2; do
#         if echo "$element" | grep -q "score" >/dev/null 2>&1; then
#             status_t2=1
#             break
#         else
#             status_t2=2
#             break
#         fi
#     done
#     local i=0
#     if ! [ "$status_t2" -eq 1 ]; then
#         while read -r temp3; do
#             if [[ -n "$temp3" ]]; then
#                 echo "${temp3#*>}" >>/tmp/ip_quality_scamalytics_ipv6_${nlist[$i]}
#                 i=$((i + 1))
#             fi
#         done <<<"$(echo "$temp2" | sed 's/<[^>]*>//g' | sed 's/^[[:blank:]]*//g')"
#     fi
# }

# # virustotal数据库 ③
# virustotal() {
#     local ip="$1"
#     rm -rf /tmp/ip_quality_virustotal*
#     local api_keys=(
#     )
#     local api_key=${api_keys[$RANDOM % ${#api_keys[@]}]}
#     local output=$(curl -s --request GET --url "https://www.virustotal.com/api/v3/ip_addresses/$ip" --header "x-apikey:$api_key")
#     result=$(echo "$output" | awk -F"[,:}]" '{
#         for(i=1;i<=NF;i++){
#             if($i~/\042timeout\042/){
#                 exit
#             } else if($i~/\042harmless\042/){
#                 print $(i+1)
#             } else if($i~/\042malicious\042/){
#                 print $(i+1)
#             } else if($i~/\042suspicious\042/){
#                 print $(i+1)
#             } else if($i~/\042undetected\042/){
#                 print $(i+1)
#             }
#         }
#     }' | sed 's/\"//g')
#     # 黑名单记录统计:(有多少黑名单网站有记录)
#     if [[ -n "$result" ]] && [[ -n "$(echo "$result" | awk 'NF')" ]]; then
#         echo "$result" | sed 's/ //g' | awk 'NR==1' >/tmp/ip_quality_virustotal_harmlessness_records
#         echo "$result" | sed 's/ //g' | awk 'NR==2' >/tmp/ip_quality_virustotal_malicious_records
#         echo "$result" | sed 's/ //g' | awk 'NR==3' >/tmp/ip_quality_virustotal_suspicious_records
#         echo "$result" | sed 's/ //g' | awk 'NR==4' >/tmp/ip_quality_virustotal_no_records
#     fi
# }

# # abuseipdb数据库 ④ IP2Location数据库 ⑤
# abuse_ipv4() {
#     local ip="$1"
#     local score
#     local usageType
#     rm -rf /tmp/ip_quality_abuseipdb_ipv4*
#     local api_heads=(
#         'key: e88362808d1219e27a786a465a1f57ec3417b0bdeab46ad670432b7ce1a7fdec0d67b05c3463dd3c'
#         'key: a240c11ca3d2f3d58486fa86f1744a143448d3a6fcb2fc1f8880bafd58c3567a0adddcfd7a722364'
#     )
#     local head=${api_heads[$RANDOM % ${#api_heads[@]}]}
#     local context2=$(curl -sL -H "$head" -m 10 "https://api.abuseipdb.com/api/v2/check?ipAddress=${ip}")
#     if [[ "$context2" == *"abuseConfidenceScore"* ]]; then
#         score=$(echo "$context2" | grep -o '"abuseConfidenceScore":[^,}]*' | sed 's/.*://')
#         echo "$score" >/tmp/ip_quality_abuseipdb_ipv4_score
#         usageType=$(grep -oP '"usageType":\s*"\K[^"]+' <<<"$context2" | sed 's/\\\//\//g')
#         if [ -z "$usageType" ]; then
#             usageType="Unknown (Maybe Fixed Line ISP)"
#         fi
#         echo "$usageType" >/tmp/ip_quality_ip2location_ipv4_usage_type
#     fi
# }

# # abuseipdb数据库 ④ IP2Location数据库 ⑤
# abuse_ipv6() {
#     local ip="$1"
#     local score
#     local usageType
#     rm -rf /tmp/ip_quality_abuseipdb_ipv6*
#     local api_heads=(
#         'key: e88362808d1219e27a786a465a1f57ec3417b0bdeab46ad670432b7ce1a7fdec0d67b05c3463dd3c'
#         'key: a240c11ca3d2f3d58486fa86f1744a143448d3a6fcb2fc1f8880bafd58c3567a0adddcfd7a722364'
#     )
#     local head=${api_heads[$RANDOM % ${#api_heads[@]}]}
#     local context2=$(curl -sL -H "$head" -m 10 "https://api.abuseipdb.com/api/v2/check?ipAddress=${ip}")
#     if [[ "$context2" == *"abuseConfidenceScore"* ]]; then
#         score=$(echo "$context2" | grep -o '"abuseConfidenceScore":[^,}]*' | sed 's/.*://')
#         echo "$score" >/tmp/ip_quality_abuseipdb_ipv6_score
#         usageType=$(grep -oP '"usageType":\s*"\K[^"]+' <<<"$context2" | sed 's/\\\//\//g')
#         if [ -z "$usageType" ]; then
#             usageType="Unknown (Maybe Fixed Line ISP)"
#         fi
#         echo "$usageType" >/tmp/ip_quality_ip2location_ipv6_usage_type
#     fi
# }

# # ip-api数据库 ⑥
# ip_api() {
#     local ip=$1
#     local mobile
#     local tp1
#     local proxy
#     local tp2
#     local hosting
#     local tp3
#     rm -rf /tmp/ip_quality_ipapi*
#     local context4=$(curl -sL -m 10 "http://ip-api.com/json/$ip?fields=mobile,proxy,hosting")
#     if [[ "$context4" == *"mobile"* ]]; then
#         mobile=$(echo "$context4" | grep -o '"mobile":[^,}]*' | sed 's/.*://;s/"//g')
#         tp1=$(translate_status ${mobile})
#         echo "$tp1" >>/tmp/ip_quality_ip_api_mobile
#         proxy=$(echo "$context4" | grep -o '"proxy":[^,}]*' | sed 's/.*://;s/"//g')
#         tp2=$(translate_status ${proxy})
#         echo "$tp2" >>/tmp/ip_quality_ip_api_proxy
#         hosting=$(echo "$context4" | grep -o '"hosting":[^,}]*' | sed 's/.*://;s/"//g')
#         tp3=$(translate_status ${hosting})
#         echo "$tp3" >>/tmp/ip_quality_ip_api_datacenter
#     fi
# }

# # ipwhois数据库 ⑦
# ipwhois() {
#     local ip="$1"
#     rm -rf /tmp/ip_quality_ipwhois*
#     local url="https://ipwhois.io/widget?ip=${ip}&lang=en"
#     local response=$(curl -s "$url" --compressed \
#         -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0" \
#         -H "Accept: */*" \
#         -H "Accept-Language: zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2" \
#         -H "Accept-Encoding: gzip, deflate, br" \
#         -H "Connection: keep-alive" \
#         -H "Referer: https://ipwhois.io/" \
#         -H "Sec-Fetch-Dest: empty" \
#         -H "Sec-Fetch-Mode: cors" \
#         -H "Sec-Fetch-Site: same-origin" \
#         -H "TE: trailers")
#     if [[ "$?" -ne 0 ]]; then
#         return
#     fi
#     security_section=$(echo "$response" | grep -o '"security":{[^}]*}')
#     anonymous=$(echo "$security_section" | awk -F'"anonymous":' '{print $2}' | cut -d',' -f1)
#     proxy=$(echo "$security_section" | awk -F'"proxy":' '{print $2}' | cut -d',' -f1)
#     vpn=$(echo "$security_section" | awk -F'"vpn":' '{print $2}' | cut -d',' -f1)
#     tor=$(echo "$security_section" | awk -F'"tor":' '{print $2}' | cut -d',' -f1)
#     hosting=$(echo "$security_section" | awk -F'"hosting":' '{print $2}' | cut -d',' -f1 | sed 's/}//')
#     echo "$anonymous" >>/tmp/ip_quality_ipwhois_anonymous
#     echo "$proxy" >>/tmp/ip_quality_ipwhois_proxy
#     echo "$vpn" >>/tmp/ip_quality_ipwhois_vpn
#     echo "$tor" >>/tmp/ip_quality_ipwhois_tor
#     echo "$hosting" >>/tmp/ip_quality_ipwhois_hosting
# }

# # ipregistry数据库 ⑧
# ipregistry() {
#     rm -rf /tmp/ip_quality_ipregistry*
#     local ip="$1"
#     local api_keys=(
#     )
#     local api_key=${api_keys[$RANDOM % ${#api_keys[@]}]}
#     local response
#     response=$(curl -sL -H "Origin: https://ipregistry.co" -H "Referer: https://ipregistry.co" --header "Content-Type: application/json" -m 10 "https://api.ipregistry.co/${ip}?hostname=true&key=sb69ksjcajfs4c" 2>/dev/null)
#     if [ $? -ne 0 ]; then
#         response=$(curl -sL -m 10 "https://api.ipregistry.co/${ip}?key=${api_keys}" 2>/dev/null)
#     fi
#     local company_type=$(echo "$response" | grep -oE '"company":\{"domain":"[^"]+","name":"[^"]+","type":"[^"]+"}' | sed 's/.*"type":"\([^"]*\)".*/\1/')
#     local connection_type=$(echo "$response" | grep -oE '"connection":\{"asn":[0-9]+,"domain":"[^"]+","organization":"[^"]+","route":"[^"]+","type":"[^"]+"}' | sed 's/.*"type":"\([^"]*\)".*/\1/')
#     local abuser=$(echo "$response" | grep -o '"is_abuser":[a-zA-Z]*' | awk -F':' '{print $2}')
#     local attacker=$(echo "$response" | grep -o '"is_attacker":[a-zA-Z]*' | awk -F':' '{print $2}')
#     local bogon=$(echo "$response" | grep -o '"is_bogon":[a-zA-Z]*' | awk -F':' '{print $2}')
#     local cloud_provider=$(echo "$response" | grep -o '"is_cloud_provider":[a-zA-Z]*' | awk -F':' '{print $2}')
#     local proxy=$(echo "$response" | grep -o '"is_proxy":[a-zA-Z]*' | awk -F':' '{print $2}')
#     local relay=$(echo "$response" | grep -o '"is_relay":[a-zA-Z]*' | awk -F':' '{print $2}')
#     local tor=$(echo "$response" | grep -o '"is_tor":[a-zA-Z]*' | awk -F':' '{print $2}')
#     local tor_exit=$(echo "$response" | grep -o '"is_tor_exit":[a-zA-Z]*' | awk -F':' '{print $2}')
#     local vpn=$(echo "$response" | grep -o '"is_vpn":[a-zA-Z]*' | awk -F':' '{print $2}')
#     local anonymous=$(echo "$response" | grep -o '"is_anonymous":[a-zA-Z]*' | awk -F':' '{print $2}')
#     local threat=$(echo "$response" | grep -o '"is_threat":[a-zA-Z]*' | awk -F':' '{print $2}')
#     echo "$company_type" >/tmp/ip_quality_ipregistry_company_type
#     echo "$connection_type" >/tmp/ip_quality_ipregistry_usage_type
#     echo "$abuser" >/tmp/ip_quality_ipregistry_abuser
#     echo "$attacker" >/tmp/ip_quality_ipregistry_attacker
#     echo "$bogon" >/tmp/ip_quality_ipregistry_bogon
#     echo "$cloud_provider" >/tmp/ip_quality_ipregistry_cloud_provider
#     echo "$proxy" >/tmp/ip_quality_ipregistry_proxy
#     echo "$relay" >/tmp/ip_quality_ipregistry_icloud_relay
#     echo "$tor" >/tmp/ip_quality_ipregistry_tor
#     echo "$tor_exit" >/tmp/ip_quality_ipregistry_tor_exit
#     echo "$vpn" >/tmp/ip_quality_ipregistry_vpn
#     echo "$anonymous" >/tmp/ip_quality_ipregistry_anonymous
#     echo "$threat" >/tmp/ip_quality_ipregistry_threat
# }

# # ipdata数据库 ⑨
# ipdata() {
#     rm -rf /tmp/ip_quality_ipdata*
#     local ip="$1"
#     local api_keys=(
#     )
#     local api_key=${api_keys[$RANDOM % ${#api_keys[@]}]}
#     response=$(curl -sL -m 10 "https://api.ipdata.co/${ip}?api-key=${api_key}" 2>/dev/null)
#     local usage_type=$(echo "$response" | grep -o '"type": "[^"]*' | cut -d'"' -f4 | tr -d '\n')
#     local tor=$(grep -o '"is_tor": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local icloud_relay=$(grep -o '"is_icloud_relay": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local proxy=$(grep -o '"is_proxy": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local datacenter=$(grep -o '"is_datacenter": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local anonymous=$(grep -o '"is_anonymous": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local attacker=$(grep -o '"is_known_attacker": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local abuser=$(grep -o '"is_known_abuser": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local threat=$(grep -o '"is_threat": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local bogon=$(grep -o '"is_bogon": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     echo "$usage_type" >/tmp/ip_quality_ipdata_usage_type
#     echo "$tor" >/tmp/ip_quality_ipdata_tor
#     echo "$icloud_relay" >/tmp/ip_quality_ipdata_icloud_relay
#     echo "$proxy" >/tmp/ip_quality_ipdata_proxy
#     echo "$datacenter" >/tmp/ip_quality_ipdata_datacenter
#     echo "$anonymous" >/tmp/ip_quality_ipdata_anonymous
#     echo "$attacker" >/tmp/ip_quality_ipdata_attacker
#     echo "$abuser" >/tmp/ip_quality_ipdata_abuser
#     echo "$threat" >/tmp/ip_quality_ipdata_threat
#     echo "$bogon" >/tmp/ip_quality_ipdata_bogon
# }

# # ipgeolocation数据库 ⑩
# ipgeolocation() {
#     rm -rf /tmp/ip_quality_ipgeolocation*
#     local ip="$1"
#     local api_keys=(
#     )
#     local api_key=${api_keys[$RANDOM % ${#api_keys[@]}]}
#     local response=$(curl -sL -m 10 "https://api.ip2location.io/?key=${api_key}&ip=${ip}" 2>/dev/null)
#     local is_proxy=$(echo "$response" | grep -o '"is_proxy":\s*false\|true' | cut -d ":" -f2)
#     is_proxy=$(echo "$is_proxy" | tr -d '"')
#     echo "$is_proxy" >/tmp/ip_quality_ipgeolocation_proxy
# }

# # ipapiis数据库 ⑪
# ipapiis_ipv4() {
#     rm -rf /tmp/ip_quality_ipapiis_ipv4_*
#     local ip="$1"
#     local response=$(curl -sL -m 10 "https://api.ipapi.is/?q=${ip}" 2>/dev/null)
#     local company_type=$(echo "$response" | sed -n 's/.*"type": "\(.*\)".*/\1/p' | head -n 1)
#     local usage_type=$(echo "$response" | sed -n 's/.*"type": "\(.*\)".*/\1/p' | tail -n 1)
#     local abuser_score=$(echo "$response" | sed -n 's/.*"abuser_score": "\(.*\)".*/\1/p' | head -n 1)
#     local bogon=$(grep -o '"is_bogon": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local mobile=$(grep -o '"is_mobile": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local crawler=$(grep -o '"is_crawler": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local datacenter=$(grep -o '"is_datacenter": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local tor=$(grep -o '"is_tor": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local proxy=$(grep -o '"is_proxy": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local vpn=$(grep -o '"is_vpn": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local abuser=$(grep -o '"is_abuser": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     echo "$company_type" >/tmp/ip_quality_ipapiis_ipv4_company_type
#     echo "$usage_type" >/tmp/ip_quality_ipapiis_ipv4_usage_type
#     echo "$abuser_score" >/tmp/ip_quality_ipapiis_ipv4_score
#     echo "$bogon" >/tmp/ip_quality_ipapiis_ipv4_bogon
#     echo "$mobile" >/tmp/ip_quality_ipapiis_ipv4_mobile
#     echo "$crawler" >/tmp/ip_quality_ipapiis_ipv4_crawler
#     echo "$datacenter" >/tmp/ip_quality_ipapiis_ipv4_datacenter
#     echo "$tor" >/tmp/ip_quality_ipapiis_ipv4_tor
#     echo "$proxy" >/tmp/ip_quality_ipapiis_ipv4_proxy
#     echo "$vpn" >/tmp/ip_quality_ipapiis_ipv4_vpn
#     echo "$abuser" >/tmp/ip_quality_ipapiis_ipv4_abuser
# }

# # ipapiis数据库 ⑪
# ipapiis_ipv6() {
#     rm -rf /tmp/ip_quality_ipapiis_ipv6_*
#     local ip="$1"
#     local response=$(curl -sL -m 10 "https://api.ipapi.is/?q=${ip}" 2>/dev/null)
#     local company_type=$(echo "$response" | sed -n 's/.*"type": "\(.*\)".*/\1/p' | head -n 1)
#     local usage_type=$(echo "$response" | sed -n 's/.*"type": "\(.*\)".*/\1/p' | tail -n 1)
#     local abuser_score=$(echo "$response" | sed -n 's/.*"abuser_score": "\(.*\)".*/\1/p' | tail -n 1)
#     # local bogon=$(grep -o '"is_bogon": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     # local mobile=$(grep -o '"is_mobile": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     # local crawler=$(grep -o '"is_crawler": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     # local datacenter=$(grep -o '"is_datacenter": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     # local tor=$(grep -o '"is_tor": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     # local proxy=$(grep -o '"is_proxy": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     # local vpn=$(grep -o '"is_vpn": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     # local abuser=$(grep -o '"is_abuser": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     echo "$company_type" >/tmp/ip_quality_ipapiis_ipv6_company_type
#     echo "$usage_type" >/tmp/ip_quality_ipapiis_ipv6_usage_type
#     echo "$abuser_score" >/tmp/ip_quality_ipapiis_ipv6_score
#     # echo "$bogon" >/tmp/ip_quality_ipapiis_ipv6_bogon
#     # echo "$mobile" >/tmp/ip_quality_ipapiis_ipv6_mobile
#     # echo "$crawler" >/tmp/ip_quality_ipapiis_ipv6_crawler
#     # echo "$datacenter" >/tmp/ip_quality_ipapiis_ipv6_datacenter
#     # echo "$tor" >/tmp/ip_quality_ipapiis_ipv6_tor
#     # echo "$proxy" >/tmp/ip_quality_ipapiis_ipv6_proxy
#     # echo "$vpn" >/tmp/ip_quality_ipapiis_ipv6_vpn
#     # echo "$abuser" >/tmp/ip_quality_ipapiis_ipv6_abuser
# }

# # ipapicom数据库 ⑫
# ipapicom_ipv4() {
#     rm -rf /tmp/ip_quality_ipapicom*
#     local ip="$1"
#     local response=$(curl -sL -m 10 "https://ipapi.com/ip_api.php?ip=${ip}" 2>/dev/null)
#     local proxy=$(grep -o '"is_proxy": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local crawler=$(grep -o '"is_crawler": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local tor=$(grep -o '"is_tor": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local threat_level=$(grep -o '"threat_level": "[^"]\+"' <<<"$response" | cut -d '"' -f 4)
#     echo "$crawler" >/tmp/ip_quality_ipapicom_ipv4_crawler
#     echo "$tor" >/tmp/ip_quality_ipapicom_ipv4_tor
#     echo "$proxy" >/tmp/ip_quality_ipapicom_ipv4_proxy
#     echo "$threat_level" >/tmp/ip_quality_ipapicom_ipv4_threat_level
# }

# # ipapicom数据库 ⑫
# ipapicom_ipv6() {
#     rm -rf /tmp/ip_quality_ipapicom*
#     local ip="$1"
#     local response=$(curl -sL -m 10 "https://ipapi.com/ip_api.php?ip=${ip}" 2>/dev/null)
#     local proxy=$(grep -o '"is_proxy": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local crawler=$(grep -o '"is_crawler": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local tor=$(grep -o '"is_tor": \w\+' <<<"$response" | cut -d ' ' -f 2)
#     local threat_level=$(grep -o '"threat_level": "[^"]\+"' <<<"$response" | cut -d '"' -f 4)
#     echo "$crawler" >/tmp/ip_quality_ipapicom_ipv6_crawler
#     echo "$tor" >/tmp/ip_quality_ipapicom_ipv6_tor
#     echo "$proxy" >/tmp/ip_quality_ipapicom_ipv6_proxy
#     echo "$threat_level" >/tmp/ip_quality_ipapicom_ipv6_threat_level
# }


# ipcheck() {
#     if [ "$en_status" = true ]; then
#         _blue "The following is the number of each database, the output will come with the corresponding number of the database source"
#         _blue "ipinfo  databases ① | scamalytics databases ②  | virustotal  databases ③ | abuseipdb databases ④  | ip2location databases   ⑤"
#         _blue "ip-api  databases ⑥ | ipwhois databases     ⑦  | ipregistry  databases ⑧ | ipdata databases    ⑨  | ipgeolocation databases ⑩"
#         _blue "ipapiis databases ⑪ | ipapicom databases    ⑫  "
#     else
#         _blue "以下为各数据库编号，输出结果后将自带数据库来源对应的编号"
#         _blue "ipinfo数据库  ① | scamalytics数据库 ②  | virustotal数据库  ③ | abuseipdb数据库 ④  | ip2location数据库   ⑤"
#         _blue "ip-api数据库  ⑥ | ipwhois数据库     ⑦  | ipregistry数据库  ⑧ | ipdata数据库    ⑨  | ipgeolocation数据库 ⑩"
#         _blue "ipapiis数据库 ⑪ | ipapicom数据库    ⑫  "
#     fi
#     local ip4=$(echo "$IPV4" | tr -d '\n')
#     local ip6=$(echo "$IPV6" | tr -d '\n')
#     if [[ -z "${ip4}" ]] && [[ ! -z "${ip6}" ]]; then
#         if [ "$en_status" = true ]; then
#             echo "The following IPV6 detection"
#         else
#             echo "以下为IPV6检测"
#         fi
#     fi
#     { ipapiis_ipv4 "$ip4"; } &
#     { ipapicom_ipv4 "$ip4"; } &
#     { scamalytics_ipv4 "$ip4"; } &
#     { abuse_ipv4 "$ip4"; } &
#     { google; } &
#     { ipinfo "$ip4"; } &
#     { virustotal "$ip4"; } &
#     { ip_api "$ip4"; } &
#     { ipwhois "$ip4"; } &
#     { ipregistry "$ip4"; } &
#     { ipdata "$ip4"; } &
#     { ipgeolocation "$ip4"; } &
#     if command -v nc >/dev/null; then
#         { check_port_25; } &
#     fi
#     if [[ -n "$ip6" ]]; then
#         { ipapiis_ipv6 "$ip6"; } &
#         { ipapicom_ipv6 "$ip6"; } &
#         { scamalytics_ipv6 "$ip6"; } &
#         { abuse_ipv6 "$ip6"; } &
#     fi
#     wait
#     # 预处理部分类型
#     rm -rf /tmp/ip_quality_scamalytics_ipv4_proxy
#     local public_proxy_4=$(check_and_cat_file '/tmp/ip_quality_scamalytics_ipv4_public_proxy')
#     local web_proxy_4=$(check_and_cat_file '/tmp/ip_quality_scamalytics_ipv4_web_proxy')
#     if [ -n "$public_proxy_4" ] && [ -n "$web_proxy_4" ]; then
#         if [ "$public_proxy_4" = "Yes" ] || [ "$web_proxy_4" = "Yes" ]; then
#             echo "Yes" >/tmp/ip_quality_scamalytics_ipv4_proxy
#         else
#             echo "No" >/tmp/ip_quality_scamalytics_ipv4_proxy
#         fi
#     fi
#     # 得分和等级合并同一行
#     local temp_text=""
#     local score_2_4=$(check_and_cat_file '/tmp/ip_quality_scamalytics_ipv4_score')
#     if [[ -z "$score_2_4" ]]; then
#         if [ "$en_status" = true ]; then
#             temp_text+="Fraud_score(the lower the better): $score_14_4⑪  "
#         else
#             temp_text+="欺诈分数(越低越好): $score_14_4⑪  "
#         fi
#     fi
#     local score_4_4=$(check_and_cat_file '/tmp/ip_quality_abuseipdb_ipv4_score')
#     local score_11_4=$(check_and_cat_file '/tmp/ip_quality_ipapiis_ipv4_score')
#     if [[ -n "$score_4_4" && -n "$score_11_4" ]]; then
#         if [ "$en_status" = true ]; then
#             temp_text+="Abuse_score(the lower the better): $score_4_4⑤  $score_11_4⑪  "
#         else
#             temp_text+="abuse得分(越低越好): $score_4_4⑤  $score_11_4⑪  "
#         fi
#     elif [[ -n "$score_4_4" && -z "$score_11_4" ]]; then
#         if [ "$en_status" = true ]; then
#             temp_text+="Abuse_score(the lower the better): $score_4_4⑤  "
#         else
#             temp_text+="abuse得分(越低越好): $score_4_4⑤  "
#         fi
#     elif [[ -n "$score_11_4" && -z "$score_5_4" ]]; then
#         if [ "$en_status" = true ]; then
#             temp_text+="Abuse_score(the lower the better): $score_11_4⑪  "
#         else
#             temp_text+="abuse得分(越低越好): $score_11_4⑪  "
#         fi
#     fi
#     local threat_12_4=$(check_and_cat_file '/tmp/ip_quality_ipapicom_ipv4_threat_level')
#     if [[ -n "$threat_12_4" ]]; then
#         if [ "$en_status" = true ]; then
#             temp_text+="threat_level: $threat_12_4②  "
#         else
#             temp_text+="威胁等级: $threat_12_4②  "
#         fi
#     fi
#     echo "$temp_text"
#     if [ "$en_status" = true ]; then
#         echo "IP Type: "
#     else
#         echo "IP类型: "
#     fi
#     local ip_quality_filename_data=("/tmp/ip_quality_ipinfo_" "/tmp/ip_quality_scamalytics_ipv4_" "/tmp/ip_quality_ip2location_ipv4_" "/tmp/ip_quality_ip_api_" "/tmp/ip_quality_ipwhois_" "/tmp/ip_quality_ipregistry_" "/tmp/ip_quality_ipdata_" "/tmp/ip_quality_ipgeolocation_" "/tmp/ip_quality_ipapiis_ipv4_" "/tmp/ip_quality_ipapicom_ipv4_")
#     local serial_number=("①" "②" "⑤" "⑥" "⑦" "⑧" "⑨" "⑩" "⑪" "⑫" "⑬" "⑭")
#     local project_data=("usage_type" "company_type" "cloud_provider" "datacenter" "mobile" "proxy" "vpn" "tor" "tor_exit" "search_engine_robot" "anonymous" "attacker" "abuser" "threat" "icloud_relay" "bogon")
#     if [ "$en_status" = true ]; then
#         local project_translate_data=("" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "")
#     else
#         local project_translate_data=("使用类型" "公司类型" "云服务提供商" "数据中心" "移动网络" "代理" "VPN" "TOR" "TOR出口" "搜索引擎机器人" "匿名代理" "攻击方" "滥用者" "威胁" "iCloud中继" "未分配IP")
#     fi
#     declare -A project_translate
#     for ((i = 0; i < ${#project_data[@]}; i++)); do
#         project_translate[${project_data[i]}]=${project_translate_data[i]}
#     done
#     for project in "${project_data[@]}"; do
#         content=""
#         no_appear=0
#         yes_appear=0
#         for ((i = 0; i < ${#ip_quality_filename_data[@]}; i++)); do
#             file_content=$(check_and_cat_file "${ip_quality_filename_data[i]}${project}")
#             if [ -n "$file_content" ]; then
#                 if [ "$project" = "usage_type" ] || [ "$project" = "company_type" ]; then
#                     content+="${file_content}${serial_number[i]}"
#                     content+=" "
#                 else
#                     file_status=$(translate_status ${file_content})
#                     if [ "$file_status" = "No" ]; then
#                         if [ $no_appear -eq 0 ]; then
#                             content+="  "
#                             content+="No"
#                             no_appear=1
#                         fi
#                     elif [ "$file_status" = "Yes" ]; then
#                         if [ $yes_appear -eq 0 ]; then
#                             content+="  "
#                             content+="Yes"
#                             yes_appear=1
#                         fi
#                     fi
#                     content+="${serial_number[i]}"
#                 fi
#                 content+=" "
#             fi
#         done
#         if [ -n "$content" ]; then
#             if [ "$en_status" = true ]; then
#                 echo "  ${project_translate[$project]}${project}:${content}"
#             else
#                 echo "  ${project_translate[$project]}(${project}):${content}"
#             fi
#         fi
#     done
#     local score_3_1=$(check_and_cat_file '/tmp/ip_quality_virustotal_harmlessness_records')
#     local score_3_2=$(check_and_cat_file '/tmp/ip_quality_virustotal_malicious_records')
#     local score_3_3=$(check_and_cat_file '/tmp/ip_quality_virustotal_suspicious_records')
#     local score_3_4=$(check_and_cat_file '/tmp/ip_quality_virustotal_no_records')
#     if [ -n "$score_3_1" ] && [ -n "$score_3_2" ] && [ -n "$score_3_3" ] && [ -n "$score_3_4" ]; then
#         if [ "$en_status" = true ]; then
#             echo "Blacklist_Records_Statistics(how many blacklisted websites have records): harmless $score_3_1 malware $score_3_2 dubious $score_3_3 untested $score_3_4 ③"
#         else
#             echo "黑名单记录统计(有多少个黑名单网站有记录): 无害$score_3_1 恶意$score_3_2 可疑$score_3_3 未检测$score_3_4 ③"
#         fi
#     fi
#     check_and_cat_file "/tmp/ip_quality_google"
#     check_and_cat_file "/tmp/ip_quality_check_port_25"
#     if [[ ! -z "${ip6}" ]]; then
#         if [[ ! -z "${ip4}" ]] && [[ ! -z "${ip6}" ]]; then
#             if [ "$en_status" = true ]; then
#                 echo "------The following IPV6 detection------"
#             else
#                 echo "------以下为IPV6检测------"
#             fi
#         fi
#         temp_text=""
#         local score_2_6=$(check_and_cat_file '/tmp/ip_quality_scamalytics_ipv6_score')
#         if [[ -n "$score_2_6" ]]; then
#             if [ "$en_status" = true ]; then
#                 temp_text+="Fraud_score(the lower the better): $score_2_6②  "
#             else
#                 temp_text+="欺诈分数(越低越好): $score_2_6②  "
#             fi
#         fi
#         local score_4_6=$(check_and_cat_file '/tmp/ip_quality_abuseipdb_ipv6_score')
#         local score_11_6=$(check_and_cat_file '/tmp/ip_quality_ipapiis_ipv6_score')
#         if [[ -n "$score_4_6" && -n "$score_11_6" ]]; then
#             if [ "$en_status" = true ]; then
#                 temp_text+="Abuse_score(the lower the better): $score_4_6⑤  $score_11_6⑪  "
#             else
#                 temp_text+="abuse得分(越低越好): $score_4_6⑤  $score_11_6⑪  "
#             fi
#         elif [[ -n "$score_4_6" && -z "$score_11_6" ]]; then
#             if [ "$en_status" = true ]; then
#                 temp_text+="Abuse_score(the lower the better): $score_4_6⑤  "
#             else
#                 temp_text+="abuse得分(越低越好): $score_4_6⑤  "
#             fi
#         elif [[ -n "$score_11_6" && -z "$score_5_6" ]]; then
#             if [ "$en_status" = true ]; then
#                 temp_text+="Abuse_score(the lower the better): $score_11_6⑪  "
#             else
#                 temp_text+="abuse得分(越低越好): $score_11_6⑪  "
#             fi
#         fi
#         local threat_12_6=$(check_and_cat_file '/tmp/ip_quality_ipapicom_ipv6_threat_level')
#         if [[ -n "$threat_12_6" ]]; then
#             if [ "$en_status" = true ]; then
#                 temp_text+="threat_level: $threat_12_6②  "
#             else
#                 temp_text+="威胁等级: $threat_12_6②  "
#             fi
#         fi
#         echo "$temp_text"
#         local usage_type_5_6=$(check_and_cat_file '/tmp/ip_quality_ip2location_ipv6_usage_type')
#         local usage_type_11_6=$(check_and_cat_file '/tmp/ip_quality_ipapiis_ipv6_usage_type')
#         if [[ -n "$usage_type_5_6" && -n "$usage_type_11_6" ]]; then
#             if [ "$en_status" = true ]; then
#                 echo "IP_Type: $usage_type_5_6⑤  $usage_type_11_6⑪"
#             else
#                 echo "IP类型: $usage_type_5_6⑤  $usage_type_11_6⑪"
#             fi
#         elif [[ -n "$usage_type_5_6" && -z "$usage_type_11_6" ]]; then
#             if [ "$en_status" = true ]; then
#                 echo "IP_Type: $usage_type_5_6⑤"
#             else
#                 echo "IP类型: $usage_type_5_6⑤"
#             fi
#         elif [[ -n "$usage_type_11_6" && -z "$usage_type_5_6" ]]; then
#             if [ "$en_status" = true ]; then
#                 echo "IP_Type: $usage_type_11_6⑪"
#             else
#                 echo "IP类型: $usage_type_11_6⑪"
#             fi
#         fi
#     fi
#     rm -rf /tmp/ip_quality_*
# }

# check_port_25() {
#     rm -rf /tmp/ip_quality_check_port_25
#     rm -rf /tmp/ip_quality_check_email_service
#     rm -rf /tmp/ip_quality_local_port_25
#     if [ "$en_status" = true ]; then
#         echo "Port 25 Detection:" >>/tmp/ip_quality_check_port_25
#     else
#         echo "端口25检测:" >>/tmp/ip_quality_check_port_25
#     fi
#     { local_port_25 "localhost" 25; } &
#     check_email_service "163邮箱"
#     if [[ $(cat /tmp/ip_quality_check_email_service) == *"No"* ]]; then
#         wait
#         combine_result_of_ip_quality
#         return
#     else
#         check_email_service "gmail邮箱"
#         if [[ $(cat /tmp/ip_quality_check_email_service) == *"No"* ]]; then
#             wait
#             combine_result_of_ip_quality
#             return
#         else
#             { check_email_service "outlook邮箱"; } &
#             { check_email_service "yandex邮箱"; } &
#             { check_email_service "qq邮箱"; } &
#         fi
#     fi
#     wait
#     combine_result_of_ip_quality
# }

# local_port_25() {
#     local host=$1
#     local port=$2
#     rm -rf /tmp/ip_quality_local_port_25
#     if [ "$en_status" = true ]; then
#         nc -z -w5 $host $port >/dev/null 2>&1
#         if [ $? -eq 0 ]; then
#             echo "  Local: Yes" >>/tmp/ip_quality_local_port_25
#         else
#             echo "  Local: No" >>/tmp/ip_quality_local_port_25
#         fi
#     else
#         nc -z -w5 $host $port >/dev/null 2>&1
#         if [ $? -eq 0 ]; then
#             echo "  本地: Yes" >>/tmp/ip_quality_local_port_25
#         else
#             echo "  本地: No" >>/tmp/ip_quality_local_port_25
#         fi
#     fi
# }

# combine_result_of_ip_quality() {
#     check_and_cat_file /tmp/ip_quality_local_port_25 >>/tmp/ip_quality_check_port_25
#     check_and_cat_file /tmp/ip_quality_check_email_service >>/tmp/ip_quality_check_port_25
# }

# check_email_service() {
#     local service=$1
#     local host=""
#     local en_service=""
#     local port=25
#     local expected_response="220"
#     case $service in
#     "gmail邮箱")
#         host="smtp.gmail.com"
#         en_service="gmail"
#         ;;
#     "163邮箱")
#         host="smtp.163.com"
#         en_service="163"
#         ;;
#     "yandex邮箱")
#         host="smtp.yandex.com"
#         en_service="yandex"
#         ;;
#     "outlook邮箱")
#         host="smtp.office365.com"
#         en_service="outlook"
#         ;;
#     "qq邮箱")
#         host="smtp.qq.com"
#         en_service="qq"
#         ;;
#     *)
#         if [ "$en_status" = true ]; then
#             echo "Unsupported mailbox services: $service"
#         else
#             echo "不支持的邮箱服务: $service"
#         fi
#         return
#         ;;
#     esac
#     local response=$(echo -e "QUIT\r\n" | nc -w6 $host $port 2>/dev/null)
#     if [ "$en_status" = true ]; then
#         if [[ $response == *"$expected_response"* ]]; then
#             echo "  $en_service: Yes" >>/tmp/ip_quality_check_email_service
#         else
#             echo "  $en_service：No" >>/tmp/ip_quality_check_email_service
#         fi
#     else
#         if [[ $response == *"$expected_response"* ]]; then
#             echo "  $service: Yes" >>/tmp/ip_quality_check_email_service
#         else
#             echo "  $service：No" >>/tmp/ip_quality_check_email_service
#         fi
#     fi
# }

            # "$TEMP_DIR/$BESTTRACE_FILE" "${test_ip_4[a]}" -g cn 2>/dev/null | sed "s/^[ ]//g" | sed "/^[ ]/d" | sed '/ms/!d' | sed "s#.* \([0-9.]\+ ms.*\)#\1#g" >>/tmp/ip_temp
            # if [ ! -s "/tmp/ip_temp" ] || grep -q "http: 403" /tmp/ip_temp || grep -q "error" /tmp/ip_temp 2>/dev/null; then
            #     rm -rf /tmp/ip_temp
            #     RESULT=$("$TEMP_DIR/$NEXTTRACE_FILE" "${test_ip_4[a]}" --nocolor 2>/dev/null)
            #     RESULT=$(echo "$RESULT" | grep '^[0-9 ]')
            #     PART_1=$(echo "$RESULT" | grep '^[0-9]\{1,2\}[ ]\+[0-9a-f]' | awk '{$1="";$2="";print}' | sed "s@^[ ]\+@@g")
            #     PART_2=$(echo "$RESULT" | grep '\(.*ms\)\{3\}' | sed 's/.* \([0-9*].*ms\).*ms.*ms/\1/g')
            #     SPACE=' '
            #     for ((i = 1; i <= $(echo "$PART_1" | wc -l); i++)); do
            #         [ "$i" -eq 10 ] && unset SPACE
            #         p_1=$(echo "$PART_2" | sed -n "${i}p") 2>/dev/null
            #         p_2=$(echo "$PART_1" | sed -n "${i}p") 2>/dev/null
            #         echo -e "$p_1 \t$p_2" >>/tmp/ip_temp
            #     done
            # fi
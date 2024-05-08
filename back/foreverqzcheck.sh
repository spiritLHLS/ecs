#!/usr/bin/env bash
#by spiritlhl
#from https://github.com/spiritLHLS/ecs


ver="2023.04.14"
changeLog="IP质量测试(含欺诈得分)，由频道 https://t.me/vps_reviews 原创"

red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
reading(){ read -rp "$(green "$1")" "$2"; }
REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "alpine")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Alpine")
PACKAGE_UPDATE=("apt -y update" "apt -y update" "yum -y update" "yum -y update" "apk update -f")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "apk add -f")
CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

for i in "${CMD[@]}"; do
    SYS="$i" && [[ -n $SYS ]] && break
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
    if [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]]; then
        SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
    fi
done

trap _exit INT QUIT TERM

_red() { echo -e "\033[31m\033[01m$@\033[0m"; }

_green() { echo -e "\033[32m\033[01m$@\033[0m"; }

_yellow() { echo -e "\033[33m\033[01m$@\033[0m"; }

_blue() { echo -e "\033[36m\033[01m$@\033[0m"; }

_exists() {
    local cmd="$1"
    if eval type type > /dev/null 2>&1; then
        eval type "$cmd" > /dev/null 2>&1
    elif command > /dev/null 2>&1; then
        command -v "$cmd" > /dev/null 2>&1
    else
        which "$cmd" > /dev/null 2>&1
    fi
    local rt=$?
    return ${rt}
}

_exit() {
    _red "\n检测到退出操作，脚本终止！\n"
    # clean up
    rm -fr benchtest_*
    exit 1
}


checkroot(){
	[[ $EUID -ne 0 ]] && echo -e "${RED}请使用 root 用户运行本脚本！${PLAIN}" && exit 1
}

checksystem() {
	if [ -f /etc/redhat-release ]; then
	    release="centos"
	elif cat /etc/issue | grep -Eqi "debian"; then
	    release="debian"
	elif cat /etc/issue | grep -Eqi "ubuntu"; then
	    release="ubuntu"
	elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
	    release="centos"
	elif cat /proc/version | grep -Eqi "debian"; then
	    release="debian"
	elif cat /proc/version | grep -Eqi "ubuntu"; then
	    release="ubuntu"
	elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
	    release="centos"
	fi
}


checkupdate(){
	    echo "正在更新包管理源"
	    if [ "${release}" == "centos" ]; then
		    yum update > /dev/null 2>&1
		else
		    apt-get update > /dev/null 2>&1
		fi

}

checkupdate(){
	    echo "正在更新包管理源"
	    if [ "${release}" == "centos" ]; then
		    yum update > /dev/null 2>&1
			yum install dos2unix -y
		else
		    apt-get update > /dev/null 2>&1
			apt install dos2unix -y
		fi

}


checkdnsutils() {
	if  [ ! -e '/usr/bin/dnsutils' ]; then
	        echo "正在安装 dnsutils"
	            if [ "${release}" == "centos" ]; then
# 	                    yum update > /dev/null 2>&1
	                    yum -y install dnsutils > /dev/null 2>&1
	                else
# 	                    apt-get update > /dev/null 2>&1
	                    apt-get -y install dnsutils > /dev/null 2>&1
	                fi

	fi
}

checkcurl() {
	if  [ ! -e '/usr/bin/curl' ]; then
	        echo "正在安装 Curl"
	            if [ "${release}" == "centos" ]; then
# 	                yum update > /dev/null 2>&1
	                yum -y install curl > /dev/null 2>&1
	            else
# 	                apt-get update > /dev/null 2>&1
	                apt-get -y install curl > /dev/null 2>&1
	            fi
	fi
}

checkwget() {
	if  [ ! -e '/usr/bin/wget' ]; then
	        echo "正在安装 Wget"
	            if [ "${release}" == "centos" ]; then
# 	                yum update > /dev/null 2>&1
	                yum -y install wget > /dev/null 2>&1
	            else
# 	                apt-get update > /dev/null 2>&1
	                apt-get -y install wget > /dev/null 2>&1
	            fi
	fi
}

SystemInfo_GetOSRelease() {
    _yellow "checking OS"
    if [ -f "/etc/centos-release" ]; then # CentOS
        Var_OSRelease="centos"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/PRETTY_NAME/{print $3,$4}')"
        if [ "$(rpm -qa | grep -o el6 | sort -u)" = "el6" ]; then
            Var_CentOSELRepoVersion="6"
            local Var_OSReleaseVersion="$(cat /etc/centos-release | awk '{print $3}')"
        elif [ "$(rpm -qa | grep -o el7 | sort -u)" = "el7" ]; then
            Var_CentOSELRepoVersion="7"
            local Var_OSReleaseVersion="$(cat /etc/centos-release | awk '{print $4}')"
        elif [ "$(rpm -qa | grep -o el8 | sort -u)" = "el8" ]; then
            Var_CentOSELRepoVersion="8"
            local Var_OSReleaseVersion="$(cat /etc/centos-release | awk '{print $4}')"
        else
            local Var_CentOSELRepoVersion="unknown"
            local Var_OSReleaseVersion="<Unknown Release>"
        fi
        local Var_OSReleaseArch="$(arch)"
        LBench_Result_OSReleaseFullName="$Var_OSReleaseFullName $Var_OSReleaseVersion ($Var_OSReleaseArch)"
    elif [ -f "/etc/fedora-release" ]; then # Fedora
        Var_OSRelease="fedora"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/PRETTY_NAME/{print $3}')"
        local Var_OSReleaseVersion="$(cat /etc/fedora-release | awk '{print $3,$4,$5,$6,$7}')"
        local Var_OSReleaseArch="$(arch)"
        LBench_Result_OSReleaseFullName="$Var_OSReleaseFullName $Var_OSReleaseVersion ($Var_OSReleaseArch)"
    elif [ -f "/etc/redhat-release" ]; then # RedHat
        Var_OSRelease="rhel"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/PRETTY_NAME/{print $3,$4}')"
        if [ "$(rpm -qa | grep -o el6 | sort -u)" = "el6" ]; then
            Var_RedHatELRepoVersion="6"
            local Var_OSReleaseVersion="$(cat /etc/redhat-release | awk '{print $3}')"
        elif [ "$(rpm -qa | grep -o el7 | sort -u)" = "el7" ]; then
            Var_RedHatELRepoVersion="7"
            local Var_OSReleaseVersion="$(cat /etc/redhat-release | awk '{print $4}')"
        elif [ "$(rpm -qa | grep -o el8 | sort -u)" = "el8" ]; then
            Var_RedHatELRepoVersion="8"
            local Var_OSReleaseVersion="$(cat /etc/redhat-release | awk '{print $4}')"
        else
            local Var_RedHatELRepoVersion="unknown"
            local Var_OSReleaseVersion="<Unknown Release>"
        fi
        local Var_OSReleaseArch="$(arch)"
        LBench_Result_OSReleaseFullName="$Var_OSReleaseFullName $Var_OSReleaseVersion ($Var_OSReleaseArch)"
    elif [ -f "/etc/lsb-release" ]; then # Ubuntu
        Var_OSRelease="ubuntu"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/NAME/{print $3}' | head -n1)"
        local Var_OSReleaseVersion="$(cat /etc/os-release | awk -F '[= "]' '/VERSION/{print $3,$4,$5,$6,$7}' | head -n1)"
        local Var_OSReleaseArch="$(arch)"
        LBench_Result_OSReleaseFullName="$Var_OSReleaseFullName $Var_OSReleaseVersion ($Var_OSReleaseArch)"
        Var_OSReleaseVersion_Short="$(cat /etc/lsb-release | awk -F '[= "]' '/DISTRIB_RELEASE/{print $2}')"
    elif [ -f "/etc/debian_version" ]; then # Debian
        Var_OSRelease="debian"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/PRETTY_NAME/{print $3,$4}')"
        local Var_OSReleaseVersion="$(cat /etc/debian_version | awk '{print $1}')"
        local Var_OSReleaseVersionShort="$(cat /etc/debian_version | awk '{printf "%d\n",$1}')"
        if [ "${Var_OSReleaseVersionShort}" = "7" ]; then
            Var_OSReleaseVersion_Short="7"
            Var_OSReleaseVersion_Codename="wheezy"
            local Var_OSReleaseFullName="${Var_OSReleaseFullName} \"Wheezy\""
        elif [ "${Var_OSReleaseVersionShort}" = "8" ]; then
            Var_OSReleaseVersion_Short="8"
            Var_OSReleaseVersion_Codename="jessie"
            local Var_OSReleaseFullName="${Var_OSReleaseFullName} \"Jessie\""
        elif [ "${Var_OSReleaseVersionShort}" = "9" ]; then
            Var_OSReleaseVersion_Short="9"
            Var_OSReleaseVersion_Codename="stretch"
            local Var_OSReleaseFullName="${Var_OSReleaseFullName} \"Stretch\""
        elif [ "${Var_OSReleaseVersionShort}" = "10" ]; then
            Var_OSReleaseVersion_Short="10"
            Var_OSReleaseVersion_Codename="buster"
            local Var_OSReleaseFullName="${Var_OSReleaseFullName} \"Buster\""
        else
            Var_OSReleaseVersion_Short="sid"
            Var_OSReleaseVersion_Codename="sid"
            local Var_OSReleaseFullName="${Var_OSReleaseFullName} \"Sid (Testing)\""
        fi
        local Var_OSReleaseArch="$(arch)"
        LBench_Result_OSReleaseFullName="$Var_OSReleaseFullName $Var_OSReleaseVersion ($Var_OSReleaseArch)"
    elif [ -f "/etc/alpine-release" ]; then # Alpine Linux
        Var_OSRelease="alpinelinux"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/NAME/{print $3,$4}' | head -n1)"
        local Var_OSReleaseVersion="$(cat /etc/alpine-release | awk '{print $1}')"
        local Var_OSReleaseArch="$(arch)"
        LBench_Result_OSReleaseFullName="$Var_OSReleaseFullName $Var_OSReleaseVersion ($Var_OSReleaseArch)"
    elif [ -f "/etc/almalinux-release" ]; then # almalinux
        Var_OSRelease="almalinux"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/PRETTY_NAME/{print $3}')"
        local Var_OSReleaseVersion="$(cat /etc/almalinux-release | awk '{print $3,$4,$5,$6,$7}')"
        local Var_OSReleaseArch="$(arch)"
        LBench_Result_OSReleaseFullName="$Var_OSReleaseFullName $Var_OSReleaseVersion ($Var_OSReleaseArch)"
    elif [ -f "/etc/arch-release" ]; then # archlinux
        Var_OSRelease="arch"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/PRETTY_NAME/{print $3}')"
        local Var_OSReleaseArch="$(uname -m)"
        LBench_Result_OSReleaseFullName="$Var_OSReleaseFullName ($Var_OSReleaseArch)" # 滚动发行版 不存在版本号
    else
        Var_OSRelease="unknown" # 未知系统分支
        LBench_Result_OSReleaseFullName="[Error: Unknown Linux Branch !]"
    fi
}

checktar() {
    _yellow "checking tar"
	if  [ ! -e '/usr/bin/tar' ]; then
            _yellow "Installing tar"
	        ${PACKAGE_INSTALL[int]} tar 
	fi
    if [ $? -ne 0 ]; then
        apt-get -f install > /dev/null 2>&1
        ${PACKAGE_INSTALL[int]} tar > /dev/null 2>&1
    fi
}


SystemInfo_GetSystemBit() {
    _yellow "checking SystemBit"
    local sysarch="$(uname -m)"
    if [ "${sysarch}" = "unknown" ] || [ "${sysarch}" = "" ]; then
        local sysarch="$(arch)"
    fi
    # 根据架构信息设置系统位数并下载文件,其余 * 包括了 x86_64
    case "${sysarch}" in
        "i386" | "i686")
            LBench_Result_SystemBit_Short="32"
            LBench_Result_SystemBit_Full="i386"
            BESTTRACE_FILE=besttracemac
            ;;
        "armv7l" | "armv8" | "armv8l" | "aarch64")
            LBench_Result_SystemBit_Short="arm"
            LBench_Result_SystemBit_Full="arm"
            BESTTRACE_FILE=besttracearm
            BACKTRACE_FILE=backtrace-linux-arm64.tar.gz
            ;;
        *)
            LBench_Result_SystemBit_Short="64"
            LBench_Result_SystemBit_Full="amd64"
            BESTTRACE_FILE=besttrace
            BACKTRACE_FILE=backtrace-linux-amd64.tar.gz
            ;;
    esac
}


Check_JSONQuery() {
    _yellow "checking jq"
    # 判断 jq 命令是否存在
    if ! command -v jq > /dev/null; then
        # 获取系统位数
        SystemInfo_GetSystemBit
        # 获取操作系统版本
        SystemInfo_GetOSRelease
        # 根据系统位数设置下载地址
        local DownloadSrc
        if [ -z "${LBench_Result_SystemBit_Short}" ] || [ "${LBench_Result_SystemBit_Short}" != "amd64" ] || [ "${LBench_Result_SystemBit_Short}" != "i386" ]; then
            DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/JSONQuery/jq-i386.tar.gz"
        else
            DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/JSONQuery/jq-${LBench_Result_SystemBit_Short}.tar.gz"
            # local DownloadSrc="https://raw.githubusercontent.com/LemonBench/LemonBench/master/Resources/JSONQuery/jq-amd64.tar.gz"
            # local DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/jq/1.6/amd64/jq.tar.gz"
            # local DownloadSrc="https://raw.githubusercontent.com/LemonBench/LemonBench/master/Resources/JSONQuery/jq-i386.tar.gz"
            # local DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/jq/1.6/i386/jq.tar.gz"
        fi
        mkdir -p ${WorkDir}/
        echo -e "${Msg_Warning}JSON Query Module not found, Installing ..."
        echo -e "${Msg_Info}Installing Dependency ..."
        if [[ "${Var_OSRelease}" =~ ^(centos|rhel|almalinux)$ ]]; then
            yum install -y epel-release
            if [ $? -ne 0 ]; then
                if [ "$(grep -Ei 'centos|almalinux' /etc/os-release | awk -F'=' '{print $2}')" == "AlmaLinux" ]; then
                    cd /etc/yum.repos.d/
                    sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/AlmaLinux-*
                    sed -i 's|#baseurl=https://repo.almalinux.org/|baseurl=https://vault.almalinux.org/|g' /etc/yum.repos.d/AlmaLinux-*
                    yum makecache
                else
                    cd /etc/yum.repos.d/
                    sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
                    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
                    yum makecache
                fi
                if [ $? -ne 0 ]; then
                    yum -y update && yum install -y epel-release
                fi
            fi
            yum install -y tar
            yum install -y jq
        elif [[ "${Var_OSRelease}" =~ ^debian$ ]]; then
            ! apt-get update && apt-get --fix-broken install -y && apt-get update
            ! apt-get install -y jq && apt-get --fix-broken install -y && apt-get install jq -y
            if [ $? -ne 0 ]; then
                ! apt-get install -y jq && apt-get --fix-broken install -y && apt-get install jq -y --force-yes
            fi
            if [ $? -ne 0 ]; then
                ! apt-get install -y jq && apt-get --fix-broken install -y && apt-get install jq -y --allow
            fi
        elif [[ "${Var_OSRelease}" =~ ^ubuntu$ ]]; then
            ! apt-get update && apt-get --fix-broken install -y && apt-get update
            ! apt-get install -y jq && apt-get --fix-broken install -y && apt-get install jq -y
            if [ $? -ne 0 ]; then
                ! apt-get install -y jq && apt-get --fix-broken install -y && apt-get install jq -y --allow-unauthenticated
            fi
        elif [ "${Var_OSRelease}" = "fedora" ]; then
            dnf install -y jq
        elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
            apk update
            apk add jq
        elif [ "${Var_OSRelease}" = "arch" ]; then
            pacman -Sy --needed --noconfirm jq
        else
            apk update
            apk add wget unzip curl
            echo -e "${Msg_Info}Downloading Json Query Module ..."
            curl --user-agent "${UA_LemonBench}" ${DownloadSrc} -o ${WorkDir}/jq.tar.gz
            echo -e "${Msg_Info}Installing JSON Query Module ..."
            tar xvf ${WorkDir}/jq.tar.gz
            mv ${WorkDir}/jq /usr/bin/jq
            chmod +x /usr/bin/jq
            echo -e "${Msg_Info}Cleaning up ..."
            rm -rf ${WorkDir}/jq.tar.gz
        fi
    fi
    # 二次检测
    if [ ! -f "/usr/bin/jq" ]; then
        echo -e "JSON Query Moudle install Failure! Try Restart Bench or Manually install it! (/usr/bin/jq)"
        exit 1
    fi
}

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}

print_end_time() {
    end_time=$(date +%s)
    time=$(( ${end_time} - ${start_time} ))
    if [ ${time} -gt 60 ]; then
        min=$(expr $time / 60)
        sec=$(expr $time % 60)
        echo " 总共花费        : ${min} 分 ${sec} 秒"
    else
        echo " 总共花费        : ${time} 秒"
    fi
    date_time=$(date +%Y-%m-%d" "%H:%M:%S)
    echo " 时间          : $date_time"
}

head='key: '

translate_status() {
    if [[ "$1" == "false" ]]; then
        echo "No"
    elif [[ "$1" == "true" ]]; then
        echo "Yes"
    else
        echo "未知"
    fi
}

scamalytics() {
    ip="$1"
    echo "scamalytics数据库:"
    context=$(curl -s -H "$head" "https://scamalytics.com/ip/$ip")
    temp1=$(echo "$context" | grep -oP '(?<=>Fraud Score: )[^<]+')
    echo "  欺诈分数(越低越好)：$temp1"
    temp2=$(echo "$context" | grep -oP '(?<=<div).*?(?=</div>)' | tail -n 6)
    nlist=("匿名代理" "Tor出口节点" "服务器IP" "公共代理" "网络代理" "搜索引擎机器人")
    i=0
    while read -r temp3; do
        echo "  ${nlist[$i]}: ${temp3#*>}"
        i=$((i+1))
    done <<< "$(echo "$temp2" | sed 's/<[^>]*>//g' | sed 's/^[[:blank:]]*//g')"
}

abuse() {
    ip="$1"
    context2=$(curl -s -H "$head" "https://api.abuseipdb.com/api/v2/check?ipAddress=${ip}")
    if [[ "$context2" == *"abuseConfidenceScore"* ]]; then
        score=$(echo "$context2" | jq -r '.data.abuseConfidenceScore')
        echo "abuseipdb数据库-abuse得分：$score"
        echo "IP类型:"
        echo "  IP2Location数据库: $(echo "$context2" | jq -r '.data.usageType')"
    fi
}

ipapi() {
    ip=$1
    context4=$(curl -s "http://ip-api.com/json/$ip?fields=mobile,proxy,hosting")
    if [[ "$context4" == *"mobile"* ]]; then
        echo "ip-api数据库:"
        mobile=$(echo "$context4" | jq -r '.mobile')
        tp1=$(translate_status ${mobile})
        echo "  手机流量: $tp1"
        proxy=$(echo "$context4" | jq -r '.proxy')
        tp2=$(translate_status ${proxy})
        echo "  代理服务: $tp2"
        hosting=$(echo "$context4" | jq -r '.hosting')
        tp3=$(translate_status ${hosting})
        echo "  数据中心: $tp3"
    fi
}

ip234() {
  local ip="$1"
  context5=$(curl -s "http://ip234.in/fraud_check?ip=$ip")
  if [[ "$?" -ne 0 ]]; then
    return
  fi
  risk=$(echo "$context5" | jq -r '.data.score')
  echo "ip234数据库："
  echo "  欺诈分数(越低越好)：$risk"
}

google() {
  curl_result=$(curl -sL "https://www.google.com/search?q=www.spiritysdx.top" -H "User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:54.0) Gecko/20100101 Firefox/54.0")
  if echo "$curl_result" | grep -q "二叉树的博客"; then
    echo "Google搜索可行性：YES"
  else
    echo "Google搜索可行性：NO"
  fi
}

main() {
  reading "\n 请输入需要查询的 IP: " ip4
  yellow "\n 检测中，请稍等片刻。\n"
  echo "-----------------欺诈分数以及IP质量检测--本频道独创-------------------"
  echo "                   测评频道: https://t.me/vps_reviews                    "
  next
  yellow "得分仅作参考，不代表100%准确，IP类型如果不一致请手动查询多个数据库比对"
  scamalytics "$ip4"
  ip234 "$ip4"
  ipapi "$ip4"
  abuse "$ip4"
  next
}

checkupdate
checkroot
checkwget
checkcurl
checksystem
checktar
SystemInfo_GetOSRelease
SystemInfo_GetSystemBit
Check_JSONQuery
! _exists "wget" && _red "Error: wget command not found.\n" && exit 1
! _exists "free" && _red "Error: free command not found.\n" && exit 1
clear
while [ "1" = "1" ]
  do
    main
  done

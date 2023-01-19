#!/usr/bin/env bash

ver="2022.12.11"
changeLog="路由相关工具合集，由频道 https://t.me/vps_reviews 整理修改"

test_area=("广州电信" "广州联通" "广州移动")
test_ip=("58.60.188.222" "210.21.196.6" "120.196.165.2")
TEMP_FILE='ip.test'
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN="\033[0m"

red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}

REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "fedora")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Fedora")
PACKAGE_UPDATE=("apt-get update" "apt-get update" "yum -y update" "yum -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "yum -y install")
PACKAGE_REMOVE=("apt -y remove" "apt -y remove" "yum -y remove" "yum -y remove" "yum -y remove")
PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove" "yum -y autoremove" "yum -y autoremove")

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



checkpython() {
    ! type -p python3 >/dev/null 2>&1 && yellow "\n Install python3\n" && ${PACKAGE_INSTALL[int]} python3
    ! type -p pip3 install requests >/dev/null 2>&1 && yellow "\n Install pip3\n" && ${PACKAGE_INSTALL[int]} python3-pip
    pip3 install requests
    sleep 0.5
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

fscarmen_route_script(){
    echo -e "------------------回程路由--感谢fscarmen开源及PR----------------------"
    yellow "以下测试的带宽类型可能有误，商宽可能被判断为家宽，仅作参考使用"
    rm -f $TEMP_FILE
    IP_4=$(curl -s4m5 https://api.ipify.org) &&
    WAN_4=$(expr "$IP_4" : '.*ip\":\"\([^"]*\).*') &&
    ASNORG_4=$(expr "$IP_4" : '.*asn_org\":\"\([^"]*\).*') &&
    PE_4=$(curl -sm5 ping.pe/$WAN_4) &&
    COOKIE_4=$(echo $PE_4 | sed "s/.*document.cookie=\"\([^;]\{1,\}\).*/\1/g") &&
    TYPE_4=$(curl -sm5 --header "cookie: $COOKIE_4" ping.pe/$WAN_4 | grep "id='page-div'" | sed "s/.*\[\(.*\)\].*/\1/g" | sed "s/.*orange'>\([^<]\{1,\}\).*/\1/g" | sed "s/hosting/数据中心/g;s/residential/家庭宽带/g;s/cellular/蜂窝网络/g;s/business/商业带宽/g;s#</b>##g") &&
    _blue " IPv4 宽带类型: $TYPE_4\t ASN: $ASNORG_4" >> $TEMP_FILE
    IP_6=$(curl -s6m5 https://api.ipify.org) &&
    WAN_6=$(expr "$IP_6" : '.*ip\":\"\([^"]*\).*') &&
    ASNORG_6=$(expr "$IP_6" : '.*asn_org\":\"\([^"]*\).*') &&
    PE_6=$(curl -sm5 ping6.ping.pe/$WAN_6) &&
    COOKIE_6=$(echo $PE_6 | sed "s/.*document.cookie=\"\([^;]\{1,\}\).*/\1/g") &&
    TYPE_6=$(curl -sm5 --header "cookie: $COOKIE_6" ping6.ping.pe/$WAN_6 | grep "id='page-div'" | sed "s/.*\[\(.*\)\].*/\1/g" | sed "s/.*orange'>\([^<]\{1,\}\).*/\1/g" | sed "s/hosting/数据中心/g;s/residential/家庭宽带/g;s/cellular/蜂窝网络/g;s/business/商业带宽/g;s#</b>##g") &&
    _blue " IPv6 宽带类型: $TYPE_6\t ASN: $ASNORG_6" >> $TEMP_FILE
    local ARCHITECTURE="$(arch)"
      case $ARCHITECTURE in
        x86_64 )  local FILE=besttrace;;
        aarch64 ) local FILE=besttracearm;;
        i386 )    local FILE=besttracemac;;
        * ) red " 只支持 AMD64、ARM64、Mac 使用，问题反馈:[https://github.com/fscarmen/tools/issues] " && return;;
      esac

    [[ ! -e $FILE ]] && wget -q https://github.com/fscarmen/tools/raw/main/besttrace/$FILE >/dev/null 2>&1
    chmod 777 $FILE >/dev/null 2>&1
    _green "依次测试电信，联通，移动经过的地区及线路，核心程序来由: ipip.net ，请知悉!" >> $TEMP_FILE
    for ((a=0;a<${#test_area_s[@]};a++)); do
    _yellow "${test_area_s[a]} ${test_ip_g[a]}" >> $TEMP_FILE
    ./"$FILE" "${test_ip_s[a]}" -g cn | sed "s/^[ ]//g" | sed "/^[ ]/d" | sed '/ms/!d' | sed "s#.* \([0-9.]\+ ms.*\)#\1#g" >> $TEMP_FILE
    done
    cat $TEMP_FILE
    rm -f $TEMP_FILE
}


print_intro() {
    echo "--------------------- A Bench Script By spiritlhl --------------------"
    echo "                   测评频道: https://t.me/vps_reviews                    "
    echo "版本：$ver"
    echo "更新日志：$changeLog"
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

checkupdate
checkroot
checkwget
checksystem
checkpython
checkcurl
if [ "${release}" == "centos" ]; then
#     yum update > /dev/null 2>&1
    yum -y install python3.7 > /dev/null 2>&1
else
#     apt-get update > /dev/null 2>&1
    apt-get -y install python3.7 > /dev/null 2>&1
fi
export PYTHONIOENCODING=utf-8
! _exists "wget" && _red "Error: wget command not found.\n" && exit 1
! _exists "free" && _red "Error: free command not found.\n" && exit 1
clear
start_time=$(date +%s)
print_intro
echo -e "-----------------三网回程--感谢zhanghanyun/backtrace开源--------------"
rm -f $TEMP_FILE2
curl https://raw.githubusercontent.com/zhanghanyun/backtrace/main/install.sh -sSf | sh
fscarmen_route_script
echo -e "-----------------测端口开通--感谢fscarmen开源及PR----------------------"
if [ -n "$IP_4" ]; then
  PORT4=(22 80 443 8080)
  for i in ${PORT4[@]}; do
    bash <(curl -s4SL https://raw.githubusercontent.com/fscarmen/tools/main/check_port.sh) $WAN_4:$i > PORT4_$i
    sed -i "1,5 d; s/状态/$i/g" PORT4_$i
    cut -f 1 PORT4_$i > PORT4_${i}_1
    cut -f 2,3  PORT4_$i > PORT4_${i}_2
  done
  paste PORT4_${PORT4[0]}_1 PORT4_${PORT4[1]}_1 PORT4_${PORT4[2]}_1 PORT4_${PORT4[3]} > PORT4_RESULT
  _blue " IPv4 端口开通情况 "
  cat PORT4_RESULT
  rm -f PORT4_*
else _red " VPS 没有 IPv4 "
fi
next
print_end_time
next
rm -rf wget-log*
rm -rf ipip.py*
rm -rf return.sh*
rm -rf besttrace
rm -rf $TEMP_FILE

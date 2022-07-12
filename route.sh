#!/usr/bin/env bash

ver="2022.07.12"
changeLog="路由相关工具合集，由频道 https://t.me/vps_reviews 整理修改"



test_area=("广州电信" "广州联通" "广州移动")
test_ip=("58.60.188.222" "210.21.196.6" "120.196.165.2")
TEMP_FILE='ip.test'


trap _exit INT QUIT TERM

_red() { echo -e "\033[31m\033[01m$@\033[0m"; }

_green() { echo -e "\033[32m\033[01m$@\033[0m"; }

_yellow() { echo -e "\033[33m\033[01m$@\033[0m"; }

_blue() { echo -e "\033[36m\033[01m$@\033[0m"; }


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
	if  [ ! -e '/usr/bin/python' ]; then
	        echo "正在安装 Python"
	            if [ "${release}" == "centos" ]; then
# 	            	    yum update > /dev/null 2>&1
	                    yum -y install python > /dev/null 2>&1
	                else
# 	                    apt-get update > /dev/null 2>&1
	                    apt-get -y install python > /dev/null 2>&1
	                fi

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
echo -e "------------------回程路由--感谢fscarmen开源及PR----------------------"
rm -f $TEMP_FILE
IP_4=$(curl -s4m5 https:/ip.gs/json) &&
WAN_4=$(expr "$IP_4" : '.*ip\":\"\([^"]*\).*') &&
ASNORG_4=$(expr "$IP_4" : '.*asn_org\":\"\([^"]*\).*') &&
PE_4=$(curl -sm5 ping.pe/$WAN_4) &&
COOKIE_4=$(echo $PE_4 | sed "s/.*document.cookie=\"\([^;]\{1,\}\).*/\1/g") &&
TYPE_4=$(curl -sm5 --header "cookie: $COOKIE_4" ping.pe/$WAN_4 | grep "id='page-div'" | sed "s/.*\[\(.*\)\].*/\1/g" | sed "s/.*orange'>\([^<]\{1,\}\).*/\1/g" | sed "s/hosting/数据中心/g;s/residential/家庭宽带/g") &&
_blue " IPv4 宽带类型: $TYPE_4\t ASN: $ASNORG_4" >> $TEMP_FILE
IP_6=$(curl -s6m5 https:/ip.gs/json) &&
WAN_6=$(expr "$IP_6" : '.*ip\":\"\([^"]*\).*') &&
ASNORG_6=$(expr "$IP_6" : '.*asn_org\":\"\([^"]*\).*') &&
PE_6=$(curl -sm5 ping6.ping.pe/$WAN_6) &&
COOKIE_6=$(echo $PE_6 | sed "s/.*document.cookie=\"\([^;]\{1,\}\).*/\1/g") &&
TYPE_6=$(curl -sm5 --header "cookie: $COOKIE_6" ping6.ping.pe/$WAN_6 | grep "id='page-div'" | sed "s/.*\[\(.*\)\].*/\1/g" | sed "s/.*orange'>\([^<]\{1,\}\).*/\1/g" | sed "s/hosting/数据中心/g;s/residential/家庭宽带/g") &&
_blue " IPv6 宽带类型: $TYPE_6\t ASN: $ASNORG_6" >> $TEMP_FILE
[[ ! -e return.sh ]] && curl -qO https://raw.githubusercontent.com/spiritLHLS/ecs/main/return.sh > /dev/null 2>&1
chmod +x return.sh >/dev/null 2>&1
_green "依次测试电信，联通，移动经过的地区及线路，核心程序来由: ipip.net ，请知悉!" >> $TEMP_FILE
for ((a=0;a<${#test_area[@]};a++)); do
  _yellow "${test_area[a]} ${test_ip[a]}" >> $TEMP_FILE
  ./return.sh ${test_ip[a]} >> $TEMP_FILE
done
cat $TEMP_FILE
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
rm -rf besttrace
rm -rf $TEMP_FILE

#!/usr/bin/env bash

ver="2022.12.13"
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
    rm -rf wget-log*
    rm -rf gdlog*
    rm -rf foreverqzcheck.py*
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

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}

checkpython() {
    ! type -p python3 >/dev/null 2>&1 && yellow "\n Install python3\n" && ${PACKAGE_INSTALL[int]} python3
    ! type -p pip3 install requests >/dev/null 2>&1 && yellow "\n Install pip3\n" && ${PACKAGE_INSTALL[int]} python3-pip
    pip3 install requests
    pip3 install magic_google
    sleep 0.5
}

main() {
  reading "\n 请输入需要查询的 IP: " ip
  yellow "\n 检测中，请稍等片刻。\n"
  clear
  echo "------------------欺诈分数以及IP质量检测--本频道独创--------------------"
  echo "                   测评频道: https://t.me/vps_reviews                    "
  yellow "得分仅作参考，不代表100%准确，IP类型如果不一致请手动查询多个数据库比对"
  python3 foreverqzcheck.py "$ip"
  next
  rm -rf wget-log*
  rm -rf gdlog*
}

checkupdate
checkroot
checkwget
checkcurl
checksystem
checkpython
curl -L https://raw.githubusercontent.com/spiritLHLS/ecs/main/foreverqzcheck.py -o foreverqzcheck.py
dos2unix qzcheck.py 
if [ "${release}" == "centos" ]; then
    yum -y install python3.7 > /dev/null 2>&1
else
    apt-get -y install python3.7 > /dev/null 2>&1
fi
export PYTHONIOENCODING=utf-8
! _exists "wget" && _red "Error: wget command not found.\n" && exit 1
! _exists "free" && _red "Error: free command not found.\n" && exit 1
sleep 0.5

while [ "1" = "1" ]
  do
    main
  done

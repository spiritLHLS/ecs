#!/usr/bin/env bash

ver="2022.08.14"
changeLog="融合怪八代目(集合百家之长)(专为测评频道小鸡而生)"

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

# Trap终止信号捕获
trap "Global_TrapSigExit_Sig1" 1
trap "Global_TrapSigExit_Sig2" 2
trap "Global_TrapSigExit_Sig3" 3
trap "Global_TrapSigExit_Sig15" 15

# Trap终止信号1 - 处理
Global_TrapSigExit_Sig1() {
    echo -e "\n\n${Msg_Error}Caught Signal SIGHUP, Exiting ...\n"
    Global_TrapSigExit_Action
    rm_script
    exit 1
}

# Trap终止信号2 - 处理 (Ctrl+C)
Global_TrapSigExit_Sig2() {
    echo -e "\n\n${Msg_Error}Caught Signal SIGINT (or Ctrl+C), Exiting ...\n"
    Global_TrapSigExit_Action
    rm_script
    exit 1
}

# Trap终止信号3 - 处理
Global_TrapSigExit_Sig3() {
    echo -e "\n\n${Msg_Error}Caught Signal SIGQUIT, Exiting ...\n"
    Global_TrapSigExit_Action
    rm_script
    exit 1
}

# Trap终止信号15 - 处理 (进程被杀)
Global_TrapSigExit_Sig15() {
    echo -e "\n\n${Msg_Error}Caught Signal SIGTERM, Exiting ...\n"
    Global_TrapSigExit_Action
    rm_script
    exit 1
}

# 新版JSON解析
PharseJSON() {
    # 使用方法: PharseJSON "要解析的原JSON文本" "要解析的键值"
    # Example: PharseJSON ""Value":"123456"" "Value" [返回结果: 123456]
    echo -n $1 | jq -r .$2
}

# 程序启动动作
Global_StartupInit_Action() {
    Global_Startup_Header
    Function_CheckTracemode
    # 清理残留, 为新一次的运行做好准备
    echo -e "${Msg_Info}Initializing Running Enviorment, Please wait ..."
    rm -rf ${WorkDir}
    rm -rf /.tmp_LBench/
    mkdir ${WorkDir}/
    echo -e "${Msg_Info}Checking Dependency ..."
    Check_Virtwhat
    Check_JSONQuery
    Check_Speedtest
    Check_BestTrace
    Check_Spoofer
    Check_SysBench
    echo -e "${Msg_Info}Starting Test ...\n\n"
    clear
}

# 捕获异常信号后的动作
Global_TrapSigExit_Action() {
    rm -rf ${WorkDir}
    rm -rf /.tmp_LBench/
}

Global_Exit_Action() {
    rm -rf ${WorkDir}/
}

Function_BenchFinish() {
    # 清理临时文件
    sleep 1
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
		${PACKAGE_UPDATE[int]} > /dev/null 2>&1
        ${PACKAGE_INSTALL[int]} dmidecode > /dev/null 2>&1

}

checkpython() {
    ! type -p python3 >/dev/null 2>&1 && yellow "\n Install python3\n" && ${PACKAGE_INSTALL[int]} python3
    ! type -p pip3 install requests >/dev/null 2>&1 && yellow "\n Install pip3\n" && ${PACKAGE_INSTALL[int]} python3-pip
    pip3 install requests
    sleep 0.5
}


checkmagic(){
    pip3 install magic_google
    sleep 0.4
}


checkdnsutils() {
	if  [ ! -e '/usr/bin/dnsutils' ]; then
	        echo "正在安装 dnsutils"
	            if [ "${release}" == "centos" ]; then
	                    yum -y install dnsutils > /dev/null 2>&1
                        yum -y install bind-utils > /dev/null 2>&1
	                else
	                    ${PACKAGE_INSTALL[int]} dnsutils > /dev/null 2>&1
	                fi

	fi
}

checkcurl() {
	if  [ ! -e '/usr/bin/curl' ]; then
	        echo "正在安装 Curl"
	        ${PACKAGE_INSTALL[int]} curl > /dev/null 2>&1
	fi
}

checkwget() {
	if  [ ! -e '/usr/bin/wget' ]; then
	        echo "正在安装 Wget"
	        ${PACKAGE_INSTALL[int]} wget > /dev/null 2>&1
	fi
}

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
    rm -fr speedtest.tgz speedtest-cli benchtest_*
    exit 1
}

get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print $0}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}

checkssh() {
	for i in "${CMD[@]}"; do
		SYS="$i" && [[ -n $SYS ]] && break
	done

	for ((int=0; int<${#REGEX[@]}; int++)); do
		[[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
	done
	echo "开启22端口中，以便于测试IP是否被阻断"
	sshport=22
	[[ ! -f /etc/ssh/sshd_config ]] && sudo ${PACKAGE_UPDATE[int]} && sudo ${PACKAGE_INSTALL[int]} openssh-server
	[[ -z $(type -P curl) ]] && sudo ${PACKAGE_UPDATE[int]} && sudo ${PACKAGE_INSTALL[int]} curl
	sudo sed -i "s/^#\?Port.*/Port $sshport/g" /etc/ssh/sshd_config;
	sudo service ssh restart >/dev/null 2>&1 # 某些VPS系统的ssh服务名称为ssh，以防无法重启服务导致无法立刻使用密码登录
	sudo service sshd restart >/dev/null 2>&1
	echo "开启22端口完毕"
}

checkspeedtest() {
	if  [ ! -e './speedtest-cli/speedtest' ]; then
		echo "正在安装 Speedtest-cli"
                arch=$(uname -m)
                if [ "${arch}" == "i686" ]; then
                    arch="i386"
                fi
		wget --no-check-certificate -qO speedtest.tgz https://cdn.jsdelivr.net/gh/oooldking/script@1.1.7/speedtest_cli/ookla-speedtest-1.0.0-${arch}-linux.tgz > /dev/null 2>&1
		# wget --no-check-certificate -qO speedtest.tgz https://bintray.com/ookla/download/download_file?file_path=ookla-speedtest-1.0.0-${arch}-linux.tgz > /dev/null 2>&1
	fi
	mkdir -p speedtest-cli && tar zxvf speedtest.tgz -C ./speedtest-cli/ > /dev/null 2>&1 && chmod a+rx ./speedtest-cli/speedtest
}

install_speedtest() {
    if [ ! -e "./speedtest-cli/speedtest" ]; then
        sys_bit=""
        local sysarch="$(uname -m)"
        if [ "${sysarch}" = "unknown" ] || [ "${sysarch}" = "" ]; then
            local sysarch="$(arch)"
        fi
        if [ "${sysarch}" = "x86_64" ]; then
            sys_bit="x86_64"
        fi
        if [ "${sysarch}" = "i386" ] || [ "${sysarch}" = "i686" ]; then
            sys_bit="i386"
        fi
        if [ "${sysarch}" = "armv8" ] || [ "${sysarch}" = "armv8l" ] || [ "${sysarch}" = "aarch64" ] || [ "${sysarch}" = "arm64" ]; then
            sys_bit="aarch64"
        fi
        if [ "${sysarch}" = "armv7" ] || [ "${sysarch}" = "armv7l" ]; then
            sys_bit="armhf"
        fi
        if [ "${sysarch}" = "armv6" ]; then
            sys_bit="armel"
        fi
        [ -z "${sys_bit}" ] && _red "Error: Unsupported system architecture (${sysarch}).\n" && exit 1
        url1="https://install.speedtest.net/app/cli/ookla-speedtest-1.1.1-linux-${sys_bit}.tgz"
        url2="https://dl.lamp.sh/files/ookla-speedtest-1.1.1-linux-${sys_bit}.tgz"
        wget --no-check-certificate -q -T10 -O speedtest.tgz ${url1}
        if [ $? -ne 0 ]; then
            wget --no-check-certificate -q -T10 -O speedtest.tgz ${url2}
            [ $? -ne 0 ] && _red "Error: Failed to download speedtest-cli.\n" && exit 1
        fi
        mkdir -p speedtest-cli && tar zxf speedtest.tgz -C ./speedtest-cli && chmod +x ./speedtest-cli/speedtest
        rm -f speedtest.tgz
    fi
}

SystemInfo_GetOSRelease() {
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
    elif [ -f "/etc/fedora-release" ]; then # Fedora
        Var_OSRelease="fedora"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/PRETTY_NAME/{print $3}')"
        local Var_OSReleaseVersion="$(cat /etc/fedora-release | awk '{print $3,$4,$5,$6,$7}')"
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
    else
        Var_OSRelease="unknown" # 未知系统分支
        LBench_Result_OSReleaseFullName="[Error: Unknown Linux Branch !]"
    fi
}

function Global_UnlockTest() {
    echo "============[ Multination ]============"
    MediaUnlockTest_Dazn ${1}
    MediaUnlockTest_HotStar ${1}
    MediaUnlockTest_DisneyPlus ${1}
    MediaUnlockTest_Netflix ${1}
    MediaUnlockTest_YouTube_Premium ${1}
    MediaUnlockTest_PrimeVideo_Region ${1}
    MediaUnlockTest_TVBAnywhere ${1}
    MediaUnlockTest_iQYI_Region ${1}
    MediaUnlockTest_Viu.com ${1}
    MediaUnlockTest_YouTube_CDN ${1}
    MediaUnlockTest_NetflixCDN ${1}
    MediaUnlockTest_Spotify ${1}
    GameTest_Steam ${1}
    echo "======================================="
}


# =============== 检查 SysBench 组件 ===============
Check_SysBench() {
    if [ ! -f "/usr/bin/sysbench" ] && [ ! -f "/usr/local/bin/sysbench" ]; then
        SystemInfo_GetOSRelease
        SystemInfo_GetSystemBit
        if [ "${Var_OSRelease}" = "centos" ] || [ "${Var_OSRelease}" = "rhel" ]; then
            echo -e "${Msg_Warning}Sysbench Module not found, installing ..."
            yum -y install epel-release
            yum -y install sysbench
        elif [ "${Var_OSRelease}" = "ubuntu" ]; then
            echo -e "${Msg_Warning}Sysbench Module not found, installing ..."
            apt-get install -y sysbench
        elif [ "${Var_OSRelease}" = "debian" ]; then
            echo -e "${Msg_Warning}Sysbench Module not found, installing ..."
            local mirrorbase="https://raindrop.ilemonrain.com/LemonBench"
            local componentname="Sysbench"
            local version="1.0.19-1"
            local arch="debian"
            local codename="${Var_OSReleaseVersion_Codename}"
            local bit="${LBench_Result_SystemBit_Full}"
            local filenamebase="sysbench"
            local filename="${filenamebase}_${version}_${bit}.deb"
            local downurl="${mirrorbase}/include/${componentname}/${version}/${arch}/${codename}/${filename}"
            mkdir -p ${WorkDir}/download/
            pushd ${WorkDir}/download/ >/dev/null
            wget -U "${UA_LemonBench}" -O ${filenamebase}_${version}_${bit}.deb ${downurl}
            dpkg -i ./${filename}
            apt-get install -f -y
            popd
            if [ ! -f "/usr/bin/sysbench" ] && [ ! -f "/usr/local/bin/sysbench" ]; then
                echo -e "${Msg_Warning}Sysbench Module Install Failed!"
            fi
        elif [ "${Var_OSRelease}" = "fedora" ]; then
            echo -e "${Msg_Warning}Sysbench Module not found, installing ..."
            dnf -y install sysbench
        elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
            echo -e "${Msg_Warning}Sysbench Module not found, installing ..."
            echo -e "${Msg_Warning}SysBench Current not support Alpine Linux, Skipping..."
            Var_Skip_SysBench="1"
        fi
    fi
    # 垂死挣扎 (尝试编译安装)
    if [ ! -f "/usr/bin/sysbench" ] && [ ! -f "/usr/local/bin/sysbench" ]; then
        echo -e "${Msg_Warning}Sysbench Module install Failure, trying compile modules ..."
        Check_Sysbench_InstantBuild >/dev/null 2>&1
    fi
    # 最终检测
    if [ ! -f "/usr/bin/sysbench" ] && [ ! -f "/usr/local/bin/sysbench" ]; then
        echo -e "${Msg_Error}SysBench Moudle install Failure! Try Restart Bench or Manually install it! (/usr/bin/sysbench)"
        # exit 1
    fi
}

Check_Sysbench_InstantBuild() {
    SystemInfo_GetOSRelease
    SystemInfo_GetCPUInfo
    if [ "${Var_OSRelease}" = "centos" ] || [ "${Var_OSRelease}" = "rhel" ]; then
        echo -e "${Msg_Info}Release Detected: ${Var_OSRelease}"
        echo -e "${Msg_Info}Preparing compile enviorment ..."
        yum install -y epel-release >/dev/null 2>&1
        yum install -y wget curl make gcc gcc-c++ make automake libtool pkgconfig libaio-devel >/dev/null 2>&1
        echo -e "${Msg_Info}Release Detected: ${Var_OSRelease}"
        echo -e "${Msg_Info}Downloading Source code (Version 1.0.20)..."
        mkdir -p /tmp/_LBench/src/
        wget -U "${UA_LemonBench}" -O /tmp/_LBench/src/sysbench.zip https://github.com/akopytov/sysbench/archive/1.0.20.zip >/dev/null 2>&1
        echo -e "${Msg_Info}Compiling Sysbench Module ..."
        cd /tmp/_LBench/src/
        unzip sysbench.zip && cd sysbench-1.0.20 >/dev/null 2>&1
        ./autogen.sh && ./configure --without-mysql && make -j8 && make install
        echo -e "${Msg_Info}Cleaning up ..."
        cd /tmp && rm -rf /tmp/_LBench/src/sysbench*  >/dev/null 2>&1
    elif [ "${Var_OSRelease}" = "ubuntu" ] || [ "${Var_OSRelease}" = "debian" ]; then
        echo -e "${Msg_Info}Release Detected: ${Var_OSRelease}"
        echo -e "${Msg_Info}Preparing compile enviorment ..."
        apt -y install --no-install-recommends curl wget make automake libtool pkg-config libaio-dev unzip >/dev/null 2>&1
        echo -e "${Msg_Info}Downloading Source code (Version 1.0.20)..."
        mkdir -p /tmp/_LBench/src/
        wget -U "${UA_LemonBench}" -O /tmp/_LBench/src/sysbench.zip https://github.com/akopytov/sysbench/archive/1.0.20.zip >/dev/null 2>&1
        echo -e "${Msg_Info}Compiling Sysbench Module ..."
        cd /tmp/_LBench/src/
        unzip sysbench.zip && cd sysbench-1.0.20 >/dev/null 2>&1
        ./autogen.sh && ./configure --without-mysql && make -j8 && make install
        echo -e "${Msg_Info}Cleaning up ..."
        cd /tmp && rm -rf /tmp/_LBench/src/sysbench*  >/dev/null 2>&1
    elif [ "${Var_OSRelease}" = "fedora" ]; then
        echo -e "${Msg_Info}Release Detected: ${Var_OSRelease}"
        echo -e "${Msg_Info}Preparing compile enviorment ..."
        dnf install -y wget curl gcc gcc-c++ make automake libtool pkgconfig libaio-devel
        echo -e "${Msg_Info}Downloading Source code (Version 1.0.20)..."
        mkdir -p /tmp/_LBench/src/
        wget -U "${UA_LemonBench}" -O /tmp/_LBench/src/sysbench.zip https://github.com/akopytov/sysbench/archive/1.0.20.zip >/dev/null 2>&1
        echo -e "${Msg_Info}Compiling Sysbench Module ..."
        cd /tmp/_LBench/src/
        unzip sysbench.zip && cd sysbench-1.0.20 >/dev/null 2>&1
        ./autogen.sh && ./configure --without-mysql && make -j8 && make install
        echo -e "${Msg_Info}Cleaning up ..."
        cd /tmp && rm -rf /tmp/_LBench/src/sysbench*  >/dev/null 2>&1
    else
        echo -e "${Msg_Error}Cannot compile on current enviorment！ (Only Support CentOS/Debian/Ubuntu/Fedora) "
    fi
}

# =============== SysBench - CPU性能 部分 ===============
Run_SysBench_CPU() {
    # 调用方式: Run_SysBench_CPU "线程数" "测试时长(s)" "测试遍数" "说明"
    # 变量初始化
    mkdir -p ${WorkDir}/SysBench/CPU/ >/dev/null 2>&1
    maxtestcount="$3"
    local count="1"
    local TestScore="0"
    local TotalScore="0"
    # 运行测试
    while [ $count -le $maxtestcount ]; do
        echo -e "\r ${Font_Yellow}$4: ${Font_Suffix}\t\t$count/$maxtestcount \c"
        local TestResult="$(sysbench --test=cpu --num-threads=$1 --cpu-max-prime=10000 --max-requests=1000000 --max-time=$2 run 2>&1)"
        local TestScore="$(echo ${TestResult} | grep -oE "events per second: [0-9]+" | grep -oE "[0-9]+")"
        local TotalScore="$(echo "${TotalScore} ${TestScore}" | awk '{printf "%d",$1+$2}')"
        let count=count+1
        local TestResult=""
        local TestScore="0"
    done
    local ResultScore="$(echo "${TotalScore} ${maxtestcount}" | awk '{printf "%d",$1/$2}')"
    if [ "$1" = "1" ]; then
        echo -e "\r ${Font_Yellow}$4: ${Font_Suffix}\t\t${Font_SkyBlue}${ResultScore}${Font_Suffix} ${Font_Yellow}Scores${Font_Suffix}"
        echo -e " $4:\t\t\t${ResultScore} Scores" >>${WorkDir}/SysBench/CPU/result.txt
    elif [ "$1" -ge "2" ]; then
        echo -e "\r ${Font_Yellow}$4: ${Font_Suffix}\t\t${Font_SkyBlue}${ResultScore}${Font_Suffix} ${Font_Yellow}Scores${Font_Suffix}"
        echo -e " $4:\t\t${ResultScore} Scores" >>${WorkDir}/SysBench/CPU/result.txt
    fi
}

Function_SysBench_CPU_Fast() {
    mkdir -p ${WorkDir}/SysBench/CPU/ >/dev/null 2>&1
    echo -e " ${Font_Yellow}-> CPU 测试中 (Fast Mode, 1-Pass @ 5sec)${Font_Suffix}"
    echo -e " -> CPU 测试中 (Fast Mode, 1-Pass @ 5sec)\n" >>${WorkDir}/SysBench/CPU/result.txt
    Run_SysBench_CPU "1" "5" "1" "1 线程测试(1核)得分"
    if [ "${LBench_Result_CPUThreadNumber}" -ge "2" ]; then
        Run_SysBench_CPU "${LBench_Result_CPUThreadNumber}" "5" "1" "${LBench_Result_CPUThreadNumber} 线程测试(多核)得分"
    elif [ "${LBench_Result_CPUProcessorNumber}" -ge "2" ]; then
        Run_SysBench_CPU "${LBench_Result_CPUProcessorNumber}" "5" "1" "${LBench_Result_CPUProcessorNumber} 线程测试(多核)得分"
    fi
    # 完成FLAG
    LBench_Flag_FinishSysBenchCPUFast="1"
}


# =============== SystemInfo模块 部分 ===============
SystemInfo_GetHostname() {
    LBench_Result_Hostname="$(hostname)"
}



SystemInfo_GetCPUInfo() {
    mkdir -p ${WorkDir}/data >/dev/null 2>&1
    cat /proc/cpuinfo >${WorkDir}/data/cpuinfo
    local ReadCPUInfo="cat ${WorkDir}/data/cpuinfo"
    LBench_Result_CPUModelName="$($ReadCPUInfo | awk -F ': ' '/model name/{print $2}' | sort -u)"
    local CPUFreqCount="$($ReadCPUInfo | awk -F ': ' '/cpu MHz/{print $2}' | sort -run | wc -l)"
    if [ "${CPUFreqCount}" -ge "2" ]; then
        local CPUFreqArray="$(cat /proc/cpuinfo | awk -F ': ' '/cpu MHz/{print $2}' | sort -run)"
        local CPUFreq_Min="$(echo "$CPUFreqArray" | grep -oE '[0-9]+.[0-9]{3}' | awk 'BEGIN {min = 2147483647} {if ($1+0 < min+0) min=$1} END {print min}')"
        local CPUFreq_Max="$(echo "$CPUFreqArray" | grep -oE '[0-9]+.[0-9]{3}' | awk 'BEGIN {max = 0} {if ($1+0 > max+0) max=$1} END {print max}')"
        LBench_Result_CPUFreqMinGHz="$(echo $CPUFreq_Min | awk '{printf "%.2f\n",$1/1000}')"
        LBench_Result_CPUFreqMaxGHz="$(echo $CPUFreq_Max | awk '{printf "%.2f\n",$1/1000}')"
        Flag_DymanicCPUFreqDetected="1"
    else
        LBench_Result_CPUFreqMHz="$($ReadCPUInfo | awk -F ': ' '/cpu MHz/{print $2}' | sort -u)"
        LBench_Result_CPUFreqGHz="$(echo $LBench_Result_CPUFreqMHz | awk '{printf "%.2f\n",$1/1000}')"
        Flag_DymanicCPUFreqDetected="0"
    fi
    LBench_Result_CPUCacheSize="$($ReadCPUInfo | awk -F ': ' '/cache size/{print $2}' | sort -u)"
    LBench_Result_CPUPhysicalNumber="$($ReadCPUInfo | awk -F ': ' '/physical id/{print $2}' | sort -u | wc -l)"
    LBench_Result_CPUCoreNumber="$($ReadCPUInfo | awk -F ': ' '/cpu cores/{print $2}' | sort -u)"
    LBench_Result_CPUThreadNumber="$($ReadCPUInfo | awk -F ': ' '/cores/{print $2}' | wc -l)"
    LBench_Result_CPUProcessorNumber="$($ReadCPUInfo | awk -F ': ' '/processor/{print $2}' | wc -l)"
    LBench_Result_CPUSiblingsNumber="$($ReadCPUInfo | awk -F ': ' '/siblings/{print $2}' | sort -u)"
    LBench_Result_CPUTotalCoreNumber="$($ReadCPUInfo | awk -F ': ' '/physical id/&&/0/{print $2}' | wc -l)"
    
    # 虚拟化能力检测
    SystemInfo_GetVirtType
    if [ "${Var_VirtType}" = "dedicated" ] || [ "${Var_VirtType}" = "wsl" ]; then
        LBench_Result_CPUIsPhysical="1"
        local VirtCheck="$(cat /proc/cpuinfo | grep -oE 'vmx|svm' | uniq)"
        if [ "${VirtCheck}" != "" ]; then
            LBench_Result_CPUVirtualization="1"
            local VirtualizationType="$(lscpu | awk /Virtualization:/'{print $2}')"
            LBench_Result_CPUVirtualizationType="${VirtualizationType}"
        else
            LBench_Result_CPUVirtualization="0"
        fi
    elif [ "${Var_VirtType}" = "kvm" ] || [ "${Var_VirtType}" = "hyperv" ] || [ "${Var_VirtType}" = "microsoft" ] || [ "${Var_VirtType}" = "vmware" ]; then
        LBench_Result_CPUIsPhysical="0"
        local VirtCheck="$(cat /proc/cpuinfo | grep -oE 'vmx|svm' | uniq)"
        if [ "${VirtCheck}" = "vmx" ] || [ "${VirtCheck}" = "svm" ]; then
            LBench_Result_CPUVirtualization="2"
            local VirtualizationType="$(lscpu | awk /Virtualization:/'{print $2}')"
            LBench_Result_CPUVirtualizationType="${VirtualizationType}"
        else
            LBench_Result_CPUVirtualization="0"
        fi        
    else
        LBench_Result_CPUIsPhysical="0"
    fi
}

SystemInfo_GetCPUStat() {
    local CPUStat_Result="$(top -bn1 | grep Cpu)"
    # 原始数据
    LBench_Result_CPUStat_user="$(Function_ReadCPUStat "${CPUStat_Result}" "us")"
    LBench_Result_CPUStat_system="$(Function_ReadCPUStat "${CPUStat_Result}" "sy")"
    LBench_Result_CPUStat_anice="$(Function_ReadCPUStat "${CPUStat_Result}" "ni")"
    LBench_Result_CPUStat_idle="$(Function_ReadCPUStat "${CPUStat_Result}" "id")"
    LBench_Result_CPUStat_iowait="$(Function_ReadCPUStat "${CPUStat_Result}" "wa")"
    LBench_Result_CPUStat_hardint="$(Function_ReadCPUStat "${CPUStat_Result}" "hi")"
    LBench_Result_CPUStat_softint="$(Function_ReadCPUStat "${CPUStat_Result}" "si")"
    LBench_Result_CPUStat_steal="$(Function_ReadCPUStat "${CPUStat_Result}" "st")"
    # 加工后的数据
    LBench_Result_CPUStat_UsedAll="$(echo ${LBench_Result_CPUStat_user} ${LBench_Result_CPUStat_system} ${LBench_Result_CPUStat_nice} | awk '{printf "%.1f\n",$1+$2+$3}')"
}

Function_ReadCPUStat() {
    if [ "$1" == "" ]; then
        echo -n "nil"
    else
        local result="$(echo $1 | grep -oE "[0-9]{1,2}.[0-9]{1} $2" | awk '{print $1}')"
        echo $result
    fi
}

SystemInfo_GetKernelVersion() {
    local version="$(uname -r)"
    LBench_Result_KernelVersion="${version}"
}

SystemInfo_GetNetworkCCMethod() {
    local val_cc="$(sysctl -n net.ipv4.tcp_congestion_control)"
    local val_qdisc="$(sysctl -n net.core.default_qdisc)"
    LBench_Result_NetworkCCMethod="${val_cc} + ${val_qdisc}"
}

SystemInfo_GetSystemBit() {
    local sysarch="$(uname -m)"
    if [ "${sysarch}" = "unknown" ] || [ "${sysarch}" = "" ]; then
        local sysarch="$(arch)"
    fi
    if [ "${sysarch}" = "x86_64" ]; then
        # X86平台 64位
        LBench_Result_SystemBit_Short="64"
        LBench_Result_SystemBit_Full="amd64"
	curl -L https://github.com/sjlleo/VerifyDisneyPlus/releases/download/1.01/dp_1.01_linux_amd64 -o dp && chmod +x dp
	sleep 0.5
        curl -L https://github.com/sjlleo/netflix-verify/releases/download/v3.1.0/nf_linux_amd64 -o nf && chmod +x nf
	sleep 0.5
        curl -L https://github.com/sjlleo/TubeCheck/releases/download/1.0Beta/tubecheck_1.0beta_linux_amd64 -o tubecheck && chmod +x tubecheck
	sleep 0.5
    elif [ "${sysarch}" = "i386" ] || [ "${sysarch}" = "i686" ]; then
        # X86平台 32位
        LBench_Result_SystemBit_Short="32"
        LBench_Result_SystemBit_Full="i386"
        curl -L https://github.com/sjlleo/VerifyDisneyPlus/releases/download/1.01/dp_1.01_linux_386 -o dp && chmod +x dp
	sleep 0.5
        curl -L https://github.com/sjlleo/netflix-verify/releases/download/v3.1.0/nf_linux_amd64 -o nf && chmod +x nf
        sleep 0.5
	curl -L https://github.com/sjlleo/TubeCheck/releases/download/1.0Beta/tubecheck_1.0beta_linux_386 -o tubecheck && chmod +x tubecheck
	sleep 0.5
    elif [ "${sysarch}" = "armv7l" ] || [ "${sysarch}" = "armv8" ] || [ "${sysarch}" = "armv8l" ] || [ "${sysarch}" = "aarch64" ]; then
        # ARM平台 暂且将32位/64位统一对待
        LBench_Result_SystemBit_Short="arm"
        LBench_Result_SystemBit_Full="arm"
        curl -L https://github.com/sjlleo/VerifyDisneyPlus/releases/download/1.01/dp_1.01_linux_arm -o dp && chmod +x dp
	sleep 0.5
        curl -L https://github.com/sjlleo/netflix-verify/releases/download/v3.1.0/nf_linux_arm64 -o nf && chmod +x nf
	sleep 0.5
        curl -L https://github.com/sjlleo/TubeCheck/releases/download/1.0Beta/tubecheck_1.0beta_linux_arm -o tubecheck && chmod +x tubecheck
	sleep 0.5
    else
        LBench_Result_SystemBit_Short="unknown"
        LBench_Result_SystemBit_Full="unknown"
        curl -L https://github.com/sjlleo/VerifyDisneyPlus/releases/download/1.01/dp_1.01_linux_amd64 -o dp && chmod +x dp
	sleep 0.5
        curl -L https://github.com/sjlleo/netflix-verify/releases/download/v3.1.0/nf_linux_amd64 -o nf && chmod +x nf
	sleep 0.5
        curl -L https://github.com/sjlleo/TubeCheck/releases/download/1.0Beta/tubecheck_1.0beta_linux_amd64 -o tubecheck && chmod +x tubecheck
	sleep 0.5
    fi
}


SystemInfo_GetVirtType() {
    if [ -f "/usr/bin/systemd-detect-virt" ]; then
        Var_VirtType="$(/usr/bin/systemd-detect-virt)"
        # 虚拟机检测
        if [ "${Var_VirtType}" = "qemu" ]; then
            LBench_Result_VirtType="QEMU"
        elif [ "${Var_VirtType}" = "kvm" ]; then
            LBench_Result_VirtType="KVM"
        elif [ "${Var_VirtType}" = "zvm" ]; then
            LBench_Result_VirtType="S390 Z/VM"
        elif [ "${Var_VirtType}" = "vmware" ]; then
            LBench_Result_VirtType="VMware"
        elif [ "${Var_VirtType}" = "microsoft" ]; then
            LBench_Result_VirtType="Microsoft Hyper-V"
        elif [ "${Var_VirtType}" = "xen" ]; then
            LBench_Result_VirtType="Xen Hypervisor"
        elif [ "${Var_VirtType}" = "bochs" ]; then
            LBench_Result_VirtType="BOCHS"   
        elif [ "${Var_VirtType}" = "uml" ]; then
            LBench_Result_VirtType="User-mode Linux"   
        elif [ "${Var_VirtType}" = "parallels" ]; then
            LBench_Result_VirtType="Parallels"   
        elif [ "${Var_VirtType}" = "bhyve" ]; then
            LBench_Result_VirtType="FreeBSD Hypervisor"
        # 容器虚拟化检测
        elif [ "${Var_VirtType}" = "openvz" ]; then
            LBench_Result_VirtType="OpenVZ"
        elif [ "${Var_VirtType}" = "lxc" ]; then
            LBench_Result_VirtType="LXC"        
        elif [ "${Var_VirtType}" = "lxc-libvirt" ]; then
            LBench_Result_VirtType="LXC (libvirt)"        
        elif [ "${Var_VirtType}" = "systemd-nspawn" ]; then
            LBench_Result_VirtType="Systemd nspawn"        
        elif [ "${Var_VirtType}" = "docker" ]; then
            LBench_Result_VirtType="Docker"        
        elif [ "${Var_VirtType}" = "rkt" ]; then
            LBench_Result_VirtType="RKT"
        # 特殊处理
        elif [ -c "/dev/lxss" ]; then # 处理WSL虚拟化
            Var_VirtType="wsl"
            LBench_Result_VirtType="Windows Subsystem for Linux (WSL)"
        # 未匹配到任何结果, 或者非虚拟机 
        elif [ "${Var_VirtType}" = "none" ]; then
            Var_VirtType="dedicated"
            LBench_Result_VirtType="None"
            local Var_BIOSVendor="$(dmidecode -s bios-vendor)"
            if [ "${Var_BIOSVendor}" = "SeaBIOS" ]; then
                Var_VirtType="Unknown"
                LBench_Result_VirtType="Unknown with SeaBIOS BIOS"
            else
                Var_VirtType="dedicated"
                LBench_Result_VirtType="Dedicated with ${Var_BIOSVendor} BIOS"
            fi
        fi
    elif [ ! -f "/usr/sbin/virt-what" ]; then
        Var_VirtType="Unknown"
        LBench_Result_VirtType="[Error: virt-what not found !]"
    elif [ -f "/.dockerenv" ]; then # 处理Docker虚拟化
        Var_VirtType="docker"
        LBench_Result_VirtType="Docker"
    elif [ -c "/dev/lxss" ]; then # 处理WSL虚拟化
        Var_VirtType="wsl"
        LBench_Result_VirtType="Windows Subsystem for Linux (WSL)"
    else # 正常判断流程
        Var_VirtType="$(virt-what | xargs)"
        local Var_VirtTypeCount="$(echo $Var_VirtTypeCount | wc -l)"
        if [ "${Var_VirtTypeCount}" -gt "1" ]; then # 处理嵌套虚拟化
            LBench_Result_VirtType="echo ${Var_VirtType}"
            Var_VirtType="$(echo ${Var_VirtType} | head -n1)" # 使用检测到的第一种虚拟化继续做判断
        elif [ "${Var_VirtTypeCount}" -eq "1" ] && [ "${Var_VirtType}" != "" ]; then # 只有一种虚拟化
            LBench_Result_VirtType="${Var_VirtType}"
        else
            local Var_BIOSVendor="$(dmidecode -s bios-vendor)"
            if [ "${Var_BIOSVendor}" = "SeaBIOS" ]; then
                Var_VirtType="Unknown"
                LBench_Result_VirtType="Unknown with SeaBIOS BIOS"
            else
                Var_VirtType="dedicated"
                LBench_Result_VirtType="Dedicated with ${Var_BIOSVendor} BIOS"
            fi
        fi
    fi
}

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


Entrance_SysBench_CPU_Fast() {
    Check_SysBench > /dev/null 2>&1
    SystemInfo_GetCPUInfo > /dev/null 2>&1
    Function_SysBench_CPU_Fast
    Function_BenchFinish > /dev/null 2>&1
    # Function_GenerateResult
}

speed_test(){
	speedLog="./speedtest.log"
	true > $speedLog
		speedtest-cli/speedtest -p no -s $1 --accept-license > $speedLog 2>&1
		is_upload=$(cat $speedLog | grep 'Upload')
		if [[ ${is_upload} ]]; then
	        local REDownload=$(cat $speedLog | awk -F ' ' '/Download/{print $3}')
	        local reupload=$(cat $speedLog | awk -F ' ' '/Upload/{print $3}')
	        local relatency=$(cat $speedLog | awk -F ' ' '/Latency/{print $2}')

			local nodeID=$1
			local nodeLocation=$2
			local nodeISP=$3

			strnodeLocation="${nodeLocation}　　　　　　"
			LANG=C
			#echo $LANG

			temp=$(echo "${REDownload}" | awk -F ' ' '{print $1}')
	        if [[ $(awk -v num1=${temp} -v num2=0 'BEGIN{print(num1>num2)?"1":"0"}') -eq 1 ]]; then
	       		echo -e "${strnodeLocation:0:20}\t ${reupload}Mbps\t ${REDownload}Mbps\t ${relatency}ms"
			fi
		else
	        local cerror="ERROR"
		fi
}

speed_test2() {
    local nodeName="$2"
    [ -z "$1" ] && ./speedtest-cli/speedtest --progress=no --accept-license --accept-gdpr > ./speedtest-cli/speedtest.log 2>&1 || \
    ./speedtest-cli/speedtest --progress=no --server-id=$1 --accept-license --accept-gdpr > ./speedtest-cli/speedtest.log 2>&1
    if [ $? -eq 0 ]; then
        local dl_speed=$(awk '/Download/{print $3" "$4}' ./speedtest-cli/speedtest.log)
        local up_speed=$(awk '/Upload/{print $3" "$4}' ./speedtest-cli/speedtest.log)
        local latency=$(awk '/Latency/{print $2" "$3}' ./speedtest-cli/speedtest.log)
        if [[ -n "${dl_speed}" && -n "${up_speed}" && -n "${latency}" ]]; then
            echo -e "${nodeName}\t ${up_speed}\t ${dl_speed}\t ${latency}"
        fi
    fi
}

function MediaUnlockTest_Dazn() {
    echo -n -e " Dazn:\t\t\t\t\t->\c"
    local tmpresult=$(curl $useNIC $xForward -${1} -sS --max-time 10 -X POST -H "Content-Type: application/json" -d '{"LandingPageKey":"generic","Languages":"zh-CN,zh,en","Platform":"web","PlatformAttributes":{},"Manufacturer":"","PromoCode":"","Version":"2"}' "https://startup.core.indazn.com/misl/v5/Startup" 2>&1)

    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Dazn:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    isAllowed=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'isAllowed' | awk '{print $2}' | cut -f1 -d',')
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep '"GeolocatedCountry":' | awk '{print $2}' | cut -f2 -d'"')

    if [[ "$isAllowed" == "true" ]]; then
        local CountryCode=$(echo $result | tr [:lower:] [:upper:])
        echo -n -e "\r Dazn:\t\t\t\t\t${Font_Green}Yes (Region: ${CountryCode})${Font_Suffix}\n"
        return
    elif [[ "$isAllowed" == "false" ]]; then
        echo -n -e "\r Dazn:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Dazn:\t\t\t\t\t${Font_Red}Unsupport${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_Netflix() {
    echo -n -e " Netflix:\t\t\t\t->\c"
    local result1=$(curl $useNIC $xForward -${1} --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567" 2>&1)

    if [[ "$result1" == "404" ]]; then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Yellow}Originals Only${Font_Suffix}\n"
        return
    elif [[ "$result1" == "403" ]]; then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$result1" == "200" ]]; then
        local region=$(curl $useNIC $xForward -${1} --user-agent "${UA_Browser}" -fs --max-time 10 --write-out %{redirect_url} --output /dev/null "https://www.netflix.com/title/80018499" | cut -d '/' -f4 | cut -d '-' -f1 | tr [:lower:] [:upper:])
        if [[ ! -n "$region" ]]; then
            region="US"
        fi
        echo -n -e "\r Netflix:\t\t\t\t${Font_Green}Yes (Region: ${region})${Font_Suffix}\n"
        return
    elif [[ "$result1" == "000" ]]; then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
}


function MediaUnlockTest_DisneyPlus() {
    echo -n -e " Disney+:\t\t\t\t->\c"
    local PreAssertion=$(curl $useNIC $xForward -${1} --user-agent "${UA_Browser}" -s --max-time 10 -X POST "https://disney.api.edge.bamgrid.com/devices" -H "authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -H "content-type: application/json; charset=UTF-8" -d '{"deviceFamily":"browser","applicationRuntime":"chrome","deviceProfile":"windows","attributes":{}}' 2>&1)
    if [[ "$PreAssertion" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$PreAssertion" == "curl"* ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local assertion=$(echo $PreAssertion | python -m json.tool 2>/dev/null | grep assertion | cut -f4 -d'"')
    local PreDisneyCookie=$(curl -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/cookies" | sed -n '1p')
    local disneycookie=$(echo $PreDisneyCookie | sed "s/DISNEYASSERTION/${assertion}/g")
    local TokenContent=$(curl $useNIC $xForward -${1} --user-agent "${UA_Browser}" -s --max-time 10 -X POST "https://disney.api.edge.bamgrid.com/token" -H "authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -d "$disneycookie")
    local isBanned=$(echo $TokenContent | python -m json.tool 2>/dev/null | grep 'forbidden-location')
    local is403=$(echo $TokenContent | grep '403 ERROR')

    if [ -n "$isBanned" ] || [ -n "$is403" ]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    local fakecontent=$(curl -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/cookies" | sed -n '8p')
    local refreshToken=$(echo $TokenContent | python -m json.tool 2>/dev/null | grep 'refresh_token' | awk '{print $2}' | cut -f2 -d'"')
    local disneycontent=$(echo $fakecontent | sed "s/ILOVEDISNEY/${refreshToken}/g")
    local tmpresult=$(curl $useNIC $xForward -${1} --user-agent "${UA_Browser}" -X POST -sSL --max-time 10 "https://disney.api.edge.bamgrid.com/graph/v1/device/graphql" -H "authorization: ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -d "$disneycontent" 2>&1)
    local previewcheck=$(curl $useNIC $xForward -${1} -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://disneyplus.com" | grep preview)
    local isUnabailable=$(echo $previewcheck | grep 'unavailable')
    local region=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'countryCode' | cut -f4 -d'"')
    local inSupportedLocation=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'inSupportedLocation' | awk '{print $2}' | cut -f1 -d',')

    if [[ "$region" == "JP" ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Green}Yes (Region: JP)${Font_Suffix}\n"
        return
    elif [ -n "$region" ] && [[ "$inSupportedLocation" == "false" ]] && [ -z "$isUnabailable" ]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Yellow}Available For [Disney+ $region] Soon${Font_Suffix}\n"
        return
    elif [ -n "$region" ] && [ -n "$isUnavailable" ]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -n "$region" ] && [[ "$inSupportedLocation" == "true" ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
        return
    elif [ -z "$region" ]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi

}


function MediaUnlockTest_HotStar() {
    echo -n -e " HotStar:\t\t\t\t->\c"
    local result=$(curl $useNIC $xForward --user-agent "${UA_Browser}" -${1} ${ssll} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://api.hotstar.com/o/v1/page/1557?offset=0&size=20&tao=0&tas=20")
    if [ "$result" = "000" ]; then
        echo -n -e "\r HotStar:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "401" ]; then
        local region=$(curl $useNIC $xForward --user-agent "${UA_Browser}" -${1} ${ssll} -sI "https://www.hotstar.com" | grep 'geo=' | sed 's/.*geo=//' | cut -f1 -d",")
        local site_region=$(curl $useNIC $xForward -${1} ${ssll} -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.hotstar.com" | sed 's@.*com/@@' | tr [:lower:] [:upper:])
        if [ -n "$region" ] && [ "$region" = "$site_region" ]; then
            echo -n -e "\r HotStar:\t\t\t\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
            return
        else
            echo -n -e "\r HotStar:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            return
        fi
    elif [ "$result" = "475" ]; then
        echo -n -e "\r HotStar:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r HotStar:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_NetflixCDN() {
    echo -n -e " Netflix Preferred CDN:\t\t\t->\c"
    local tmpresult=$(curl $useNIC $xForward -${1} ${ssll} -s --max-time 10 "https://api.fast.com/netflix/speedtest/v2?https=true&token=YXNkZmFzZGxmbnNkYWZoYXNkZmhrYWxm&urlCount=1")
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    elif [ -n "$(echo $tmpresult | grep '>403<')" ]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Red}Failed (IP Banned By Netflix)${Font_Suffix}\n"
        return
    fi

    local CDNAddr=$(echo $tmpresult | sed 's/.*"url":"//' | cut -f3 -d"/")
    if [[ "$1" == "6" ]]; then
        nslookup -q=AAAA $CDNAddr >~/v6_addr.txt
        ifAAAA=$(cat ~/v6_addr.txt | grep 'AAAA address' | awk '{print $NF}')
        if [ -z "$ifAAAA" ]; then
            CDNIP=$(cat ~/v6_addr.txt | grep Address | sed -n '$p' | awk '{print $NF}')
        else
            CDNIP=${ifAAAA}
        fi
    else
        CDNIP=$(nslookup $CDNAddr | sed '/^\s*$/d' | awk 'END {print}' | awk '{print $2}')
    fi

    if [ -z "$CDNIP" ]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Red}Failed (CDN IP Not Found)${Font_Suffix}\n"
        rm -rf ~/v6_addr.txt
        return
    fi

    local CDN_ISP=$(curl $useNIC $xForward --user-agent "${UA_Browser}" -s --max-time 20 "https://api.ip.sb/geoip/$CDNIP" | python -m json.tool 2>/dev/null | grep 'isp' | cut -f4 -d'"')
    local iata=$(echo $CDNAddr | cut -f3 -d"-" | sed 's/.\{3\}$//' | tr [:lower:] [:upper:])
    local isIataFound1=$(curl -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/reference/IATACode.txt" | grep $iata)
    local isIataFound2=$(curl -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/reference/IATACode2.txt" | grep $iata)

    if [ -n "$isIataFound1" ]; then
        local lineNo=$(curl $useNIC $xForward -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/reference/IATACode.txt" | cut -f3 -d"|" | sed -n "/${iata}/=")
        local location=$(curl $useNIC $xForward -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/reference/IATACode.txt" | awk "NR==${lineNo}" | cut -f1 -d"|" | sed -e 's/^[[:space:]]*//')
    elif [ -z "$isIataFound1" ] && [ -n "$isIataFound2" ]; then
        local lineNo=$(curl $useNIC $xForward -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/reference/IATACode2.txt" | awk '{print $1}' | sed -n "/${iata}/=")
        local location=$(curl $useNIC $xForward -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/reference/IATACode2.txt" | awk "NR==${lineNo}" | cut -f2 -d"," | sed -e 's/^[[:space:]]*//' | tr [:upper:] [:lower:] | sed 's/\b[a-z]/\U&/g')
    fi

    if [ -n "$location" ] && [[ "$CDN_ISP" == "Netflix Streaming Services" ]]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Green}$location ${Font_Suffix}\n"
        rm -rf ~/v6_addr.txt
        return
    elif [ -n "$location" ] && [[ "$CDN_ISP" != "Netflix Streaming Services" ]]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Yellow}Associated with [$CDN_ISP] in [$location]${Font_Suffix}\n"
        rm -rf ~/v6_addr.txt
        return
    elif [ -n "$location" ] && [ -z "$CDN_ISP" ]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Red}No ISP Info Founded${Font_Suffix}\n"
        rm -rf ~/v6_addr.txt
        return
    fi
}

function MediaUnlockTest_YouTube_Premium() {
    echo -n -e " YouTube Premium:\t\t\t->\c"
    local tmpresult=$(curl $useNIC $xForward --user-agent "${UA_Browser}" -${1} --max-time 10 -sSL -H "Accept-Language: en" -b "YSC=BiCUU3-5Gdk; CONSENT=YES+cb.20220301-11-p0.en+FX+700; GPS=1; VISITOR_INFO1_LIVE=4VwPMkB7W5A; PREF=tz=Asia.Shanghai; _gcl_au=1.1.1809531354.1646633279" "https://www.youtube.com/premium" 2>&1)

    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r YouTube Premium:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local isCN=$(echo $tmpresult | grep 'www.google.cn')
    if [ -n "$isCN" ]; then
        echo -n -e "\r YouTube Premium:\t\t\t${Font_Red}No${Font_Suffix} ${Font_Green} (Region: CN)${Font_Suffix} \n"
        return
    fi
    local isNotAvailable=$(echo $tmpresult | grep 'Premium is not available in your country')
    local region=$(echo $tmpresult | grep "countryCode" | sed 's/.*"countryCode"//' | cut -f2 -d'"')
    local isAvailable=$(echo $tmpresult | grep 'manageSubscriptionButton')

    if [ -n "$isNotAvailable" ]; then
        echo -n -e "\r YouTube Premium:\t\t\t${Font_Red}No${Font_Suffix} \n"
        return
    elif [ -n "$isAvailable" ] && [ -n "$region" ]; then
        echo -n -e "\r YouTube Premium:\t\t\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
        return
    elif [ -z "$region" ] && [ -n "$isAvailable" ]; then
        echo -n -e "\r YouTube Premium:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r YouTube Premium:\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_PrimeVideo_Region() {
    echo -n -e " Amazon Prime Video:\t\t\t->\c"
    local tmpresult=$(curl $useNIC $xForward -${1} ${ssll} --user-agent "${UA_Browser}" -s --max-time 10 "https://www.primevideo.com")

    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r Amazon Prime Video:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | grep '"currentTerritory":' | sed 's/.*currentTerritory//' | cut -f3 -d'"' | head -n 1)
    if [ -n "$result" ]; then
        echo -n -e "\r Amazon Prime Video:\t\t\t${Font_Green}Yes (Region: $result)${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Amazon Prime Video:\t\t\t${Font_Red}Unsupported${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_TVBAnywhere() {
    echo -n -e " TVBAnywhere+:\t\t\t\t->\c"
    local tmpresult=$(curl $useNIC $xForward -${1} ${ssll} -s --max-time 10 "https://uapisfm.tvbanywhere.com.sg/geoip/check/platform/android")
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r TVBAnywhere+:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'allow_in_this_country' | awk '{print $2}' | cut -f1 -d",")
    if [[ "$result" == "true" ]]; then
        echo -n -e "\r TVBAnywhere+:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "false" ]]; then
        echo -n -e "\r TVBAnywhere+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r TVBAnywhere+:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_iQYI_Region() {
    echo -n -e " iQyi Oversea Region:\t\t\t->\c"
    curl $useNIC $xForward -${1} ${ssll} -s -I --max-time 10 "https://www.iq.com/" >~/iqiyi

    if [ $? -eq 1 ]; then
        echo -n -e "\r iQyi Oversea Region:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    result=$(cat ~/iqiyi | grep 'mod=' | awk '{print $2}' | cut -f2 -d'=' | cut -f1 -d';')
    rm ~/iqiyi >/dev/null 2>&1

    if [ -n "$result" ]; then
        if [[ "$result" == "ntw" ]]; then
            result=TW
            echo -n -e "\r iQyi Oversea Region:\t\t\t${Font_Green}${result}${Font_Suffix}\n"
            return
        else
            result=$(echo $result | tr [:lower:] [:upper:])
            echo -n -e "\r iQyi Oversea Region:\t\t\t${Font_Green}${result}${Font_Suffix}\n"
            return
        fi
    else
        echo -n -e "\r iQyi Oversea Region:\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_Viu.com() {
    echo -n -e " Viu.com:\t\t\t\t->\c"
    local tmpresult=$(curl $useNIC $xForward -${1} ${ssll} -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.viu.com/")
    if [ "$tmpresult" = "000" ]; then
        echo -n -e "\r Viu.com:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    result=$(echo $tmpresult | cut -f5 -d"/")
    if [ -n "$result" ]; then
        if [[ "$result" == "no-service" ]]; then
            echo -n -e "\r Viu.com:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            return
        else
            result=$(echo $result | tr [:lower:] [:upper:])
            echo -n -e "\r Viu.com:\t\t\t\t${Font_Green}Yes (Region: ${result})${Font_Suffix}\n"
            return
        fi

    else
        echo -n -e "\r Viu.com:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_YouTube_CDN() {
    echo -n -e " YouTube CDN:\t\t\t\t->\c"
    local tmpresult=$(curl $useNIC $xForward -${1} ${ssll} -sS --max-time 10 "https://redirector.googlevideo.com/report_mapping" 2>&1)

    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r YouTube Region:\t\t\t${Font_Red}Check Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local iata=$(echo $tmpresult | grep router | cut -f2 -d'"' | cut -f2 -d"." | sed 's/.\{2\}$//' | tr [:lower:] [:upper:])
    local checkfailed=$(echo $tmpresult | grep "=>")
    if [ -z "$iata" ] && [ -n "$checkfailed" ]; then
        CDN_ISP=$(echo $checkfailed | awk '{print $3}' | cut -f1 -d"-" | tr [:lower:] [:upper:])
        echo -n -e "\r YouTube CDN:\t\t\t\t${Font_Yellow}Associated with [$CDN_ISP]${Font_Suffix}\n"
        return
    elif [ -n "$iata" ]; then
        local lineNo=$(curl $useNIC $xForward -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/reference/IATACode.txt" | cut -f3 -d"|" | sed -n "/${iata}/=")
        local location=$(curl $useNIC $xForward -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/reference/IATACode.txt" | awk "NR==${lineNo}" | cut -f1 -d"|" | sed -e 's/^[[:space:]]*//')
        echo -n -e "\r YouTube CDN:\t\t\t\t${Font_Green}$location${Font_Suffix}\n"
        return
    else
        echo -n -e "\r YouTube CDN:\t\t\t\t${Font_Red}Undetectable${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_NetflixCDN() {
    echo -n -e " Netflix Preferred CDN:\t\t\t->\c"
    local tmpresult=$(curl $useNIC $xForward -${1} ${ssll} -s --max-time 10 "https://api.fast.com/netflix/speedtest/v2?https=true&token=YXNkZmFzZGxmbnNkYWZoYXNkZmhrYWxm&urlCount=1")
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    elif [ -n "$(echo $tmpresult | grep '>403<')" ]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Red}Failed (IP Banned By Netflix)${Font_Suffix}\n"
        return
    fi

    local CDNAddr=$(echo $tmpresult | sed 's/.*"url":"//' | cut -f3 -d"/")
    if [[ "$1" == "6" ]]; then
        nslookup -q=AAAA $CDNAddr >~/v6_addr.txt
        ifAAAA=$(cat ~/v6_addr.txt | grep 'AAAA address' | awk '{print $NF}')
        if [ -z "$ifAAAA" ]; then
            CDNIP=$(cat ~/v6_addr.txt | grep Address | sed -n '$p' | awk '{print $NF}')
        else
            CDNIP=${ifAAAA}
        fi
    else
        CDNIP=$(nslookup $CDNAddr | sed '/^\s*$/d' | awk 'END {print}' | awk '{print $2}')
    fi

    if [ -z "$CDNIP" ]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Red}Failed (CDN IP Not Found)${Font_Suffix}\n"
        rm -rf ~/v6_addr.txt
        return
    fi

    local CDN_ISP=$(curl $useNIC $xForward --user-agent "${UA_Browser}" -s --max-time 20 "https://api.ip.sb/geoip/$CDNIP" | python -m json.tool 2>/dev/null | grep 'isp' | cut -f4 -d'"')
    local iata=$(echo $CDNAddr | cut -f3 -d"-" | sed 's/.\{3\}$//' | tr [:lower:] [:upper:])
    local isIataFound1=$(curl -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/reference/IATACode.txt" | grep $iata)
    local isIataFound2=$(curl -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/reference/IATACode2.txt" | grep $iata)

    if [ -n "$isIataFound1" ]; then
        local lineNo=$(curl $useNIC $xForward -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/reference/IATACode.txt" | cut -f3 -d"|" | sed -n "/${iata}/=")
        local location=$(curl $useNIC $xForward -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/reference/IATACode.txt" | awk "NR==${lineNo}" | cut -f1 -d"|" | sed -e 's/^[[:space:]]*//')
    elif [ -z "$isIataFound1" ] && [ -n "$isIataFound2" ]; then
        local lineNo=$(curl $useNIC $xForward -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/reference/IATACode2.txt" | awk '{print $1}' | sed -n "/${iata}/=")
        local location=$(curl $useNIC $xForward -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/reference/IATACode2.txt" | awk "NR==${lineNo}" | cut -f2 -d"," | sed -e 's/^[[:space:]]*//' | tr [:upper:] [:lower:] | sed 's/\b[a-z]/\U&/g')
    fi

    if [ -n "$location" ] && [[ "$CDN_ISP" == "Netflix Streaming Services" ]]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Green}$location ${Font_Suffix}\n"
        rm -rf ~/v6_addr.txt
        return
    elif [ -n "$location" ] && [[ "$CDN_ISP" != "Netflix Streaming Services" ]]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Yellow}Associated with [$CDN_ISP] in [$location]${Font_Suffix}\n"
        rm -rf ~/v6_addr.txt
        return
    elif [ -n "$location" ] && [ -z "$CDN_ISP" ]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Red}No ISP Info Founded${Font_Suffix}\n"
        rm -rf ~/v6_addr.txt
        return
    fi
}

function MediaUnlockTest_Spotify() {
    local tmpresult=$(curl $useNIC $xForward -${1} ${ssll} --user-agent "${UA_Browser}" -s --max-time 10 -X POST "https://spclient.wg.spotify.com/signup/public/v1/account" -d "birth_day=11&birth_month=11&birth_year=2000&collect_personal_info=undefined&creation_flow=&creation_point=https%3A%2F%2Fwww.spotify.com%2Fhk-en%2F&displayname=Gay%20Lord&gender=male&iagree=1&key=a1e486e2729f46d6bb368d6b2bcda326&platform=www&referrer=&send-email=0&thirdpartyemail=0&identifier_token=AgE6YTvEzkReHNfJpO114514" -H "Accept-Language: en")
    local region=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep '"country":' | cut -f4 -d'"')
    local isLaunched=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep is_country_launched | cut -f1 -d',' | awk '{print $2}')
    local StatusCode=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep status | cut -f1 -d',' | awk '{print $2}')
    echo -n -e " Spotify Registration:\t\t\t->\c"

    if [ "$tmpresult" = "000" ]; then
        echo -n -e "\r Spotify Registration:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$StatusCode" = "320" ]; then
        echo -n -e "\r Spotify Registration:\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ "$StatusCode" = "311" ] && [ "$isLaunched" = "true" ]; then
        echo -n -e "\r Spotify Registration:\t\t\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
        return
    fi
}

function GameTest_Steam() {
    echo -n -e " Steam Currency:\t\t\t->\c"
    local result=$(curl $useNIC $xForward --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://store.steampowered.com/app/761830" 2>&1 | grep priceCurrency | cut -d '"' -f4)

    if [ ! -n "$result" ]; then
        echo -n -e "\r Steam Currency:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    else
        echo -n -e "\r Steam Currency:\t\t\t${Font_Green}${result}${Font_Suffix}\n"
    fi
}

speed() {
    speed_test2 '' 'speedtest'
    speed_test '21541' '洛杉矶\t'
    speed_test '13623' '新加坡\t'
    speed_test '44988' '日本东京'
    speed_test '16176' '中国香港'
    speed_test '3633' '电信上海' '电信'
#    speed_test '27594' '电信广东广州5G' '电信'
    speed_test '5396' '电信江苏苏州5G' '电信'
    speed_test '24447' '联通上海' '联通'
    speed_test '4870' '联通湖南长沙' '联通'
#    speed_test '4870' '联通湖南长沙' '联通'
    speed_test '15863' '移动广西南宁' '移动'
    speed_test '16398' '移动贵州贵阳' '移动'
#     speed_test '27249' '移动江苏南京5G' '移动'
#https://raw.githubusercontent.com/zq/superspeed/master/superspeed.sh
}

speed2() {
    speed_test2 '' 'speedtest'
    speed_test '3633' '电信上海' '电信'
    speed_test '24447' '联通上海' '联通'
    speed_test '15863' '移动广西南宁' '移动'
#https://raw.githubusercontent.com/zq/superspeed/master/superspeed.sh
}

# =============== 磁盘测试 部分 ===============
Run_DiskTest_DD() {
    # 调用方式: Run_DiskTest_DD "测试文件名" "块大小" "写入次数" "测试项目名称"
    mkdir -p ${WorkDir}/DiskTest/ >/dev/null 2>&1
    SystemInfo_GetVirtType
    mkdir -p /.tmp_LBench/DiskTest >/dev/null 2>&1
    mkdir -p ${WorkDir}/data >/dev/null 2>&1
    local Var_DiskTestResultFile="${WorkDir}/data/disktest_result"
    # 将先测试读, 后测试写
    echo -n -e " $4\t\t->\c"
    # 清理缓存, 避免影响测试结果
    sync
    if [ "${Var_VirtType}" != "docker" ] && [ "${Var_VirtType}" != "openvz" ] && [ "${Var_VirtType}" != "lxc" ] && [ "${Var_VirtType}" != "wsl" ]; then
        echo 3 >/proc/sys/vm/drop_caches > /dev/null 2>&1
    fi
    # 避免磁盘压力过高, 启动测试前暂停1s
    sleep 1
    # 正式写测试
    dd if=/dev/zero of=/.tmp_LBench/DiskTest/$1 bs=$2 count=$3 oflag=direct 2>${Var_DiskTestResultFile}
    local DiskTest_WriteSpeed_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,4} kB\/s|[0-9]{1,4}.[0-9]{1,2} kB\/s|[0-9]{1,4} KB\/s|[0-9]{1,4}.[0-9]{1,2} KB\/s|[0-9]{1,4} MB\/s|[0-9]{1,4}.[0-9]{1,2} MB\/s|[0-9]{1,4} GB\/s|[0-9]{1,4}.[0-9]{1,2} GB\/s|[0-9]{1,4} TB\/s|[0-9]{1,4}.[0-9]{1,2} TB\/s|[0-9]{1,4} kB\/秒|[0-9]{1,4}.[0-9]{1,2} kB\/秒|[0-9]{1,4} KB\/秒|[0-9]{1,4}.[0-9]{1,2} KB\/秒|[0-9]{1,4} MB\/秒|[0-9]{1,4}.[0-9]{1,2} MB\/秒|[0-9]{1,4} GB\/秒|[0-9]{1,4}.[0-9]{1,2} GB\/秒|[0-9]{1,4} TB\/秒|[0-9]{1,4}.[0-9]{1,2} TB\/秒")"
    DiskTest_WriteSpeed="$(echo "${DiskTest_WriteSpeed_ResultRAW}" | sed "s/秒/s/")"
    local DiskTest_WriteTime_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,}.[0-9]{1,} s|[0-9]{1,}.[0-9]{1,} s|[0-9]{1,}.[0-9]{1,} 秒|[0-9]{1,}.[0-9]{1,} 秒")"
    DiskTest_WriteTime="$(echo ${DiskTest_WriteTime_ResultRAW} | awk '{print $1}')"
    DiskTest_WriteIOPS="$(echo ${DiskTest_WriteTime} $3 | awk '{printf "%d\n",$2/$1}')"
    DiskTest_WritePastTime="$(echo ${DiskTest_WriteTime} | awk '{printf "%.2f\n",$1}')"
    if [ "${DiskTest_WriteIOPS}" -ge "10000" ]; then
        DiskTest_WriteIOPS="$(echo ${DiskTest_WriteIOPS} 1000 | awk '{printf "%.2f\n",$2/$1}')"
        echo -n -e "\r $4\t\t${Font_SkyBlue}${DiskTest_WriteSpeed} (${DiskTest_WriteIOPS}K IOPS, ${DiskTest_WritePastTime}s)${Font_Suffix}\t\t->\c"
    else
        echo -n -e "\r $4\t\t${Font_SkyBlue}${DiskTest_WriteSpeed} (${DiskTest_WriteIOPS} IOPS, ${DiskTest_WritePastTime}s)${Font_Suffix}\t\t->\c"
    fi
    # 清理结果文件, 准备下一次测试
    rm -f ${Var_DiskTestResultFile}
    # 清理缓存, 避免影响测试结果
    sync
    if [ "${Var_VirtType}" != "docker" ] && [ "${Var_VirtType}" != "wsl" ]; then
        echo 3 >/proc/sys/vm/drop_caches > /dev/null 2>&1
    fi
    sleep 0.5
    # 正式读测试
    dd if=/.tmp_LBench/DiskTest/$1 of=/dev/null bs=$2 count=$3 iflag=direct 2>${Var_DiskTestResultFile}
    local DiskTest_ReadSpeed_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,4} kB\/s|[0-9]{1,4}.[0-9]{1,2} kB\/s|[0-9]{1,4} KB\/s|[0-9]{1,4}.[0-9]{1,2} KB\/s|[0-9]{1,4} MB\/s|[0-9]{1,4}.[0-9]{1,2} MB\/s|[0-9]{1,4} GB\/s|[0-9]{1,4}.[0-9]{1,2} GB\/s|[0-9]{1,4} TB\/s|[0-9]{1,4}.[0-9]{1,2} TB\/s|[0-9]{1,4} kB\/秒|[0-9]{1,4}.[0-9]{1,2} kB\/秒|[0-9]{1,4} KB\/秒|[0-9]{1,4}.[0-9]{1,2} KB\/秒|[0-9]{1,4} MB\/秒|[0-9]{1,4}.[0-9]{1,2} MB\/秒|[0-9]{1,4} GB\/秒|[0-9]{1,4}.[0-9]{1,2} GB\/秒|[0-9]{1,4} TB\/秒|[0-9]{1,4}.[0-9]{1,2} TB\/秒")"
    DiskTest_ReadSpeed="$(echo "${DiskTest_ReadSpeed_ResultRAW}" | sed "s/s/s/")"
    local DiskTest_ReadTime_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,}.[0-9]{1,} s|[0-9]{1,}.[0-9]{1,} s|[0-9]{1,}.[0-9]{1,} 秒|[0-9]{1,}.[0-9]{1,} 秒")"
    DiskTest_ReadTime="$(echo ${DiskTest_ReadTime_ResultRAW} | awk '{print $1}')"
    DiskTest_ReadIOPS="$(echo ${DiskTest_ReadTime} $3 | awk '{printf "%d\n",$2/$1}')"
    DiskTest_ReadPastTime="$(echo ${DiskTest_ReadTime} | awk '{printf "%.2f\n",$1}')"
    rm -f ${Var_DiskTestResultFile}
    # 输出结果
    echo -n -e "\r $4\t\t${Font_SkyBlue}${DiskTest_WriteSpeed} (${DiskTest_WriteIOPS} IOPS, ${DiskTest_WritePastTime}s)${Font_Suffix}\t\t${Font_SkyBlue}${DiskTest_ReadSpeed} (${DiskTest_ReadIOPS} IOPS, ${DiskTest_ReadPastTime}s)${Font_Suffix}\n"
    echo -e " $4\t\t${DiskTest_WriteSpeed} (${DiskTest_WriteIOPS} IOPS, ${DiskTest_WritePastTime} s)\t\t${DiskTest_ReadSpeed} (${DiskTest_ReadIOPS} IOPS, ${DiskTest_ReadPastTime} s)" >>${WorkDir}/DiskTest/result.txt
    rm -rf /.tmp_LBench/DiskTest/
}

Function_DiskTest_Fast() {
    mkdir -p ${WorkDir}/DiskTest/ >/dev/null 2>&1
    echo -e " ${Font_Yellow}-> 磁盘IO测试中 (4K Block/1M Block, Direct Mode)${Font_Suffix}"
    echo -e " -> 磁盘IO测试中 (4K Block/1M Block, Direct Mode)\n" >>${WorkDir}/DiskTest/result.txt
    SystemInfo_GetVirtType
    SystemInfo_GetOSRelease
    if [ "${Var_VirtType}" = "docker" ] || [ "${Var_VirtType}" = "wsl" ]; then
        echo -e " ${Msg_Warning}Due to virt architecture limit, the result may affect by the cache !\n"
    fi
    echo -e " ${Font_Yellow}测试操作\t\t写速度\t\t\t\t\t读速度${Font_Suffix}"
    echo -e " Test Name\t\tWrite Speed\t\t\t\tRead Speed" >>${WorkDir}/DiskTest/result.txt
    Run_DiskTest_DD "100MB.test" "4k" "25600" "100MB-4K Block"
    Run_DiskTest_DD "1GB.test" "1M" "1000" "1GB-1M Block"
    # 执行完成, 标记FLAG
    LBench_Flag_FinishDiskTestFast="1"
    sleep 0.5
}

# =============== SysBench - 内存性能 部分 ===============
Run_SysBench_Memory() {
    # 调用方式: Run_SysBench_Memory "线程数" "测试时长(s)" "测试遍数" "测试模式(读/写)" "读写方式(顺序/随机)" "说明"
    # 变量初始化
    mkdir -p ${WorkDir}/SysBench/Memory/ >/dev/null 2>&1
    maxtestcount="$3"
    local count="1"
    local TestScore="0.00"
    local TestSpeed="0.00"
    local TotalScore="0.00"
    local TotalSpeed="0.00"
    if [ "$1" -ge "2" ]; then
        MultiThread_Flag="1"
    else
        MultiThread_Flag="0"
    fi
    # 运行测试
    while [ $count -le $maxtestcount ]; do
        if [ "$1" -ge "2" ] && [ "$4" = "write" ]; then
            echo -e "\r ${Font_Yellow}$6:${Font_Suffix}\t$count/$maxtestcount \c"
        else
            echo -e "\r ${Font_Yellow}$6:${Font_Suffix}\t\t$count/$maxtestcount \c"
        fi
        local TestResult="$(sysbench --test=memory --num-threads=$1 --memory-block-size=1M --memory-total-size=102400G --memory-oper=$4 --max-time=$2 --memory-access-mode=$5 run 2>&1)"
        # 判断是MB还是MiB
        echo "${TestResult}" | grep -oE "MiB" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            local MiB_Flag="1"
        else
            local MiB_Flag="0"
        fi
        local TestScore="$(echo "${TestResult}" | grep -oE "[0-9]{1,}.[0-9]{1,2} ops\/sec|[0-9]{1,}.[0-9]{1,2} per second" | grep -oE "[0-9]{1,}.[0-9]{1,2}")"
        local TestSpeed="$(echo "${TestResult}" | grep -oE "[0-9]{1,}.[0-9]{1,2} MB\/sec|[0-9]{1,}.[0-9]{1,2} MiB\/sec" | grep -oE "[0-9]{1,}.[0-9]{1,2}")"
        local TotalScore="$(echo "${TotalScore} ${TestScore}" | awk '{printf "%.2f",$1+$2}')"
        local TotalSpeed="$(echo "${TotalSpeed} ${TestSpeed}" | awk '{printf "%.2f",$1+$2}')"
        let count=count+1
        local TestResult=""
        local TestScore="0.00"
        local TestSpeed="0.00"
    done
    ResultScore="$(echo "${TotalScore} ${maxtestcount} 1000" | awk '{printf "%.2f",$1/$2/$3}')"
    if [ "${MiB_Flag}" = "1" ]; then
        # MiB to MB
        ResultSpeed="$(echo "${TotalSpeed} ${maxtestcount} 1048576 1000000" | awk '{printf "%.2f",$1/$2/$3*$4}')"
    else
        # 直接输出
        ResultSpeed="$(echo "${TotalSpeed} ${maxtestcount}" | awk '{printf "%.2f",$1/$2}')"
    fi
    # 1线程的测试结果写入临时变量，方便与后续的多线程变量做对比
    if [ "$1" = "1" ] && [ "$4" = "read" ]; then
        LBench_Result_MemoryReadSpeedSingle="${ResultSpeed}"
    elif [ "$1" = "1" ] &&[ "$4" = "write" ]; then
        LBench_Result_MemoryWriteSpeedSingle="${ResultSpeed}"
    fi
    if [ "${MultiThread_Flag}" = "1" ]; then
        # 如果是多线程测试，输出与1线程测试对比的倍率
        if [ "$1" -ge "2" ] && [ "$4" = "read" ]; then
            LBench_Result_MemoryReadSpeedMulti="${ResultSpeed}"
            local readmultiple="$(echo "${LBench_Result_MemoryReadSpeedMulti} ${LBench_Result_MemoryReadSpeedSingle}" | awk '{printf "%.2f", $1/$2}')"
            echo -e "\r ${Font_Yellow}$6:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryReadSpeedMulti}${Font_Suffix} ${Font_Yellow}MB/s${Font_Suffix} (${readmultiple} x)"
        elif [ "$1" -ge "2" ] && [ "$4" = "write" ]; then
            LBench_Result_MemoryWriteSpeedMulti="${ResultSpeed}"
            local writemultiple="$(echo "${LBench_Result_MemoryWriteSpeedMulti} ${LBench_Result_MemoryWriteSpeedSingle}" | awk '{printf "%.2f", $1/$2}')"
            echo -e "\r ${Font_Yellow}$6:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryWriteSpeedMulti}${Font_Suffix} ${Font_Yellow}MB/s${Font_Suffix} (${writemultiple} x)"
        fi
    else
        if [ "$4" = "read" ]; then
            echo -e "\r ${Font_Yellow}$6:${Font_Suffix}\t\t${Font_SkyBlue}${ResultSpeed}${Font_Suffix} ${Font_Yellow}MB/s${Font_Suffix}"
        elif [ "$4" = "write" ]; then
            echo -e "\r ${Font_Yellow}$6:${Font_Suffix}\t\t${Font_SkyBlue}${ResultSpeed}${Font_Suffix} ${Font_Yellow}MB/s${Font_Suffix}"
        fi
    fi
    # Fix
    if [ "$1" -ge "2" ] && [ "$4" = "write" ]; then
        echo -e " $6:\t${ResultSpeed} MB/s" >>${WorkDir}/SysBench/Memory/result.txt
    else
        echo -e " $6:\t\t${ResultSpeed} MB/s" >>${WorkDir}/SysBench/Memory/result.txt
    fi
    sleep 0.5
}

Function_SysBench_Memory_Fast() {
    mkdir -p ${WorkDir}/SysBench/Memory/ >/dev/null 2>&1
    echo -e " ${Font_Yellow}-> 内存测试 Test (Fast Mode, 1-Pass @ 5sec)${Font_Suffix}"
    echo -e " -> 内存测试 (Fast Mode, 1-Pass @ 5sec)\n" >>${WorkDir}/SysBench/Memory/result.txt
    Run_SysBench_Memory "1" "5" "1" "read" "seq" "单线程读测试"
    Run_SysBench_Memory "1" "5" "1" "write" "seq" "单线程写测试"
    # 完成FLAG
    LBench_Flag_FinishSysBenchMemoryFast="1"
    sleep 0.5
}

Entrance_SysBench_Memory_Fast() {
    Function_SysBench_Memory_Fast
}

Entrance_DiskTest_Fast() {
    Function_DiskTest_Fast
#    Function_BenchFinish
}

calc_disk() {
    local total_size=0
    local array=$@
    for size in ${array[@]}
    do
        [ "${size}" == "0" ] && size_t=0 || size_t=`echo ${size:0:${#size}-1}`
        [ "`echo ${size:(-1)}`" == "K" ] && size=0
        [ "`echo ${size:(-1)}`" == "M" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' / 1024}' )
        [ "`echo ${size:(-1)}`" == "T" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' * 1024}' )
        [ "`echo ${size:(-1)}`" == "G" ] && size=${size_t}
        total_size=$( awk 'BEGIN{printf "%.1f", '$total_size' + '$size'}' )
    done
    echo ${total_size}
}

check_virt(){
    _exists "dmesg" && virtualx="$(dmesg 2>/dev/null)"
    if _exists "dmidecode"; then
        sys_manu="$(dmidecode -s system-manufacturer 2>/dev/null)"
        sys_product="$(dmidecode -s system-product-name 2>/dev/null)"
        sys_ver="$(dmidecode -s system-version 2>/dev/null)"
    else
        sys_manu=""
        sys_product=""
        sys_ver=""
    fi
    if   grep -qa docker /proc/1/cgroup; then
        virt="Docker"
    elif grep -qa lxc /proc/1/cgroup; then
        virt="LXC"
    elif grep -qa container=lxc /proc/1/environ; then
        virt="LXC"
    elif [[ -f /proc/user_beancounters ]]; then
        virt="OpenVZ"
    elif [[ "${virtualx}" == *kvm-clock* ]]; then
        virt="KVM"
    elif [[ "${cname}" == *KVM* ]]; then
        virt="KVM"
    elif [[ "${cname}" == *QEMU* ]]; then
        virt="KVM"
    elif [[ "${virtualx}" == *"VMware Virtual Platform"* ]]; then
        virt="VMware"
    elif [[ "${virtualx}" == *"Parallels Software International"* ]]; then
        virt="Parallels"
    elif [[ "${virtualx}" == *VirtualBox* ]]; then
        virt="VirtualBox"
    elif [[ -e /proc/xen ]]; then
        if grep -q "control_d" "/proc/xen/capabilities" 2>/dev/null; then
            virt="Xen-Dom0"
        else
            virt="Xen-DomU"
        fi
    elif [ -f "/sys/hypervisor/type" ] && grep -q "xen" "/sys/hypervisor/type"; then
        virt="Xen"
    elif [[ "${sys_manu}" == *"Microsoft Corporation"* ]]; then
        if [[ "${sys_product}" == *"Virtual Machine"* ]]; then
            if [[ "${sys_ver}" == *"7.0"* || "${sys_ver}" == *"Hyper-V" ]]; then
                virt="Hyper-V"
            else
                virt="Microsoft Virtual Machine"
            fi
        fi
    else
        virt="Dedicated"
    fi
}

ipv4_info() {
    local org="$(wget -q -T10 -O- ipinfo.io/org)"
    local city="$(wget -q -T10 -O- ipinfo.io/city)"
    local country="$(wget -q -T10 -O- ipinfo.io/country)"
    local region="$(wget -q -T10 -O- ipinfo.io/region)"
    if [[ -n "$org" ]]; then
        echo " ASN组织           : $(_blue "$org")"
    fi
    if [[ -n "$city" && -n "$country" ]]; then
        echo " 位置              : $(_blue "$city / $country")"
    fi
    if [[ -n "$region" ]]; then
        echo " 地区              : $(_yellow "$region")"
    fi
    if [[ -z "$org" ]]; then
        echo " 地区              : $(_red "无法获取ISP信息")"
    fi
}

print_intro() {
    echo "--------------------- A Bench Script By spiritlhl ---------------------"
    echo "                   测评频道: https://t.me/vps_reviews                    "
    echo "版本：$ver"
    echo "更新日志：$changeLog"
}

# Get System information
get_system_info() {
    cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
    cores=$( awk -F: '/processor/ {core++} END {print core}' /proc/cpuinfo )
    freq=$( awk -F'[ :]' '/cpu MHz/ {print $4;exit}' /proc/cpuinfo )
    ccache=$( awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
    tram=$( LANG=C; free -m | awk '/Mem/ {print $2}' )
    uram=$( LANG=C; free -m | awk '/Mem/ {print $3}' )
    swap=$( LANG=C; free -m | awk '/Swap/ {print $2}' )
    uswap=$( LANG=C; free -m | awk '/Swap/ {print $3}' )
    up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days, %d hour %d min\n",a,b,c)}' /proc/uptime )
    if _exists "w"; then
        load=$( LANG=C; w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
    elif _exists "uptime"; then
        load=$( LANG=C; uptime | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
    fi
    opsy=$( get_opsy )
    arch=$( uname -m )
    if _exists "getconf"; then
        lbit=$( getconf LONG_BIT )
    else
        echo ${arch} | grep -q "64" && lbit="64" || lbit="32"
    fi
    kern=$( uname -r )
    disk_size1=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem|udev|docker|snapd' | awk '{print $2}' ))
    disk_size2=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem|udev|docker|snapd' | awk '{print $3}' ))
    disk_total_size=$( calc_disk "${disk_size1[@]}" )
    disk_used_size=$( calc_disk "${disk_size2[@]}" )
    tcpctrl=$( sysctl net.ipv4.tcp_congestion_control | awk -F ' ' '{print $3}' )  
}
# Print System information
print_system_info() {
    if [ -n "$cname" ]; then
        echo " CPU 型号          : $(_blue "$cname")"
    else
        echo " CPU 型号          : $(_blue "无法检测到CPU型号")"
    fi
    echo " CPU 核心数        : $(_blue "$cores")"
    if [ -n "$freq" ]; then
        echo " CPU 频率          : $(_blue "$freq MHz")"
    fi
    if [ -n "$ccache" ]; then
        echo " CPU 缓存          : $(_blue "$ccache")"
    fi
    echo " 硬盘空间          : $(_yellow "$disk_total_size GB") $(_blue "($disk_used_size GB 已用)")"
    echo " 内存              : $(_yellow "$tram MB") $(_blue "($uram MB 已用)")"
    echo " Swap              : $(_blue "$swap MB ($uswap MB 已用)")"
    echo " 系统在线时间      : $(_blue "$up")"
    echo " 负载              : $(_blue "$load")"
    DISTRO=$(grep 'PRETTY_NAME' /etc/os-release | cut -d '"' -f 2 )
    echo " 系统              : $(_blue "$DISTRO")"  
    # $(_blue "$opsy")"
    CPU_AES=$(cat /proc/cpuinfo | grep aes)
    [[ -z "$CPU_AES" ]] && CPU_AES="\xE2\x9D\x8C Disabled" || CPU_AES="\xE2\x9C\x94 Enabled"
    echo " AES-NI指令集      : $(_blue "$CPU_AES")"  
    CPU_VIRT=$(cat /proc/cpuinfo | grep 'vmx\|svm')
    [[ -z "$CPU_VIRT" ]] && CPU_VIRT="\xE2\x9D\x8C Disabled" || CPU_VIRT="\xE2\x9C\x94 Enabled"
    echo " VM-x/AMD-V支持    : $(_blue "$CPU_VIRT")"  
    echo " 架构              : $(_blue "$arch ($lbit Bit)")"
    echo " 内核              : $(_blue "$kern")"
    echo " TCP加速方式       : $(_yellow "$tcpctrl")"
    echo " 虚拟化架构        : $(_blue "$virt")"
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
    date_time=$(date)
    # date_time=$(date +%Y-%m-%d" "%H:%M:%S)
    echo " 时间          : $date_time"
}



#######################################################################################


python_all_script(){
    checkpython
    checkmagic
    export PYTHONIOENCODING=utf-8
    curl -L https://raw.githubusercontent.com/spiritLHLS/ecs/main/qzcheck_ecs.py -o qzcheck_ecs.py 
    curl -L https://raw.githubusercontent.com/spiritLHLS/ecs/main/googlesearchcheck.py -o googlesearchcheck.py
    curl -L https://raw.githubusercontent.com/spiritLHLS/ecs/main/tkcheck.py -o tk.py
    sleep 0.5
    python3 googlesearchcheck.py
}

python_tk_script(){
    checkpython
    export PYTHONIOENCODING=utf-8
    curl -L https://raw.githubusercontent.com/spiritLHLS/ecs/main/tkcheck.py -o tk.py
    sleep 0.5
}

python_gd_script(){
    checkpython
    checkmagic
    export PYTHONIOENCODING=utf-8
    curl -L https://raw.githubusercontent.com/spiritLHLS/ecs/main/qzcheck_ecs.py -o qzcheck_ecs.py 
    curl -L https://raw.githubusercontent.com/spiritLHLS/ecs/main/googlesearchcheck.py -o googlesearchcheck.py
    sleep 0.5
    python3 googlesearchcheck.py
}


pre_check(){
    checkupdate
    checkroot
    checkwget
    checksystem
    checkcurl
    curl -L https://gitlab.com/spiritysdx/za/-/raw/main/yabsiotest.sh -o yabsiotest.sh && chmod +x yabsiotest.sh  >/dev/null 2>&1
    ! _exists "wget" && _red "Error: wget command not found.\n" && exit 1
    ! _exists "free" && _red "Error: free command not found.\n" && exit 1
}

sjlleo_script(){
    echo "--------------------流媒体解锁--感谢sjlleo开源-------------------------"
    yellow "以下测试的解锁地区是准确的，但是不是完整解锁的判断可能有误，这方面仅作参考使用"
    yellow "Youtube"
    ./tubecheck | sed "/@sjlleo/d"
    sleep 0.5
    yellow "Netflix"
    ./nf | sed "/@sjlleo/d;/^$/d"
    sleep 0.5
    yellow "DisneyPlus"
    ./dp | sed "/@sjlleo/d"
    sleep 0.5
    yellow "解锁Youtube，Netflix，DisneyPlus的地区以上面为准，下面这三测的不准"
}

basic_script(){
    echo "-----------------感谢teddysun和misakabench和yabs开源-------------------"
    print_system_info
    ipv4_info
    echo "-------------------CPU测试--感谢lemonbench开源------------------------"
    Entrance_SysBench_CPU_Fast
    echo "-------------------内存测试--感谢lemonbench开源-----------------------"
    Entrance_SysBench_Memory_Fast
}

io1_script(){
    echo "----------------磁盘IO读写测试--感谢lemonbench开源--------------------"
    Entrance_DiskTest_Fast
    # Function_GenerateResult
    Global_Exit_Action >/dev/null 2>&1
}

io2_script(){
    echo "-------------------磁盘IO读写测试--感谢yabs开源-----------------------"
    bash ./yabsiotest.sh 
    rm -rf yabsiotest.sh
}

RegionRestrictionCheck_script(){
    echo -e "---------------流媒体解锁--感谢RegionRestrictionCheck开源-------------"
    yellow " 以下为IPV4网络测试"
    Global_UnlockTest 4
    yellow " 以下为IPV6网络测试"
    Global_UnlockTest 6
}

lmc999_script(){
    echo -e "-------------------TikTok解锁--感谢lmc999提供检测----------------------"
    python3 tk.py 
}

spiritlhl_script(){
    echo -e "------------------欺诈分数以及IP质量检测--本频道原创-------------------"
    yellow "得分仅作参考，不代表100%准确"
    python3 qzcheck_ecs.py 
}

backtrace_script(){
    echo -e "-----------------三网回程--感谢zhanghanyun/backtrace开源--------------"
    rm -f $TEMP_FILE2
    curl https://raw.githubusercontent.com/zhanghanyun/backtrace/main/install.sh -sSf | sh
}


fscarmen_route_script(){
    echo -e "------------------回程路由--感谢fscarmen开源及PR----------------------"
    yellow "以下测试的带宽类型可能有误，商宽可能被判断为家宽，仅作参考使用"
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
}


fscarmen_port_script(){
    echo -e "-----------------测端口开通--感谢fscarmen开源及PR----------------------"
    IP_4=$(curl -s4m5 https:/ip.gs/json)
    sleep 0.5
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
}

superspeed_all_script(){
    echo "--------网络测速--由teddysun和superspeed开源及spiritlhls整理----------"
    sleep 0.5
    echo -e "测速点位置\t 上传速度\t 下载速度\t 延迟"
    speed && rm -fr speedtest-cli
}

superspeed_minal_script(){
    echo "--------网络测速--由teddysun和superspeed开源及spiritlhls整理----------"
    sleep 0.5
    echo -e "测速点位置\t 上传速度\t 下载速度\t 延迟"
    speed2 && rm -fr speedtest-cli
}

end_script(){
    next
    print_end_time
    next
}

all_script(){
    pre_check
    SystemInfo_GetSystemBit
    get_system_info >/dev/null 2>&1
    check_virt
    # checkssh
    checkdnsutils
    python_all_script
    checkspeedtest
    install_speedtest
    start_time=$(date +%s)
    clear
    print_intro
    basic_script
    io1_script
    sleep 1
    io2_script
    sjlleo_script
    RegionRestrictionCheck_script
    lmc999_script
    spiritlhl_script
    backtrace_script
    fscarmen_route_script
    fscarmen_port_script
    superspeed_all_script
    end_script
}

minal_script(){
    pre_check
    SystemInfo_GetSystemBit
    get_system_info >/dev/null 2>&1
    check_virt
    checkspeedtest
    install_speedtest
    start_time=$(date +%s)
    clear
    print_intro
    basic_script
    io2_script
    superspeed_minal_script
    end_script
}

minal_plus(){
    pre_check
    SystemInfo_GetSystemBit
    get_system_info >/dev/null 2>&1
    check_virt
    python_tk_script
    checkdnsutils
    checkspeedtest
    install_speedtest
    start_time=$(date +%s)
    clear
    print_intro
    basic_script
    io2_script
    sjlleo_script
    RegionRestrictionCheck_script
    lmc999_script
    backtrace_script
    fscarmen_route_script
    superspeed_minal_script
    end_script
}


minal_plus_network(){
    pre_check
    SystemInfo_GetSystemBit
    get_system_info >/dev/null 2>&1
    check_virt
    checkspeedtest
    install_speedtest
    start_time=$(date +%s)
    clear
    print_intro
    basic_script
    io2_script
    backtrace_script
    fscarmen_route_script
    superspeed_minal_script
    end_script
}

minal_plus_media(){
    pre_check
    SystemInfo_GetSystemBit
    get_system_info >/dev/null 2>&1
    check_virt
    checkdnsutils
    python_tk_script
    checkspeedtest
    install_speedtest
    start_time=$(date +%s)
    clear
    print_intro
    basic_script
    io2_script
    sjlleo_script
    RegionRestrictionCheck_script
    lmc999_script
    superspeed_minal_script
    end_script
}

network_script(){
    pre_check
    python_gd_script
    checkspeedtest
    install_speedtest
    start_time=$(date +%s)
    clear
    print_intro
    spiritlhl_script
    backtrace_script
    fscarmen_route_script
    fscarmen_port_script
    superspeed_all_script
    end_script
}

media_script(){
    pre_check
    SystemInfo_GetSystemBit
    checkdnsutils
    python_tk_script
    start_time=$(date +%s)
    clear
    print_intro
    sjlleo_script
    RegionRestrictionCheck_script
    lmc999_script
    end_script
}

hardware_script(){
    pre_check
    SystemInfo_GetSystemBit
    get_system_info >/dev/null 2>&1
    check_virt
    start_time=$(date +%s)
    clear
    print_intro
    basic_script
    io1_script
    io2_script
    end_script
}

port_script(){
    pre_check
    SystemInfo_GetSystemBit
    get_system_info >/dev/null 2>&1
    check_virt
    # checkssh
    start_time=$(date +%s)
    clear
    print_intro
    fscarmen_port_script
    end_script
}

rm_script(){
    rm -rf return.sh
    rm -rf speedtest.tgz*
    rm -rf wget-log*
    rm -rf ipip.py*
    rm -rf tk.py*
    rm -rf qzcheck_ecs.py*
    rm -rf dp
    rm -rf nf
    rm -rf tubecheck
    rm -rf besttrace
    rm -rf LemonBench.Result.txt*
    rm -rf speedtest.log*
    rm -rf ecs.sh*
    rm -rf googlesearchcheck.py*
    rm -rf gdlog*
    rm -rf $TEMP_FILE
}


Start_script(){
    clear
    echo "#############################################################"
    echo -e "#                     ${YELLOW}融合怪测评脚本${PLAIN}                        #"
    echo "# 版本：$ver                                          #"
    echo "# 更新日志：$changeLog#"
    echo -e "# ${GREEN}作者${PLAIN}: spiritlhl                                           #"
    echo -e "# ${GREEN}测评站点${PLAIN}: https://vps.spiritysdx.top                      #"
    echo -e "# ${GREEN}TG频道${PLAIN}: https://t.me/vps_reviews                          #"
    echo -e "# ${GREEN}GitHub${PLAIN}: https://github.com/spiritLHLS                     #"
    echo -e "# ${GREEN}GitLab${PLAIN}: https://gitlab.com/spiritysdx                     #"
    echo "#############################################################"
    echo ""
    green "请选择你接下来测评的组合或单项"
    echo -e "${GREEN}1.${PLAIN} 完全体(所有项目都测试)(平均运行8分钟以上)"
    echo -e "${GREEN}2.${PLAIN} 极简版(基础系统信息+CPU+内存+磁盘IO+测速节点4个)(平均运行3分钟不到)"
    echo -e "${GREEN}3.${PLAIN} 精简版(基础系统信息+CPU+内存+磁盘IO+御三家解锁+常用流媒体解锁+TikTok解锁+回程+路由+测速节点4个)(平均运行4分钟左右)"
    echo -e "${GREEN}4.${PLAIN} 精简网络版(基础系统信息+CPU+内存+磁盘IO+回程+路由+测速节点4个)(平均运行不到4分钟)"
    echo -e "${GREEN}5.${PLAIN} 精简解锁版(基础系统信息+CPU+内存+磁盘IO+御三家解锁+常用流媒体解锁+TikTok解锁+测速节点4个)(平均运行4分钟左右)"
    echo -e "${GREEN}6.${PLAIN} 网络方面(简化的IP质量检测+三网回程+三网路由+测速节点11个)(平均运行7分钟左右)"
    echo -e "${GREEN}7.${PLAIN} 解锁方面(御三家解锁+常用流媒体解锁+TikTok解锁)(平均运行1分钟出头)(arm架构未修复)"
    echo -e "${GREEN}8.${PLAIN} 硬件方面(基础系统信息+CPU+内存+双重磁盘IO测试)(平均运行1分半钟)"
    echo -e "${GREEN}9.${PLAIN} 完整的IP质量检测(平均运行10~20秒)"
    echo -e "${GREEN}10.${PLAIN} 常用端口开通情况(是否有阻断)(平均运行1分钟左右)(暂时有bug未修复)"
    echo " -------------"
    echo -e "${GREEN}0.${PLAIN} 退出"
    echo ""
    read -rp "请输入选项:" StartInput
	case $StartInput in
        1) all_script ;;
        2) minal_script ;;
        3) minal_plus ;;
        4) minal_plus_network ;;
        5) minal_plus_media ;;
        6) network_script;;
        7) media_script;;
        8) hardware_script;;
        9) bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/qzcheck.sh);;
        10) port_script ;;
        0) exit 1 ;;
    esac
}


Start_script
rm_script

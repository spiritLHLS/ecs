#!/usr/bin/env bash
# by spiritlhl
# from https://github.com/spiritLHLS/ecs

myvar=$(pwd)
ver="2023.07.05"
changeLog="融合怪十代目(集合百家之长)(专为测评频道小鸡而生)"
test_area_g=("广州电信" "广州联通" "广州移动")
test_ip_g=("58.60.188.222" "210.21.196.6" "120.196.165.24")
test_area_s=("上海电信" "上海联通" "上海移动")
test_ip_s=("202.96.209.133" "210.22.97.1" "211.136.112.200")
test_area_b=("北京电信" "北京联通" "北京移动")
test_ip_b=("219.141.136.12" "202.106.50.1" "221.179.155.161")
test_area_c=("成都电信" "成都联通" "成都移动")
test_ip_c=("61.139.2.69" "119.6.6.6" "211.137.96.205")
TEMP_DIR='/tmp/ecs'
TEMP_FILE='ip.test'
temp_file_apt_fix="${TEMP_DIR}/apt_fix.txt"
BrowserUA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.74 Safari/537.36"
WorkDir="/tmp/.LemonBench"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN="\033[0m"
shorturl=""
export DEBIAN_FRONTEND=noninteractive
_red() { echo -e "\033[31m\033[01m$@\033[0m"; }
_green() { echo -e "\033[32m\033[01m$@\033[0m"; }
_yellow() { echo -e "\033[33m\033[01m$@\033[0m"; }
_blue() { echo -e "\033[36m\033[01m$@\033[0m"; }
reading(){ read -rp "$(_green "$1")" "$2"; }
REGEX=("debian|astra" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "fedora" "arch" "freebsd")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Fedora" "Arch" "FreeBSD")
PACKAGE_UPDATE=("! apt-get update && apt-get --fix-broken install -y && apt-get update" "apt-get update" "yum -y update" "yum -y update" "yum -y update" "pacman -Sy" "pkg update")
PACKAGE_INSTALL=("apt-get -y install" "apt-get -y install" "yum -y install" "yum -y install" "yum -y install" "pacman -Sy --noconfirm --needed" "pkg install -y")
PACKAGE_REMOVE=("apt-get -y remove" "apt-get -y remove" "yum -y remove" "yum -y remove" "yum -y remove" "pacman -Rsc --noconfirm" "pkg delete")
PACKAGE_UNINSTALL=("apt-get -y autoremove" "apt-get -y autoremove" "yum -y autoremove" "yum -y autoremove" "yum -y autoremove" "" "pkg autoremove")

CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')" "$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(uname -s)") 
SYS="${CMD[0]}"
[[ -n $SYS ]] || exit 1
for ((int = 0; int < ${#REGEX[@]}; int++)); do
    if [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]]; then
        SYSTEM="${RELEASE[int]}"
        [[ -n $SYSTEM ]] && break
    fi
done
utf8_locale=$(locale -a 2>/dev/null | grep -i -m 1 -E "UTF-8|utf8")
if [[ -z "$utf8_locale" ]]; then
  _yellow "No UTF-8 locale found"
else
  export LC_ALL="$utf8_locale"
  export LANG="$utf8_locale"
  export LANGUAGE="$utf8_locale"
  _green "Locale set to $utf8_locale"
fi
rm -rf test_result.txt > /dev/null 2>&1

check_cdn() {
  local o_url=$1
  for cdn_url in "${cdn_urls[@]}"; do
    if curl -sL -k "$cdn_url$o_url" --max-time 6 | grep -q "success" > /dev/null 2>&1; then
      export cdn_success_url="$cdn_url"
      return
    fi
    sleep 0.5
  done
  export cdn_success_url=""
}

check_cdn_file() {
    check_cdn "https://raw.githubusercontent.com/spiritLHLS/ecs/main/back/test"
    if [ -n "$cdn_success_url" ]; then
        _yellow "CDN available, using CDN"
    else
        _yellow "No CDN available, no use CDN"
    fi
}

check_time_zone(){
    _yellow "adjusting the time"
    if command -v ntpd > /dev/null 2>&1; then
        if which systemctl >/dev/null 2>&1; then
            systemctl stop chronyd
            systemctl stop ntpd
            ntpd -gq
            systemctl start ntpd
        else
            service chronyd stop
            service ntpd stop
            ntpd -gq
            service ntpd start
        fi
        sleep 0.5
        return
    fi
    if ! command -v chronyd > /dev/null 2>&1; then
        ${PACKAGE_INSTALL[int]} chrony > /dev/null 2>&1
    fi
    if which systemctl >/dev/null 2>&1; then
        systemctl stop chronyd
        chronyd -q
        systemctl start chronyd
    else
        service chronyd stop
        chronyd -q
        service chronyd start
    fi
    sleep 0.5
}

checkhaveged(){
    [ "${Var_OSRelease}" = "freebsd" ] && return
    _yellow "checking haveged"
    if ! command -v haveged > /dev/null 2>&1; then
        ${PACKAGE_INSTALL[int]} haveged > /dev/null 2>&1
    fi
    if which systemctl >/dev/null 2>&1; then
        systemctl disable --now haveged
        systemctl enable --now haveged
    else
        service haveged stop
        service haveged start
    fi
}

declare -A sysctl_vars=(
    ["fs.file-max"]=1024000
    ["net.core.rmem_max"]=134217728
    ["net.core.wmem_max"]=134217728
    ["net.core.netdev_max_backlog"]=250000
    ["net.core.somaxconn"]=1024000
    ["net.ipv4.conf.all.rp_filter"]=0
    ["net.ipv4.conf.default.rp_filter"]=0
    ["net.ipv4.conf.lo.arp_announce"]=2
    ["net.ipv4.conf.all.arp_announce"]=2
    ["net.ipv4.conf.default.arp_announce"]=2
    ["net.ipv4.ip_forward"]=1
    ["net.ipv4.ip_local_port_range"]="1024 65535"
    ["net.ipv4.neigh.default.gc_stale_time"]=120
    ["net.ipv4.tcp_syncookies"]=1
    ["net.ipv4.tcp_tw_reuse"]=1
    ["net.ipv4.tcp_low_latency"]=1
    ["net.ipv4.tcp_fin_timeout"]=10
    ["net.ipv4.tcp_window_scaling"]=1
    ["net.ipv4.tcp_keepalive_time"]=10
    ["net.ipv4.tcp_timestamps"]=0
    ["net.ipv4.tcp_sack"]=1
    ["net.ipv4.tcp_fack"]=1
    ["net.ipv4.tcp_syn_retries"]=3
    ["net.ipv4.tcp_synack_retries"]=3
    ["net.ipv4.tcp_max_syn_backlog"]=16384
    ["net.ipv4.tcp_max_tw_buckets"]=8192
    ["net.ipv4.tcp_fastopen"]=3
    ["net.ipv4.tcp_mtu_probing"]=1
    ["net.ipv4.tcp_rmem"]="4096 87380 67108864"
    ["net.ipv4.tcp_wmem"]="4096 65536 67108864"
    ["net.ipv6.conf.all.forwarding"]=1
    ["net.ipv6.conf.default.forwarding"]=1
    ["net.nf_conntrack_max"]=25000000
    ["net.netfilter.nf_conntrack_max"]=25000000
    ["net.netfilter.nf_conntrack_tcp_timeout_time_wait"]=30
    ["net.netfilter.nf_conntrack_tcp_timeout_established"]=180
    ["net.netfilter.nf_conntrack_tcp_timeout_close_wait"]=30
    ["net.netfilter.nf_conntrack_tcp_timeout_fin_wait"]=30
)
sysctl_conf="/etc/sysctl.conf"
sysctl_conf_backup="/etc/sysctl.conf.backup"
sysctl_default="${TEMP_DIR}/sysctl_backup.txt"
sysctl_path=$(which sysctl)

variable_exists() {
    local variable="$1"
    grep -q "^$variable=" "$sysctl_conf"
}

optimized_kernel(){
    _yellow "optimizing resource limits"
    if [ -f /etc/security/limits.conf ]; then
        cp /etc/security/limits.conf /etc/security/limits.conf.backup
        cat > /etc/security/limits.conf << EOF
* soft nofile 512000
* hard nofile 512000
* soft nproc 512000
* hard nproc 512000
root soft nofile 512000
root hard nofile 512000
root soft nproc 512000
root hard nproc 512000
EOF
    fi
    if which systemctl >/dev/null 2>&1; then
        _yellow "optimizing sysctl configuration"
        declare -A default_values
        if [ -f "$sysctl_conf" ]; then
            if [ ! -f "$sysctl_conf_backup" ]; then
                cp "$sysctl_conf" "$sysctl_conf_backup"
            fi
            while IFS= read -r line; do
                variable="${line%%=*}"
                variable="${variable%%[[:space:]]*}"
                default_value="${line#*=}"
                default_values["$variable"]="$default_value"
            done < <($sysctl_path -a)
            echo "" > "$sysctl_default"
            for variable in "${!sysctl_vars[@]}"; do
                value="${sysctl_vars[$variable]}"
                if variable_exists "$variable"; then
                    sed -i "s/^$variable=.*/$variable=$value/" "$sysctl_conf"
                else
                    echo "$variable=$value" >> "$sysctl_conf"
                    default_value="${default_values[$variable]}"
                    echo "$variable=$default_value" >> "$sysctl_default"
                fi
            done
            $sysctl_path -p 2> /dev/null
        fi
    fi
}

checkping() {
    _yellow "checking ping"
	if ! which ping >/dev/null; then
        _yellow "Installing ping"
	    ${PACKAGE_INSTALL[int]} iputils-ping > /dev/null 2>&1
	    ${PACKAGE_INSTALL[int]} ping > /dev/null 2>&1
	fi
}

checknc() {
    _yellow "checking nc"
	if ! command -v nc >/dev/null; then
        _yellow "Installing nc"
        if command -v apt >/dev/null; then
	        ${PACKAGE_INSTALL[int]} netcat > /dev/null 2>&1
        else
	        ${PACKAGE_INSTALL[int]} nc > /dev/null 2>&1
        fi
	fi
}

checkpip(){
    [ "${Var_OSRelease}" = "freebsd" ] && curl -L https://bootstrap.pypa.io/get-pip.py -o get-pip.py && chmod +x get-pip.py && python3 get-pip.py && rm -rf get-pip.py && return
    local pvr="$1"
    local pip_version=$(pip --version 2>&1)
    if [[ $? -eq 0 && $pip_version != *"command not found"* ]]; then
        _blue "$pip_version"
    else
        _yellow "installing python${pvr}-pip"
        ${PACKAGE_INSTALL[int]} python${pvr}-pip
        pip_version=$(pip --version 2>&1)
        if [[ $? -eq 0 ]]; then
            _blue "$pip_version"
        else
            _red "python${pvr}-pip installation failed, please install it manually"
            return
        fi
    fi
}

checkpystun() {
    _yellow "checking pystun"
    local python_command
    local pip_command
    if command -v python3 >/dev/null 2>&1; then
        python_command="python3"
        pip_command="pip3"
        _blue "$($python_command --version 2>&1)"
    elif command -v python >/dev/null 2>&1; then
        python_command="python"
        pip_command="pip"
        _blue "$($python_command --version 2>&1)"
    else
        _yellow "installing python3"
        ${PACKAGE_INSTALL[int]} python3
        if command -v python3 >/dev/null 2>&1; then
            python_command="python3"
            pip_command="pip3"
            _blue "$($python_command --version 2>&1)"
        elif command -v python >/dev/null 2>&1; then
            python_command="python"
            pip_command="pip"
            _blue "$($python_command --version 2>&1)"
        else
            _yellow "installing python"
            ${PACKAGE_INSTALL[int]} python
            if command -v python3 >/dev/null 2>&1; then
                python_command="python3"
                pip_command="pip3"
                _blue "$($python_command --version 2>&1)"
            elif command -v python >/dev/null 2>&1; then
                python_command="python"
                pip_command="pip"
                _blue "$($python_command --version 2>&1)"
            else
                return
            fi
        fi
    fi
    if [[ $python_command == "python3" ]]; then
        checkpip 3
        if ! command -v pystun3 >/dev/null 2>&1; then
            _yellow "Installing pystun3"
            if ! "$pip_command" install -q pystun3 > /dev/null 2>&1; then
                "$pip_command" install -q pystun3
            fi
        fi
    fi
    if [[ $python_command == "python" ]]; then
        checkpip
        if [[ $($python_command --version 2>&1) == Python\ 2* ]]; then
            _yellow "Installing pystun"
            if ! "$pip_command" install -q pystun > /dev/null 2>&1; then
                "$pip_command" install -q pystun
            fi
        fi
    fi
}

checkstun() {
    _yellow "checking stun"
    if ! command -v stun > /dev/null 2>&1; then
        _yellow "Installing stun"
        ${PACKAGE_INSTALL[int]} stun-client > /dev/null 2>&1
    fi
}

checktar() {
    _yellow "checking tar"
	if ! command -v tar &> /dev/null; then
            _yellow "Installing tar"
	        ${PACKAGE_INSTALL[int]} tar 
	fi
    if [ $? -ne 0 ]; then
        apt-get -f install > /dev/null 2>&1
        ${PACKAGE_INSTALL[int]} tar > /dev/null 2>&1
    fi
}

checksudo() {
    _yellow "checking sudo"
    if ! command -v sudo > /dev/null 2>&1; then
        _yellow "Installing sudo"
        ${PACKAGE_INSTALL[int]} sudo > /dev/null 2>&1
    fi
}


# 后台静默预下载文件并解压
pre_download() {
    if [ -n "$LBench_Result_SystemBit_Full" ]; then
        if [ "$LBench_Result_SystemBit_Full" = "arm" ]; then
            tp_sys="arm64"
        else
            tp_sys="$LBench_Result_SystemBit_Full"
        fi
    fi
    for file in "$@"; do
        case $file in
            sysbench)
                wget -O $TEMP_DIR/sysbench.zip "${cdn_success_url}https://github.com/akopytov/sysbench/archive/1.0.20.zip"
                unzip $TEMP_DIR/sysbench.zip -d ${TEMP_DIR}
                ;;
            dp)
                curl -sL -k "${cdn_success_url}https://github.com/sjlleo/VerifyDisneyPlus/releases/download/1.01/dp_1.01_linux_${tp_sys}" -o $TEMP_DIR/dp && chmod +x $TEMP_DIR/dp
                ;;
            nf)
                curl -sL -k "${cdn_success_url}https://github.com/sjlleo/netflix-verify/releases/download/v3.1.0/nf_linux_${tp_sys}" -o $TEMP_DIR/nf && chmod +x $TEMP_DIR/nf
                ;;
            tubecheck)
                curl -sL -k "${cdn_success_url}https://github.com/sjlleo/TubeCheck/releases/download/1.0Beta/tubecheck_1.0beta_linux_${tp_sys}" -o $TEMP_DIR/tubecheck && chmod +x $TEMP_DIR/tubecheck
                ;;
            media_lmc_check)
                curl -sL -k "${cdn_success_url}https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh" -o $TEMP_DIR/media_lmc_check.sh && chmod 777 $TEMP_DIR/media_lmc_check.sh
                ;;
            besttrace)
                curl -sL -k "${cdn_success_url}https://raw.githubusercontent.com/fscarmen/tools/main/besttrace/${BESTTRACE_FILE}" -o $TEMP_DIR/$BESTTRACE_FILE && chmod +x $TEMP_DIR/$BESTTRACE_FILE
                ;;
            backtrace)
                wget -q -O $TEMP_DIR/backtrace.tar.gz  https://github.com/zhanghanyun/backtrace/releases/latest/download/$BACKTRACE_FILE
                tar -xf $TEMP_DIR/backtrace.tar.gz -C $TEMP_DIR
                ;;
            yabsiotest)
                curl -sL -k "${cdn_success_url}https://raw.githubusercontent.com/spiritLHLS/ecs/main/archive/yabsiotest.sh" -o yabsiotest.sh && chmod +x yabsiotest.sh
            ;;
            ecsspeed_ping)
                curl -sL -k "${cdn_success_url}https://raw.githubusercontent.com/spiritLHLS/ecsspeed/main/script/ecsspeed-ping.sh" -o $TEMP_DIR/ecsspeed-ping.sh && chmod +x $TEMP_DIR/ecsspeed-ping.sh
            ;;
            *)
                echo "Invalid file: $file"
                ;;
        esac
    done
}


# Trap终止信号捕获
_exit() {
    echo -e "\n${Msg_Error}Exiting ...\n"
    _red "检测到退出操作，脚本终止！\n"
    global_exit_action
    rm_script
    exit 1
}

trap _exit INT QUIT TERM

global_startup_init_action() {
    # 清理残留, 为新一次的运行做好准备
    echo -e "${Msg_Info}Initializing Running Enviorment, Please wait ..."
    rm -rf "$WorkDir"
    rm -rf /.tmp_LBench/
    mkdir "$WorkDir"/
    echo -e "${Msg_Info}Checking Dependency ..."
    check_virtwhat
    Check_SysBench
    SystemInfo_GetCPUInfo
    echo -e "${Msg_Info}Starting Test ..."
}

reset_default_sysctl(){
    if [ -f /etc/security/limits.conf ]; then
        cp /etc/security/limits.conf.backup /etc/security/limits.conf
        rm /etc/security/limits.conf.backup
    fi
    if which systemctl >/dev/null 2>&1; then
        if [ -f "$sysctl_conf" ]; then
            cp "$sysctl_conf_backup" "$sysctl_conf"
            cat "$sysctl_default" >> "$sysctl_conf"
            $sysctl_path -p 2> /dev/null
            cp "$sysctl_conf_backup" "$sysctl_conf"
            rm "$sysctl_conf_backup"
            rm "$sysctl_default"
        fi
        $sysctl_path -p 2> /dev/null
    fi
}

global_exit_action() {
    reset_default_sysctl > /dev/null 2>&1
    build_text
    if [ -n "$shorturl" ]
    then
        _green "  短链:"
        _blue "    $shorturl"
    fi
    rm -rf ${TEMP_DIR}
    rm -rf ${WorkDir}/
    rm -rf /.tmp_LBench/
    rm -rf *00_00
}

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

next() {
    echo -en "\r"
    [ "${Var_OSRelease}" = "freebsd" ] && printf "%-72s\n" "-" | tr ' ' '-' && return
    printf "%-72s\n" "-" | sed 's/\s/-/g'
}

# =============== 检查 Virt-what 组件 ===============
check_virtwhat() {
    if [ ! -f "/usr/sbin/virt-what" ]; then
        echo -e "${Msg_Warning}Virt-What Module not found, Installing ..."
        if [[ "${Var_OSRelease}" =~ ^(centos|rhel|almalinux|arch)$ ]]; then
            yum -y install virt-what
            if [ $? -ne 0 ]; then
                dnf -y install virt-what
            fi
        elif [ "${Var_OSRelease}" = "astra" ]; then
            apt-get install -y virt-what
            if [ $? -ne 0 ]; then
                echo "deb http://deb.debian.org/debian ${Var_OSReleaseVersion_Codename} main contrib non-free" >> /etc/apt/sources.list
                echo "deb-src http://deb.debian.org/debian ${Var_OSReleaseVersion_Codename} main contrib non-free" >> /etc/apt/sources.list
                apt_update_output=$(apt-get update 2>&1)
                echo "$apt_update_output" > "$temp_file_apt_fix"
                if grep -q 'NO_PUBKEY' "$temp_file_apt_fix"; then
                    public_keys=$(grep -oE 'NO_PUBKEY [0-9A-F]+' "$temp_file_apt_fix" | awk '{ print $2 }')
                    joined_keys=$(echo "$public_keys" | paste -sd " ")
                    _yellow "No Public Keys: $joined_keys"
                    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $joined_keys
                    apt-get update
                    if [ $? -eq 0 ]; then
                        _green "Fixed"
                    fi
                fi
                rm "$temp_file_apt_fix"
            fi
            apt-get install -y virt-what
        elif [[ "${Var_OSRelease}" =~ ^debian$ ]]; then
            apt-get install -y virt-what
            if [ $? -ne 0 ]; then
                echo "Retrying with additional options..."
                apt-get update && apt-get --fix-broken install -y
                apt-get install -y virt-what --force-yes
            fi
            if [ $? -ne 0 ]; then
                echo "Retrying with different options..."
                apt-get update && apt-get --fix-broken install -y
                apt-get install -y virt-what --allow
            fi
        elif [[ "${Var_OSRelease}" =~ ^ubuntu$ ]]; then
            apt-get install -y virt-what
            if [ $? -ne 0 ]; then
                echo "Retrying with additional options..."
                apt-get install -y virt-what -y --allow-unauthenticated
            fi
            if [ $? -ne 0 ]; then
                re='^[0-9]+$'
                if [[ $Var_OSReleaseVersion =~ $re ]]; then
                    local OSReleaseVersion=$(($Var_OSReleaseVersion + 0))
                    if [ $OSReleaseVersion -le 18 ]; then
                        if [ -f "/etc/apt/sources.list" ]; then
                            if ! grep -q "deb.*universe" /etc/apt/sources.list; then
                                check_lsb_release
                                echo "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe" | tee -a /etc/apt/sources.list
                                apt-get update
                                apt-get install -y virt-what
                            fi
                        fi
                    fi
                fi
            fi
        elif [ "${Var_OSRelease}" = "fedora" ]; then
            dnf -y install virt-what
        elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
            apk update
            apk add virt-what
        elif [ "${Var_OSRelease}" = "arch" ]; then
            pacman -Sy --needed --noconfirm virt-what
        elif [ "${Var_OSRelease}" = "freebsd" ]; then
            pkg install -y virt-what
        else
            echo -e "${Msg_Warning}Virt-What Module not found, but we could not find the os's release ..."
        fi
    fi
    # 二次检测
    if ! which virt-what >/dev/null 2>&1; then
        echo -e "Virt-What Moudle install Failure! Try Restart Bench or Manually install it!"
        exit 1
    fi
}

checkroot(){
	[[ $EUID -ne 0 ]] && echo -e "${RED}请使用 root 用户运行本脚本！${PLAIN}" && exit 1
}

checkupdate(){
	    _yellow "Updating package management sources"
        if command -v apt-get > /dev/null 2>&1; then
            apt_update_output=$(apt-get update 2>&1)
            echo "$apt_update_output" > "$temp_file_apt_fix"
            if grep -q 'NO_PUBKEY' "$temp_file_apt_fix"; then
                public_keys=$(grep -oE 'NO_PUBKEY [0-9A-F]+' "$temp_file_apt_fix" | awk '{ print $2 }')
                joined_keys=$(echo "$public_keys" | paste -sd " ")
                _yellow "No Public Keys: ${joined_keys}"
                apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ${joined_keys}
                apt-get update
                if [ $? -eq 0 ]; then
                    _green "Fixed"
                fi
            fi
            rm "$temp_file_apt_fix"
        else
            ${PACKAGE_UPDATE[int]}
        fi 
}

checkdmidecode(){
    ${PACKAGE_INSTALL[int]} dmidecode
    if [ $? -ne 0 ]; then
        if command -v apt-get > /dev/null 2>&1; then
            echo "Retrying with additional options..."
            apt-get update && apt-get --fix-broken install -y
            apt-get install -y dmidecode --force-yes
            if [ $? -ne 0 ]; then
                apt-get update && apt-get --fix-broken install -y
                apt-get install -y dmidecode --allow
                if [ $? -ne 0 ]; then
                    apt-get update && apt-get --fix-broken install -y
                    apt-get install -y dmidecode -y --allow-unauthenticated
                fi
            fi
        fi
    fi   
}

checkdnsutils() {
    _yellow "Installing dnsutils"
    if [ "${Var_OSRelease}" == "centos" ]; then
        yum -y install dnsutils > /dev/null 2>&1
        yum -y install bind-utils > /dev/null 2>&1
    elif [ "${Var_OSRelease}" == "arch" ]; then
        pacman -S --noconfirm --needed bind > /dev/null 2>&1
    else
        ${PACKAGE_INSTALL[int]} dnsutils > /dev/null 2>&1
    fi
}

checkcurl() {
	if ! which curl >/dev/null; then
        _yellow "Installing curl"
        ${PACKAGE_INSTALL[int]} curl
	fi
    if [ $? -ne 0 ]; then
        apt-get -f install > /dev/null 2>&1
        ${PACKAGE_INSTALL[int]} curl
    fi
}

checkwget() {
	if ! which wget >/dev/null; then
        _yellow "Installing wget"
        ${PACKAGE_INSTALL[int]} wget
	fi
}

checkfree() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
	if ! command -v free > /dev/null 2>&1; then
        _yellow "Installing procps"
	    ${PACKAGE_INSTALL[int]} procps
	fi
}

check_lsb_release() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
	if ! command -v lsb_release > /dev/null 2>&1; then
        _yellow "Installing lsb-release"
	    ${PACKAGE_INSTALL[int]} lsb-release
	fi
}

checklscpu() {
	if ! command -v lscpu > /dev/null 2>&1; then
        _yellow "Installing lscpu"
	    ${PACKAGE_INSTALL[int]} lscpu
	fi
}

checkunzip() {
	if ! command -v unzip > /dev/null 2>&1; then
        _yellow "Installing unzip"
        ${PACKAGE_INSTALL[int]} unzip
	fi
}

check_china(){
    _yellow "IP area being detected ......"
    if [[ -z "${CN}" ]]; then
        if [[ $(curl -m 6 -s https://ipapi.co/json | grep 'China') != "" ]]; then
            _yellow "根据ipapi.co提供的信息，当前IP可能在中国"
            read -e -r -p "是否选用中国镜像完成相关组件安装? ([y]/n) " input
            case $input in
                [yY][eE][sS] | [yY])
                    echo "使用中国镜像"
                    CN=true
                    ;;
                [nN][oO] | [nN])
                    echo "不使用中国镜像"
                    ;;
                *)
                    echo "使用中国镜像"
                    CN=true
                    ;;
            esac
        else
            if [[ $? -ne 0 ]]; then
                if [[ $(curl -m 6 -s cip.cc) =~ "中国" ]]; then
                    _yellow "根据cip.cc提供的信息，当前IP可能在中国"
                    read -e -r -p "是否选用中国镜像完成相关组件安装? [Y/n] " input
                    case $input in
                        [yY][eE][sS] | [yY])
                            echo "使用中国镜像"
                            CN=true
                            ;;
                        [nN][oO] | [nN])
                            echo "不使用中国镜像"
                            ;;
                        *)
                            echo "不使用中国镜像"
                            ;;
                    esac
                fi
            fi
        fi
    fi
}

statistics_of_run-times() {
COUNT=$(
  curl -4 -ksm1 "https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2FspiritLHLS%2Fecs&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=&edge_flat=true" 2>&1 ||
  curl -6 -ksm1 "https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2FspiritLHLS%2Fecs&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=&edge_flat=true" 2>&1) &&
  TODAY=$(expr "$COUNT" : '.*\s\([0-9]\{1,\}\)\s/.*') && TOTAL=$(expr "$COUNT" : '.*/\s\([0-9]\{1,\}\)\s.*')
}

download_speedtest_file() {
    file="./speedtest-cli/speedtest"
    if [[ -e "$file" ]]; then
        # _green "speedtest found"
        return
    fi
    file="./speedtest-cli/speedtest-go"
    if [[ -e "$file" ]]; then
        # _green "speedtest-go found"
        return
    fi
    local sys_bit="$1"
    if [[ -z "${CN}" || "${CN}" != true ]]; then
        if [ "$speedtest_ver" = "1.2.0" ]; then
            local url1="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-${sys_bit}.tgz"
            local url2="https://dl.lamp.sh/files/ookla-speedtest-1.2.0-linux-${sys_bit}.tgz"
        else
            local url1="https://filedown.me/Linux/Tool/speedtest_cli/ookla-speedtest-1.0.0-${sys_bit}-linux.tgz"
            local url2="https://bintray.com/ookla/download/download_file?file_path=ookla-speedtest-1.0.0-${sys_bit}-linux.tgz"
        fi
        curl --fail -sL -m 10 -o speedtest.tgz "${url1}" || curl --fail -sL -m 10 -o speedtest.tgz "${url2}"
        if [[ $? -ne 0 ]]; then
            # _red "Error: Failed to download official speedtest-cli."
            rm -rf speedtest.tgz*
            # _yellow "Try using the unofficial speedtest-go"
        fi
        if [ "$sys_bit" = "aarch64" ]; then
            sys_bit="arm64"
        fi
        local url3="https://github.com/showwin/speedtest-go/releases/download/v1.6.0/speedtest-go_1.6.0_Linux_${sys_bit}.tar.gz"
        curl --fail -sL -m 10 -o speedtest.tar.gz "${url3}" || curl --fail -sL -m 15 -o speedtest.tar.gz "${cdn_success_url}${url3}"
    else
        if [ "$sys_bit" = "aarch64" ]; then
            sys_bit="arm64"
        fi
        local url3="https://github.com/showwin/speedtest-go/releases/download/v1.6.0/speedtest-go_1.6.0_Linux_${sys_bit}.tar.gz"
        curl -o speedtest.tar.gz "${cdn_success_url}${url3}"
        # if [ $? -eq 0 ]; then
        #     _green "Used unofficial speedtest-go"
        # fi
    fi
    if [ ! -d "./speedtest-cli" ]; then
        mkdir -p "./speedtest-cli"
    fi
    if [ -f "./speedtest.tgz" ]; then
        tar -zxf speedtest.tgz -C ./speedtest-cli
        chmod 777 ./speedtest-cli/speedtest
        rm -rf speedtest.tgz*
    elif [ -f "./speedtest.tar.gz" ]; then
        tar -zxf speedtest.tar.gz -C ./speedtest-cli
        chmod 777 ./speedtest-cli/speedtest-go
        rm -rf speedtest.tar.gz*
    else
        _red "Error: Failed to download speedtest tool."
        exit 1
    fi
}

install_speedtest() {
    sys_bit=""
    local sysarch="$(uname -m)"
    case "${sysarch}" in
        "x86_64"|"x86"|"amd64"|"x64") sys_bit="x86_64";;
        "i386"|"i686") sys_bit="i386";;
        "aarch64"|"armv7l"|"armv8"|"armv8l") sys_bit="aarch64";;
        "s390x") sys_bit="s390x";;
        "riscv64") sys_bit="riscv64";;
        "ppc64le") sys_bit="ppc64le";;
        "ppc64") sys_bit="ppc64";;
        *) sys_bit="x86_64";;
    esac
    download_speedtest_file "${sys_bit}"
}

get_string_length() {
  local nodeName="$1"
  local length
  local converted
  converted=$(echo -n "$nodeName" | iconv -f utf8 -t gb2312 2>/dev/null)
  if [[ $? -eq 0 && -n "$converted" ]]; then
    length=$(echo -n "$converted" | wc -c)
    echo $length
    return
  fi
  converted=$(echo -n "$nodeName" | iconv -f utf8 -t big5 2>/dev/null)
  if [[ $? -eq 0 && -n "$converted" ]]; then
    length=$(echo -n "$converted" | wc -c)
    echo $length
    return
  fi
  length=$(echo -n "$nodeName" | awk '{len=0; for(i=1;i<=length($0);i++){c=substr($0,i,1);if(c~/[^\x00-\x7F]/){len+=2}else{len++}}; print len}')
  echo $length
}

speed_test() {
    local nodeName="$2"
    if [ ! -f "./speedtest-cli/speedtest" ]; then
        if [ -z "$1" ]; then
            ./speedtest-cli/speedtest-go > ./speedtest-cli/speedtest.log 2>&1
        else
            ./speedtest-cli/speedtest-go --server=$1 > ./speedtest-cli/speedtest.log 2>&1
        fi
        if [ $? -eq 0 ]; then
            local dl_speed=$(grep -oP 'Download: \K[\d\.]+' ./speedtest-cli/speedtest.log)
            local up_speed=$(grep -oP 'Upload: \K[\d\.]+' ./speedtest-cli/speedtest.log)
            local latency=$(grep -oP 'Latency: \K[\d\.]+' ./speedtest-cli/speedtest.log)
            if [[ -n "${latency}" && "${latency}" == *.* ]]; then
                latency=$(awk '{printf "%.2f", $1}' <<< "${latency}")
            fi
            if [[ -n "${dl_speed}" || -n "${up_speed}" || -n "${latency}" ]]; then
                if [[ $selection =~ ^[1-5]$ ]]; then
                    echo -e "${nodeName}\t ${up_speed}Mbps\t ${dl_speed}Mbps\t ${latency}ms\t"
                else
                    length=$(get_string_length "$nodeName")
                    if [ $length -ge 8 ]; then
		    	echo -e "${nodeName}\t ${up_speed}Mbps\t ${dl_speed}Mbps\t ${latency}ms\t"
                    else
		    	echo -e "${nodeName}\t\t ${up_speed}Mbps\t ${dl_speed}Mbps\t ${latency}ms\t"
                    fi
                fi
            fi
        fi
    else
        if [ -z "$1" ]; then
            ./speedtest-cli/speedtest --progress=no --accept-license --accept-gdpr > ./speedtest-cli/speedtest.log 2>&1
        else
            ./speedtest-cli/speedtest --progress=no --server-id=$1 --accept-license --accept-gdpr > ./speedtest-cli/speedtest.log 2>&1
        fi
        if [ $? -eq 0 ]; then
            local dl_speed=$(awk '/Download/{print $3" "$4}' ./speedtest-cli/speedtest.log)
            local up_speed=$(awk '/Upload/{print $3" "$4}' ./speedtest-cli/speedtest.log)
            if [ "$speedtest_ver" = "1.2.0" ]; then
                local latency=$(grep -oP 'Idle Latency:\s+\K[\d\.]+' ./speedtest-cli/speedtest.log)
            else
                local latency=$(grep -oP 'Latency:\s+\K[\d\.]+' ./speedtest-cli/speedtest.log)
            fi
            local packet_loss=$(awk -F': +' '/Packet Loss/{if($2=="Not available."){print "NULL"}else{print $2}}' ./speedtest-cli/speedtest.log)
            if [[ -n "${dl_speed}" || -n "${up_speed}" || -n "${latency}" ]]; then
                if [[ $selection =~ ^[1-5]$ ]]; then
                    echo -e "${nodeName}\t ${up_speed}\t ${dl_speed}\t ${latency}\t  $packet_loss"
                else
                    length=$(get_string_length "$nodeName")
                    if [ $length -ge 8 ]; then
                        echo -e "${nodeName}\t ${up_speed}\t ${dl_speed}\t ${latency}\t  $packet_loss"
                    else
			echo -e "${nodeName}\t\t ${up_speed}\t ${dl_speed}\t ${latency}\t  $packet_loss"
                    fi
                fi
            fi
        fi
    fi
}

is_ipv4() {
    local ip=$1
    local regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
    if [[ $ip =~ $regex ]]; then
        return 0  # 符合IPv4格式
    else
        return 1  # 不符合IPv4格式
    fi
}

test_list() {
    local list=("$@")
    if [ ${#list[@]} -eq 0 ]; then
        echo "列表为空，程序退出"
        return
    fi
    for ((i=0; i<${#list[@]}; i+=1))
    do
        id=$(echo "${list[i]}" | cut -d',' -f1)
        name=$(echo "${list[i]}" | cut -d',' -f2)
        speed_test "$id" "$name"
    done
}

temp_head(){
    echo "--------------------自动更新测速节点列表--本脚本原创--------------------"
    if [[ $selection =~ ^[1-5]$ ]]; then
        if [ -f "./speedtest-cli/speedtest" ]; then
	        echo -e "位置\t         上传速度\t 下载速度\t 延迟\t  丢包率"
        else
	        echo -e "位置\t         上传速度\t 下载速度\t 延迟"
        fi
    else
        if [ -f "./speedtest-cli/speedtest" ]; then
	        echo -e "位置\t\t 上传速度\t 下载速度\t 延迟\t  丢包率"
        else
	        echo -e "位置\t\t 上传速度\t 下载速度\t 延迟"
        fi
    fi
}

ping_test() {
    local ip="$1"
    local result="$(ping -c1 -W3 "$ip" 2>/dev/null | awk -F '/' 'END {print $5}')"
    echo "$ip,$result"
}


get_nearest_data() {
    local url="$1"
    local data=()
    local response
    if [[ -z "${CN}" || "${CN}" != true ]]; then
        local retries=0
        while [[ $retries -lt 2 ]]; do
            response=$(curl -sL --max-time 2 "$url")
            if [[ $? -eq 0 ]]; then
                break
            else
                retries=$((retries+1))
                sleep 1
            fi
        done
        if [[ $retries -eq 2 ]]; then
            url="${cdn_success_url}${url}"
            response=$(curl -sL --max-time 6 "$url")
        fi
    else
        url="${cdn_success_url}${url}"
        response=$(curl -sL --max-time 10 "$url")
    fi
    while read line; do
        if [[ -n "$line" ]]; then
            local id=$(echo "$line" | awk -F ',' '{print $1}')
            local city=$(echo "$line" | sed 's/ //g' | awk -F ',' '{print $4}')
            local ip=$(echo "$line" | awk -F ',' '{print $5}')
            if [[ "$id,$city,$ip" == "id,city,ip" ]]; then
                continue
            fi
            if [[ $url == *"Mobile"* ]]; then
                city="移动${city}"
            elif [[ $url == *"Telecom"* ]]; then
                city="电信${city}"
            elif [[ $url == *"Unicom"* ]]; then
                city="联通${city}" 
            fi
            data+=("$id,$city,$ip")
        fi
    done <<< "$response"
    
    rm -f /tmp/pingtest
    # 并行ping测试所有IP
    for (( i=0; i<${#data[@]}; i++ )); do
        { ip=$(echo "${data[$i]}" | awk -F ',' '{print $3}')
        ping_test "$ip" >> /tmp/pingtest; }&
    done
    wait
    
    # 取IP顺序列表results
    output=$(cat /tmp/pingtest)
    rm -f /tmp/pingtest
    IFS=$'\n' read -rd '' -a lines <<<"$output"
    results=()
    for line in "${lines[@]}"; do
        field=$(echo "$line" | cut -d',' -f1)
        results+=("$field")
    done

    # 比对data取IP对应的数组
    sorted_data=()
    for result in "${results[@]}"; do
        for item in "${data[@]}"; do
            if [[ "$item" == *"$result"* ]]; then
                id=$(echo "$item" | cut -d',' -f1)
                name=$(echo "$item" | cut -d',' -f2)
                sorted_data+=("$id,$name")
            fi
        done
    done
    sorted_data=("${sorted_data[@]:0:2}")

    # 返回结果
    echo "${sorted_data[@]}"
}

checknslookup() {
    _yellow "checking nslookup"
	if ! command -v nslookup &> /dev/null; then
        _yellow "Installing dnsutils"
	    ${PACKAGE_INSTALL[int]} dnsutils
	fi
}

get_ip_from_url() {
    nslookup -querytype=A $1 | awk '/^Name:/ {next;} /^Address: / { print $2 }'
}

get_nearest_data2() {
    local url="$1"
    local data=()
    local response
    if [[ -z "${CN}" || "${CN}" != true ]]; then
        local retries=0
        while [[ $retries -lt 2 ]]; do
            response=$(curl -sL --max-time 2 "$url")
            if [[ $? -eq 0 ]]; then
                break
            else
                retries=$((retries+1))
                sleep 1
            fi
        done
        if [[ $retries -eq 2 ]]; then
            url="${cdn_success_url}${url}"
            response=$(curl -sL --max-time 6 "$url")
        fi
    else
        url="${cdn_success_url}${url}"
        response=$(curl -sL --max-time 10 "$url")
    fi
    ip_list=()
    city_list=()
    while read line; do
        if [[ -n "$line" ]]; then
            # local id=$(echo "$line" | awk -F ',' '{print $1}')
            local city=$(echo "$line" | sed 's/ //g' | awk -F ',' '{print $9}')
            city=${city/市/}; city=${city/中国/}
            local host=$(echo "$line" | awk -F ',' '{print $6}')
            local host_url=$(echo $host | sed 's/:.*//')
            if [[ "$host,$city" == "host,city" || "$city" == *"香港"* || "$city" == *"台湾"* ]]; then
                continue
            fi
            if is_ipv4 "$host_url"; then
                local ip="$host_url"
            else
                local ip=$(get_ip_from_url ${host_url})
            fi
            if [[ $url == *"mobile"* ]]; then
                city="移动${city}"
            elif [[ $url == *"telecom"* ]]; then
                city="电信${city}"
            elif [[ $url == *"unicom"* ]]; then
                city="联通${city}" 
            fi
            if [[ ! " ${ip_list[@]} " =~ " ${ip} " ]] && [[ ! " ${city_list[@]} " =~ " ${city} " ]]; then
                data+=("$host,$city,$ip")
                ip_list+=("$ip")
                city_list+=("$city")
            fi
        fi
    done <<< "$response"
 
    rm -f /tmp/pingtest
    for (( i=0; i<${#data[@]}; i++ )); do
        { ip=$(echo "${ip_list[$i]}")
        ping_test "$ip" >> /tmp/pingtest; }&
    done
    wait
    
    output=$(cat /tmp/pingtest)
    rm -f /tmp/pingtest
    IFS=$'\n' read -rd '' -a lines <<<"$output"
    results=()
    for line in "${lines[@]}"; do
        field=$(echo "$line" | cut -d',' -f1)
        results+=("$field")
    done

    sorted_data=()
    for result in "${results[@]}"; do
        for item in "${data[@]}"; do
            if [[ "$(echo "$item" | cut -d ',' -f 3)" == "$result" ]]; then
# 	      if [[ "$item" == *"$result"* ]]; then
                host=$(echo "$item" | cut -d',' -f1)
                name=$(echo "$item" | cut -d',' -f2)
                sorted_data+=("$host,$name")
            fi
        done
    done
    sorted_data=("${sorted_data[@]:0:2}")

    echo "${sorted_data[@]}"
}

systemInfo_get_os_release() {
    if [ -f "/etc/centos-release" ]; then # CentOS
        Var_OSRelease="centos"
        if [ "$(rpm -qa | grep -o el6 | sort -u)" = "el6" ]; then
            Var_CentOSELRepoVersion="6"
            Var_OSReleaseVersion="$(cat /etc/centos-release | awk '{print $3}')"
        elif [ "$(rpm -qa | grep -o el7 | sort -u)" = "el7" ]; then
            Var_CentOSELRepoVersion="7"
            Var_OSReleaseVersion="$(cat /etc/centos-release | awk '{print $4}')"
        elif [ "$(rpm -qa | grep -o el8 | sort -u)" = "el8" ]; then
            Var_CentOSELRepoVersion="8"
            Var_OSReleaseVersion="$(cat /etc/centos-release | awk '{print $4}')"
        else
            local Var_CentOSELRepoVersion="unknown"
            Var_OSReleaseVersion="<Unknown Release>"
        fi
    elif [ -f "/etc/fedora-release" ]; then # Fedora
        Var_OSRelease="fedora"
        Var_OSReleaseVersion="$(cat /etc/fedora-release | awk '{print $3,$4,$5,$6,$7}')"
    elif [ -f "/etc/redhat-release" ]; then # RedHat
        Var_OSRelease="rhel"
        if [ "$(rpm -qa | grep -o el6 | sort -u)" = "el6" ]; then
            Var_RedHatELRepoVersion="6"
            Var_OSReleaseVersion="$(cat /etc/redhat-release | awk '{print $3}')"
        elif [ "$(rpm -qa | grep -o el7 | sort -u)" = "el7" ]; then
            Var_RedHatELRepoVersion="7"
            Var_OSReleaseVersion="$(cat /etc/redhat-release | awk '{print $4}')"
        elif [ "$(rpm -qa | grep -o el8 | sort -u)" = "el8" ]; then
            Var_RedHatELRepoVersion="8"
            Var_OSReleaseVersion="$(cat /etc/redhat-release | awk '{print $4}')"
        else
            local Var_RedHatELRepoVersion="unknown"
            Var_OSReleaseVersion="<Unknown Release>"
        fi
    elif [ -f "/etc/astra_version" ]; then # Astra
        Var_OSRelease="astra"
        local Var_OSReleaseVersionShort="$(cat /etc/debian_version | awk '{printf "%d\n",$1}')"
        if [ "${Var_OSReleaseVersionShort}" = "7" ]; then
            Var_OSReleaseVersion_Codename="wheezy"
        elif [ "${Var_OSReleaseVersionShort}" = "8" ]; then
            Var_OSReleaseVersion_Codename="jessie"
        elif [ "${Var_OSReleaseVersionShort}" = "9" ]; then
            Var_OSReleaseVersion_Codename="stretch"
        elif [ "${Var_OSReleaseVersionShort}" = "10" ]; then
            Var_OSReleaseVersion_Codename="buster"
        elif [ "${Var_OSReleaseVersionShort}" = "11" ]; then
            Var_OSReleaseVersion_Codename="bullseye"
        elif [ "${Var_OSReleaseVersionShort}" = "12" ]; then
            Var_OSReleaseVersion_Codename="bookworm"
        else
            Var_OSReleaseVersion_Codename="sid"
        fi
    elif [ -f "/etc/lsb-release" ]; then # Ubuntu
        Var_OSRelease="ubuntu"
        Var_OSReleaseVersion="$(cat /etc/os-release | awk -F '[= "]' '/VERSION/{print $3,$4,$5,$6,$7}' | head -n1)"
        cleaned_string=$(echo "$Var_OSReleaseVersion" | sed 's/[^0-9A-Za-z.]//g')
        if [[ "$cleaned_string" =~ \. ]]; then
            Var_OSReleaseVersion=${cleaned_string%%.*}
        else
            Var_OSReleaseVersion=${cleaned_string}
        fi
    elif [ -f "/etc/debian_version" ]; then # Debian
        Var_OSRelease="debian"
        local Var_OSReleaseVersion="$(cat /etc/debian_version | awk '{print $1}')"
        local Var_OSReleaseVersionShort="$(cat /etc/debian_version | awk '{printf "%d\n",$1}')"
        if [ "${Var_OSReleaseVersionShort}" = "7" ]; then
            Var_OSReleaseVersion_Codename="wheezy"
        elif [ "${Var_OSReleaseVersionShort}" = "8" ]; then
            Var_OSReleaseVersion_Codename="jessie"
        elif [ "${Var_OSReleaseVersionShort}" = "9" ]; then
            Var_OSReleaseVersion_Codename="stretch"
        elif [ "${Var_OSReleaseVersionShort}" = "10" ]; then
            Var_OSReleaseVersion_Codename="buster"
        elif [ "${Var_OSReleaseVersionShort}" = "11" ]; then
            Var_OSReleaseVersion_Codename="bullseye"
        elif [ "${Var_OSReleaseVersionShort}" = "12" ]; then
            Var_OSReleaseVersion_Codename="bookworm"
        else
            Var_OSReleaseVersion_Codename="sid"
        fi
    elif [ -f "/etc/alpine-release" ]; then # Alpine Linux
        Var_OSRelease="alpinelinux"
        Var_OSReleaseVersion="$(cat /etc/alpine-release | awk '{print $1}')"
    elif [ -f "/etc/almalinux-release" ]; then # almalinux
        Var_OSRelease="almalinux"
        Var_OSReleaseVersion="$(cat /etc/almalinux-release | awk '{print $3,$4,$5,$6,$7}')"
    elif [ -f "/etc/arch-release" ]; then # archlinux
        Var_OSRelease="arch"
    elif [ -f "/etc/freebsd-update.conf" ] && [ -d "/usr/src" ]; then # freebsd
        Var_OSRelease="freebsd"
    else
        Var_OSRelease="unknown" # 未知系统分支
    fi
    if [ -f /etc/os-release ]; then
        DISTRO=$(grep 'PRETTY_NAME' /etc/os-release | cut -d '"' -f 2)
    fi
}

# =============== 检查 SysBench 组件 ===============
GetOSRelease() {
  local OS_TYPE
  case "${Var_OSRelease}" in
    centos|rhel|almalinux) OS_TYPE="redhat";;
    ubuntu) OS_TYPE="ubuntu";;
    debian|astra) OS_TYPE="debian";;
    fedora) OS_TYPE="fedora";;
    alpinelinux) OS_TYPE="alpinelinux";;
    arch) OS_TYPE="arch";;
    freebsd) OS_TYPE="freebsd";;
    *) OS_TYPE="unknown";;
  esac
  echo "${OS_TYPE}"
}

InstallSysbench() {
  local os_release=$1
  case "$os_release" in
    redhat) yum -y install epel-release && yum -y install sysbench ;;
    ubuntu) ! apt-get install sysbench -y && apt-get --fix-broken install -y && apt-get install sysbench -y ;;
    debian)
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
      ! apt-get install sysbench -y && apt-get --fix-broken install -y && apt-get install sysbench -y
      popd
      if [ ! -f "/usr/bin/sysbench" ] && [ ! -f "/usr/local/bin/sysbench" ]; then
        echo -e "${Msg_Warning}Sysbench Module Install Failed!"
      fi ;;
    fedora) dnf -y install sysbench ;;
    arch) pacman -S --needed --noconfirm sysbench ;;
    freebsd) pkg install -y sysbench ;;
    alpinelinux) echo -e "${Msg_Warning}Sysbench Module not found, installing ..." && echo -e "${Msg_Warning}SysBench Current not support Alpine Linux, Skipping..." && Var_Skip_SysBench="1" ;;
    *) echo "Error: Unknown OS release: $os_release" && exit 1 ;;
  esac
}

Check_SysBench() {
  if [ ! -f "/usr/bin/sysbench" ] && [ ! -f "/usr/local/bin/sysbench" ]; then
    local os_release=$(GetOSRelease)
    if [ "$os_release" = "alpinelinux" ]; then
      Var_Skip_SysBench="1"
    else
        if [ "$os_release" = "astra" ]; then
            InstallSysbench "debian"
        else
            InstallSysbench "$os_release"
        fi
    fi
  fi
  # 垂死挣扎 (尝试编译安装)
  if [ ! -f "/usr/bin/sysbench" ] && [ ! -f "/usr/local/bin/sysbench" ]; then
    echo -e "${Msg_Warning}Sysbench Module install Failure, trying compile modules ..."
    Check_Sysbench_InstantBuild
  fi
  # 最终检测
  if [ ! -f "/usr/bin/sysbench" ] && [ ! -f "/usr/local/bin/sysbench" ]; then
    echo -e "${Msg_Error}SysBench Moudle install Failure! Try Restart Bench or Manually install it! (/usr/bin/sysbench)"
    exit 1
  fi
}

Check_Sysbench_InstantBuild() {
    if [ "${Var_OSRelease}" = "centos" ] || [ "${Var_OSRelease}" = "rhel" ] || [ "${Var_OSRelease}" = "almalinux" ] || [ "${Var_OSRelease}" = "ubuntu" ] || [ "${Var_OSRelease}" = "debian" ] || [ "${Var_OSRelease}" = "fedora" ] || [ "${Var_OSRelease}" = "arch" ] || [ "${Var_OSRelease}" = "astra" ]; then
        local os_sysbench=${Var_OSRelease}
        if [ "$os_sysbench" = "astra" ]; then
            os_sysbench="debian"
        fi
        echo -e "${Msg_Info}Release Detected: ${os_sysbench}"
        echo -e "${Msg_Info}Preparing compile enviorment ..."
        prepare_compile_env "${os_sysbench}"
        echo -e "${Msg_Info}Downloading Source code (Version 1.0.20)..."
        mkdir -p /tmp/_LBench/src/
        pre_download sysbench
        mv ${TEMP_DIR}/sysbench-1.0.20 /tmp/_LBench/src/
        echo -e "${Msg_Info}Compiling Sysbench Module ..."
        cd /tmp/_LBench/src/sysbench-1.0.20
        ./autogen.sh && ./configure --without-mysql && make -j8 && make install
        echo -e "${Msg_Info}Cleaning up ..."
        cd /tmp && rm -rf /tmp/_LBench/src/sysbench*
    else
        echo -e "${Msg_Warning}Unsupported operating system: ${Var_OSRelease}"
    fi
}

prepare_compile_env() {
    local system="$1"
    if [ "${system}" = "centos" ] || [ "${system}" = "rhel" ] || [ "${system}" = "almalinux" ]; then
        yum install -y epel-release
        yum install -y wget curl make gcc gcc-c++ make automake libtool pkgconfig libaio-devel
    elif [ "${system}" = "ubuntu" ] || [ "${system}" = "debian" ]; then
        ! apt-get update &&  apt-get --fix-broken install -y && apt-get update
        ! apt-get -y install --no-install-recommends curl wget make automake libtool pkg-config libaio-dev unzip && apt-get --fix-broken install -y && apt-get -y install --no-install-recommends curl wget make automake libtool pkg-config libaio-dev unzip
    elif [ "${system}" = "fedora" ]; then
        dnf install -y wget curl gcc gcc-c++ make automake libtool pkgconfig libaio-devel
    elif [ "${system}" = "arch" ]; then
        pacman -S --needed --noconfirm wget curl gcc gcc make automake libtool pkgconfig libaio lib32-libaio
    else
        echo -e "${Msg_Warning}Unsupported operating system: ${system}"
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
        if [ -z "$TestScore" ]; then
            TestScore=$(echo "${TestResult}" | grep -oE "total number of events:\s+[0-9]+" | awk '{print $NF}' | awk -v time="$(echo "${TestResult}" | grep -oE "total time:\s+[0-9.]+[a-z]*" | awk '{print $NF}')" '{printf "%.2f\n", $0 / time}')
        fi
        local TotalScore="$(echo "${TotalScore} ${TestScore}" | awk '{printf "%d",$1+$2}')"
        let count=count+1
        local TestResult=""
        local TestScore="0"
    done
    local ResultScore="$(echo "${TotalScore} ${maxtestcount}" | awk '{printf "%d",$1/$2}')"
    if [ "$1" = "1" ]; then
        if [ "$ResultScore" -eq "0" ] || ([ "$1" -lt "2" ] && [ "$ResultScore" -gt "100000" ]); then
            echo -e "\r ${Font_Yellow}$4: ${Font_Suffix}\t\t${Font_Red}sysbench测试失效，请使用本脚本选项6中的gb4或gb5测试${Font_Suffix}"
            echo -e " $4:\t\tsysbench测试失效，请使用本脚本选项6中的gb4或gb5测试" >>${WorkDir}/SysBench/CPU/result.txt
        else
            echo -e "\r ${Font_Yellow}$4: ${Font_Suffix}\t\t${Font_SkyBlue}${ResultScore}${Font_Suffix} ${Font_Yellow}Scores${Font_Suffix}"
            echo -e " $4:\t\t\t${ResultScore} Scores" >>${WorkDir}/SysBench/CPU/result.txt
        fi
    elif [ "$1" -ge "2" ]; then
        if [ "$ResultScore" -eq "0" ] || ([ "$1" -lt "2" ] && [ "$ResultScore" -gt "100000" ]); then
            echo -e "\r ${Font_Yellow}$4: ${Font_Suffix}\t\t${Font_Red}sysbench测试失效，请使用本脚本选项5中的gb4或gb5测试${Font_Suffix}"
            echo -e " $4:\t\tsysbench测试失效，请使用本脚本选项5中的gb4或gb5测试" >>${WorkDir}/SysBench/CPU/result.txt
        else
            echo -e "\r ${Font_Yellow}$4: ${Font_Suffix}\t\t${Font_SkyBlue}${ResultScore}${Font_Suffix} ${Font_Yellow}Scores${Font_Suffix}"
            echo -e " $4:\t\t${ResultScore} Scores" >>${WorkDir}/SysBench/CPU/result.txt
        fi
    fi
}

Function_SysBench_CPU_Fast() {
    cd $myvar >/dev/null 2>&1
    mkdir -p ${WorkDir}/SysBench/CPU/ >/dev/null 2>&1
    echo -e " ${Font_Yellow}-> CPU 测试中 (Fast Mode, 1-Pass @ 5sec)${Font_Suffix}"
    echo -e " -> CPU 测试中 (Fast Mode, 1-Pass @ 5sec)\n" >>${WorkDir}/SysBench/CPU/result.txt
    Run_SysBench_CPU "1" "5" "1" "1 线程测试(1核)得分"
    sleep 1
    if [ "${LBench_Result_CPUThreadNumber}" -ge "2" ]; then
        Run_SysBench_CPU "${LBench_Result_CPUThreadNumber}" "5" "1" "${LBench_Result_CPUThreadNumber} 线程测试(多核)得分"
    elif [ "${LBench_Result_CPUProcessorNumber}" -ge "2" ]; then
        Run_SysBench_CPU "${LBench_Result_CPUProcessorNumber}" "5" "1" "${LBench_Result_CPUProcessorNumber} 线程测试(多核)得分"
    fi
}

# =============== SystemInfo模块 部分 ===============
SystemInfo_GetCPUInfo() {
    mkdir -p ${WorkDir}/data >/dev/null 2>&1
    if [ -f "/proc/cpuinfo" ]; then
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
    else
        $sysctl_path -a >${WorkDir}/data/sysctl_info
        local ReadCPUInfo="cat ${WorkDir}/data/sysctl_info"
        LBench_Result_CPUModelName="$($ReadCPUInfo 2>/dev/null | awk -F ': ' '/hw.model/{print $2}' | sort -u)"
        LBench_Result_CPUFreqMHz="$($ReadCPUInfo 2>/dev/null | awk -F ': ' '/dev.cpu.0.freq/{print $2}')"
        LBench_Result_CPUCacheSize="$($ReadCPUInfo 2>/dev/null | awk -F ': ' '/hw.cacheconfig/{print $2}')"
        LBench_Result_CPUFreqGHz="$(echo $LBench_Result_CPUFreqMHz | awk '{printf "%.2f\n",$1/1000}')"
        LBench_Result_CPUPhysicalNumber="$($ReadCPUInfo 2>/dev/null | awk -F ': ' '/hw.physicalcpu/{print $2}')"
        LBench_Result_CPUCoreNumber="$($ReadCPUInfo 2>/dev/null | awk -F ': ' '/hw.ncpu/{print $2}')"
        LBench_Result_CPUThreadNumber="$($ReadCPUInfo 2>/dev/null | awk -F ': ' '/hw.ncpu/{print $2}')"
        LBench_Result_CPUProcessorNumber="$($ReadCPUInfo 2>/dev/null | awk -F ': ' '/hw.ncpu/{print $2}')"
        LBench_Result_CPUSiblingsNumber="$($ReadCPUInfo 2>/dev/null | awk -F ': ' '/hw.smt/{print $2}')"
        LBench_Result_CPUTotalCoreNumber="$($ReadCPUInfo 2>/dev/null | awk -F ': ' '/hw.ncpu/{print $2}')"

        # 虚拟化能力检测
        SystemInfo_GetVirtType
        if [ "${Var_VirtType}" = "dedicated" ] || [ "${Var_VirtType}" = "wsl" ]; then
            LBench_Result_CPUIsPhysical="1"
            local VirtCheck="$($sysctl_path -a | grep -E 'hw.vmx|hw.svm' | uniq)"
            if [ "${VirtCheck}" != "" ]; then
                LBench_Result_CPUVirtualization="1"
                LBench_Result_CPUVirtualizationType="Native"
            else
                LBench_Result_CPUVirtualization="0"
            fi
        elif [ "${Var_VirtType}" = "kvm" ] || [ "${Var_VirtType}" = "hyperv" ] || [ "${Var_VirtType}" = "microsoft" ] || [ "${Var_VirtType}" = "vmware" ]; then
            LBench_Result_CPUIsPhysical="0"
            local VirtCheck="$($sysctl_path -a | grep -E 'hw.vmx|hw.svm' | uniq)"
            if [ "${VirtCheck}" != "" ]; then
                LBench_Result_CPUVirtualization="2"
                LBench_Result_CPUVirtualizationType="${Var_VirtType}"
            else
                LBench_Result_CPUVirtualization="0"
            fi
        else
            LBench_Result_CPUIsPhysical="0"
        fi
    fi
}

Function_ReadCPUStat() {
    if [ "$1" == "" ]; then
        echo -n "nil"
    else
        local result="$(echo $1 | grep -oE "[0-9]{1,2}.[0-9]{1} $2" | awk '{print $1}')"
        echo $result
    fi
}

get_system_bit() {
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

SystemInfo_GetVirtType() {
    if [ -f "/usr/bin/systemd-detect-virt" ]; then
        Var_VirtType="$(/usr/bin/systemd-detect-virt)"
        # 虚拟机检测
        case "${Var_VirtType}" in
            "*qemu*") LBench_Result_VirtType="QEMU" ;;
            "*kvm*") LBench_Result_VirtType="KVM" ;;
            "*zvm*") LBench_Result_VirtType="S390 Z/VM" ;;
            "*vmware*") LBench_Result_VirtType="VMware" ;;
            "*microsoft*") LBench_Result_VirtType="Microsoft Hyper-V" ;;
            "*xen*") LBench_Result_VirtType="Xen Hypervisor" ;;
            "*bochs*") LBench_Result_VirtType="BOCHS" ;;
            "*uml*") LBench_Result_VirtType="User-mode Linux" ;;
            "*parallels*") LBench_Result_VirtType="Parallels" ;;
            "*bhyve*") LBench_Result_VirtType="FreeBSD Hypervisor" ;;
            "*openvz*") LBench_Result_VirtType="OpenVZ" ;;
            "lxc") LBench_Result_VirtType="LXC" ;;
            "lxc-libvirt") LBench_Result_VirtType="LXC (libvirt)" ;;
            "*systemd-nspawn*") LBench_Result_VirtType="Systemd nspawn" ;;
            "*docker*") LBench_Result_VirtType="Docker" ;;
            "*rkt*") LBench_Result_VirtType="RKT" ;;
            "none")
                sleep 1
                Var_VirtType="$(/usr/bin/systemd-detect-virt)"
                LBench_Result_VirtType="None"
                local Var_BIOSVendor="$(dmidecode -s bios-vendor)"
                if [ "${Var_BIOSVendor}" = "SeaBIOS" ]; then
                    Var_VirtType="Unknown"
                    LBench_Result_VirtType="Unknown with SeaBIOS BIOS"
                else
                    Var_VirtType="dedicated"
                    LBench_Result_VirtType="Dedicated with ${Var_BIOSVendor} BIOS"
                fi
                ;;
            *)
                if [ -c "/dev/lxss" ]; then
                    Var_VirtType="wsl"
                    LBench_Result_VirtType="Windows Subsystem for Linux (WSL)"
                fi
                ;;
        esac
    elif [ -f "/.dockerenv" ]; then # 处理Docker虚拟化
        Var_VirtType="docker"
        LBench_Result_VirtType="Docker"
    elif [ -c "/dev/lxss" ]; then # 处理WSL虚拟化
        Var_VirtType="wsl"
        LBench_Result_VirtType="Windows Subsystem for Linux (WSL)"
    elif $sysctl_path kern.vm_guest >/dev/null 2>&1 && Var_VirtType=$($sysctl_path -n kern.vm_guest 2>/dev/null); then
        LBench_Result_VirtType="Virtualization platform: $Var_VirtType"
    elif $sysctl_path -a | grep hw.vmm >/dev/null 2>&1 && Var_VirtType=$($sysctl_path -n hw.vmm 2>/dev/null); then
        LBench_Result_VirtType="Virtualization platform: $Var_VirtType"
    elif [ ! -f "/usr/sbin/virt-what" ] && [ ! -f "/usr/local/sbin/virt-what" ]; then
        Var_VirtType="Unknown"
        LBench_Result_VirtType="[Error: virt-what not found !]"
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

speed_test2() {
    local nodeName="$2"
    if [ ! -f "./speedtest-cli/speedtest" ]; then
        if [ -z "$1" ]; then
            ./speedtest-cli/speedtest-go > ./speedtest-cli/speedtest.log 2>&1
        else
            ./speedtest-cli/speedtest-go --custom-url=http://"$1"/upload.php > ./speedtest-cli/speedtest.log 2>&1
        fi
        if [ $? -eq 0 ]; then
            local dl_speed=$(grep -oP 'Download: \K[\d\.]+' ./speedtest-cli/speedtest.log)
            local up_speed=$(grep -oP 'Upload: \K[\d\.]+' ./speedtest-cli/speedtest.log)
            local latency=$(grep -oP 'Latency: \K[\d\.]+' ./speedtest-cli/speedtest.log)
            if [[ -n "${latency}" && "${latency}" == *.* ]]; then
                latency=$(awk '{printf "%.2f", $1}' <<< "${latency}")
            fi
            if [[ -n "${dl_speed}" || -n "${up_speed}" || -n "${latency}" ]]; then
                if [[ $selection =~ ^[1-5]$ ]]; then
                    echo -e "\r${nodeName}\t ${up_speed} Mbps\t ${dl_speed} Mbps\t ${latency}\t"
                else
                    length=$(get_string_length "$nodeName")
                    if [ $length -ge 8 ]; then
		    	echo -e "\r${nodeName}\t ${up_speed} Mbps\t ${dl_speed} Mbps\t ${latency}\t"
                    else
		    	echo -e "\r${nodeName}\t\t ${up_speed} Mbps\t ${dl_speed} Mbps\t ${latency}\t"
                    fi
                fi
            fi
        fi
    fi
}

speed() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
    temp_head
    speed_test '' 'Speedtest.net'
    test_list "${ls_sg_hk_jp[@]}"
    test_list "${CN_Unicom[@]}"
    test_list "${CN_Telecom[@]}"
    if [ ${#CN_Mobile[@]} -eq 0 ]; then
        echo -n "该运营商.net的节点列表为空，正在替换为.cn的节点列表。。。"
        CN=true
        if [ -f "./speedtest-cli/speedtest" ]; then
            rm -rf ./speedtest-cli/speedtest
            ( install_speedtest > /dev/null 2>&1 )
        fi
        checknslookup > /dev/null 2>&1
        CN_Mobile=($(get_nearest_data2 "${SERVER_BASE_URL2}/mobile.csv")) > /dev/null 2>&1
        wait
        if [ ${#CN_Mobile[@]} -eq 0 ]; then
            return
        else
            unset -f speed_test
            speed_test() { speed_test2 "$@"; }
            echo -en "\r测速中                                                        \r"
            test_list "${CN_Mobile[@]}"
        fi
    else
        test_list "${CN_Mobile[@]}"
    fi
}

speed2() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
    temp_head
    speed_test '' 'Speedtest.net'
    test_list "${CN_Unicom[0]}"
    test_list "${CN_Telecom[0]}"
    if [ ${#CN_Mobile[@]} -eq 0 ]; then
        echo -n "该运营商.net的节点列表为空，正在替换为.cn的节点列表。。。"
        CN=true
        if [ -f "./speedtest-cli/speedtest" ]; then
            rm -rf ./speedtest-cli/speedtest
            ( install_speedtest > /dev/null 2>&1 )
        fi
        checknslookup > /dev/null 2>&1
        CN_Mobile=($(get_nearest_data2 "${SERVER_BASE_URL2}/mobile.csv")) > /dev/null 2>&1
        wait
        if [ ${#CN_Mobile[@]} -eq 0 ]; then
            return
        else
            unset -f speed_test
            speed_test() { speed_test2 "$@"; }
            echo -en "\r测速中                                                         "
            test_list "${CN_Mobile[0]}"
        fi
    else
        test_list "${CN_Mobile[0]}"
    fi
}

# =============== 磁盘测试 部分 ===============
Run_DiskTest_DD() {
    # 调用方式: Run_DiskTest_DD "测试文件名" "块大小" "写入次数" "测试项目名称"
    mkdir -p ${WorkDir}/DiskTest/ >/dev/null 2>&1
    mkdir -p /.tmp_LBench/DiskTest >/dev/null 2>&1
    mkdir -p ${WorkDir}/data >/dev/null 2>&1
    local Var_DiskTestResultFile="${WorkDir}/data/disktest_result"
    # 将先测试读, 后测试写
    echo -n -e " $4\t\t->\c"
    # 清理缓存, 避免影响测试结果
    sync
    if [ "${Var_VirtType}" != "docker" ] && [ "${Var_VirtType}" != "openvz" ] && [ "${Var_VirtType}" != "lxc" ] && [ "${Var_VirtType}" != "wsl" ]; then
        echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1
    fi
    # 避免磁盘压力过高, 启动测试前暂停1s
    sleep 1
    # 正式写测试
    dd if=/dev/zero of=/.tmp_LBench/DiskTest/$1 bs=$2 count=$3 oflag=direct 2>${Var_DiskTestResultFile}
    local DiskTest_WriteSpeed_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,4} kB/s|[0-9]{1,4}.[0-9]{1,2} kB/s|[0-9]{1,4} KB/s|[0-9]{1,4}.[0-9]{1,2} KB/s|[0-9]{1,4} MB/s|[0-9]{1,4}.[0-9]{1,2} MB/s|[0-9]{1,4} GB/s|[0-9]{1,4}.[0-9]{1,2} GB/s|[0-9]{1,4} TB/s|[0-9]{1,4}.[0-9]{1,2} TB/s|[0-9]{1,4} kB/秒|[0-9]{1,4}.[0-9]{1,2} kB/秒|[0-9]{1,4} KB/秒|[0-9]{1,4}.[0-9]{1,2} KB/秒|[0-9]{1,4} MB/秒|[0-9]{1,4}.[0-9]{1,2} MB/秒|[0-9]{1,4} GB/秒|[0-9]{1,4}.[0-9]{1,2} GB/秒|[0-9]{1,4} TB/秒|[0-9]{1,4}.[0-9]{1,2} TB/秒")"
    DiskTest_WriteSpeed="$(echo "${DiskTest_WriteSpeed_ResultRAW}" | sed "s/秒/s/")"
    local DiskTest_WriteTime_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,}.[0-9]{1,} s|[0-9]{1,}.[0-9]{1,} s|[0-9]{1,}.[0-9]{1,} 秒|[0-9]{1,}.[0-9]{1,} 秒")"
    DiskTest_WriteTime="$(echo ${DiskTest_WriteTime_ResultRAW} | awk '{print $1}')"
    DiskTest_WriteIOPS=$(awk -v t="${DiskTest_WriteTime}" -v c="${3}" 'BEGIN{ printf "%.0f\n", c / t }')
    DiskTest_WritePastTime="$(echo ${DiskTest_WriteTime} | awk '{printf "%.2f\n",$1}')"
    if [ ${DiskTest_WriteIOPS} -ge 10000 ]; then
        DiskTest_WriteIOPS=$(awk -v i="${DiskTest_WriteIOPS}" 'BEGIN{ printf "%.2f\n", i / 1000 }')
        echo -n -e "\r $4\t\t${Font_SkyBlue}${DiskTest_WriteSpeed} (${DiskTest_WriteIOPS}K IOPS, ${DiskTest_WritePastTime}s)${Font_Suffix}\t\t->\c"
    else
        echo -n -e "\r $4\t\t${Font_SkyBlue}${DiskTest_WriteSpeed} (${DiskTest_WriteIOPS} IOPS, ${DiskTest_WritePastTime}s)${Font_Suffix}\t\t->\c"
    fi
    # 清理结果文件, 准备下一次测试
    rm -f ${Var_DiskTestResultFile}
    # 清理缓存, 避免影响测试结果
    sync
    if [ "${Var_VirtType}" != "docker" ] && [ "${Var_VirtType}" != "wsl" ]; then
        if [ -w /proc/sys/vm/drop_caches ]; then
            echo 3 >/proc/sys/vm/drop_caches > /dev/null 2>&1
        fi
    fi
    sleep 0.5
    # 正式读测试
    dd if=/.tmp_LBench/DiskTest/$1 of=/dev/null bs=$2 count=$3 iflag=direct 2>${Var_DiskTestResultFile}
    local DiskTest_ReadSpeed_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,4} kB/s|[0-9]{1,4}.[0-9]{1,2} kB/s|[0-9]{1,4} KB/s|[0-9]{1,4}.[0-9]{1,2} KB/s|[0-9]{1,4} MB/s|[0-9]{1,4}.[0-9]{1,2} MB/s|[0-9]{1,4} GB/s|[0-9]{1,4}.[0-9]{1,2} GB/s|[0-9]{1,4} TB/s|[0-9]{1,4}.[0-9]{1,2} TB/s|[0-9]{1,4} kB/秒|[0-9]{1,4}.[0-9]{1,2} kB/秒|[0-9]{1,4} KB/秒|[0-9]{1,4}.[0-9]{1,2} KB/秒|[0-9]{1,4} MB/秒|[0-9]{1,4}.[0-9]{1,2} MB/秒|[0-9]{1,4} GB/秒|[0-9]{1,4}.[0-9]{1,2} GB/秒|[0-9]{1,4} TB/秒|[0-9]{1,4}.[0-9]{1,2} TB/秒")"
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
    if [ "${Var_VirtType}" = "docker" ] || [ "${Var_VirtType}" = "wsl" ]; then
        echo -e " ${Msg_Warning}Due to virt architecture limit, the result may affect by the cache !"
    fi
    echo -e " ${Font_Yellow}测试操作\t\t写速度\t\t\t\t\t读速度${Font_Suffix}"
    echo -e " Test Name\t\tWrite Speed\t\t\t\tRead Speed" >>${WorkDir}/DiskTest/result.txt
    Run_DiskTest_DD "100MB.test" "4k" "25600" "100MB-4K Block"
    Run_DiskTest_DD "1GB.test" "1M" "1000" "1GB-1M Block"
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
        local TestScore="$(echo "${TestResult}" | grep -oE "[0-9]{1,}.[0-9]{1,2} ops/sec|[0-9]{1,}.[0-9]{1,2} per second" | grep -oE "[0-9]{1,}.[0-9]{1,2}")"
        local TestSpeed="$(echo "${TestResult}" | grep -oE "[0-9]{1,}.[0-9]{1,2} MB/sec|[0-9]{1,}.[0-9]{1,2} MiB/sec" | grep -oE "[0-9]{1,}.[0-9]{1,2}")"
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
    sleep 0.5
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
        [ "`echo ${size:(-1)}`" == "E" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' * 1024 * 1024}' )
        total_size=$( awk 'BEGIN{printf "%.1f", '$total_size' + '$size'}' )
    done
    echo ${total_size}
}

check_virt(){
    _exists "dmesg" && virtualx="$(dmesg 2>/dev/null)"
    if _exists "dmidecode"; then
        output="$(dmidecode -s system-manufacturer -s system-product-name -s system-version 2>/dev/null)"
        sys_manu="$(echo "$output" | sed -n 1p)"
        sys_product="$(echo "$output" | sed -n 2p)"
        sys_ver="$(echo "$output" | sed -n 3p)"
    else
        sys_manu=""
        sys_product=""
        sys_ver=""
    fi
    if grep -qa docker /proc/1/cgroup || grep -qa lxc /proc/1/cgroup || grep -qa container=lxc /proc/1/environ; then
        virt="LXC"
    elif [ -f "/.dockerenv" ] || grep -q -E '(docker|rkt)' /proc/1/cgroup; then
        virt="Docker"
    elif [[ -f /proc/user_beancounters ]]; then
        virt="OpenVZ"
    elif [[ "${virtualx}" == *kvm-clock* ]]; then
        virt="KVM"
    elif [[ "${cname}" == *KVM* ]] || [[ "${cname}" == *QEMU* ]]; then
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
    elif [[ -f "/sys/hypervisor/type" ]] && grep -q "xen" "/sys/hypervisor/type"; then
        virt="Xen"
    elif [[ "${sys_manu}" == *"Microsoft Corporation"* ]] && [[ "${sys_product}" == *"Virtual Machine"* ]]; then
        if [[ "${sys_ver}" == *"7.0"* || "${sys_ver}" == *"Hyper-V" ]]; then
            virt="Hyper-V"
        else
            virt="Microsoft Virtual Machine"
        fi
    else
        SystemInfo_GetVirtType
        virt="${Var_VirtType}"
    fi
}

check_ipv4(){
  # 遍历本机可以使用的 IP API 服务商
  # 定义可能的 IP API 服务商
  API_NET=("ip.sb" "ipget.net" "ip.ping0.cc" "https://ip4.seeip.org" "https://api.my-ip.io/ip" "https://ipv4.icanhazip.com" "api.ipify.org")

  # 遍历每个 API 服务商，并检查它是否可用
  for p in "${API_NET[@]}"; do
    # 使用 curl 请求每个 API 服务商
    response=$(curl -s4m8 "$p")
    sleep 1
    # 检查请求是否失败，或者回传内容中是否包含 error
    if [ $? -eq 0 ] && ! echo "$response" | grep -q "error"; then
      # 如果请求成功且不包含 error，则设置 IP_API 并退出循环
      IP_API="$p"
      IPV4=$(curl -s4m8 "$IP_API")
      break
    fi
  done
  export IPV4
}

get_longest_first_element() {
    # 获取一个列表中最长的元素 - 信息最多的
    local list=("$@")
    local longest_element="${list[0]}"
    for element in "${list[@]}"; do
        if [[ ${#element} -gt ${#longest_element} ]]; then
            longest_element=$element
        fi
    done
    echo "$longest_element"
}

check_ip_info_by_cloudflare(){
    # cloudflare.com
    rm -rf /tmp/cloudflare
    # 获取 IPv4 信息
    local ipv4_output=$(curl -ksL4m6 -A Mozilla https://speed.cloudflare.com/meta 2>/dev/null)
    # 提取 IPv4 的 asn、asOrganization、city 和 region
    local ipv4_asn=$(echo "$ipv4_output" | grep -oE '"asn":[0-9]+' | grep -oE '[0-9]+')
    local ipv4_as_organization=$(echo "$ipv4_output" | grep -oE '"asOrganization":"[^"]+"' | grep -oE '":"[^"]+"' | sed 's/":"//g')
    local ipv4_city=$(echo "$ipv4_output" | grep -oE '"city":"[^"]+"' | grep -oE '":"[^"]+"' | sed 's/":"//g')
    local ipv4_region=$(echo "$ipv4_output" | grep -oE '"region":"[^"]+"' | grep -oE '":"[^"]+"' | sed 's/":"//g')
    if [ -n "$ipv4_asn" ] && [ -n "$ipv4_as_organization" ] && [ -n "$ipv4_city" ] && [ -n "$ipv4_region" ]; then
        local ipv4_asn_info="AS${ipv4_asn::-1} ${ipv4_as_organization::-1}"
        local ipv4_location="${ipv4_city::-1} / ${ipv4_region::-1}"
    else
        local ipv4_asn_info="None"
        local ipv4_location="None"
    fi
    # 返回结果
    echo "$ipv4_asn_info" >> /tmp/cloudflare
    echo "$ipv4_location" >> /tmp/cloudflare
    # 获取 IPv6 信息
    sleep 1
    local ipv6_output=$(curl -ksL6m6 -A Mozilla https://speed.cloudflare.com/meta 2>/dev/null)
    # 提取 IPv6 的 asn、asOrganization、city 和 region
    local ipv6_asn=$(echo "$ipv6_output" | grep -oE '"asn":[0-9]+' | grep -oE '[0-9]+')
    local ipv6_as_organization=$(echo "$ipv6_output" | grep -oE '"asOrganization":"[^"]+"' | grep -oE '":"[^"]+"' | sed 's/":"//g')
    local ipv6_city=$(echo "$ipv6_output" | grep -oE '"city":"[^"]+"' | grep -oE '":"[^"]+"' | sed 's/":"//g')
    local ipv6_region=$(echo "$ipv6_output" | grep -oE '"region":"[^"]+"' | grep -oE '":"[^"]+"' | sed 's/":"//g')
    if [ -n "$ipv6_asn" ] && [ -n "$ipv6_as_organization" ] && [ -n "$ipv6_city" ] && [ -n "$ipv6_region" ]; then
        local ipv6_asn_info="AS${ipv6_asn::-1} ${ipv6_as_organization::-1}"
        local ipv6_location="${ipv6_city::-1} / ${ipv6_region::-1}"
    else
        local ipv6_asn_info="None"
        local ipv6_location="None"
    fi
    # 返回结果
    echo "$ipv6_asn_info" >> /tmp/cloudflare
    echo "$ipv6_location" >> /tmp/cloudflare
}

check_ip_info_by_ipinfo(){
    # ipinfo.io
    rm -rf /tmp/ipinfo
    # 获取IPv4的asn、city、region、country
    local ipv4_asn=$(curl -ksL4m6 -A Mozilla ipinfo.io/org 2>/dev/null)
    sleep 1
    local ipv4_city=$(curl -ksL4m6 -A Mozilla ipinfo.io/city 2>/dev/null)
    sleep 1
    local ipv4_region=$(curl -ksL4m6 -A Mozilla ipinfo.io/region 2>/dev/null)
    sleep 1
    local ipv4_country=$(curl -ksL4m6 -A Mozilla ipinfo.io/country 2>/dev/null)
    if [ -n "$ipv4_asn" ] && [ -n "$ipv4_city" ] && [ -n "$ipv4_country" ]; then
        local ipv4_asn_info="${ipv4_asn}"
        local ipv4_location="${ipv4_city} / ${ipv4_region} / ${ipv4_country}"
    elif [[ -n $ipv4_asn && -n $ipv4_city && -n $ipv4_region ]]; then
        local ipv4_asn_info="${ipv4_asn}"
        local ipv4_location="${ipv4_city} / ${ipv4_region}"
    else
        local ipv4_asn_info="None"
        local ipv4_location="None"
    fi
    # 返回结果
    echo "$ipv4_asn_info" >> /tmp/ipinfo
    echo "$ipv4_location" >> /tmp/ipinfo
    # 获取IPv6的asn、city和region - 无 - 该站点不支持IPV6网络识别
    local ipv6_asn_info="None"
    local ipv6_location="None"
    # 返回结果
    echo "$ipv6_asn_info" >> /tmp/ipinfo
    echo "$ipv6_location" >> /tmp/ipinfo
}

check_ip_info_by_ipsb(){
    # ip.sb
    rm -rf /tmp/ipsb
    local result_ipv4=$(curl -ksL4m6 -A Mozilla https://api.ip.sb/geoip 2>/dev/null)
    # 获取IPv4的asn、city、region、country
    if [ -n "$result_ipv4" ]; then
        local ipv4_asn=$(expr "$result_ipv4" : '.*asn\":[ ]*\([0-9]*\).*')
        local ipv4_as_organization=$(expr "$result_ipv4" : '.*isp\":[ ]*\"\([^"]*\).*')
        local ipv4_city=$(echo $result_ipv4 | grep -oE '"city":"[^"]+"' | cut -d ":" -f2 | tr -d '"')
        local ipv4_region=$(echo $result_ipv4 | grep -oE '"region":"[^"]+"' | cut -d ":" -f2 | tr -d '"')
        local ipv4_country=$(echo "$result_ipv4" | grep -oP '(?<="country":")[^"]*')
        if [ -n "$ipv4_asn" ] && [ -n "$ipv4_as_organization" ] && [ -n "$ipv4_city" ] && [ -n "$ipv4_region" ] && [ -n "$ipv4_country" ]; then
            local ipv4_asn_info="AS${ipv4_asn} ${ipv4_as_organization}"
            local ipv4_location="${ipv4_city} / ${ipv4_region} / ${ipv4_country}"
        else
            local ipv4_asn_info="None"
            local ipv4_location="None"
        fi
    else
        local ipv4_asn_info="None"
        local ipv4_location="None"
    fi
    # 返回结果
    echo "$ipv4_asn_info" >> /tmp/ipsb
    echo "$ipv4_location" >> /tmp/ipsb
    # 获取IPv6的asn、city、region、country
    sleep 1
    local result_ipv6=$(curl -ksL6m6 -A Mozilla https://api.ip.sb/geoip 2>/dev/null)
    if [ -n "$result_ipv6" ]; then
        local ipv6_asn=$(expr "$result_ipv6" : '.*asn\":[ ]*\([0-9]*\).*')
        local ipv6_as_organization=$(expr "$result_ipv6" : '.*isp\":[ ]*\"\([^"]*\).*')
        local ipv6_city=$(echo $result_ipv6 | grep -oE '"city":"[^"]+"' | cut -d ":" -f2 | tr -d '"')
        local ipv6_region=$(echo $result_ipv6 | grep -oE '"region":"[^"]+"' | cut -d ":" -f2 | tr -d '"')
        local ipv6_country=$(echo "$result_ipv4" | grep -oP '(?<="country":")[^"]*')
        if [ -n "$ipv6_asn" ] && [ -n "$ipv6_as_organization" ] && [ -n "$ipv6_city" ] && [ -n "$ipv6_region" ] && [ -n "$ipv6_country" ]; then
            local ipv6_asn_info="AS${ipv6_asn} ${ipv6_as_organization}"
            local ipv6_location="${ipv6_city} / ${ipv6_region} / ${ipv6_country}"
        else
            local ipv6_asn_info="None"
            local ipv6_location="None"
        fi
    else
        local ipv6_asn_info="None"
        local ipv6_location="None"
    fi
    # 返回结果
    echo "$ipv6_asn_info" >> /tmp/ipsb
    echo "$ipv6_location" >> /tmp/ipsb
}

check_ip_info_by_cheervision(){
    # ipdata.cheervision.co
    rm -rf /tmp/cheervision
    local ipv4_result=$(curl -ksL4m6 -A Mozilla ipdata.cheervision.co 2>/dev/null)
    # 获取IPv4的asn、city、region
    if [ -n "$ipv4_result" ]; then
        local ipv4_asn=$(echo "$ipv4_result" | sed -n 's/.*"asn":\([0-9]*\),.*/\1/p')
        local ipv4_organization=$(echo "$ipv4_result" | sed -n 's/.*"organization":"\([^"]*\)",.*/\1/p')
        local ipv4_city=$(echo "$ipv4_result" | sed -n 's/.*"city":"\([^"]*\)",.*/\1/p')
        local ipv4_region=$(echo "$ipv4_result" | sed -n 's/.*"region":{"code":"\([^"]*\)".*/\1/p')
        if [ -n "$ipv4_asn" ] && [ -n "$ipv4_organization" ] && [ -n "$ipv4_city" ] && [ -n "$ipv4_region" ]; then
            local ipv4_asn_info="AS${ipv4_asn} ${ipv4_organization}"
            local ipv4_location="${ipv4_city} / ${ipv4_region}"
        else
            local ipv4_asn_info="None"
            local ipv4_location="None"
        fi
    else
        local ipv4_asn_info="None"
        local ipv4_location="None"
    fi
    # 返回结果
    echo "$ipv4_asn_info" >> /tmp/cheervision
    echo "$ipv4_location" >> /tmp/cheervision
    # 获取IPv6的asn、city、region
    sleep 1
    local ipv6_result=$(curl -ksL6m6 -A Mozilla ipdata.cheervision.co 2>/dev/null)
    if [ -n "$ipv6_result" ]; then
        local ipv6_asn=$(echo "$ipv6_result" | sed -n 's/.*"asn":\([0-9]*\),.*/\1/p')
        local ipv6_organization=$(echo "$ipv6_result" | sed -n 's/.*"organization":"\([^"]*\)",.*/\1/p')
        local ipv6_city=$(echo "$ipv6_result" | sed -n 's/.*"city":"\([^"]*\)",.*/\1/p')
        local ipv6_region=$(echo "$ipv6_result" | sed -n 's/.*"region":{"code":"\([^"]*\)".*/\1/p')
        if [ -n "$ipv6_asn" ] && [ -n "$ipv6_organization" ] && [ -n "$ipv6_city" ] && [ -n "$ipv6_region" ]; then
            local ipv6_asn_info="AS${ipv6_asn} ${ipv6_organization}"
            local ipv6_location="${ipv6_city} / ${ipv6_region}"
        else
            local ipv6_asn_info="None"
            local ipv6_location="None"
        fi
    else
        local ipv6_asn_info="None"
        local ipv6_location="None"
    fi
    # 返回结果
    echo "$ipv6_asn_info" >> /tmp/cheervision
    echo "$ipv6_location" >> /tmp/cheervision
}

check_ip_info(){
    # 并行执行四个函数
    check_ip_info_by_cloudflare &
    check_ip_info_by_ipinfo &
    check_ip_info_by_ipsb &
    check_ip_info_by_cheervision
    # 等待所有后台任务执行完毕
    wait
    # 存储结果的四个列表
    local ipv4_asn_info_list=()
    local ipv4_location_list=()
    local ipv6_asn_info_list=()
    local ipv6_location_list=()
    # 遍历每个函数的结果文件，读取内容到对应的列表中
    files=("/tmp/cloudflare" "/tmp/ipinfo" "/tmp/ipsb" "/tmp/cheervision")
    for file in "${files[@]}"; do
        {
            read -r asn_info
            read -r location
            read -r ipv6_asn_info
            read -r ipv6_location
        } < "$file"
        ipv4_asn_info_list+=("$asn_info")
        ipv4_location_list+=("$location")
        ipv6_asn_info_list+=("$ipv6_asn_info")
        ipv6_location_list+=("$ipv6_location")
    done
    # 找到每个列表中最长的第一个元素作为最终结果
    local ipv4_asn_info=$(get_longest_first_element "${ipv4_asn_info_list[@]}")
    local ipv4_location=$(get_longest_first_element "${ipv4_location_list[@]}")
    local ipv6_asn_info=$(get_longest_first_element "${ipv6_asn_info_list[@]}")
    local ipv6_location=$(get_longest_first_element "${ipv6_location_list[@]}")
    # 删除缓存文件
    for file in "${files[@]}"; do
        rm -rf ${file}
    done
    # 打印最终结果
    if [[ -n "$ipv4_asn_info" ]]; then
        echo " IPV4 ASN          : $(_blue "$ipv4_asn_info")"
    fi
    if [[ -n "$ipv4_location" ]]; then
        echo " IPV4 位置         : $(_blue "$ipv4_location")"
    fi
    if [[ -n "$ipv6_asn_info" ]]; then
        echo " IPV6 ASN          : $(_blue "$ipv6_asn_info")"
    fi
    if [[ -n "$ipv6_location" ]]; then
        echo " IPV6 位置         : $(_blue "$ipv6_location")"
    fi
}

print_intro() {
    echo "--------------------- A Bench Script By spiritlhl ----------------------"
    echo "                   测评频道: https://t.me/vps_reviews                    "
    echo "版本：$ver"
    echo "更新日志：$changeLog"
}

get_system_info() {
	arch=$( uname -m )
    disk_size1=($( LC_ALL=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem|udev|docker|snapd' | awk '{print $2}' ))
    disk_size2=($( LC_ALL=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem|udev|docker|snapd' | awk '{print $3}' ))
    disk_total_size=$( calc_disk "${disk_size1[@]}" )
    disk_used_size=$( calc_disk "${disk_size2[@]}" )
    if [ -f "/proc/cpuinfo" ]; then
        cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
        cores=$( awk -F: '/processor/ {core++} END {print core}' /proc/cpuinfo )
        freq=$( awk -F'[ :]' '/cpu MHz/ {print $4;exit}' /proc/cpuinfo )
        ccache=$( awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
        CPU_AES=$(cat /proc/cpuinfo | grep aes)
        CPU_VIRT=$(cat /proc/cpuinfo | grep 'vmx\|svm')
        up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days, %d hour %d min\n",a,b,c)}' /proc/uptime )
        if _exists "w"; then
            load=$( LANG=C; w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
        elif _exists "uptime"; then
            load=$( LANG=C; uptime | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
        fi
    elif [ "${Var_OSRelease}" = "freebsd" ]; then
        cname=$($sysctl_path -n hw.model)
        cores=$($sysctl_path -n hw.ncpu)
        freq=$($sysctl_path -n dev.cpu.0.freq 2>/dev/null || echo "")
        ccache=$($sysctl_path -n hw.cacheconfig 2>/dev/null | awk -F: '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' || echo "")
        CPU_AES=$($sysctl_path -a | grep -E 'crypto.aesni' | awk '{print $2}')
        CPU_VIRT=$($sysctl_path -a | grep -E 'hw.vmx|hw.svm' | awk '{print $2}')
        up=$($sysctl_path -n kern.boottime | perl -MPOSIX -nE 'if (/sec = (\d+), usec = (\d+)/) { $boottime = $1; $uptime = time() - $boottime; $days = int($uptime / 86400); $hours = int(($uptime % 86400) / 3600); $minutes = int(($uptime % 3600) / 60); say "$days days, $hours hours, $minutes minutes" }')
        if _exists "w"; then
            load=$( w | awk '{print $(NF-2), $(NF-1), $NF}' | head -n 1 )
        elif _exists "uptime"; then
            load=$( uptime | awk '{print $(NF-2), $(NF-1), $NF}' )
        fi
        disk_total_size=0
        disk_used_size=0
        for size in "${disk_size1[@]}"; do
            size_gb=$(expr $size / 1024 / 1024)  # 转换为GB单位
            disk_total_size=$(expr $disk_total_size + $size_gb)  # 总大小累加
        done
        for size in "${disk_size2[@]}"; do
            size_gb=$(expr $size / 1024 / 1024)  # 转换为GB单位
            disk_used_size=$(expr $disk_used_size + $size_gb)  # 已用空间累加
        done
    fi
    if [ -z "$cname" ] || [ ! -e /proc/cpuinfo ]; then
        cname=$(lscpu | grep "Model name" | sed 's/Model name: *//g')
        if [ $? -ne 0 ]; then
            ${PACKAGE_INSTALL[int]} util-linux
            cname=$(lscpu | grep "Model name" | sed 's/Model name: *//g')
        fi
        if [ -z "$cname" ]; then
            cname=$(cat /proc/device-tree/model)
        fi
    fi
    cname=$(echo -n "$cname" | tr '\n' ' ' | sed -E 's/ +/ /g')
    if command -v free > /dev/null 2>&1; then
        if free -m | grep -q '内存'; then  # 如果输出中包含 "内存" 关键词
            tram=$(free -m | awk '/内存/{print $2}')
            uram=$(free -m | awk '/内存/{print $3}')
            swap=$(free -m | awk '/交换/{print $2}')
            uswap=$(free -m | awk '/交换/{print $3}')
        else  # 否则，假定输出是英文的
            tram=$(LANG=C; free -m | awk '/Mem/ {print $2}')
            uram=$(LANG=C; free -m | awk '/Mem/ {print $3}')
            swap=$(LANG=C; free -m | awk '/Swap/ {print $2}')
            uswap=$(LANG=C; free -m | awk '/Swap/ {print $3}')
        fi
    else
        tram=$($sysctl_path -n hw.physmem | awk '{printf "%.0f", $1/1024/1024}')
        uram=$($sysctl_path -n vm.stats.vm.v_active_count | awk '{printf "%.0f", $1/1024}')
        swap=$(swapinfo -k | awk 'NR>1{sum+=$2} END{printf "%.0f", sum/1024}')
        uswap=$(swapinfo -k | awk 'NR>1{sum+=$4} END{printf "%.0f", sum/1024}')
    fi
    if _exists "getconf"; then
        lbit=$( getconf LONG_BIT )
    else
        echo ${arch} | grep -q "64" && lbit="64" || lbit="32"
    fi
    kern=$( uname -r )
    if [ -z "$sysctl_path" ]; then
        tcpctrl="None"
    fi
    tcpctrl=$($sysctl_path -n net.ipv4.tcp_congestion_control 2> /dev/null)
    if [ $? -ne 0 ]; then
        tcpctrl="未设置TCP拥塞控制算法"
    else
        if [ $tcpctrl == "bbr" ]; then
            :
        else
            if lsmod | grep bbr > /dev/null; then
                reading "是否要开启bbr再进行测试？(回车则默认不开启) [y/n] " confirmbbr
                echo ""
                if [ "$confirmbbr" != "y" ]; then
                    echo "net.core.default_qdisc=fq" >> "$sysctl_conf"
                    echo "net.ipv4.tcp_congestion_control=bbr" >> "$sysctl_conf"
                    $sysctl_path -p
                fi
                tcpctrl=$($sysctl_path -n net.ipv4.tcp_congestion_control 2> /dev/null)
                if [ $? -ne 0 ]; then
                    tcpctrl="None"
                fi
            fi
        fi
    fi
    checkstun
    if command -v stun > /dev/null 2>&1; then
        result=$(stun stun.l.google.com)
        nat_type=$(echo "$result" | grep '^Primary' | awk -F'Primary:' '{print $2}' | tr -d ' ')
        nat_type_r=""
        if echo "$nat_type" | grep -qE "IndependentMapping|Independent Mapping"; then
            nat_type_r+="独立映射"
        fi
        if echo "$nat_type" | grep -qE "IndependentFilter|Independent Filter"; then
            if [ -n "$nat_type_r" ]; then
                nat_type_r+=","
            fi
                nat_type_r+="独立过滤"
        fi
        if echo "$nat_type" | grep -q "preservesports|preserves ports"; then
            if [ -n "$nat_type_r" ]; then
                nat_type_r+=","
            fi
            nat_type_r+="保留端口"
        fi
        if echo "$nat_type" | grep -q "randomport|random port"; then
            if [ -n "$nat_type_r" ]; then
                nat_type_r+=","
            fi
            nat_type_r+="随机端口"
        fi
        if echo "$nat_type" | grep -qE "nohairpin|no hairpin"; then
            if [ -n "$nat_type_r" ]; then
                nat_type_r+=","
            fi
            nat_type_r+="不支持回环"
        fi
        if echo "$nat_type" | grep -qE "willhairpin|will hairpin"; then
            if [ -n "$nat_type_r" ]; then
                nat_type_r+=","
            fi
            nat_type_r+="支持回环"
        fi
        if echo "$nat_type" | grep -q "Open"; then
            if [ -n "$nat_type_r" ]; then
                nat_type_r+=","
            fi
            nat_type_r+="开放型"
        fi
        if echo "$nat_type" | grep -qE "BlockedorcouldnotreachSTUNserver|Blocked or could not reach STUN server"; then
            checkpystun
            if command -v pystun3 > /dev/null 2>&1; then
                result=$(pystun3 </dev/null)
                nat_type_r=$(echo "$result" | grep -oP 'NAT Type:\s*\K.*')
                if echo "$nat_type_r" | grep -qE "Blocked"; then
                    nat_type_r="无法检测"
                fi
            elif command -v pystun > /dev/null 2>&1; then
                result=$(pystun </dev/null)
                nat_type_r=$(echo "$result" | grep -oP 'NAT Type:\s*\K.*')
                if echo "$nat_type_r" | grep -qE "Blocked"; then
                    nat_type_r="无法检测"
                fi
            else
                if [ -n "$nat_type_r" ]; then
                    nat_type_r+=","
                fi
                nat_type_r+="无法检测"
            fi
        fi
        if [ -z "$nat_type_r" ]; then
            nat_type_r="$nat_type"
        fi
    else
        checkpystun
        if command -v pystun3 > /dev/null 2>&1; then
            result=$(pystun3 </dev/null)
            nat_type_r=$(echo "$result" | grep -oP 'NAT Type:\s*\K.*')
        elif command -v pystun > /dev/null 2>&1; then
            result=$(pystun </dev/null)
            nat_type_r=$(echo "$result" | grep -oP 'NAT Type:\s*\K.*')
        fi
    fi
}

isvalidipv4()
{
    local ipaddr=$1
    local stat=1
    if [[ $ipaddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ipaddr=($ipaddr)
        IFS=$OIFS
        [[ ${ipaddr[0]} -le 255 && ${ipaddr[1]} -le 255 \
            && ${ipaddr[2]} -le 255 && ${ipaddr[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

cnlatency() {    
    ipaddr=$(getent ahostsv4 $1 | grep STREAM | head -n 1 | cut -d ' ' -f 1)
	if isvalidipv4 "$ipaddr"; then
		host=$2
		retry=1
		rtt=999	
		while [[ "$retry" < 4 ]] ; do
			echo -en "\r\033[0K [$3 of $4] : $host ($ipaddr) attemp #$retry"
			rtt=$(ping -c1 -w1 $ipaddr | sed -nE 's/.*time=([0-9.]+).*/\1/p')				
			if [[ -z "$rtt" ]]; then
				rtt=999
				retry=$((retry+1))
				continue
			fi
			[[ "$rtt" < 1 ]] && rtt=1
			int=${rtt%.*}
			if [[ "$int" -gt 999 || "$int" -eq 0 ]]; then
				rtt=999
				break
			fi
			rtt=$(printf "%.0f" $rtt)
			rtt=$(printf "%03d" $rtt)
			break
		done
		result="${rtt}ms : $host , $ipaddr"
		CHINALIST[${#CHINALIST[@]}]=$result		
	fi
}

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
    echo " 系统              : $(_blue "$DISTRO")"  
    [[ -z "$CPU_AES" ]] && CPU_AES="\xE2\x9D\x8C Disabled" || CPU_AES="\xE2\x9C\x94 Enabled"
    echo " AES-NI指令集      : $(_blue "$CPU_AES")"  
    [[ -z "$CPU_VIRT" ]] && CPU_VIRT="\xE2\x9D\x8C Disabled" || CPU_VIRT="\xE2\x9C\x94 Enabled"
    echo " VM-x/AMD-V支持    : $(_blue "$CPU_VIRT")"  
    echo " 架构              : $(_blue "$arch ($lbit Bit)")"
    echo " 内核              : $(_blue "$kern")"
    echo " TCP加速方式       : $(_yellow "$tcpctrl")"
    echo " 虚拟化架构        : $(_blue "$virt")"
    [[ -n "$nat_type_r" ]] && echo " NAT类型           : $(_blue "$nat_type_r")"
}

print_end_time() {
    end_time=$(date +%s)
    time=$(( ${end_time} - ${start_time} ))
    if [ ${time} -gt 60 ]; then
        min=$(expr $time / 60)
        sec=$(expr $time % 60)
        echo " 总共花费      : ${min} 分 ${sec} 秒"
    else
        echo " 总共花费      : ${time} 秒"
    fi
    date_time=$(date)
    # date_time=$(date +%Y-%m-%d" "%H:%M:%S)
    echo " 时间          : $date_time"
}

check_lmc_script(){
    mv $TEMP_DIR/media_lmc_check.sh ./
}

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
    context=$(curl -sL -H "$head" -m 10 "https://scamalytics.com/ip/$ip")
    if [[ "$?" -ne 0 ]]; then
        return
    fi
    temp1=$(echo "$context" | grep -oP '(?<=>Fraud Score: )[^<]+')
    if [ -n "$temp1" ]; then
        echo "scamalytics数据库:"
        echo "  欺诈分数(越低越好)：$temp1"
    else
        return
    fi
    temp2=$(echo "$context" | grep -oP '(?<=<div).*?(?=</div>)' | tail -n 6)
    nlist=("匿名代理" "Tor出口节点" "服务器IP" "公共代理" "网络代理" "搜索引擎机器人")
    for element in $temp2
    do
        if echo "$element" | grep -q "score" >/dev/null 2>&1; then
            status_t2=1
            break
        else
            status_t2=2
            break
        fi
    done
    i=0
    if ! [ "$status_t2" -eq 1 ]; then
        while read -r temp3; do
            if [[ -n "$temp3" ]]; then
                echo "  ${nlist[$i]}: ${temp3#*>}"
                i=$((i+1))
            fi
        done <<< "$(echo "$temp2" | sed 's/<[^>]*>//g' | sed 's/^[[:blank:]]*//g')"
    fi
}

virustotal() {
    local ip="$1"
    local api_keys=(
    "401e74a0a76ff4a5c2462177bfe54d1fb71a86a97031a3a5b461eb9fe06fa9a5"
    "e6184c04de532cd5a094f3fd6b3ce36cd187e41e671b5336fd69862257d07a9a"
    "9929218dcd124c19bcee49ecd6d7555213de0e8f27d407cc3e85c92c3fc2508e"
    "bcc1f94cc4ec1966f43a5552007d6c4fa3461cec7200f8d95053ebeeecc68afa"
    )
    local api_key=${api_keys[$RANDOM % ${#api_keys[@]}]}
    local output=$(curl -s --request GET --url "https://www.virustotal.com/api/v3/ip_addresses/$ip" --header "x-apikey:$api_key")
    local result=$(echo "$output" | awk -F"[,:}]" '{
        for(i=1;i<=NF;i++){
            if($i~/\042timeout\042/){
                exit
            } else if($i~/\042harmless\042/){
                print "  无害记录：" $(i+1)
            } else if($i~/\042malicious\042/){
                print "  恶意记录：" $(i+1)
            } else if($i~/\042suspicious\042/){
                print "  可疑记录：" $(i+1)
            } else if($i~/\042undetected\042/){
                print "  未检测到记录：" $(i+1)
            }
        }
    }' | sed 's/\"//g')
    if [[ -n "$result" ]] && [[ -n "$(echo "$result" | awk 'NF')" ]]; then
        echo "黑名单记录统计:(有多少黑名单网站有记录)"
        echo "$result"
    fi
}

cloudflare() {
    status=0
    for ((i=1; i<=100; i++)); do
        context1=$(curl -sL -m 10 "https://cf-threat.sukkaw.com/hello.json?threat=$i")
        if [[ "$context1" != *"pong!"* ]]; then
            echo "Cloudflare威胁得分高于10为爬虫或垃圾邮件发送者,高于40有严重不良行为(如僵尸网络等),数值一般不会大于60"
            echo "Cloudflare威胁得分：$i"
            status=1
            break
        fi
    done
    if [[ $i == 100 && $status == 0 ]]; then
        echo "Cloudflare威胁得分(0为低风险): 0"
    fi
}

abuse() {
    ip="$1"
    context2=$(curl -sL -H "$head" -m 10 "https://api.abuseipdb.com/api/v2/check?ipAddress=${ip}")
    if [[ "$context2" == *"abuseConfidenceScore"* ]]; then
        score=$(echo "$context2" | grep -o '"abuseConfidenceScore":[^,}]*' | sed 's/.*://')
        echo "abuseipdb数据库-abuse得分：$score"
        echo "IP类型:"
        usageType=$(grep -oP '"usageType":\s*"\K[^"]+' <<< "$context2" | sed 's/\\\//\//g')
        if [ -z "$usageType" ]; then
            usageType="Unknown (Maybe Fixed Line ISP)"
        fi
        echo "  IP2Location数据库: $usageType"
    fi
}

ipapi() {
    ip=$1
    context4=$(curl -sL -m 10 "http://ip-api.com/json/$ip?fields=mobile,proxy,hosting")
    if [[ "$context4" == *"mobile"* ]]; then
        echo "ip-api数据库:"
        mobile=$(echo "$context4" | grep -o '"mobile":[^,}]*' | sed 's/.*://;s/"//g')
        tp1=$(translate_status ${mobile})
        echo "  手机流量: $tp1"
        proxy=$(echo "$context4" | grep -o '"proxy":[^,}]*' | sed 's/.*://;s/"//g')
        tp2=$(translate_status ${proxy})
        echo "  代理服务: $tp2"
        hosting=$(echo "$context4" | grep -o '"hosting":[^,}]*' | sed 's/.*://;s/"//g')
        tp3=$(translate_status ${hosting})
        echo "  数据中心: $tp3"
    fi
}

ip234() {
    local ip="$1"
    context5=$(curl -sL -m 10 "http://ip234.in/fraud_check?ip=$ip")
    if [[ "$?" -ne 0 ]]; then
        return
    fi
    risk=$(grep -oP '(?<="score":)[^,}]+' <<< "$context5")
    if [[ -n "$risk" ]]; then
        echo "ip234数据库："
        echo "  欺诈分数(越低越好)：$risk"
    else
        return
    fi
}

google() {
  curl_result=$(curl -sL -m 10 "https://www.google.com/search?q=www.spiritysdx.top" -H "User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:54.0) Gecko/20100101 Firefox/54.0")
  if echo "$curl_result" | grep -q "二叉树的博客"; then
    echo "Google搜索可行性：YES"
  else
    echo "Google搜索可行性：NO"
  fi
}

local_port_25() {
    host=$1
    port=$2
    nc -z -w5 $host $port > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "  本地: Yes"
    else
        echo "  本地: No"
    fi
}

check_email_service() {
    service=$1
    host=""
    port=25
    expected_response="220"
    case $service in
        "gmail邮箱")
            host="smtp.gmail.com"
            ;;
        "163邮箱")
            host="smtp.163.com"
            ;;
        "yandex邮箱")
            host="smtp.yandex.com"
            ;;
        "outlook邮箱")
            host="smtp.office365.com"
            ;;
        "qq邮箱")
            host="smtp.qq.com"
            ;;
        *)
            echo "不支持的邮箱服务: $service"
            return
            ;;
    esac
    response=$(echo -e "QUIT\r\n" | nc -w5 $host $port 2>/dev/null)
    if [[ $response == *"$expected_response"* ]]; then
        echo "  $service: Yes"
        # echo "$response"
    else
        echo "  $service：No"
        # echo "$response"
    fi
}

check_port_25() {
    echo "端口25检测:"
    local_port_25 "localhost" 25
    check_email_service "163邮箱"
    if [[ $(check_email_service "163邮箱") == *"No"* ]]; then
        return
    fi
    check_email_service "gmail邮箱"
    if [[ $(check_email_service "gmail邮箱") == *"No"* ]]; then
        return
    fi
    check_email_service "outlook邮箱"
    check_email_service "yandex邮箱"
    check_email_service "qq邮箱"
}

ipcheck(){
    ip4=$IPV4
    ip6=$(curl -sL6m8 -k ip.sb | tr -d '[:space:]')
    ip4=$(echo "$ip4" | tr -d '\n')
    ip6=$(echo "$ip6" | tr -d '\n')
    scamalytics "$ip4"
    virustotal "$ip4"
    ip234 "$ip4"
    ipapi "$ip4"
    abuse "$ip4"
    google
    if command -v nc >/dev/null; then
        check_port_25
    fi
    if [[ -n "$ip6" ]]; then
        echo "------以下为IPV6检测------"
        scamalytics "$ip6"
        abuse "$ip6"
    fi
}

cdn_urls=("https://cdn.spiritlhl.workers.dev/" "https://cdn3.spiritlhl.net/" "https://cdn1.spiritlhl.net/" "https://ghproxy.com/" "https://cdn2.spiritlhl.net/")
ST="dvWYwv20KSWm8AXSceRw8toa.MTY4MDQzMzUxNDczNw"
head='key: e88362808d1219e27a786a465a1f57ec3417b0bdeab46ad670432b7ce1a7fdec0d67b05c3463dd3c'
speedtest_ver="1.2.0"
SERVER_BASE_URL="https://raw.githubusercontent.com/spiritLHLS/speedtest.net-CN-ID/main"
SERVER_BASE_URL2="https://raw.githubusercontent.com/spiritLHLS/speedtest.cn-CN-ID/main"

pre_check(){
    checkupdate
    systemInfo_get_os_release
    checkdmidecode
    checkroot
    checksudo
    checkwget
    checkfree
    checklscpu
    checkunzip
    checktar
    checknc
    check_time_zone
    checkhaveged
    optimized_kernel
    checkcurl
    check_ipv4
    check_cdn_file
    global_startup_init_action
    cd $myvar >/dev/null 2>&1
    ! _exists "wget" && _red "Error: wget command not found.\n" && exit 1
    check_china
}

sjlleo_script(){
    [ "${Var_OSRelease}" = "freebsd" ] && return
    cd $myvar >/dev/null 2>&1
    mv $TEMP_DIR/{dp,nf,tubecheck} ./
    echo "---------------------流媒体解锁--感谢sjlleo开源-------------------------"
    _yellow "以下测试的解锁地区是准确的，但是不是完整解锁的判断可能有误，这方面仅作参考使用"
    _yellow "----------------Youtube----------------"
    ./tubecheck | sed "/@sjlleo/d;/^$/d"
    sleep 0.5
    _yellow "----------------Netflix----------------"
    ./nf | sed "/@sjlleo/d;/^$/d"
    sleep 0.5
    _yellow "---------------DisneyPlus---------------"
    ./dp | sed "/@sjlleo/d;/^$/d"
    sleep 0.5
    _yellow "解锁Youtube，Netflix，DisneyPlus上面和下面进行比较，不同之处自行判断"
}

basic_script(){
    echo "-------------------感谢teddysun和superbench和yabs开源-------------------"
    print_system_info
    check_ip_info
    cd $myvar >/dev/null 2>&1
    sleep 1
    echo "---------------------CPU测试--感谢lemonbench开源------------------------"
    Function_SysBench_CPU_Fast
    cd $myvar >/dev/null 2>&1
    sleep 1
    echo "---------------------内存测试--感谢lemonbench开源-----------------------"
    Function_SysBench_Memory_Fast
}

io1_script(){
    cd $myvar >/dev/null 2>&1
    sleep 1
    echo "------------------磁盘dd读写测试--感谢lemonbench开源--------------------"
    Function_DiskTest_Fast
}

io2_script(){
    [ "${Var_OSRelease}" = "freebsd" ] && return
    cd $myvar >/dev/null 2>&1
    echo "---------------------磁盘fio读写测试--感谢yabs开源----------------------"
    bash yabsiotest.sh 2>/dev/null
    rm -rf yabsiotest.sh
}

RegionRestrictionCheck_script(){
    echo -e "----------------流媒体解锁--感谢RegionRestrictionCheck开源--------------"
    _yellow " 以下为IPV4网络测试，若无IPV4网络则无输出"
    echo 0 | bash media_lmc_check.sh -M 4 2>/dev/null | grep -A999999 '============\[ Multination \]============' | sed '/=======================================/q'
    _yellow " 以下为IPV6网络测试，若无IPV6网络则无输出"
    echo 0 | bash media_lmc_check.sh -M 6 2>/dev/null | grep -A999999 '============\[ Multination \]============' | sed '/=======================================/q'
}

lmc999_script(){
    cd $myvar >/dev/null 2>&1
    echo -e "---------------TikTok解锁--感谢lmc999的源脚本及fscarmen PR--------------"
    local Ftmpresult=$(curl $useNIC --user-agent "${UA_Browser}" -sL --max-time 10 "https://www.tiktok.com/")

    if [[ "$Ftmpresult" = "curl"* ]]; then
        _red "\r Tiktok Region:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}"
        return
    fi

    local FRegion=$(echo $Ftmpresult | grep '"region":' | sed 's/.*"region"//' | cut -f2 -d'"')
    if [ -n "$FRegion" ]; then
        _green "\r Tiktok Region:\t\t${Font_Green}【${FRegion}】${Font_Suffix}"
        return
    fi

    local STmpresult=$(curl $useNIC --user-agent "${UA_Browser}" -sL --max-time 10 -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9" -H "Accept-Encoding: gzip" -H "Accept-Language: en" "https://www.tiktok.com" | gunzip 2>/dev/null)
    local SRegion=$(echo $STmpresult | grep '"region":' | sed 's/.*"region"//' | cut -f2 -d'"')
    if [ -n "$SRegion" ]; then
        _yellow "\r Tiktok Region:\t\t${Font_Yellow}【${SRegion}】(可能为IDC IP)${Font_Suffix}"
        return
    else
        _red "\r Tiktok Region:\t\t${Font_Red}Failed${Font_Suffix}"
        return
    fi
}

spiritlhl_script(){
    [ "${Var_OSRelease}" = "freebsd" ] && return
    cd $myvar >/dev/null 2>&1
    echo -e "-------------------欺诈分数以及IP质量检测--本脚本原创-------------------"
    _yellow "数据仅作参考，不代表100%准确，如果和实际情况不一致请手动查询多个数据库比对"
    ipcheck
}

backtrace_script(){
    [ "${Var_OSRelease}" = "freebsd" ] && return
    cd $myvar >/dev/null 2>&1
    echo -e "----------------三网回程--感谢zhanghanyun/backtrace开源-----------------"
    if [ -f "${TEMP_DIR}/backtrace" ]; then
        chmod 777 ${TEMP_DIR}/backtrace
        curl_output=$(${TEMP_DIR}/backtrace 2>&1)
    else
        return
    fi
    grep -sq 'sendto: network is unreachable' <<< $curl_output && _yellow "纯IPV6网络无法查询" || echo "${curl_output}" | grep -v 'github.com/zhanghanyun/backtrace' | grep -v '正在测试'
}

fscarmen_route_script(){
    [ "${Var_OSRelease}" = "freebsd" ] && return
    cd $myvar >/dev/null 2>&1
    echo -e "---------------------回程路由--感谢fscarmen开源及PR---------------------"
    rm -f $TEMP_FILE
    _green "依次测试电信，联通，移动经过的地区及线路，核心程序来由: ipip.net ，请知悉!" >> $TEMP_FILE
    local test_area=("${!1}")
    local test_ip=("${!2}")
    for ((a=0;a<${#test_area[@]};a++)); do
        _yellow "${test_area[a]} ${test_ip[a]}" >> $TEMP_FILE
        "$TEMP_DIR/$BESTTRACE_FILE" "${test_ip[a]}" -g cn 2>/dev/null | sed "s/^[ ]//g" | sed "/^[ ]/d" | sed '/ms/!d' | sed "s#.* \([0-9.]\+ ms.*\)#\1#g" >> $TEMP_FILE
    done
    # if [[ $(cat "$TEMP_FILE") == *"timestamp is error"* ]]; then
    #     check_time_zone >/dev/null 2>&1
    #     echo "" > $TEMP_FILE
    #     for ((a=0;a<${#test_area[@]};a++)); do
    #         _yellow "${test_area[a]} ${test_ip[a]}" >> $TEMP_FILE
    #         "$TEMP_DIR/$BESTTRACE_FILE" "${test_ip[a]}" -g cn 2>/dev/null | sed "s/^[ ]//g" | sed "/^[ ]/d" | sed '/ms/!d' | sed "s#.* \([0-9.]\+ ms.*\)#\1#g" >> $TEMP_FILE
    #     done
    # fi
    cat $TEMP_FILE
    rm -f $TEMP_FILE
}

ecs_ping(){
    cd $myvar >/dev/null 2>&1
    echo -e "-----------------------全国延迟检测--本脚本原创-------------------------"
    if [ -f "${TEMP_DIR}/ecsspeed-ping.sh" ]; then
        ping_output=$(bash ${TEMP_DIR}/ecsspeed-ping.sh 2>&1)
    else
        return
    fi
    echo "${ping_output}" | grep "|"
}

ecs_net_all_script(){
    cd $myvar >/dev/null 2>&1
    s_time=$(date +%s)
    rm -rf ./speedtest-cli/speedlog.txt

    speed | tee ./speedtest-cli/speedlog.txt
    e_time=$(date +%s)
    time=$(( ${e_time} - ${s_time} ))
    if ! grep -qE "(Speedtest.net|洛杉矶|新加坡|香港|联通|电信|移动|日本|中国)" ./speedtest-cli/speedlog.txt;
    then
        export speedtest_ver="1.0.0"
        rm -rf ./speedtest-cli/speedlog.txt
        rm -rf ./speedtest-cli*
        ( install_speedtest > /dev/null 2>&1 )
        speed
    fi
    rm -fr speedtest-cli
}

ecs_net_minal_script(){
    cd $myvar >/dev/null 2>&1
    s_time=$(date +%s)
    rm -rf ./speedtest-cli/speedlog.txt
    speed2 | tee ./speedtest-cli/speedlog.txt
    e_time=$(date +%s)
    time=$(( ${e_time} - ${s_time} ))
    if ! grep -qE "(Speedtest.net|洛杉矶|新加坡|香港|联通|电信|移动|日本|中国)" ./speedtest-cli/speedlog.txt;
    then
        export speedtest_ver="1.0.0"
        rm -rf ./speedtest-cli/speedlog.txt
        rm -rf ./speedtest-cli*
        ( install_speedtest > /dev/null 2>&1 )
        speed2
    fi
    rm -fr speedtest-cli
}

end_script(){
    next
    print_end_time
    next
}

all_script(){
    pre_check
    if [ "$1" = "B" ]; then
        if [[ -z "${CN}" || "${CN}" != true ]]; then
            dfiles=(yabsiotest dp nf tubecheck media_lmc_check besttrace backtrace)
            for dfile in "${dfiles[@]}"
            do
                { pre_download ${dfile};} &
            done
            get_system_info
            check_virt
            checkdnsutils
            checkping
            ls_sg_hk_jp=($(get_nearest_data "${SERVER_BASE_URL}/ls_sg_hk_jp.csv"))
            CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
            CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
            CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
            _yellow "checking speedtest" && install_speedtest &
            check_lmc_script &
            start_time=$(date +%s)
            clear
            print_intro
            basic_script
            wait
            ecs_net_all_script > ${TEMP_DIR}/ecs_net_output.txt &
            io1_script
            sleep 0.5
            io2_script
            sjlleo_script > ${TEMP_DIR}/sjlleo_output.txt &
            RegionRestrictionCheck_script > ${TEMP_DIR}/RegionRestrictionCheck_output.txt &
            lmc999_script > ${TEMP_DIR}/lmc999_output.txt &
            spiritlhl_script > ${TEMP_DIR}/spiritlhl_output.txt &
            backtrace_script > ${TEMP_DIR}/backtrace_output.txt &
            fscarmen_route_script test_area_g[@] test_ip_g[@] > ${TEMP_DIR}/fscarmen_route_output.txt &
            echo "正在并发测试中，大概2~3分钟无输出，请耐心等待。。。"
            wait
            cat ${TEMP_DIR}/sjlleo_output.txt
            cat ${TEMP_DIR}/RegionRestrictionCheck_output.txt
            cat ${TEMP_DIR}/lmc999_output.txt
            cat ${TEMP_DIR}/spiritlhl_output.txt
            cat ${TEMP_DIR}/backtrace_output.txt
            cat ${TEMP_DIR}/fscarmen_route_output.txt
            cat ${TEMP_DIR}/ecs_net_output.txt
        else
            dfiles=(ecsspeed_ping)
            for dfile in "${dfiles[@]}"
            do
                { pre_download ${dfile};} &
            done
            get_system_info
            check_virt
            checkdnsutils
            checkping
            ls_sg_hk_jp=($(get_nearest_data "${SERVER_BASE_URL}/ls_sg_hk_jp.csv"))
            CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
            CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
            CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
            _yellow "checking speedtest" && install_speedtest &
            check_lmc_script &
            start_time=$(date +%s)
            clear
            print_intro
            basic_script
            wait
            ecs_net_all_script > ${TEMP_DIR}/ecs_net_output.txt &
            io1_script
            sleep 0.5
            spiritlhl_script > ${TEMP_DIR}/spiritlhl_output.txt &
            ecs_ping > ${TEMP_DIR}/ecs_ping.txt &
            echo "正在并发测试中，大概2~3分钟无输出，请耐心等待。。。"
            wait
            cat ${TEMP_DIR}/spiritlhl_output.txt
            cat ${TEMP_DIR}/ecs_ping.txt
            cat ${TEMP_DIR}/ecs_net_output.txt
        fi
    else
        if [[ -z "${CN}" || "${CN}" != true ]]; then
            pre_download yabsiotest dp nf tubecheck media_lmc_check besttrace backtrace
            get_system_info
            check_virt
            checkdnsutils
            checkping
            ls_sg_hk_jp=($(get_nearest_data "${SERVER_BASE_URL}/ls_sg_hk_jp.csv"))
            CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
            CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
            CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
            _yellow "checking speedtest" && install_speedtest
            check_lmc_script
            start_time=$(date +%s)
            clear
            print_intro
            basic_script
            io1_script
            sleep 0.5
            io2_script
            sjlleo_script
            RegionRestrictionCheck_script
            lmc999_script
            spiritlhl_script
            backtrace_script
            fscarmen_route_script test_area_g[@] test_ip_g[@]
            wait
            ecs_net_all_script
        else
            pre_download ecsspeed_ping
            get_system_info
            check_virt
            checkdnsutils
            checkping
            ls_sg_hk_jp=($(get_nearest_data "${SERVER_BASE_URL}/ls_sg_hk_jp.csv"))
            CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
            CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
            CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
            _yellow "checking speedtest" && install_speedtest
            check_lmc_script
            start_time=$(date +%s)
            clear
            print_intro
            basic_script
            io1_script
            sleep 0.5
            spiritlhl_script
            ecs_ping
            wait
            sleep 1
            ecs_net_all_script
        fi
    fi
    # fscarmen_port_script
    end_script
}

minal_script(){
    pre_check
    get_system_info
    pre_download yabsiotest
    check_virt
    checkping
    CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
    CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
    CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
    _yellow "checking speedtest" && install_speedtest
    start_time=$(date +%s)
    clear
    print_intro
    basic_script
    io2_script
    ecs_net_minal_script
    end_script
}

minal_plus(){
    pre_check
    pre_download yabsiotest dp nf tubecheck media_lmc_check besttrace backtrace
    get_system_info
    check_virt
    check_lmc_script
    checkdnsutils
    checkping
    CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
    CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
    CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
    _yellow "checking speedtest" && install_speedtest
    start_time=$(date +%s)
    clear
    print_intro
    basic_script
    io2_script
    sjlleo_script
    RegionRestrictionCheck_script
    lmc999_script
    backtrace_script
    fscarmen_route_script test_area_g[@] test_ip_g[@]
    ecs_net_minal_script
    end_script
}

minal_plus_network(){
    pre_check
    pre_download yabsiotest besttrace backtrace
    get_system_info
    check_virt
    checkping
    CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
    CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
    CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
    _yellow "checking speedtest" && install_speedtest
    start_time=$(date +%s)
    clear
    print_intro
    basic_script
    io2_script
    backtrace_script
    fscarmen_route_script test_area_g[@] test_ip_g[@]
    ecs_net_minal_script
    end_script
}

minal_plus_media(){
    pre_check
    pre_download yabsiotest dp nf tubecheck media_lmc_check
    get_system_info
    check_virt
    checkdnsutils
    check_lmc_script
    checkping
    CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
    CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
    CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
    _yellow "checking speedtest" && install_speedtest
    start_time=$(date +%s)
    clear
    print_intro
    basic_script
    io2_script
    sjlleo_script
    RegionRestrictionCheck_script
    lmc999_script
    ecs_net_minal_script
    end_script
}

network_script(){
    pre_check
    pre_download besttrace backtrace
    checkping
    ls_sg_hk_jp=($(get_nearest_data "${SERVER_BASE_URL}/ls_sg_hk_jp.csv"))
    CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
    CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
    CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
    _yellow "checking speedtest" && install_speedtest
    start_time=$(date +%s)
    clear
    print_intro
    spiritlhl_script
    backtrace_script
    fscarmen_route_script test_area_g[@] test_ip_g[@]
    # fscarmen_port_script
    ecs_net_all_script
    end_script
}

media_script(){
    pre_check
    pre_download dp nf tubecheck media_lmc_check
    checkdnsutils
    check_lmc_script
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
    pre_download yabsiotest
    get_system_info
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
    pre_download XXXX
    get_system_info
    check_virt
    start_time=$(date +%s)
    clear
    print_intro
    # fscarmen_port_script
    end_script
}

sw_script(){
    pre_check
    pre_download besttrace backtrace ecsspeed_ping
    checkping
    start_time=$(date +%s)
    clear
    print_intro
    backtrace_script
    fscarmen_route_script test_area_g[@] test_ip_g[@]
    ecs_ping
    end_script
}

network_script_select() {
    pre_check
    pre_download besttrace
    start_time=$(date +%s)
    clear
    print_intro
    if [[ "$1" == "g" ]]; then
        fscarmen_route_script test_area_g[@] test_ip_g[@]
    elif [[ "$1" == "s" ]]; then
        fscarmen_route_script test_area_s[@] test_ip_s[@]
    elif [[ "$1" == "b" ]]; then
        fscarmen_route_script test_area_b[@] test_ip_b[@]
    elif [[ "$1" == "c" ]]; then
        fscarmen_route_script test_area_c[@] test_ip_c[@]
    else
        echo "Invalid argument, please use 'g', 's', 'b', or 'c'."
        return 1
    fi
    end_script
}

rm_script(){
    cd $myvar >/dev/null 2>&1
    rm -rf speedtest.tgz*
    rm -rf wget-log*
    rm -rf media_lmc_check.sh*
    rm -rf dp
    rm -rf nf
    rm -rf tubecheck
    rm -rf besttrace
    rm -rf LemonBench.Result.txt*
    rm -rf speedtest.log*
    rm -rf test
    rm -rf yabsiotest.sh*
    rm -rf speedtest.tgz*
    rm -rf speedtest.tar.gz*
    rm -rf speedtest-cli*
    rm -rf $TEMP_FILE
}

build_text(){
    cd $myvar >/dev/null 2>&1
    if { [ -n "${StartInput}" ] && [ "${StartInput}" -eq 1 ]; } || { [ -n "${StartInput}" ] && [ "${StartInput}" -eq 2 ]; } || { [ -n "${StartInput1}" ] && [ "${StartInput1}" -ge 1 ] && [ "${StartInput1}" -le 4 ]; }; then
        sed -i -e '1,/-------------------- A Bench Script By spiritlhl ---------------------/d; s/\x1B\[[0-9;]\+[a-zA-Z]//g; /^$/d' test_result.txt
        sed -i -e '/Preparing system for disk tests.../d; /Generating fio test file.../d; /Running fio random mixed R+W disk test with 4k block size.../d; /Running fio random mixed R+W disk test with 64k block size.../d; /Running fio random mixed R+W disk test with 512k block size.../d; /Running fio random mixed R+W disk test with 1m block size.../d' test_result.txt
        tr '\r' '\n' < test_result.txt > test_result1.txt && mv test_result1.txt test_result.txt
        sed -i -e '/^$/d' -e '/1\/1/d' -e '/Block\s*->/d' -e '/s)\s*->/d' -e '/^该运营商\|^测速中/d' test_result.txt
        if [ -s test_result.txt ]; then
            shorturl=$(curl --ipv4 -sL -m 10 -X POST -H "Authorization: $ST" \
            -H "Format: RANDOM" \
            -H "Max-Views: 0" \
            -H "UploadText: true" \
            -H "Content-Type: multipart/form-data" \
            -H "No-JSON: true" \
            -F "file=@${myvar}/test_result.txt" \
            "https://paste.spiritlhl.net/api/upload")
            if [ $? -ne 0 ]; then
                shorturl=$(curl --ipv6 -sL -m 10 -X POST -H "Authorization: $ST" \
                -H "Format: RANDOM" \
                -H "Max-Views: 0" \
                -H "UploadText: true" \
                -H "Content-Type: multipart/form-data" \
                -H "No-JSON: true" \
                -F "file=@${myvar}/test_result.txt" \
                "https://paste.spiritlhl.net/api/upload")
            fi
        fi
    fi
}

comprehensive_test_script(){
    head_script
    _yellow "具备综合性测试的脚本如下"
    echo -e "${GREEN}1.${PLAIN} superbench VPS测试脚本-基于teddysun的二开"
    echo -e "${GREEN}2.${PLAIN} lemonbench VPS测试脚本"
    echo -e "${GREEN}3.${PLAIN} misakabench VPS测试脚本-基于superbench的二开"
    echo -e "${GREEN}4.${PLAIN} YABS VPS测试脚本-英文论坛常用"
    echo -e "${GREEN}5.${PLAIN} teddysun的bench.sh VPS测试脚本"
    echo -e "${GREEN}6.${PLAIN} Aniverse的a.sh VPS测试脚本-特殊适配独服"
    echo -e "${GREEN}7.${PLAIN} Zbench VPS测试脚本-国内测试"
    echo -e "${GREEN}8.${PLAIN} UnixBench VPS测试脚本-特殊适配unix系统"
    echo " -------------"
    echo -e "${GREEN}0.${PLAIN} 回到上一级菜单"
    echo ""
    while true
    do
        read -rp "请输入选项:" StartInputc
        case $StartInputc in
            1) wget -qO- --no-check-certificate https://raw.githubusercontent.com/oooldking/script/master/superbench.sh | bash ; break ;;
            2) curl -fsL https://ilemonra.in/LemonBenchIntl | bash -s fast ; break ;;
            3) bash <(curl -L -Lso- https://cdn.jsdelivr.net/gh/misaka-gh/misakabench@master/misakabench.sh) ; break ;;
            4) curl -sL yabs.sh | bash ; break ;;
            5) wget -qO- bench.sh | bash ; break ;;
            6) bash <(wget -qO- git.io/ceshi) ; break ;;
            7) wget -N --no-check-certificate https://raw.githubusercontent.com/FunctionClub/ZBench/master/ZBench-CN.sh && bash ZBench-CN.sh ; break ;;
            8) wget --no-check-certificate https://raw.githubusercontent.com/teddysun/across/master/unixbench.sh && chmod +x unixbench.sh && ./unixbench.sh ; break ;;
            0) original_script ; break ;;
            *) echo "输入错误，请重新输入" ;;
        esac
    done
}

media_test_script(){
    head_script
    _yellow "流媒体测试相关的脚本如下"
    echo -e "${GREEN}1.${PLAIN} sjlleo的NetFlix解锁检测脚本 "
    echo -e "${GREEN}2.${PLAIN} sjlleo的Youtube地域信息检测脚本"
    echo -e "${GREEN}3.${PLAIN} sjlleo的DisneyPlus解锁区域检测脚本"
    echo -e "${GREEN}4.${PLAIN} lmc999的TikTok解锁区域检测脚本-本作者优化版本"
    echo -e "${GREEN}5.${PLAIN} lmc999的TikTok解锁区域检测脚本-原版脚本"
    echo -e "${GREEN}6.${PLAIN} lmc999的流媒体检测脚本-综合性地域流媒体全测的"
    echo -e "${GREEN}7.${PLAIN} nkeonkeo的流媒体检测脚本-基于上者的GO重构版本"
    echo -e "${GREEN}8.${PLAIN} missuo的OpenAI-Checker检测脚本(可能卡住)"
    echo -e "${GREEN}9.${PLAIN} 本人修改优化的OpenAI-Checker检测脚本(重构优化)"
    echo " -------------"
    echo -e "${GREEN}0.${PLAIN} 回到上一级菜单"
    echo ""
    while true
    do
        read -rp "请输入选项:" StartInputm
        case $StartInputm in
            1) wget -O nf https://github.com/sjlleo/netflix-verify/releases/download/v3.1.0/nf_linux_amd64 && chmod +x nf && ./nf ; break ;;
            2) wget -O tubecheck https://cdn.jsdelivr.net/gh/sjlleo/TubeCheck/CDN/tubecheck_1.0beta_linux_amd64 && chmod +x tubecheck && clear && ./tubecheck ; break ;;
            3) wget -O dp https://github.com/sjlleo/VerifyDisneyPlus/releases/download/1.01/dp_1.01_linux_amd64 && chmod +x dp && clear && ./dp ; break ;;
            4) lmc999_script ; break ;;
            5) bash <(curl -s https://raw.githubusercontent.com/lmc999/TikTokCheck/main/tiktok.sh) ; break ;;
            6) bash <(curl -L -s check.unlock.media) ; break ;;
            7) bash <(curl -Ls unlock.moe) ; break ;;
            8) bash <(curl -Ls https://cpp.li/openai) ; break ;;
            9) bash <(curl -Ls https://bash.spiritlhl.net/openai-checker) ; break ;;
            0) original_script ; break ;;
            *) echo "输入错误，请重新输入" ;;
        esac
    done
}


network_test_script(){
    head_script
    _yellow "网络测试相关的脚本如下"
    echo -e "${GREEN}1.${PLAIN} zhanghanyun的backtrace三网回程线路检测脚本"
    echo -e "${GREEN}2.${PLAIN} zhucaidan的mtr_trace三网回程线路测脚本"
    echo -e "${GREEN}3.${PLAIN} 基于besttrace回程路由测试脚本(带详情信息)"
    echo -e "${GREEN}4.${PLAIN} 基于besttrace回程路由测试脚本(二开整合输出)"
    echo -e "${GREEN}5.${PLAIN} 基于nexttrace回程路由测试脚本(第三方IP库)"
    echo -e "${GREEN}6.${PLAIN} 由Netflixxp维护的四网路由测试脚本"
    echo -e "${GREEN}7.${PLAIN} 原始作者维护的superspeed的三网测速脚本"
    echo -e "${GREEN}8.${PLAIN} 未知作者修复的superspeed的三网测速脚本"
    echo -e "${GREEN}9.${PLAIN} 由sunpma维护的superspeed的三网测速脚本"
    echo -e "${GREEN}10.${PLAIN} 原始作者维护的hyperspeed的三网测速脚本(测速内核不开源)"
    echo -e "${GREEN}11.${PLAIN} 综合速度测试脚本(全球的测速节点)"
    echo -e "${GREEN}12.${PLAIN} 本人的ecs-net三网测速脚本(自动更新测速节点，对应 speedtest.net)"
    echo -e "${GREEN}13.${PLAIN} 本人的ecs-cn三网测速脚本(自动更新测速节点，对应 speedtest.cn)"
    echo -e "${GREEN}14.${PLAIN} 本人的ecs-ping三网测ping脚本(自动更新测试节点)"
    echo " -------------"
    echo -e "${GREEN}0.${PLAIN} 回到上一级菜单"
    echo ""
    while true
    do
        read -rp "请输入选项:" StartInputn
        case $StartInputn in
            1) curl https://raw.githubusercontent.com/zhanghanyun/backtrace/main/install.sh -sSf | sh ; break ;;
            2) curl https://raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh|bash ; break ;;
            3) wget -qO- git.io/besttrace | bash ; break ;;
            4) bash <(curl -sSL https://raw.githubusercontent.com/spiritLHLS/ecs/main/return.sh) ; break ;;
            5) bash <(curl -sSL https://raw.githubusercontent.com/spiritLHLS/ecs/main/archive/nexttrace.sh) ; break ;;
            6) wget -O jcnf.sh https://raw.githubusercontent.com/Netflixxp/jcnfbesttrace/main/jcnf.sh && bash jcnf.sh ; break ;;
            7) bash <(curl -L -Lso- https://git.io/superspeed.sh) ; break ;;
            8) bash <(curl -Lso- https://git.io/superspeed_uxh) ; break ;;
            9) bash <(curl -Lso- https://git.io/J1SEh) ; break ;;
            10) bash <(curl -L -Lso- https://bench.im/hyperspeed) ; break ;;
            11) curl -sL network-speed.xyz | bash ; break ;;
            12) bash <(wget -qO- bash.spiritlhl.net/ecs-net) ; break ;;
            13) bash <(wget -qO- bash.spiritlhl.net/ecs-cn) ; break ;;
            14) bash <(wget -qO- bash.spiritlhl.net/ecs-ping) ; break ;;
            0) original_script ; break ;;
            *) echo "输入错误，请重新输入" ;;
        esac
    done
}

hardware_test_script(){
    head_script
    _yellow "硬件测试合集如下"
    echo " -------------"
    echo -e "${GREEN}1.${PLAIN} 检测本机硬盘(含通电时长)-一般是独服才有用"
    echo -e "${GREEN}2.${PLAIN} Geekbench4测试"
    echo -e "${GREEN}3.${PLAIN} Geekbench5测试"
    echo -e "${GREEN}4.${PLAIN} Geekbench6测试"
    echo -e "${GREEN}5.${PLAIN} 测试挂载的多个磁盘的IO(仅测试挂载盘)"
    echo " -------------"
    echo -e "${GREEN}0.${PLAIN} 回到上一级菜单"
    echo ""
    while true
    do
        read -rp "请输入选项:" StartInputh
        case $StartInputh in
            1) bash <(curl -sSL https://raw.githubusercontent.com/spiritLHLS/ecs/main/archive/disk_info.sh) ; break ;;
            2) bash <(curl -sSL https://raw.githubusercontent.com/spiritLHLS/ecs/main/archive/geekbench4.sh) ; break ;;
            3) bash <(curl -sSL https://raw.githubusercontent.com/spiritLHLS/ecs/main/archive/geekbench5.sh) ; break ;;
            4) bash <(curl -sSL https://raw.githubusercontent.com/spiritLHLS/ecs/main/archive/geekbench6.sh) ; break ;;
            5) bash <(curl -sSL https://raw.githubusercontent.com/spiritLHLS/ecs/main/archive/multi_disk_io_test.sh) ; break ;;
            0) original_script ; break ;;
            *) echo "输入错误，请重新输入" ;;
        esac
    done
}

original_script(){
    head_script
    _yellow "融合怪借鉴的脚本以及部分竞品脚本合集如下"
    echo -e "${GREEN}1.${PLAIN} 综合性测试脚本合集(比如yabs，superbench等)"
    echo -e "${GREEN}2.${PLAIN} 流媒体测试脚本合集(各种流媒体解锁相关)"
    echo -e "${GREEN}3.${PLAIN} 网络测试脚本合集(如三网回程和三网测速等)"
    echo -e "${GREEN}4.${PLAIN} 硬件测试脚本合集(如gb5，硬盘通电时长等)"
    echo " -------------"
    echo -e "${GREEN}0.${PLAIN} 回到主菜单"
    echo ""
    while true
    do
        read -rp "请输入选项:" StartInput3
        case $StartInput3 in
            1) comprehensive_test_script ; break ;;
            2) media_test_script ; break ;;
            3) network_test_script ; break ;;
            4) hardware_test_script ; break ;;
            0) start_script ; break ;;
            *) echo "输入错误，请重新输入" ;;
        esac
    done
}

simplify_script(){
    head_script
    _yellow "融合怪的精简脚本如下"
    echo -e "${GREEN}1.${PLAIN} 极简版(系统信息+CPU+内存+磁盘IO+测速节点4个)(平均运行3分钟)"
    echo -e "${GREEN}2.${PLAIN} 精简版(系统信息+CPU+内存+磁盘IO+御三家解锁+常用流媒体+TikTok+回程+路由+测速节点4个)(平均运行4分钟)"
    echo -e "${GREEN}3.${PLAIN} 精简网络版(系统信息+CPU+内存+磁盘IO+回程+路由+测速节点4个)(平均运行4分钟)"
    echo -e "${GREEN}4.${PLAIN} 精简解锁版(系统信息+CPU+内存+磁盘IO+御三家解锁+常用流媒体+TikTok+测速节点4个)(平均运行4分钟)"
    echo " -------------"
    echo -e "${GREEN}0.${PLAIN} 回到主菜单"
    echo ""
    while true
    do
        read -rp "请输入选项:" StartInput1
        case $StartInput1 in
            1) minal_script | tee -i test_result.txt; break ;;
            2) minal_plus | tee -i test_result.txt; break ;;
            3) minal_plus_network | tee -i test_result.txt; break ;;
            4) minal_plus_media | tee -i test_result.txt; break ;;
            0) start_script ; break ;;
            *) echo "输入错误，请重新输入" ;;
        esac
    done
}

single_item_script(){
    head_script
    _yellow "融合怪拆分的单项测试脚本如下"
    echo -e "${GREEN}1.${PLAIN} 网络方面(简化的IP质量检测+三网回程+三网路由与延迟+测速节点11个)(平均运行6分钟左右)"
    echo -e "${GREEN}2.${PLAIN} 解锁方面(御三家解锁+常用流媒体解锁+TikTok解锁)(平均运行30~60秒)"
    echo -e "${GREEN}3.${PLAIN} 硬件方面(基础系统信息+CPU+内存+双重磁盘IO测试)(平均运行1分半钟)"
    echo -e "${GREEN}4.${PLAIN} 完整的IP质量检测(平均运行10~20秒)"
    echo -e "${GREEN}5.${PLAIN} 常用端口开通情况(是否有阻断)(平均运行1分钟左右)(暂时有bug未修复)"
    echo -e "${GREEN}6.${PLAIN} 三网回程线路+广州三网路由+全国三网延迟(平均运行1分20秒)"
    echo " -------------"
    echo -e "${GREEN}0.${PLAIN} 回到主菜单"
    echo ""
    while true
    do
        read -rp "请输入选项:" StartInput2
        case $StartInput2 in
            1) network_script; break ;;
            2) media_script; break ;;
            3) hardware_script; break ;;
            4) bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/qzcheck.sh); break ;;
            5) port_script ; break ;;
            6) sw_script ; break ;;
            0) start_script ; break ;;
            *) echo "输入错误，请重新输入" ;;
        esac
    done
}

my_original_script(){
    head_script
    _yellow "本作者有原创成分的脚本如下"
    echo -e "${GREEN}1.${PLAIN} 完整的本机IP的IP质量检测(平均运行10~20秒)"
    echo -e "${GREEN}2.${PLAIN} 三网回程路由测试(预设广州)(平均运行1分钟)"
    echo -e "${GREEN}3.${PLAIN} 三网回程路由测试(预设上海)(平均运行1分钟)"
    echo -e "${GREEN}4.${PLAIN} 三网回程路由测试(预设北京)(平均运行1分钟)"
    echo -e "${GREEN}5.${PLAIN} 三网回程路由测试(预设成都)(平均运行1分钟)"
    echo -e "${GREEN}6.${PLAIN} 自定义IP的回程路由测试(基于besttrace)(准确率高)"
    echo -e "${GREEN}7.${PLAIN} 自定义IP的回程路由测试(基于nexttrace)(第三方IP库)"
    echo -e "${GREEN}8.${PLAIN} 自定义IP的IP质量检测(平均运行10~20秒)"
    echo -e "${GREEN}9.${PLAIN} 检测本机硬盘(含通电时长)(一般是独服才有用)"
    echo -e "${GREEN}10.${PLAIN} Geekbench4测试(最常见的CPU基准测试)"
    echo -e "${GREEN}11.${PLAIN} Geekbench5测试(测不动gb6可以试试这个)"
    echo -e "${GREEN}12.${PLAIN} Geekbench6测试(测的极其缓慢)"
    echo -e "${GREEN}13.${PLAIN} ecs-net三网测速脚本(自动更新测速节点，对应 speedtest.net)"
    echo -e "${GREEN}14.${PLAIN} ecs-cn三网测速脚本(自动更新测速节点，对应 speedtest.cn)"
    echo -e "${GREEN}15.${PLAIN} ecs-ping三网测ping脚本(自动更新测试节点)"
    echo -e "${GREEN}16.${PLAIN} 测试挂载的多个磁盘的IO(仅测试挂载盘)"
    echo " -------------"
    echo -e "${GREEN}0.${PLAIN} 回到主菜单"
    echo ""
    while true
    do
        read -rp "请输入选项:" StartInput4
        case $StartInput4 in
            1) bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/qzcheck.sh); break ;;
            2) network_script_select 'g' ; break ;;
            3) network_script_select 's' ; break ;;
            4) network_script_select 'b' ; break ;;
            5) network_script_select 'c' ; break ;;
            6) bash <(curl -sSL https://github.com/spiritLHLS/ecs/raw/main/return.sh) ; break ;;
            7) bash <(curl -sSL https://github.com/spiritLHLS/ecs/raw/main/archive/nexttrace.sh) ; break ;;
            8) bash <(curl -sSL https://github.com/spiritLHLS/ecs/raw/main/customizeqzcheck.sh) ; break ;;
            9) bash <(curl -sSL https://github.com/spiritLHLS/ecs/raw/main/archive/disk_info.sh) ; break ;;
            10) bash <(curl -sSL https://github.com/spiritLHLS/ecs/raw/main/archive/geekbench4.sh) ; break ;;
            11) bash <(curl -sSL https://github.com/spiritLHLS/ecs/raw/main/archive/geekbench5.sh) ; break ;;
            12) bash <(curl -sSL https://github.com/spiritLHLS/ecs/raw/main/archive/geekbench6.sh) ; break ;;
            13) bash <(wget -qO- bash.spiritlhl.net/ecs-net) ; break ;;
            14) bash <(wget -qO- bash.spiritlhl.net/ecs-cn) ; break ;;
            15) bash <(wget -qO- bash.spiritlhl.net/ecs-ping) ; break ;;
            16) bash <(curl -sSL https://raw.githubusercontent.com/spiritLHLS/ecs/main/archive/multi_disk_io_test.sh) ; break ;;
            0) start_script ; break ;;
            *) echo "输入错误，请重新输入" ;;
        esac
    done
}

head_script(){
    clear
    echo "#############################################################"
    echo -e "#                     ${YELLOW}融合怪测评脚本${PLAIN}                        #"
    echo "# 版本：$ver                                          #"
    echo "# 更新日志：$changeLog#"
    echo -e "# ${GREEN}作者${PLAIN}: spiritlhl                                           #"
   # echo -e "# ${GREEN}测评站点${PLAIN}: https://vps.spiritysdx.top                      #"
    echo -e "# ${GREEN}TG频道${PLAIN}: https://t.me/vps_reviews                          #"
    echo -e "# ${GREEN}GitHub${PLAIN}: https://github.com/spiritLHLS                     #"
    echo -e "# ${GREEN}GitLab${PLAIN}: https://gitlab.com/spiritysdx                     #"
    echo "#############################################################"
    echo ""
    _green "脚本当天运行次数:${TODAY}，累计运行次数:${TOTAL}"
    _green "请选择你接下来要使用的脚本"
}

start_script(){
    head_script
    echo -e "${GREEN}1.${PLAIN} 顺序测试--融合怪完全体(所有项目都测试)(平均运行7分钟)(机器普通推荐使用)"
    echo -e "${GREEN}2.${PLAIN} 并行测试--融合怪完全体(所有项目都测试)(平均运行5分钟)(仅机器强劲可使用，机器普通勿要使用)"
    echo -e "${GREEN}3.${PLAIN} 融合怪精简区(融合怪的精简版或单项测试精简版)"
    echo -e "${GREEN}4.${PLAIN} 融合怪单项区(融合怪的单项测试完整版)"
    echo -e "${GREEN}5.${PLAIN} 第三方脚本区(同类作者的各种测试脚本)"
    echo -e "${GREEN}6.${PLAIN} 原创区(本脚本独有的一些测试脚本)"
    echo " -------------"
    echo -e "${GREEN}0.${PLAIN} 退出"
    echo ""
    while true
    do
        read -rp "请输入选项:" StartInput
        case $StartInput in
            1) all_script "S" | tee -i test_result.txt ; break ;;
            2) all_script "B" | tee -i test_result.txt ; break ;;
            3) simplify_script ; break ;;
            4) single_item_script ; break ;;
            5) original_script ; break ;;
            6) my_original_script ; break ;;
            0) exit 1 ; break ;;
            *) echo "输入错误，请重新输入" ;;
        esac
    done
}

rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR
get_system_bit
statistics_of_run-times
start_script
global_exit_action
rm_script

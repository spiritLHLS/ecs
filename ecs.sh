#!/usr/bin/env bash
# by spiritlhl
# from https://github.com/spiritLHLS/ecs

cd /root >/dev/null 2>&1
myvar=$(pwd)
ver="2025.04.12"

# =============== 默认输入设置 ===============
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN="\033[0m"
SAVE_CURSOR="\033[s"
RESTORE_CURSOR="\033[u"
HIDE_CURSOR="\033[?25l"
SHOW_CURSOR="\033[?25h"
_red() { echo -e "\033[31m\033[01m$@\033[0m"; }
_green() { echo -e "\033[32m\033[01m$@\033[0m"; }
_yellow() { echo -e "\033[33m\033[01m$@\033[0m"; }
_blue() { echo -e "\033[36m\033[01m$@\033[0m"; }
reading() { read -rp "$(_green "$1")" "$2"; }
utf8_locale=$(locale -a 2>/dev/null | grep -i -m 1 -E "UTF-8|utf8")
if [[ -z "$utf8_locale" ]]; then
    _yellow "No UTF-8 locale found"
else
    export LC_ALL="$utf8_locale"
    export LANG="$utf8_locale"
    export LANGUAGE="$utf8_locale"
    _green "Locale set to $utf8_locale"
fi
menu_mode=true
en_status=false
swhc_mode=true
test_base_status=false
test_cpu_type=""
test_disk_type=""
test_network_type=""
build_text_status=true
multidisk_status=false
target_ipv4=""
route_location=""
enable_speedtest=true
main_menu_option=0
sub_menu_option=0
sub_of_sub_menu_option=0
break_status=true
m_params=()
# 解析命令行选项
while [ "$#" -gt 0 ]; do
    case "$1" in
    -m)
        # 处理 -m 选项，关闭菜单模式
        menu_mode=false
        shift # 移动到下一个参数
        while [ "$#" -gt 0 ] && [[ "$1" != -* ]]; do
            m_params+=("$1")
            shift
        done
        ;;
    -i)
        # 处理 -i 选项，获取IPv4地址
        target_ipv4="$2"
        swhc_mode=false
        shift 2
        ;;
    -r)
        # 处理 -r 选项，选择测试回程路由的目标地址 (三网)
        route_location="$2"
        shift 2
        ;;
    -en)
        # 处理 -en 选项，选择使用英文显示
        en_status=true
        shift
        ;;
    -base)
        # 处理 -base 选项，选择仅测试系统信息
        menu_mode=false
        test_base_status=true
        shift
        ;;
    -ctype)
        # 处理 -ctype 选项，选择测试cpu使用的方式
        test_cpu_type="$2"
        shift 2
        ;;
    -dtype)
        # 处理 -dtype 选项，选择测试磁盘使用的方式
        test_disk_type="$2"
        shift 2
        ;;
    -mdisk)
        # 处理 -mdisk 选项，选择测试多个挂载盘，且含系统盘
        multidisk_status=true
        shift
        ;;
    -stype)
        # 处理 -stype 选项，选择测试网速的数据来源，不指定时默认优先使用.net数据
        test_network_type="$2"
        shift 2
        ;;
    -bansp)
        # 处理 -bansp 选项，禁用测速
        enable_speedtest=false
        shift
        ;;
    -banup)
        # 处理 -banup 选项，禁用分享链接生成
        build_text_status=false
        shift
        ;;
    -h)
        if [ "$en_status" = true ]; then
            echo "Executed using parameter mode:"
            echo "-m     Mandatory, Specify the options in the original menu, support up to three levels of selection"
            echo "       For example, executing bash ecs.sh -m 5 1 1 will select the script execution for sub-option 1 under option 1 of option 5 of the main menu."
            echo "       Can specify only 1~3 parameter by default, e.g. -m 1 or -m 1 0 or -m 1 0 0"
            echo "-en    Optional, Can specify which language is used to display the test, unspecified Chinese is used."
            echo "-i     Optional, Can specify the target IPV4 address in the backhaul routing test."
            echo "-base  Optional, Only basic system information is tested, not CPU, hard disk, streaming, backhaul routing, etc."
            echo "-ctype Optional, Can specify the way to test the cpu, optional gb4 gb5 gb6 corresponds to geekbench version 4, 5, 6 respectively."
            echo "-dtype Optional, Can specify the program to test the IO of the hard disk, you can choose dd or fio, the former test is fast and the latter test is slow."
            echo "-mdisk Optional, Can specify to test the IO of multiple mounted disks."
            echo "-bansp Optional, Can specify not to run speedtest."
            echo "-banup Optional, Can specify to force not to generate the sharing link."
        else
            echo "使用参数模式执行："
            echo "-m     必填项，指定原本menu中的选项，最多支持三层选择"
            echo "       例如执行 bash ecs.sh -m 5 1 1 将选择主菜单第5选项下的第1选项下的子选项1的脚本执行"
            echo "       (可缺省仅指定一个参数，如 -m 1 仅指定执行融合怪完全体，执行 -m 1 0 以及 -m 1 0 0 都是指定执行融合怪完全体)"
            echo "-en    可选项，可指定测试时使用的是哪种语言进行展示，该指令指定为使用英语，未指定时使用中文"
            echo "-i     可选项，可指定回程路由测试中的目标IPV4地址，可通过 ip.sb ipinfo.io 等网站获取本地IPV4地址后指定"
            echo "-r     可选项，可指定回程路由测试中的三网IPV4地址，可选 b g s c 分别对应 北京、广州、上海、成都 的三网地址，如 -r g 指定测试广州地址"
            echo "       可指定仅测试IPV6三网，可选 b6 g6 s6 分别对应 北京、广州、上海 的三网的IPV6地址，如 -r b6 指定测试北京IPV6地址"
            echo "-base  可选项，仅测试基础的系统信息，不测试CPU、硬盘、流媒体、回程路由等内容"
            echo "-ctype 可选项，可指定通过何种方式测试cpu，可选 gb4 gb5 gb6 分别对应geekbench的4、5、6版本，无该指令则默认使用sysbench测试"
            echo "-dtype 可选项，可指定测试硬盘IO的程序，可选 dd 或 fio 前者测试快后者测试慢，无该指令则默认为都使用进行测试"
            echo "-mdisk 可选项，可指定测试多个挂载盘的IO，注意这也会测试系统盘且仅使用fio测试"
            echo "-stype 可选项，可指定测试时使用的是什么平台的测速节点，可选 .cn .com 分别对应 speedtest.cn speedtest.com 数据"
            echo "-bansp 可选项，可指定强制不测试网速，无该指令则默认测试网速"
            echo "-banup 可选项，可指定强制不生成分享链接，无该指令则默认生成分享链接"
        fi
        exit 1
        ;;
    *)
        echo "未知的选项: $1"
        exit 1
        ;;
    esac
done
if [ -n "$target_ipv4" ]; then
    if [ "$en_status" = true ]; then
        test_area_local=("Yor local public IPV4 address")
        test_ip_local=("$target_ipv4")
    else
        test_area_local=("你本地的IPV4地址")
        test_ip_local=("$target_ipv4")
    fi
fi
# 在menu_mode为false时才打印信息
if [ "$menu_mode" = false ]; then
    if [ "$en_status" = true ]; then
        _blue "Parameter is detected, use parameter mode, read the parameter as follows, display for 4 seconds"
    else
        _blue "检测到参数，使用参数模式，读取参数如下，显示4秒"
    fi
    echo "menu_mode: $menu_mode"
    echo "test_base_status: $test_base_status"
    echo "target_ipv4: $target_ipv4"
    echo "route_location: $route_location"
    echo "test_cpu_type: $test_cpu_type"
    echo "test_disk_type: $test_disk_type"
    echo "multidisk_status: $multidisk_status"
    echo "enable_speedtest: $enable_speedtest"
    echo "build_text_status: $build_text_status"
    # 读取 -m 选项后的参数
    main_menu_option=${m_params[0]:-0}
    sub_menu_option=${m_params[1]:-0}
    sub_of_sub_menu_option=${m_params[2]:-0}
    echo "main_menu_option: $main_menu_option"
    echo "sub_menu_option: $sub_menu_option"
    echo "sub_of_sub_menu_option: $sub_of_sub_menu_option"
    sleep 4
fi

# =============== 自定义基础参数 ==============
if [ "$en_status" = true ]; then
    changeLog="VPS Fusion Monster Test From Multi-script"
else
    changeLog="VPS融合怪测试(集百家之长)"
fi
http_short_url=""
https_short_url=""
TEMP_DIR='/tmp/ecs'
PROGRESS_DIR="/tmp/progress"
rm -rf "$PROGRESS_DIR"
mkdir -p "$PROGRESS_DIR"
PID_FILE="/tmp/pids.txt"
rm -rf "$PID_FILE"
temp_file_apt_fix="${TEMP_DIR}/apt_fix.txt"
WorkDir="/tmp/.LemonBench"
ipv6_condition=false
test_area_g=("广州电信" "广州联通" "广州移动")
test_ip_g=("58.60.188.222" "210.21.196.6" "120.196.165.24")
test_area_s=("上海电信" "上海联通" "上海移动")
test_ip_s=("202.96.209.133" "210.22.97.1" "211.136.112.200")
test_area_b=("北京电信" "北京联通" "北京移动")
test_ip_b=("219.141.140.10", "202.106.195.68", "221.179.155.161")
test_area_c=("成都电信" "成都联通" "成都移动")
test_ip_c=("61.139.2.69" "119.6.6.6" "211.137.96.205")
test_area_g6=("广州电信" "广州联通" "广州移动")
test_ip_g6=("240e:97c:2f:3000::44" "2408:8756:f50:1001::c" "2409:8c54:871:1001::12")
test_area_s6=("上海电信" "上海联通" "上海移动")
test_ip_s6=("240e:e1:aa00:4000::24" "2408:80f1:21:5003::a" "2409:8c1e:75b0:3003::26")
test_area_b6=("北京电信" "北京联通" "北京移动")
test_ip_b6=("2400:89c0:1053:3::69" "2400:89c0:1013:3::54" "2409:8c00:8421:1303::55")
BrowserUA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.74 Safari/537.36"
Speedtest_Go_version="1.7.10"

# =============== 基础信息设置 ===============
REGEX=("debian|astra" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "fedora" "arch" "freebsd" "alpine" "openbsd" "opencloudos")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Fedora" "Arch" "FreeBSD" "Alpine" "OpenBSD" "OpenCloudOS")
PACKAGE_UPDATE=("! apt-get update && apt-get --fix-broken install -y && apt-get update" "apt-get update" "yum -y update" "yum -y update" "yum -y update" "pacman -Sy" "pkg update" "apk update" "pkg_add -qu" "yum -y update")
PACKAGE_INSTALL=("apt-get -y install" "apt-get -y install" "yum -y install" "yum -y install" "yum -y install" "pacman -Sy --noconfirm --needed" "pkg install -y" "apk add --no-cache" "pkg_add -I" "yum -y install")
PACKAGE_REMOVE=("apt-get -y remove" "apt-get -y remove" "yum -y remove" "yum -y remove" "yum -y remove" "pacman -Rsc --noconfirm" "pkg delete" "apk del" "pkg_delete -I" "yum -y remove")
PACKAGE_UNINSTALL=("apt-get -y autoremove" "apt-get -y autoremove" "yum -y autoremove" "yum -y autoremove" "yum -y autoremove" "" "pkg autoremove" "apk autoremove" "pkg_delete -a" "yum -y autoremove")
CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')" "$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(uname -s)")
if [ -f /etc/opencloudos-release ]; then
    SYS="opencloudos"
else
    SYS="${CMD[0]}"
fi
[[ -n $SYS ]] || exit 1
for ((int = 0; int < ${#REGEX[@]}; int++)); do
    if [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]]; then
        SYSTEM="${RELEASE[int]}"
        [[ -n $SYSTEM ]] && break
    fi
done

# =================== 其他脚本相关设置 ===================
export DEBIAN_FRONTEND=noninteractive
rm -rf test_result.txt >/dev/null 2>&1
if [ ! -d "/tmp" ]; then
    mkdir /tmp
fi
usage_timeout=true
DISPLAY_RUNNING=1

# =============== 脚本退出执行相关函数 部分 ===============
trap _exit INT QUIT TERM

_exit() {
    # 终止信号捕获 - ctrl+c
    echo -e "\n${Msg_Error}Exiting ..."
    if [ "$en_status" = true ]; then
        _red "An exit operation is detected and the script terminates!"
    else
        _red "检测到退出操作，脚本终止！"
    fi
    global_exit_action
    rm_script
    exit 1
}

global_startup_init_action() {
    # 清理残留, 为新一次的运行做好准备
    echo -e "${Msg_Info}Initializing Running Enviorment, Please wait ..."
    rm -rf "$WorkDir"
    rm -rf /.tmp_LBench/
    mkdir "$WorkDir"/
    echo -e "${Msg_Info}Checking Dependency ..."
    BenchFunc_Systeminfo_GetSysteminfo
    echo -e "${Msg_Info}Starting Test ..."
}

global_exit_action() {
    reset_default_sysctl >/dev/null 2>&1
    echo -en "$SHOW_CURSOR"
    if [ "$build_text_status" = true ]; then
        build_text
        if [ -n "$https_short_url" ] || [ -n "$http_short_url" ]; then
            if [ "$en_status" = true ]; then
                _green "  ShortLink:"
            else
                _green "  短链:"
            fi

            if [ -n "$https_short_url" ]; then
                _blue "    $https_short_url"
            fi

            if [ -n "$http_short_url" ]; then
                _blue "    $http_short_url"
            fi
        fi
    fi
    rm -rf ${TEMP_DIR}
    rm -rf ${WorkDir}/
    rm -rf /.tmp_LBench/
    rm -rf *00_00
}

_exists() {
    # 查询对应变量或组件是否存在
    local cmd="$1"
    if eval type type >/dev/null 2>&1; then
        eval type "$cmd" >/dev/null 2>&1
    elif command >/dev/null 2>&1; then
        command -v "$cmd" >/dev/null 2>&1
    else
        which "$cmd" >/dev/null 2>&1
    fi
    local rt=$?
    return ${rt}
}

reset_default_sysctl() {
    # 还原系统原有的设置
    if [ -f /etc/security/limits.conf ]; then
        cp /etc/security/limits.conf.backup /etc/security/limits.conf
        rm /etc/security/limits.conf.backup
    fi
    if which systemctl >/dev/null 2>&1; then
        if [ -f "$sysctl_conf" ]; then
            cp "$sysctl_conf_backup" "$sysctl_conf"
            check_and_cat_file "$sysctl_default" >>"$sysctl_conf"
            $sysctl_path -p 2>/dev/null
            cp "$sysctl_conf_backup" "$sysctl_conf"
            rm "$sysctl_conf_backup"
            rm "$sysctl_default"
        fi
        $sysctl_path -p 2>/dev/null
    fi
}

next() {
    echo -en "\r"
    [ "${Var_OSRelease}" = "freebsd" ] && printf "%-72s\n" "-" | tr ' ' '-' && return
    printf "%-72s\n" "-" | sed 's/\s/-/g'
}

# =============== 组件预安装及文件预下载 部分 ===============
checkver() {
    check_cdn_file
    running_version=$(sed -n '7s/ver="\(.*\)"/\1/p' "$0")
    curl -L "${cdn_success_url}https://raw.githubusercontent.com/spiritLHLS/ecs/main/ecs.sh" -o ecs1.sh || curl -L "https://raw.githubusercontent.com/spiritLHLS/ecs/main/ecs.sh" -o ecs1.sh
    chmod 777 ecs1.sh
    downloaded_version=$(sed -n '7s/ver="\(.*\)"/\1/p' ecs1.sh)
    if [ "$running_version" != "$downloaded_version" ]; then
        if [ "$en_status" = true ]; then
            _yellow "Upgrade script from $ver to $downloaded_version"
        else
            _yellow "更新脚本从 $ver 到 $downloaded_version"
        fi
        mv ecs1.sh "$0"
        ./ecs.sh
    else
        if [ "$en_status" = true ]; then
            _green "This script is the lastes version."
        else
            _green "本脚本已是最新脚本无需更新"
        fi
        rm -rf ecs1.sh*
    fi
}

check_root() {
    local root_status=true
    [[ $EUID -ne 0 ]] && root_status=false
    if [ "$en_status" = true ] && [ "$root_status" = false ]; then
        echo -e "${RED}Please use root user to run this script!${PLAIN}" && exit 1
    elif [ "$root_status" = false ]; then
        echo -e "${RED}请使用 root 用户运行本脚本！${PLAIN}" && exit 1
    fi
}

check_update() {
    _yellow "Updating package management sources"
    if command -v apt-get >/dev/null 2>&1; then
        apt_update_output=$(apt-get update 2>&1)
        echo "$apt_update_output" >"$temp_file_apt_fix"
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

check_sudo() {
    _yellow "checking sudo"
    if ! command -v sudo >/dev/null 2>&1; then
        _yellow "Installing sudo"
        ${PACKAGE_INSTALL[int]} sudo >/dev/null 2>&1
    fi
}

check_curl() {
    if ! which curl >/dev/null; then
        _yellow "Installing curl"
        ${PACKAGE_INSTALL[int]} curl
    fi
    if [ $? -ne 0 ]; then
        apt-get -f install >/dev/null 2>&1
        ${PACKAGE_INSTALL[int]} curl
    fi
}

check_wget() {
    if ! which wget >/dev/null; then
        _yellow "Installing wget"
        ${PACKAGE_INSTALL[int]} wget
    fi
}

check_free() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
    if ! command -v free >/dev/null 2>&1; then
        _yellow "Installing procps"
        ${PACKAGE_INSTALL[int]} procps
    fi
}

check_lsb_release() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
    if ! command -v lsb_release >/dev/null 2>&1; then
        _yellow "Installing lsb-release"
        ${PACKAGE_INSTALL[int]} lsb-release
    fi
}

check_timeout() {
    if command -v timeout >/dev/null 2>&1; then
        usage_timeout=true
    else
        usage_timeout=false
    fi
}

check_lscpu() {
    if ! command -v lscpu >/dev/null 2>&1; then
        _yellow "Installing lscpu"
        ${PACKAGE_INSTALL[int]} lscpu
    fi
}

check_unzip() {
    if ! command -v unzip >/dev/null 2>&1; then
        _yellow "Installing unzip"
        ${PACKAGE_INSTALL[int]} unzip
    fi
}

check_ip() {
    if ! command -v ip >/dev/null 2>&1; then
        _yellow "Installing iproute2 to use ip command"
        ${PACKAGE_INSTALL[int]} iproute2
    fi
    if ! command -v ifconfig >/dev/null 2>&1; then
        _yellow "Installing net-tools to use ifconfig command"
        ${PACKAGE_INSTALL[int]} net-tools
    fi
}

check_ping() {
    _yellow "checking ping"
    if ! which ping >/dev/null; then
        _yellow "Installing ping"
        ${PACKAGE_INSTALL[int]} iputils-ping >/dev/null 2>&1
        ${PACKAGE_INSTALL[int]} ping >/dev/null 2>&1
    fi
}

check_nc() {
    _yellow "checking nc"
    if ! command -v nc >/dev/null; then
        _yellow "Installing nc"
        if command -v apt >/dev/null; then
            ${PACKAGE_INSTALL[int]} netcat >/dev/null 2>&1
        else
            ${PACKAGE_INSTALL[int]} nc >/dev/null 2>&1
        fi
    fi
}

check_tar() {
    _yellow "checking tar"
    if ! command -v tar &>/dev/null; then
        _yellow "Installing tar"
        ${PACKAGE_INSTALL[int]} tar
    fi
    if [ $? -ne 0 ]; then
        apt-get -f install >/dev/null 2>&1
        ${PACKAGE_INSTALL[int]} tar >/dev/null 2>&1
    fi
}

check_lsof() {
    _yellow "checking lsof"
    if ! command -v lsof &>/dev/null; then
        _yellow "Installing lsof"
        ${PACKAGE_INSTALL[int]} lsof
    fi
    if [ $? -ne 0 ]; then
        apt-get -f install >/dev/null 2>&1
        ${PACKAGE_INSTALL[int]} lsof >/dev/null 2>&1
    fi
}

check_haveged() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
    _yellow "checking haveged"
    if ! command -v haveged >/dev/null 2>&1; then
        ${PACKAGE_INSTALL[int]} haveged >/dev/null 2>&1
    fi
    if which systemctl >/dev/null 2>&1; then
        systemctl disable --now haveged
        systemctl enable --now haveged
    else
        service haveged stop
        service haveged start
    fi
}

check_dnsutils() {
    _yellow "Installing dnsutils"
    if [ "${Var_OSRelease}" == "centos" ]; then
        yum -y install dnsutils >/dev/null 2>&1
        yum -y install bind-utils >/dev/null 2>&1
    elif [ "${Var_OSRelease}" == "arch" ]; then
        pacman -S --noconfirm --needed bind >/dev/null 2>&1
    else
        ${PACKAGE_INSTALL[int]} dnsutils >/dev/null 2>&1
    fi
}

checkpip() {
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

check_and_cat_file() {
    local file="$1"
    # 检测文件是否存在
    if [[ -f "$file" ]]; then
        # 判断文件内容是否为空或只包含空行
        if [[ -s "$file" ]] && [[ "$(grep -vE '^\s*$' "$file")" ]]; then
            :
        else
            truncate -s 0 "$file"
        fi
    else
        truncate -s 0 "$file"
    fi
    # 检测文件内容是否包含"error"，如果包含则不打印文件内容
    if grep -q "error" "$file"; then
        return
    fi
    cat "$file"
}

# 移动光标并清除行
move_and_clear() {
    local line=$1
    echo -en "\033[${line};0H\033[K"
}

# 显示进度条
display_progress() {
    local use_tput=false
    if command -v tput >/dev/null 2>&1; then
        use_tput=true
    fi
    local progress_height=$((${#dfiles[@]} + 2)) # 进度显示所需的行数
    # 保存光标位置并隐藏光标
    echo -en "$SAVE_CURSOR$HIDE_CURSOR"
    while [ $DISPLAY_RUNNING -eq 1 ]; do
        # 将光标移动到保存的位置
        echo -en "$RESTORE_CURSOR"
        if [ "$en_status" = true ]; then
            echo "Download progress:"
        else
            echo "下载进度："
        fi
        local all_completed=true
        for dfile in "${dfiles[@]}"; do
            if [ -f "$PROGRESS_DIR/$dfile" ]; then
                local percentage=$(cat "$PROGRESS_DIR/$dfile")
                if [[ "$percentage" =~ ^[0-9]+$ ]]; then
                    percentage=$((percentage > 100 ? 100 : percentage))
                    printf "%-20s [%-50s] %3d%%\n" "$dfile" "$(printf '#%.0s' $(seq 1 $((percentage / 2))))" "$percentage"
                    if [ "$percentage" -lt 100 ]; then
                        all_completed=false
                    fi
                else
                    printf "%-20s [%-50s] ???\n" "$dfile" ""
                    all_completed=false
                fi
            else
                printf "%-20s [%-50s] ???\n" "$dfile" ""
                all_completed=false
            fi
        done
        if [ "$all_completed" = true ]; then
            break
        fi
        sleep 3.5
    done
    # 显示光标
    echo -en "$SHOW_CURSOR"
    echo ""
}

# 开始整体并发下载并显示进度条
start_downloads() {
    local dfiles=("$@") # 接收文件列表作为参数
    # 初始化进度
    for dfile in "${dfiles[@]}"; do
        echo "0" >"$PROGRESS_DIR/$dfile"
    done
    # 获取当前光标位置
    local current_line=$(tput lines)
    # 启动后台进程来更新显示
    display_progress $current_line &
    local display_pid=$!
    # 并发下载并跟踪PID
    for dfile in "${dfiles[@]}"; do
        main_download "$dfile" &
        echo $! >>"$PID_FILE"
    done
    wait
    # 停止显示进程
    DISPLAY_RUNNING=0
}

download_file() {
    local url=$1
    local output=$2
    local progress_file=$3
    # 获取文件总大小
    local total_size=$(curl -sIkL "$url" | grep -i Content-Length | awk '{print $2}' | tr -d '\r')
    if [ -z "$total_size" ] || [ "$total_size" -eq 0 ]; then
        echo "无法获取 $url 的文件大小,将使用 0 作为默认值。" >&2
        total_size=0
    fi
    # 连续检测到下载完成的次数
    local complete_count=0
    # 连续检测到下载失败的次数
    local download_failed=0
    while true; do
        if ! curl -Lk "$url" -o "$output" 2>&1 |
            while true; do
                if [ -f "$output" ]; then
                    sleep 1
                    local current_size=$(stat -f%z "$output" 2>/dev/null || stat -c%s "$output" 2>/dev/null)
                    if [ "$total_size" -gt 0 ]; then
                        local progress=$((current_size * 100 / total_size))
                    else
                        local progress=0
                    fi
                    echo "$progress" >"$progress_file"
                    sleep 1
                    # 检查是否下载完成
                    if [ "$current_size" -ge "$total_size" ]; then
                        complete_count=$((complete_count + 1))
                        # 只有连续3次检测到下载完成才退出循环
                        if [ "$complete_count" -ge 3 ]; then
                            break 2 # 退出外层循环
                        fi
                    else
                        complete_count=0 # 如果不完整，重置计数器
                    fi
                fi
            done; then
            complete_count=0
            download_failed=$((download_failed + 1))
            if [ "$download_failed" -ge 2 ]; then
                echo "curl 和 wget 下载都失败,退出下载。" >&2
                return 1 # 返回错误码
            fi
            echo "curl 下载失败,切换到 wget 下载。" >&2
            wget -O "$output" "$url" 2>&1 |
                while true; do
                    if [ -f "$output" ]; then
                        sleep 1
                        local current_size=$(stat -f%z "$output" 2>/dev/null || stat -c%s "$output" 2>/dev/null)
                        if [ "$total_size" -gt 0 ]; then
                            local progress=$((current_size * 100 / total_size))
                        else
                            local progress=0
                        fi
                        echo "$progress" >"$progress_file"
                        sleep 1
                        # 检查是否下载完成
                        if [ "$current_size" -ge "$total_size" ]; then
                            complete_count=$((complete_count + 1))
                            # 只有连续3次检测到下载完成才退出循环
                            if [ "$complete_count" -ge 3 ]; then
                                break 2 # 退出外层循环
                            fi
                        else
                            complete_count=0 # 如果不完整，重置计数器
                        fi
                    fi
                done
        else
            break # curl 下载成功，退出外层循环
        fi
    done
    # 确保最终进度被写入
    if [ -f "$output" ]; then
        local final_size=$(stat -f%z "$output" 2>/dev/null || stat -c%s "$output" 2>/dev/null)
        if [ "$total_size" -gt 0 ]; then
            local final_progress=$((final_size * 100 / total_size))
        else
            local final_progress=0
        fi
        echo "$final_progress" >"$progress_file"
    fi
    # 如果下载失败两次则返回错误码
    [ "$download_failed" -ge 2 ] && error_exit && return 1 || return 0
}

main_download() {
    local file=$1
    case $file in
    sysbench)
        local url="${cdn_success_url}https://github.com/akopytov/sysbench/archive/1.0.20.zip"
        local output="$TEMP_DIR/sysbench.zip"
        download_file "$url" "$output" "$PROGRESS_DIR/$file"
        chmod +x "$output"
        unzip "$output" -d ${TEMP_DIR}
        echo "100" >"$PROGRESS_DIR/$file"
        ;;
    CommonMediaTests)
        local url="${cdn_success_url}https://github.com/oneclickvirt/CommonMediaTests/releases/download/output/${CommonMediaTests_FILE}"
        local output="$TEMP_DIR/CommonMediaTests"
        download_file "$url" "$output" "$PROGRESS_DIR/$file"
        chmod +x "$output"
        echo "100" >"$PROGRESS_DIR/$file"
        ;;
    media_lmc_check)
        local url="${cdn_success_url}https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh"
        local output="$TEMP_DIR/media_lmc_check.sh"
        download_file "$url" "$output" "$PROGRESS_DIR/$file"
        chmod 777 "$output"
        echo "100" >"$PROGRESS_DIR/$file"
        ;;
    nexttrace)
        NEXTTRACE_VERSION=$(curl -m 6 -sSL "https://api.github.com/repos/nxtrace/Ntrace-core/releases/latest" | awk -F \" '/tag_name/{print $4}')
        if [ -z "$NEXTTRACE_VERSION" ]; then
            NEXTTRACE_VERSION=$(curl -m 6 -sSL "https://fd.spiritlhl.top/https://api.github.com/repos/nxtrace/Ntrace-core/releases/latest" | awk -F \" '/tag_name/{print $4}')
        fi
        if [ -z "$NEXTTRACE_VERSION" ]; then
            NEXTTRACE_VERSION=$(curl -m 6 -sSL "https://githubapi.spiritlhl.top/repos/nxtrace/Ntrace-core/releases/latest" | awk -F \" '/tag_name/{print $4}')
        fi
        local url="${cdn_success_url}https://github.com/nxtrace/Ntrace-core/releases/download/${NEXTTRACE_VERSION}/${NEXTTRACE_FILE}"
        local output="$TEMP_DIR/$NEXTTRACE_FILE"
        download_file "$url" "$output" "$PROGRESS_DIR/$file"
        chmod +x "$output"
        echo "100" >"$PROGRESS_DIR/$file"
        ;;
    backtrace)
        local url="${cdn_success_url}https://github.com/oneclickvirt/backtrace/releases/download/output/$BACKTRACE_FILE"
        local output="$TEMP_DIR/backtrace"
        download_file "$url" "$output" "$PROGRESS_DIR/$file"
        echo "100" >"$PROGRESS_DIR/$file"
        ;;
    gostun)
        local url="${cdn_success_url}https://github.com/oneclickvirt/gostun/releases/download/output/$GOSTUN_FILE"
        local output="$TEMP_DIR/gostun"
        download_file "$url" "$output" "$PROGRESS_DIR/$file"
        echo "100" >"$PROGRESS_DIR/$file"
        ;;
    securityCheck)
        local url="${cdn_success_url}https://github.com/oneclickvirt/securityCheck/releases/download/output/$SecurityCheck_FILE"
        local output="$TEMP_DIR/securityCheck"
        download_file "$url" "$output" "$PROGRESS_DIR/$file"
        echo "100" >"$PROGRESS_DIR/$file"
        ;;
    portchecker)
        local url="${cdn_success_url}https://github.com/oneclickvirt/portchecker/releases/download/output/$PortChecker_FILE"
        local output="$TEMP_DIR/pck"
        download_file "$url" "$output" "$PROGRESS_DIR/$file"
        echo "100" >"$PROGRESS_DIR/$file"
        ;;
    yabs)
        local url="${cdn_success_url}https://raw.githubusercontent.com/masonr/yet-another-bench-script/master/yabs.sh"
        local output="$TEMP_DIR/yabs.sh"
        download_file "$url" "$output" "$PROGRESS_DIR/$file"
        chmod +x "$output"
        sed -i '/# gather basic system information (inc. CPU, AES-NI\/virt status, RAM + swap + disk size)/,/^echo -e "IPv4\/IPv6  : $ONLINE"/d' "$output"
        echo "100" >"$PROGRESS_DIR/$file"
        ;;
    ecsspeed_ping)
        local url="${cdn_success_url}https://raw.githubusercontent.com/spiritLHLS/ecsspeed/main/script/ecsspeed-ping.sh"
        local output="$TEMP_DIR/ecsspeed-ping.sh"
        download_file "$url" "$output" "$PROGRESS_DIR/$file"
        chmod +x "$output"
        echo "100" >"$PROGRESS_DIR/$file"
        ;;
    *)
        echo "Invalid file: $file"
        echo "0" >"$PROGRESS_DIR/$file"
        ;;
    esac
}

# =============== 其他相关信息查询 部分 ===============
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
    ["net.ipv4.tcp_rmem"]="8192 262144 536870912"
    ["net.ipv4.tcp_wmem"]="4096 16384 536870912"
    ["net.ipv4.tcp_adv_win_scale"]=-2
    ["net.ipv4.tcp_collapse_max_bytes"]=6291456
    ["net.ipv4.tcp_notsent_lowat"]=131072
    ["net.ipv4.udp_rmem_min"]=16384
    ["net.ipv4.udp_wmem_min"]=16384
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

optimized_kernel() {
    _yellow "optimizing resource limits"
    if [ -f /etc/security/limits.conf ]; then
        cp /etc/security/limits.conf /etc/security/limits.conf.backup
        cat >/etc/security/limits.conf <<EOF
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
            echo "" >"$sysctl_default"
            for variable in "${!sysctl_vars[@]}"; do
                value="${sysctl_vars[$variable]}"
                if variable_exists "$variable"; then
                    sed -i "s/^$variable=.*/$variable=$value/" "$sysctl_conf"
                else
                    echo "$variable=$value" >>"$sysctl_conf"
                    default_value="${default_values[$variable]}"
                    echo "$variable=$default_value" >>"$sysctl_default"
                fi
            done
            $sysctl_path -p 2>/dev/null
        fi
    fi
}

check_cdn() {
    local o_url=$1
    for cdn_url in "${cdn_urls[@]}"; do
        if curl -sL -k "$cdn_url$o_url" --max-time 6 | grep -q "success" >/dev/null 2>&1; then
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
        _yellow "No CDN available, using original links"
        export cdn_success_url=""
    fi
}

check_time_zone() {
    _yellow "adjusting the time"
    if command -v ntpd >/dev/null 2>&1; then
        if which systemctl >/dev/null 2>&1; then
            systemctl stop chronyd
            systemctl stop ntpd
        else
            service chronyd stop
            service ntpd stop
        fi
        if lsof -i:123 | grep -q "ntpd"; then
            echo "Port 123 is already in use. Skipping ntpd command."
        else
            # 最多对准时长进行60秒，避免对准时间这个过程耗时过长
            if [ "$usage_timeout" = true ]; then
                timeout 60s ntpd -gq
            else
                ntpd -gq
            fi
            if which systemctl >/dev/null 2>&1; then
                systemctl start ntpd
            else
                service ntpd start
            fi
        fi
        sleep 0.5
        return
    fi
    if ! command -v chronyd >/dev/null 2>&1; then
        ${PACKAGE_INSTALL[int]} chrony >/dev/null 2>&1
    fi
    if which systemctl >/dev/null 2>&1; then
        systemctl stop chronyd
        chronyd -q -t 30
        systemctl start chronyd
    else
        service chronyd stop
        chronyd -q -t 30
        service chronyd start
    fi
    sleep 0.5
}

check_nat_type() {
    _yellow "NAT Type being detected ......"
    if [[ ! -z "$IPV4" ]]; then
        if [ -f "$TEMP_DIR/gostun" ]; then
            chmod 777 $TEMP_DIR/gostun
            output=$($TEMP_DIR/gostun | tail -n 1)
            if [[ $output == *"NAT Type"* ]]; then
                nat_type_r=$(echo "$output" | awk -F ':' '{print $NF}' | awk '{$1=$1;print}')
            else
                if [ "$en_status" = true ]; then
                    nat_type_r="The query fails, please try other architectures of https://github.com/oneclickvirt/gostun by yourself"
                else
                    nat_type_r="查询失败，请自行尝试 https://github.com/oneclickvirt/gostun 的其他架构"
                fi
            fi
        fi
    fi
}

check_china() {
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
        fi
    fi
}

statistics_of_run_times() {
    COUNT=$(curl -4 -ksm1 "https://hits.spiritlhl.net/ecs?action=hit&title=Hits&title_bg=%23555555&count_bg=%2324dde1&edge_flat=false" 2>/dev/null ||
        curl -6 -ksm1 "https://hits.spiritlhl.net/ecs?action=hit&title=Hits&title_bg=%23555555&count_bg=%2324dde1&edge_flat=false" 2>/dev/null)
    TODAY=$(echo "$COUNT" | grep -oP '"daily":\s*[0-9]+' | sed 's/"daily":\s*\([0-9]*\)/\1/')
    TOTAL=$(echo "$COUNT" | grep -oP '"total":\s*[0-9]+' | sed 's/"total":\s*\([0-9]*\)/\1/')
}

# =============== 基础系统信息 部分 ===============
systemInfo_get_os_release() {
    local regex_size=${#REGEX[@]}
    for ((i = 0; i < regex_size; i++)); do
        local pattern="${REGEX[i]}"
        if [ -f "/etc/debian_version" ] && [[ "$pattern" == "debian|astra" ]]; then
            Var_OSRelease="debian"
            break
        elif [ -f "/etc/lsb-release" ] && [[ "$pattern" == "ubuntu" ]]; then
            Var_OSRelease="ubuntu"
            break
        elif [ -f "/etc/redhat-release" ] && [[ "$pattern" == "centos|red hat|kernel|oracle linux|alma|rocky" ]]; then
            Var_OSRelease="centos"
            break
        elif [ -f "/etc/amazon-linux-release" ] && [[ "$pattern" == "'amazon linux'" ]]; then
            Var_OSRelease="centos"
            break
        elif [ -f "/etc/fedora-release" ] && [[ "$pattern" == "fedora" ]]; then
            Var_OSRelease="fedora"
            break
        elif [ -f "/etc/arch-release" ] && [[ "$pattern" == "arch" ]]; then
            Var_OSRelease="arch"
            break
        elif [ -f "/etc/freebsd-update.conf" ] && [[ "$pattern" == "freebsd" ]]; then
            Var_OSRelease="freebsd"
            break
        elif [ -f "/etc/alpine-release" ] && [[ "$pattern" == "alpine" ]]; then
            Var_OSRelease="alpinelinux"
            break
        elif [ -f "/etc/openbsd.conf" ] && [[ "$pattern" == "openbsd" ]]; then
            Var_OSRelease="openbsd"
            break
        elif [ -f "/etc/opencloudos-release" ] && [[ "$pattern" == "opencloudos" ]]; then
            Var_OSRelease="opencloudos"
            break
        fi
    done
    if [ -z "$Var_OSRelease" ]; then
        Var_OSRelease="unknown"
    fi
    if [ -f /etc/os-release ]; then
        DISTRO=$(grep 'PRETTY_NAME' /etc/os-release | cut -d '"' -f 2)
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
        GOSTUN_FILE=gostun-linux-386
        # BESTTRACE_FILE=besttracemac
        CommonMediaTests_FILE=CommonMediaTests-linux-386
        SecurityCheck_FILE=securityCheck-linux-386
        PortChecker_FILE=portchecker-linux-386
        BACKTRACE_FILE=backtrace-linux-386
        NEXTTRACE_FILE=nexttrace_darwin_amd64
        ;;
    "armv7l" | "armv8" | "armv8l" | "aarch64" | "arm64")
        LBench_Result_SystemBit_Short="arm"
        LBench_Result_SystemBit_Full="arm"
        GOSTUN_FILE=gostun-linux-arm64
        # BESTTRACE_FILE=besttracearm
        CommonMediaTests_FILE=CommonMediaTests-linux-arm64
        SecurityCheck_FILE=securityCheck-linux-arm64
        PortChecker_FILE=portchecker-linux-arm64
        BACKTRACE_FILE=backtrace-linux-arm64
        NEXTTRACE_FILE=nexttrace_linux_arm64
        ;;
    *)
        LBench_Result_SystemBit_Short="64"
        LBench_Result_SystemBit_Full="amd64"
        GOSTUN_FILE=gostun-linux-amd64
        # BESTTRACE_FILE=besttrace
        CommonMediaTests_FILE=CommonMediaTests-linux-amd64
        SecurityCheck_FILE=securityCheck-linux-amd64
        PortChecker_FILE=portchecker-linux-amd64
        BACKTRACE_FILE=backtrace-linux-amd64
        NEXTTRACE_FILE=nexttrace_linux_amd64
        ;;
    esac
}

# https://github.com/LemonBench/LemonBench/blob/main/LemonBench.sh
# ===========================================================================
# -> 系统信息模块 (Entrypoint) -> 执行
function BenchFunc_Systeminfo_GetSysteminfo() {
    BenchAPI_Systeminfo_GetCPUinfo
    BenchAPI_Systeminfo_GetVMMinfo
    BenchAPI_Systeminfo_GetMemoryinfo
    BenchAPI_Systeminfo_GetDiskinfo
    BenchAPI_Systeminfo_GetOSReleaseinfo
    # BenchAPI_Systeminfo_GetLinuxKernelinfo
}
#
# -> 系统信息模块 (Collector) -> 获取CPU信息
function BenchAPI_Systeminfo_GetCPUinfo() {
    # CPU 基础信息检测
    local r_modelname && r_modelname="$(lscpu -B 2>/dev/null | grep -oP -m1 "(?<=Model name:).*(?=)" | sed -e 's/^[ ]*//g')"
    local r_cachesize_l1d_b && r_cachesize_l1d_b="$(lscpu -B 2>/dev/null | grep -oP "(?<=L1d cache:).*(?=)" | sed -e 's/^[ ]*//g')"
    local r_cachesize_l1i_b && r_cachesize_l1i_b="$(lscpu -B 2>/dev/null | grep -oP "(?<=L1i cache:).*(?=)" | sed -e 's/^[ ]*//g')"
    local r_cachesize_l1_b && r_cachesize_l1_b="$(echo "$r_cachesize_l1d_b" "$r_cachesize_l1i_b" | awk '{printf "%d\n",$1+$2}')"
    local r_cachesize_l1_k && r_cachesize_l1_k="$(echo "$r_cachesize_l1_b" | awk '{printf "%.2f\n",$1/1024}')"
    local t_cachesize_l1_k && t_cachesize_l1_k="$(echo "$r_cachesize_l1_b" | awk '{printf "%d\n",$1/1024}')"
    if [ "$t_cachesize_l1_k" -ge "1024" ]; then
        local r_cachesize_l1_m && r_cachesize_l1_m="$(echo "$r_cachesize_l1_k" | awk '{printf "%.2f\n",$1/1024}')"
        local r_cachesize_l1="$r_cachesize_l1_m MB"
    else
        local r_cachesize_l1="$r_cachesize_l1_k KB"
    fi
    local r_cachesize_l2_b && r_cachesize_l2_b="$(lscpu -B 2>/dev/null | grep -oP "(?<=L2 cache:).*(?=)" | sed -e 's/^[ ]*//g')"
    local r_cachesize_l2_k && r_cachesize_l2_k="$(echo "$r_cachesize_l2_b" | awk '{printf "%.2f\n",$1/1024}')"
    local t_cachesize_l2_k && t_cachesize_l2_k="$(echo "$r_cachesize_l2_b" | awk '{printf "%d\n",$1/1024}')"
    if [ "$t_cachesize_l2_k" -ge "1024" ]; then
        local r_cachesize_l2_m && r_cachesize_l2_m="$(echo "$r_cachesize_l2_k" | awk '{printf "%.2f\n",$1/1024}')"
        local r_cachesize_l2="$r_cachesize_l2_m MB"
    else
        local r_cachesize_l2="$r_cachesize_l2_k KB"
    fi
    local r_cachesize_l3_b && r_cachesize_l3_b="$(lscpu -B 2>/dev/null | grep -oP "(?<=L3 cache:).*(?=)" | sed -e 's/^[ ]*//g')"
    local r_cachesize_l3_k && r_cachesize_l3_k="$(echo "$r_cachesize_l3_b" | awk '{printf "%.2f\n",$1/1024}')"
    local t_cachesize_l3_k && t_cachesize_l3_k="$(echo "$r_cachesize_l3_b" | awk '{printf "%d\n",$1/1024}')"
    if [ "$t_cachesize_l3_k" -ge "1024" ]; then
        local r_cachesize_l3_m && r_cachesize_l3_m="$(echo "$r_cachesize_l3_k" | awk '{printf "%.2f\n",$1/1024}')"
        local r_cachesize_l3="$r_cachesize_l3_m MB"
    else
        local r_cachesize_l3="$r_cachesize_l3_k KB"
    fi
    local r_sockets && r_sockets="$(lscpu -B 2>/dev/null | grep -oP "(?<=Socket\(s\):).*(?=)" | sed -e 's/^[ ]*//g')"
    if [ "$r_sockets" -ge "2" ]; then
        local r_cores && r_cores="$(lscpu -B 2>/dev/null | grep -oP "(?<=Core\(s\) per socket:).*(?=)" | sed -e 's/^[ ]*//g')"
        r_cores="$(echo "$r_sockets" "$r_cores" | awk '{printf "%d\n",$1*$2}')"
        local r_threadpercore && r_threadpercore="$(lscpu -B 2>/dev/null | grep -oP "(?<=Thread\(s\) per core:).*(?=)" | sed -e 's/^[ ]*//g')"
        local r_threads && r_threads="$(echo "$r_cores" "$r_threadpercore" | awk '{printf "%d\n",$1*$2}')"
        r_threads="$(echo "$r_threadpercore" "$r_cores" | awk '{printf "%d\n",$1*$2}')"
    else
        local r_cores && r_cores="$(lscpu -B 2>/dev/null | grep -oP "(?<=Core\(s\) per socket:).*(?=)" | sed -e 's/^[ ]*//g')"
        local r_threadpercore && r_threadpercore="$(lscpu -B 2>/dev/null | grep -oP "(?<=Thread\(s\) per core:).*(?=)" | sed -e 's/^[ ]*//g')"
        local r_threads && r_threads="$(echo "$r_cores" "$r_threadpercore" | awk '{printf "%d\n",$1*$2}')"
    fi
    # CPU AES能力检测
    # local t_aes && t_aes="$(awk -F ': ' '/flags/{print $2}' /proc/cpuinfo 2>/dev/null | grep -oE "\baes\b" | sort -u)"
    # [[ "${t_aes}" = "aes" ]] && Result_Systeminfo_CPUAES="1" || Result_Systeminfo_CPUAES="0"
    # CPU AVX能力检测
    # local t_avx && t_avx="$(awk -F ': ' '/flags/{print $2}' /proc/cpuinfo 2>/dev/null | grep -oE "\bavx\b" | sort -u)"
    # [[ "${t_avx}" = "avx" ]] && Result_Systeminfo_CPUAVX="1" || Result_Systeminfo_CPUAVX="0"
    # CPU AVX512能力检测
    # local t_avx512 && t_avx512="$(awk -F ': ' '/flags/{print $2}' /proc/cpuinfo 2>/dev/null | grep -oE "\bavx512\b" | sort -u)"
    # [[ "${t_avx512}" = "avx" ]] && Result_Systeminfo_CPUAVX512="1" || Result_Systeminfo_CPUAVX512="0"
    # CPU 虚拟化能力检测
    local t_vmx_vtx && t_vmx_vtx="$(awk -F ': ' '/flags/{print $2}' /proc/cpuinfo 2>/dev/null | grep -oE "\bvmx\b" | sort -u)"
    local t_vmx_svm && t_vmx_svm="$(awk -F ': ' '/flags/{print $2}' /proc/cpuinfo 2>/dev/null | grep -oE "\bsvm\b" | sort -u)"
    if [ "$t_vmx_vtx" = "vmx" ]; then
        Result_Systeminfo_VirtReady="1"
        Result_Systeminfo_CPUVMX="Intel VT-x"
    elif [ "$t_vmx_svm" = "svm" ]; then
        Result_Systeminfo_VirtReady="1"
        Result_Systeminfo_CPUVMX="AMD-V"
    else
        if [ -c "/dev/kvm" ]; then
            Result_Systeminfo_VirtReady="1"
            Result_Systeminfo_CPUVMX="unknown"
        else
            Result_Systeminfo_VirtReady="0"
            Result_Systeminfo_CPUVMX="unknown"
        fi
    fi
    # 输出结果
    Result_Systeminfo_CPUModelName="$r_modelname"
    Result_Systeminfo_CPUSockets="$r_sockets"
    Result_Systeminfo_CPUCores="$r_cores"
    Result_Systeminfo_CPUThreads="$r_threads"
    Result_Systeminfo_CPUCacheSizeL1="$r_cachesize_l1"
    Result_Systeminfo_CPUCacheSizeL2="$r_cachesize_l2"
    Result_Systeminfo_CPUCacheSizeL3="$r_cachesize_l3"
}
#
# -> 系统信息模块 (Collector) -> 获取内存及Swap信息
function BenchAPI_Systeminfo_GetMemoryinfo() {
    # 内存信息
    local r_memtotal_kib && r_memtotal_kib="$(awk '/MemTotal/{print $2}' /proc/meminfo | head -n1)"
    local r_memtotal_mib && r_memtotal_mib="$(echo "$r_memtotal_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_memtotal_gib && r_memtotal_gib="$(echo "$r_memtotal_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_meminfo_memfree_kib && r_meminfo_memfree_kib="$(awk '/MemFree/{print $2}' /proc/meminfo | head -n1)"
    local r_meminfo_buffers_kib && r_meminfo_buffers_kib="$(awk '/Buffers/{print $2}' /proc/meminfo | head -n1)"
    local r_meminfo_cached_kib && r_meminfo_cached_kib="$(awk '/Cached/{print $2}' /proc/meminfo | head -n1)"
    local r_memfree_kib && r_memfree_kib="$(echo "$r_meminfo_memfree_kib" "$r_meminfo_buffers_kib" "$r_meminfo_cached_kib" | awk '{printf $1+$2+$3}')"
    local r_memfree_mib && r_memfree_mib="$(echo "$r_memfree_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_memfree_gib && r_memfree_gib="$(echo "$r_memfree_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_memused_kib && r_memused_kib="$(echo "$r_memtotal_kib" "$r_memfree_kib" | awk '{printf $1-$2}')"
    local r_memused_mib && r_memused_mib="$(echo "$r_memused_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_memused_gib && r_memused_gib="$(echo "$r_memused_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    # 交换信息
    local r_swaptotal_kib && r_swaptotal_kib="$(awk '/SwapTotal/{print $2}' /proc/meminfo | head -n1)"
    local r_swaptotal_mib && r_swaptotal_mib="$(echo "$r_swaptotal_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_swaptotal_gib && r_swaptotal_gib="$(echo "$r_swaptotal_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_swapfree_kib && r_swapfree_kib="$(awk '/SwapFree/{print $2}' /proc/meminfo | head -n1)"
    local r_swapfree_mib && r_swapfree_mib="$(echo "$r_swapfree_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_swapfree_gib && r_swapfree_gib="$(echo "$r_swapfree_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_swapused_kib && r_swapused_kib="$(echo "$r_swaptotal_kib" "${r_swapfree_kib}" | awk '{printf $1-$2}')"
    local r_swapused_mib && r_swapused_mib="$(echo "$r_swapused_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_swapused_gib && r_swapused_gib="$(echo "$r_swapused_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    # 数据加工
    if [ "$r_memused_kib" -lt "1024" ] && [ "$r_memtotal_kib" -lt "1048576" ]; then
        Result_Systeminfo_Memoryinfo="$r_memused_kib KiB / $r_memtotal_mib MiB"
    elif [ "$r_memused_kib" -lt "1048576" ] && [ "$r_memtotal_kib" -lt "1048576" ]; then
        Result_Systeminfo_Memoryinfo="$r_memused_mib MiB / $r_memtotal_mib MiB"
    elif [ "$r_memused_kib" -lt "1048576" ] && [ "$r_memtotal_kib" -lt "1073741824" ]; then
        Result_Systeminfo_Memoryinfo="$r_memused_mib MiB / $r_memtotal_gib GiB"
    else
        Result_Systeminfo_Memoryinfo="$r_memused_gib GiB / $r_memtotal_gib GiB"
    fi
    if [ "$r_swaptotal_kib" -eq "0" ]; then
        Result_Systeminfo_Swapinfo="[ no swap partition or swap file detected ]"
    elif [ "$r_swapused_kib" -lt "1024" ] && [ "$r_swaptotal_kib" -lt "1048576" ]; then
        Result_Systeminfo_Swapinfo="$r_swapused_kib KiB / $r_swaptotal_mib MiB"
    elif [ "$r_swapused_kib" -lt "1024" ] && [ "$r_swaptotal_kib" -lt "1073741824" ]; then
        Result_Systeminfo_Swapinfo="$r_swapused_kib KiB / $r_swaptotal_gib GiB"
    elif [ "$r_swapused_kib" -lt "1048576" ] && [ "$r_swaptotal_kib" -lt "1048576" ]; then
        Result_Systeminfo_Swapinfo="$r_swapused_mib MiB / $r_swaptotal_mib MiB"
    elif [ "$r_swapused_kib" -lt "1048576" ] && [ "$r_swaptotal_kib" -lt "1073741824" ]; then
        Result_Systeminfo_Swapinfo="$r_swapused_mib MiB / $r_swaptotal_gib GiB"
    else
        Result_Systeminfo_Swapinfo="$r_swapused_gib GiB / $r_swaptotal_gib GiB"
    fi
}
#
# -> 系统信息模块 (Collector) -> 获取磁盘信息
function BenchAPI_Systeminfo_GetDiskinfo() {
    # 磁盘信息
    local r_diskpath_root && r_diskpath_root="$(df -x tmpfs / | awk "NR>1" | sed ":a;N;s/\\n//g;ta" | awk '{print $1}')"
    local r_disktotal_kib && r_disktotal_kib="$(df -x tmpfs / | grep -oE "[0-9]{4,}" | awk 'NR==1 {print $1}')"
    local r_disktotal_mib && r_disktotal_mib="$(echo "$r_disktotal_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_disktotal_gib && r_disktotal_gib="$(echo "$r_disktotal_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_disktotal_tib && r_disktotal_tib="$(echo "$r_disktotal_kib" | awk '{printf "%.2f\n",$1/1073741824}')"
    local r_diskused_kib && r_diskused_kib="$(df -x tmpfs / | grep -oE "[0-9]{4,}" | awk 'NR==2 {print $1}')"
    local r_diskused_mib && r_diskused_mib="$(echo "$r_diskused_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_diskused_gib && r_diskused_gib="$(echo "$r_diskused_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_diskused_tib && r_diskused_tib="$(echo "$r_diskused_kib" | awk '{printf "%.2f\n",$1/1073741824}')"
    local r_diskfree_kib && r_diskfree_kib="$(df -x tmpfs / | grep -oE "[0-9]{4,}" | awk 'NR==3 {print $1}')"
    local r_diskfree_mib && r_diskfree_mib="$(echo "$r_diskfree_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_diskfree_gib && r_diskfree_gib="$(echo "$r_diskfree_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_diskfree_tib && r_diskfree_tib="$(echo "$r_diskfree_kib" | awk '{printf "%.2f\n",$1/1073741824}')"
    # 数据加工
    Result_Systeminfo_DiskRootPath="$r_diskpath_root"
    if [ "$r_diskused_kib" -lt "1048576" ]; then
        Result_Systeminfo_Diskinfo="$r_diskused_mib MiB / $r_disktotal_mib MiB"
    elif [ "$r_diskused_kib" -lt "1048576" ] && [ "$r_disktotal_kib" -lt "1073741824" ]; then
        Result_Systeminfo_Diskinfo="$r_diskused_mib MiB / $r_disktotal_gib GiB"
    elif [ "$r_diskused_kib" -lt "1073741824" ] && [ "$r_disktotal_kib" -lt "1073741824" ]; then
        Result_Systeminfo_Diskinfo="$r_diskused_gib GiB / $r_disktotal_gib GiB"
    elif [ "$r_diskused_kib" -lt "1073741824" ] && [ "$r_disktotal_kib" -ge "1073741824" ]; then
        Result_Systeminfo_Diskinfo="$r_diskused_gib GiB / $r_disktotal_tib TiB"
    else
        Result_Systeminfo_Diskinfo="$r_diskused_tib TiB / $r_disktotal_tib TiB"
    fi
}
#
# -> 系统信息模块 (Collector) -> 获取虚拟化信息
function BenchAPI_Systeminfo_GetVMMinfo() {
    if [ -f "/usr/bin/systemd-detect-virt" ]; then
        local r_vmmtype && r_vmmtype="$(/usr/bin/systemd-detect-virt 2>/dev/null)"
        case "${r_vmmtype}" in
        kvm)
            Result_Systeminfo_VMMType="KVM"
            Result_Systeminfo_VMMTypeShort="kvm"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        xen)
            Result_Systeminfo_VMMType="Xen Hypervisor"
            Result_Systeminfo_VMMTypeShort="xen"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        microsoft)
            Result_Systeminfo_VMMType="Microsoft Hyper-V"
            Result_Systeminfo_VMMTypeShort="microsoft"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        vmware)
            Result_Systeminfo_VMMType="VMware"
            Result_Systeminfo_VMMTypeShort="vmware"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        oracle)
            Result_Systeminfo_VMMType="Oracle VirtualBox"
            Result_Systeminfo_VMMTypeShort="oracle"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        parallels)
            Result_Systeminfo_VMMType="Parallels"
            Result_Systeminfo_VMMTypeShort="parallels"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        qemu)
            Result_Systeminfo_VMMType="QEMU"
            Result_Systeminfo_VMMTypeShort="qemu"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        amazon)
            Result_Systeminfo_VMMType="Amazon Virtualization"
            Result_Systeminfo_VMMTypeShort="amazon"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        docker)
            Result_Systeminfo_VMMType="Docker"
            Result_Systeminfo_VMMTypeShort="docker"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        openvz)
            Result_Systeminfo_VMMType="OpenVZ (Virutozzo)"
            Result_Systeminfo_VMMTypeShort="openvz"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        lxc)
            Result_Systeminfo_VMMTypeShort="lxc"
            Result_Systeminfo_VMMType="LXC"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        lxc-libvirt)
            Result_Systeminfo_VMMType="LXC (Based on libvirt)"
            Result_Systeminfo_VMMTypeShort="lxc-libvirt"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        uml)
            Result_Systeminfo_VMMType="User-mode Linux"
            Result_Systeminfo_VMMTypeShort="uml"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        systemd-nspawn)
            Result_Systeminfo_VMMType="Systemd nspawn"
            Result_Systeminfo_VMMTypeShort="systemd-nspawn"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        bochs)
            Result_Systeminfo_VMMType="BOCHS"
            Result_Systeminfo_VMMTypeShort="bochs"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        rkt)
            Result_Systeminfo_VMMType="RKT"
            Result_Systeminfo_VMMTypeShort="rkt"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        zvm)
            Result_Systeminfo_VMMType="S390 Z/VM"
            Result_Systeminfo_VMMTypeShort="zvm"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        none)
            Result_Systeminfo_VMMType="Dedicated"
            Result_Systeminfo_VMMTypeShort="none"
            Result_Systeminfo_isPhysical="1"
            if test -f "/sys/class/iommu/dmar0/uevent"; then
                Result_Systeminfo_IOMMU="1"
            else
                Result_Systeminfo_IOMMU="0"
            fi
            return 0
            ;;
        *)
            echo -e "${Msg_Error} BenchAPI_Systeminfo_GetVirtinfo(): invalid result (${r_vmmtype}), please check parameter!"
            ;;
        esac
    fi
    if [ -f "/.dockerenv" ]; then
        Result_Systeminfo_VMMType="Docker"
        Result_Systeminfo_VMMTypeShort="docker"
        Result_Systeminfo_isPhysical="0"
        return 0
    elif [ -c "/dev/lxss" ]; then
        Result_Systeminfo_VMMType="Windows Subsystem for Linux"
        Result_Systeminfo_VMMTypeShort="wsl"
        Result_Systeminfo_isPhysical="0"
        return 0
    else
        if [ -f "/proc/1/cgroup" ] && grep -q "docker" /proc/1/cgroup 2>/dev/null; then
            Result_Systeminfo_VMMType="Docker"
            Result_Systeminfo_VMMTypeShort="docker"
            Result_Systeminfo_isPhysical="0"
            return 0
        fi
        Result_Systeminfo_VMMType="Dedicated"
        Result_Systeminfo_VMMTypeShort="none"
        if test -f "/sys/class/iommu/dmar0/uevent"; then
            Result_Systeminfo_IOMMU="1"
        else
            Result_Systeminfo_IOMMU="0"
        fi
        return 0
    fi
}
#
# -> 系统信息模块 (Collector) -> 获取Linux发行版信息
function BenchAPI_Systeminfo_GetOSReleaseinfo() {
    local r_arch && r_arch="$(arch)"
    Result_Systeminfo_OSArch="$r_arch"
    # CentOS/Red Hat 判断
    if [ -f "/etc/centos-release" ] || [ -f "/etc/redhat-release" ]; then
        Result_Systeminfo_OSReleaseNameShort="centos"
        local r_prettyname && r_prettyname="$(grep -oP '(?<=\bPRETTY_NAME=").*(?=")' /etc/os-release)"
        local r_elrepo_version && r_elrepo_version="$(rpm -qa | grep -oP "el[0-9]+" | sort -ur | head -n1)"
        case "$r_elrepo_version" in
        9 | el9)
            Result_Systeminfo_OSReleaseVersionShort="9"
            Result_Systeminfo_OSReleaseNameFull="$r_prettyname ($r_arch)"
            return 0
            ;;
        8 | el8)
            Result_Systeminfo_OSReleaseVersionShort="8"
            Result_Systeminfo_OSReleaseNameFull="$r_prettyname ($r_arch)"
            return 0
            ;;
        7 | el7)
            Result_Systeminfo_OSReleaseVersionShort="7"
            Result_Systeminfo_OSReleaseNameFull="$r_prettyname ($r_arch)"
            return 0
            ;;
        6 | el6)
            Result_Systeminfo_OSReleaseVersionShort="6"
            Result_Systeminfo_OSReleaseNameFull="$r_prettyname ($r_arch)"
            return 0
            ;;
        *)
            echo -e "${Msg_Error} BenchAPI_Systeminfo_GetOSReleaseinfo(): invalid result (CentOS/Redhat-$r_prettyname ($r_arch)), please check parameter!"
            exit 1
            ;;
        esac
    elif [ -f "/etc/lsb-release" ]; then # Ubuntu
        Result_Systeminfo_OSReleaseNameShort="ubuntu"
        local r_prettyname && r_prettyname="$(grep -oP '(?<=\bPRETTY_NAME=").*(?=")' /etc/os-release)"
        Result_Systeminfo_OSReleaseVersion="$(grep -oP '(?<=\bVERSION=").*(?=")' /etc/os-release)"
        Result_Systeminfo_OSReleaseVersionShort="$(grep -oP '(?<=\bVERSION_ID=").*(?=")' /etc/os-release)"
        Result_Systeminfo_OSReleaseNameFull="$r_prettyname ($r_arch)"
        return 0
    elif [ -f "/etc/debian_version" ]; then # Debian
        Result_Systeminfo_OSReleaseNameShort="debian"
        local r_prettyname && r_prettyname="$(grep -oP '(?<=\bPRETTY_NAME=").*(?=")' /etc/os-release)"
        Result_Systeminfo_OSReleaseVersion="$(grep -oP '(?<=\bVERSION=").*(?=")' /etc/os-release)"
        Result_Systeminfo_OSReleaseVersionShort="$(grep -oP '(?<=\bVERSION_ID=").*(?=")' /etc/os-release)"
        Result_Systeminfo_OSReleaseNameFull="$r_prettyname ($r_arch)"
        return 0
    else
        echo -e "${Msg_Error} BenchAPI_Systeminfo_GetOSReleaseinfo(): invalid result ($r_prettyname ($r_arch)), please check parameter!"
    fi
}
#
# -> 系统信息模块 (Collector) -> 获取Linux内核版本信息
# function BenchAPI_Systeminfo_GetLinuxKernelinfo() {
#     # 获取原始数据
#     Result_Systeminfo_LinuxKernelVersion="$(uname -r)"
# }
# ===========================================================================

# =============== sysbench组件检测 部分 ===============
get_sysbench_os_release() {
    local OS_TYPE
    case "${Var_OSRelease}" in
    centos | rhel | almalinux | opencloudos) OS_TYPE="redhat" ;;
    ubuntu) OS_TYPE="ubuntu" ;;
    debian) OS_TYPE="debian" ;;
    fedora) OS_TYPE="fedora" ;;
    alpinelinux) OS_TYPE="alpinelinux" ;;
    arch) OS_TYPE="arch" ;;
    freebsd) OS_TYPE="freebsd" ;;
    openbsd) OS_TYPE="openbsd" ;;
    *) OS_TYPE="unknown" ;;
    esac
    echo "${OS_TYPE}"
}

InstallSysbench() {
    local os_release=$1
    case "$os_release" in
    ubuntu)
        apt-get -y install sysbench || {
            apt-get --fix-broken install -y
            apt-get --no-install-recommends -y install sysbench
        }
        ;;
    debian)
        apt-get -y install sysbench || {
            apt-get --fix-broken install -y
            apt-get --no-install-recommends -y install sysbench
        }
        ;;
    redhat)
        yum -y install epel-release && yum -y install sysbench || {
            cleanup_epel
            dnf install epel-release -y && dnf install sysbench -y || {
                _red "Sysbench installation failed!"
                return 1
            }
        }
        ;;
    fedora)
        dnf -y install sysbench || {
            _red "Sysbench installation failed!"
            return 1
        }
        ;;
    arch)
        pacman -S --needed --noconfirm sysbench libaio && ldconfig || {
            _red "Sysbench installation failed!"
            return 1
        }
        ;;
    freebsd)
        pkg install -y sysbench || {
            _red "Sysbench installation failed!"
            return 1
        }
        ;;
    openbsd)
        pkg_add -I sysbench || {
            _red "Sysbench installation failed!"
            return 1
        }
        ;;
    alpinelinux)
        echo -e "${Msg_Warning}SysBench not supported on Alpine Linux, skipping..."
        Var_Skip_SysBench="1"
        ;;
    *)
        echo "Error: Unknown OS release: $os_release"
        exit 1
        ;;
    esac
}

Check_SysBench() {
    if [ ! -f "/usr/bin/sysbench" ] && [ ! -f "/usr/local/bin/sysbench" ]; then
        local os_release=$(get_sysbench_os_release)
        if [ "$os_release" = "alpinelinux" ]; then
            Var_Skip_SysBench="1"
        else
            InstallSysbench "$os_release"
        fi
    fi
    # 尝试编译安装
    if [ ! -f "/usr/bin/sysbench" ] && [ ! -f "/usr/local/bin/sysbench" ]; then
        echo -e "${Msg_Warning}Sysbench Module install Failure, trying compile modules ..."
        Check_Sysbench_InstantBuild
    fi
    source ~/.bashrc
    # 最终检测
    if [ "$(command -v sysbench)" ] || [ -f "/usr/bin/sysbench" ] || [ -f "/usr/local/bin/sysbench" ]; then
        _yellow "Install sysbench successfully!"
    else
        _red "SysBench Moudle install Failure! Try Restart Bench or Manually install it! (/usr/bin/sysbench)"
        _blue "Will try to test with geekbench5 instead later on"
        error_exit
        test_cpu_type="gb5"
    fi
    sleep 3
}

Check_Sysbench_InstantBuild() {
    # 检查是否支持编译安装
    local supported_systems="centos|rhel|almalinux|opencloudos|ubuntu|debian|fedora|arch"
    if [[ ! ${Var_OSRelease} =~ $supported_systems ]]; then
        echo -e "${Msg_Warning}Unsupported operating system: ${Var_OSRelease}"
        return
    fi
    # 使用包管理器对应关系
    local os_type=${Var_OSRelease}
    case "$os_type" in
    "opencloudos") os_type="centos" ;;
    "rhel") os_type="centos" ;;
    "almalinux") os_type="centos" ;;
    esac
    echo -e "${Msg_Info}Release Detected: ${os_type}"
    echo -e "${Msg_Info}Preparing compile environment..."
    prepare_compile_env "${os_type}"
    echo -e "${Msg_Info}Downloading Source code (Version 1.0.20)..."
    mkdir -p /tmp/_LBench/src/
    dfiles=(sysbench)
    start_downloads "${dfiles[@]}"
    mv ${TEMP_DIR}/sysbench-1.0.20 /tmp/_LBench/src/
    echo -e "${Msg_Info}Compiling Sysbench Module..."
    cd /tmp/_LBench/src/sysbench-1.0.20
    ./autogen.sh && ./configure --without-mysql && make -j8 && make install
    echo -e "${Msg_Info}Cleaning up..."
    cd /tmp
    rm -rf /tmp/_LBench/src/sysbench*
}

cleanup_epel() {
    _yellow "Cleaning up EPEL repositories..."
    rm -f /etc/yum.repos.d/*epel*
    yum clean all
}

prepare_compile_env() {
    local system="$1"
    case "${system}" in
    redhat)
        yum install -y epel-release || {
            cleanup_epel
            _yellow "EPEL installation failed, continuing..."
        }
        yum install -y wget curl make gcc gcc-c++ make automake libtool pkgconfig libaio-devel || {
            _red "Failed to install build dependencies!"
            return 1
        }
        ;;
    debian | ubuntu)
        apt-get update || {
            apt-get --fix-broken install -y && apt-get update
        }
        apt-get -y install --no-install-recommends wget curl make automake libtool pkg-config libaio-dev unzip || {
            apt-get --fix-broken install -y
            apt-get -y install --no-install-recommends wget curl make automake libtool pkg-config libaio-dev unzip
        }
        ;;
    fedora)
        dnf install -y wget curl gcc gcc-c++ make automake libtool pkgconfig libaio-devel || {
            _red "Failed to install build dependencies!"
            return 1
        }
        ;;
    arch)
        pacman -S --needed --noconfirm wget curl gcc gcc make automake libtool pkgconfig libaio lib32-libaio || {
            _red "Failed to install build dependencies!"
            return 1
        }
        ;;
    freebsd)
        pkg install -y wget curl gcc gmake autoconf automake libtool pkgconf || {
            _red "Failed to install build dependencies!"
            return 1
        }
        ;;
    openbsd)
        pkg_add -I wget curl gcc gmake autoconf automake libtool pkgconf || {
            _red "Failed to install build dependencies!"
            return 1
        }
        ;;
    *)
        _red "Unsupported operating system: ${system}"
        return 1
        ;;
    esac
}

# =============== CPU性能测试 部分 ===============
Run_SysBench_CPU() {
    # 调用方式: Run_SysBench_CPU "线程数" "测试时长(s)" "测试遍数" "说明"
    # 变量初始化
    maxtestcount="$3"
    local count="1"
    local TestScore="0"
    local TotalScore="0"
    # 运行测试
    while [ $count -le $maxtestcount ]; do
        echo -e "\r ${Font_Yellow}$4: ${Font_Suffix}\t\t$count/$maxtestcount \c"
        sysbench_version=$(sysbench --version 2>&1 | awk '{print $2}')
        local target_version="1.0.20"
        if [ "${Var_OSRelease}" == "freebsd" ]; then
            # freebsd系统下测不准待官方修复，故而设置为0
            local TestResult="events per second: 0"
        # elif [ "$sysbench_version" == "$target_version" ]; then
        elif [ "$(printf '%s\n' "$sysbench_version" "$target_version" | sort -V | head -n 1)" == "$target_version" ]; then
            # 版本号大于或等于1.0.20使用新命令检测否则使用旧命令检测
            local TestResult="$(sysbench cpu --threads=$1 --cpu-max-prime=10000 --events=1000000 --time=$2 run 2>&1)"
        else
            local TestResult="$(sysbench --test=cpu --num-threads=$1 --cpu-max-prime=10000 --max-requests=1000000 --max-time=$2 run 2>&1)"
        fi
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
            if [ "$en_status" = true ]; then
                echo -e "\r ${Font_Yellow}$4: ${Font_Suffix}\t\t${Font_Red}sysbench test failed, please use this script option '-ctype gb5' to test${Font_Suffix}"
            else
                echo -e "\r ${Font_Yellow}$4: ${Font_Suffix}\t\t${Font_Red}sysbench测试失效，请使用本脚本选项 '-ctype gb5' 进行测试${Font_Suffix}"
            fi
        else
            echo -e "\r ${Font_Yellow}$4: ${Font_Suffix}\t\t${Font_SkyBlue}${ResultScore}${Font_Suffix} ${Font_Yellow}Scores${Font_Suffix}"
        fi
    elif [ "$1" -ge "2" ]; then
        if [ "$ResultScore" -eq "0" ] || ([ "$1" -lt "2" ] && [ "$ResultScore" -gt "100000" ]); then
            if [ "$en_status" = true ]; then
                echo -e "\r ${Font_Yellow}$4: ${Font_Suffix}\t\t${Font_Red}sysbench test failed, please use this script option '-ctype gb5' to test${Font_Suffix}"
            else
                echo -e "\r ${Font_Yellow}$4: ${Font_Suffix}\t\t${Font_Red}sysbench测试失效，请使用本脚本选项5中的gb4或gb5测试${Font_Suffix}"
            fi
        else
            echo -e "\r ${Font_Yellow}$4: ${Font_Suffix}\t\t${Font_SkyBlue}${ResultScore}${Font_Suffix} ${Font_Yellow}Scores${Font_Suffix}"
        fi
    fi
}

Function_SysBench_CPU_Fast() {
    cd $myvar >/dev/null 2>&1
    if [ "$en_status" = true ]; then
        echo -e " ${Font_Yellow}-> CPU test in progress (Fast Mode, 1-Pass @ 5sec)${Font_Suffix}"
        Run_SysBench_CPU "1" "5" "1" "1 Thread(s) Test"
        sleep 1
        if [ -n "${Result_Systeminfo_CPUThreads}" ] && [ "${Result_Systeminfo_CPUThreads}" -ge "2" ] >/dev/null 2>&1; then
            Run_SysBench_CPU "${Result_Systeminfo_CPUThreads}" "5" "1" "${Result_Systeminfo_CPUThreads} Thread(s) Test"
        elif [ -n "${Result_Systeminfo_CPUCores}" ] && [ "${Result_Systeminfo_CPUCores}" -ge "2" ] >/dev/null 2>&1; then
            Run_SysBench_CPU "${Result_Systeminfo_CPUCores}" "5" "1" "${Result_Systeminfo_CPUCores} Thread(s) Test"
        elif [ -n "${cores}" ] && [ "${cores}" -ge "2" ] >/dev/null 2>&1; then
            Run_SysBench_CPU "${cores}" "5" "1" "${cores} Thread(s) Test"
        fi
    else
        echo -e " ${Font_Yellow}-> CPU 测试中 (Fast Mode, 1-Pass @ 5sec)${Font_Suffix}"
        Run_SysBench_CPU "1" "5" "1" "1 线程测试(单核)得分"
        sleep 1
        if [ -n "${Result_Systeminfo_CPUThreads}" ] && [ "${Result_Systeminfo_CPUThreads}" -ge "2" ] >/dev/null 2>&1; then
            Run_SysBench_CPU "${Result_Systeminfo_CPUThreads}" "5" "1" "${Result_Systeminfo_CPUThreads} 线程测试(多核)得分"
        elif [ -n "${Result_Systeminfo_CPUCores}" ] && [ "${Result_Systeminfo_CPUCores}" -ge "2" ] >/dev/null 2>&1; then
            Run_SysBench_CPU "${Result_Systeminfo_CPUCores}" "5" "1" "${Result_Systeminfo_CPUCores} 线程测试(多核)得分"
        elif [ -n "${cores}" ] && [ "${cores}" -ge "2" ] >/dev/null 2>&1; then
            Run_SysBench_CPU "${cores}" "5" "1" "${cores} 线程测试(多核)得分"
        fi
    fi
}

# =============== 网速测试及延迟测试 部分 ===============
download_speedtest_file() {
    cd $myvar >/dev/null 2>&1
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
    # Create directory if it doesn't exist
    if [ ! -d "./speedtest-cli" ]; then
        mkdir -p "./speedtest-cli"
    fi
    # Modified to try speedtest-go first
    if [ "$sys_bit" = "aarch64" ]; then
        sys_bit_go="arm64"
    else
        sys_bit_go="$sys_bit"
    fi
    local url3="https://github.com/showwin/speedtest-go/releases/download/v${Speedtest_Go_version}/speedtest-go_${Speedtest_Go_version}_Linux_${sys_bit_go}.tar.gz"
    if [[ -z "${CN}" || "${CN}" != true ]]; then
        curl --fail -sL -m 10 -o speedtest.tar.gz "${url3}" || curl --fail -sL -m 15 -o speedtest.tar.gz "${url3}"
        if [[ $? -eq 0 ]]; then
            # _green "Successfully downloaded speedtest-go"
            tar -zxf speedtest.tar.gz -C ./speedtest-cli
            chmod 777 ./speedtest-cli/speedtest-go
            rm -rf speedtest.tar.gz*
            return
        else
            # _yellow "Failed to download speedtest-go, falling back to official speedtest-cli"
            rm -rf speedtest.tar.gz*
        fi
        if [ "$speedtest_ver" = "1.2.0" ]; then
            local url1="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-${sys_bit}.tgz"
            local url2="https://dl.lamp.sh/files/ookla-speedtest-1.2.0-linux-${sys_bit}.tgz"
        else
            local url1="https://filedown.me/Linux/Tool/speedtest_cli/ookla-speedtest-1.0.0-${sys_bit}-linux.tgz"
            local url2="https://bintray.com/ookla/download/download_file?file_path=ookla-speedtest-1.0.0-${sys_bit}-linux.tgz"
        fi
        curl --fail -sL -m 10 -o speedtest.tgz "${url1}" || curl --fail -sL -m 10 -o speedtest.tgz "${url2}"
        if [[ $? -eq 0 ]]; then
            tar -zxf speedtest.tgz -C ./speedtest-cli
            chmod 777 ./speedtest-cli/speedtest
            rm -rf speedtest.tgz*
            return
        else
            rm -rf speedtest.tgz*
        fi
    else
        curl -o speedtest.tar.gz "${cdn_success_url}${url3}" || curl -o speedtest.tar.gz "${url3}"
        if [[ $? -eq 0 ]]; then
            # _green "Used unofficial speedtest-go"
            tar -zxf speedtest.tar.gz -C ./speedtest-cli
            chmod 777 ./speedtest-cli/speedtest-go
            rm -rf speedtest.tar.gz*
            return
        else
            rm -rf speedtest.tar.gz*
        fi
    fi
    _red "Error: Failed to download any speedtest tool."
    exit 1
}

install_speedtest() {
    sys_bit=""
    local sysarch="$(uname -m)"
    case "${sysarch}" in
    "x86_64" | "x86" | "amd64" | "x64") sys_bit="x86_64" ;;
    "i386" | "i686") sys_bit="i386" ;;
    "aarch64" | "armv7l" | "armv8" | "armv8l") sys_bit="aarch64" ;;
    "s390x") sys_bit="s390x" ;;
    "riscv64") sys_bit="riscv64" ;;
    "ppc64le") sys_bit="ppc64le" ;;
    "ppc64") sys_bit="ppc64" ;;
    *) sys_bit="x86_64" ;;
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
    cd $myvar >/dev/null 2>&1
    local nodeName="$2"
    local cmd_status=0
    if [ -f "./speedtest-cli/speedtest-go" ]; then
        if [ -z "$1" ]; then
            if [ "$usage_timeout" = true ]; then
                timeout 70s ./speedtest-cli/speedtest-go --ua="${BrowserUA}" >./speedtest-cli/speedtest.log 2>&1
            else
                ./speedtest-cli/speedtest-go --ua="${BrowserUA}" >./speedtest-cli/speedtest.log 2>&1
            fi
        else
            if [ "$usage_timeout" = true ]; then
                timeout 70s ./speedtest-cli/speedtest-go --server=$1 --ua="${BrowserUA}" >./speedtest-cli/speedtest.log 2>&1
            else
                ./speedtest-cli/speedtest-go --server=$1 --ua="${BrowserUA}" >./speedtest-cli/speedtest.log 2>&1
            fi
        fi
        cmd_status=$?
        if [ $cmd_status -eq 0 ]; then
            local dl_speed=$(grep -oP 'Download: \K[\d\.]+' ./speedtest-cli/speedtest.log)
            local up_speed=$(grep -oP 'Upload: \K[\d\.]+' ./speedtest-cli/speedtest.log)
            local latency=$(grep -oP 'Latency: \K[\d\.]+' ./speedtest-cli/speedtest.log)
            if [[ -n "${latency}" && "${latency}" == *.* ]]; then
                latency=$(awk '{printf "%.2f", $1}' <<<"${latency}")
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
            ./speedtest-cli/speedtest --progress=no --accept-license --accept-gdpr >./speedtest-cli/speedtest.log 2>&1
        else
            ./speedtest-cli/speedtest --progress=no --server-id=$1 --accept-license --accept-gdpr >./speedtest-cli/speedtest.log 2>&1
        fi
        cmd_status=$?
        if grep -i "aborted" ./speedtest-cli/speedtest.log >/dev/null 2>&1 ||
            grep -i "core dumped" ./speedtest-cli/speedtest.log >/dev/null 2>&1 ||
            [ $cmd_status -ne 0 ]; then
            # 设置全局错误标记
            export SPEEDTEST_ERROR=true
            if [ "$en_status" = true ]; then
                echo "Error detected: Aborted or core dumped, terminate speed test"
            else
                echo "检测到错误：Aborted或core dumped，终止测速"
            fi
            return 1
        fi
        if [ $cmd_status -eq 0 ]; then
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
        return 0 # 符合IPv4格式
    else
        return 1 # 不符合IPv4格式
    fi
}

test_list() {
    local list=("$@")
    if [ ${#list[@]} -eq 0 ]; then
        echo "列表为空，程序退出"
        return
    fi
    export SPEEDTEST_ERROR=false
    for ((i = 0; i < ${#list[@]}; i++)); do
        if [ "$SPEEDTEST_ERROR" = true ]; then
            if [ "$en_status" = true ]; then
                echo "Previous error detected, stopping further tests"
            else
                echo "检测到之前的错误，停止后续测试"
            fi
            error_exit
            break
        fi
        id=$(echo "${list[i]}" | cut -d',' -f1)
        name=$(echo "${list[i]}" | cut -d',' -f2)
        speed_test "$id" "$name" || {
            error_exit
            break
        }
    done
}

temp_head() {
    if [ "$en_status" = true ]; then
        echo "------------------------------Speedtest---------------------------------"
        if [[ $selection =~ ^[1-5]$ ]]; then
            if [ -f "./speedtest-cli/speedtest" ]; then
                echo -e "Location\t     Upload\t\t  Download\t Delay\t  Loss"
            else
                echo -e "Location\t     Upload\t\t Download\t Delay"
            fi
        else
            if [ -f "./speedtest-cli/speedtest" ]; then
                echo -e "Location\t Upload\t\t Download\t Delay\t Loss"
            else
                echo -e "Location\t Upload\t\t  Download\t Delay"
            fi
        fi
    else
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
    fi
}

ping_test() {
    local ip="$1"
    local result="$(ping -c1 -w3 "$ip" 2>/dev/null | awk -F '/' 'END {print $5}')"
    echo "$ip,$result"
}

get_nearest_data() {
    local url="$1"
    local data=()
    local response
    if [[ -z "${CN}" || "${CN}" != true ]]; then
        local retries=0
        while [[ $retries -lt 2 ]]; do
            response=$(curl -sL -m 2 "$url")
            if [[ $? -eq 0 ]]; then
                break
            else
                retries=$((retries + 1))
                sleep 1
            fi
        done
        if [[ $retries -eq 2 ]]; then
            url="${cdn_success_url}${url}"
            response=$(curl -sL -m 6 "$url")
        fi
    else
        url="${cdn_success_url}${url}"
        response=$(curl -sL -m 8 "$url")
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
            if [ "$en_status" = true ]; then
                city=$(echo "$city" | sed 's/洛杉矶/US_LosAngeles/g')
                city=$(echo "$city" | sed 's/法兰克福/DE_Frankfurt/g')
                city=$(echo "$city" | sed 's/新加坡/SG_Singapore/g')
                city=$(echo "$city" | sed 's/中国香港/HK_HongKong/g')
                city=$(echo "$city" | sed 's/日本东京/JP_Tokyo/g')
            fi
            data+=("$id,$city,$ip")
        fi
    done <<<"$response"
    rm -f /tmp/pingtest
    # 并行ping测试所有IP
    for ((i = 0; i < ${#data[@]}; i++)); do
        {
            ip=$(echo "${data[$i]}" | awk -F ',' '{print $3}')
            ping_test "$ip" >>/tmp/pingtest
        } &
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
    if ! command -v nslookup &>/dev/null; then
        _yellow "Installing dnsutils"
        ${PACKAGE_INSTALL[int]} dnsutils
    fi
}

get_ip_from_url() {
    nslookup -querytype=A $1 2>/dev/null | awk '/^Name:/ {next;} /^Address: / { print $2 }'
}

get_nearest_data2() {
    local url="$1"
    local data=()
    local response
    if [[ -z "${CN}" || "${CN}" != true ]]; then
        local retries=0
        while [[ $retries -lt 2 ]]; do
            response=$(curl -sL -m 2 "$url")
            if [[ $? -eq 0 ]]; then
                break
            else
                retries=$((retries + 1))
                sleep 1
            fi
        done
        if [[ $retries -eq 2 ]]; then
            url="${cdn_success_url}${url}"
            response=$(curl -sL -m 6 "$url")
        fi
    else
        url="${cdn_success_url}${url}"
        response=$(curl -sL -m 8 "$url")
    fi
    ip_list=()
    city_list=()
    while read line; do
        if [[ -n "$line" ]]; then
            # local id=$(echo "$line" | awk -F ',' '{print $1}')
            local city=$(echo "$line" | sed 's/ //g' | awk -F ',' '{print $9}')
            city=${city/市/}
            city=${city/中国/}
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
            if [ "$en_status" = true ]; then
                city=$(echo "$city" | sed 's/洛杉矶/US_LosAngeles/g')
                city=$(echo "$city" | sed 's/法兰克福/DE_Frankfurt/g')
                city=$(echo "$city" | sed 's/新加坡/SG_Singapore/g')
                city=$(echo "$city" | sed 's/中国香港/HK_HongKong/g')
                city=$(echo "$city" | sed 's/日本东京/JP_Tokyo/g')
            fi
            if [[ ! " ${ip_list[@]} " =~ " ${ip} " ]] && [[ ! " ${city_list[@]} " =~ " ${city} " ]]; then
                data+=("$host,$city,$ip")
                ip_list+=("$ip")
                city_list+=("$city")
            fi
        fi
    done <<<"$response"

    rm -f /tmp/pingtest
    for ((i = 0; i < ${#data[@]}; i++)); do
        {
            ip=$(echo "${ip_list[$i]}")
            ping_test "$ip" >>/tmp/pingtest
        } &
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

speed_test2() {
    local nodeName="$2"
    if [ ! -f "./speedtest-cli/speedtest" ]; then
        if [ -z "$1" ]; then
            if [ "$usage_timeout" = true ]; then
                timeout 70s ./speedtest-cli/speedtest-go >./speedtest-cli/speedtest.log 2>&1
            else
                ./speedtest-cli/speedtest-go >./speedtest-cli/speedtest.log 2>&1
            fi
        else
            if [ "$usage_timeout" = true ]; then
                timeout 70s ./speedtest-cli/speedtest-go --custom-url=http://"$1"/upload.php >./speedtest-cli/speedtest.log 2>&1
            else
                ./speedtest-cli/speedtest-go --custom-url=http://"$1"/upload.php >./speedtest-cli/speedtest.log 2>&1
            fi
        fi
        if [ $? -eq 0 ]; then
            local dl_speed=$(grep -oP 'Download: \K[\d\.]+' ./speedtest-cli/speedtest.log)
            local up_speed=$(grep -oP 'Upload: \K[\d\.]+' ./speedtest-cli/speedtest.log)
            local latency=$(grep -oP 'Latency: \K[\d\.]+' ./speedtest-cli/speedtest.log)
            if [[ -n "${latency}" && "${latency}" == *.* ]]; then
                latency=$(awk '{printf "%.2f", $1}' <<<"${latency}")
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

check_to_cn_test() {
    local provider_list="$1"
    local use_all="$2"
    shift 2
    local data_array=("$@")
    if [ "$test_network_type" == ".cn" ]; then
        data_array=($(get_nearest_data2 "${SERVER_BASE_URL2}/${provider_list}")) >/dev/null 2>&1
        wait
        if [ ${#data_array[@]} -eq 0 ]; then
            return
        else
            unset -f speed_test
            speed_test() { speed_test2 "$@"; }
            echo -en "\r测速中                                                        \r"
            if [ "$use_all" = "true" ]; then
                test_list "${data_array[@]}"
            else
                test_list "${data_array[0]}"
            fi
        fi
    elif [ ${#data_array[@]} -eq 0 ] && [ -z "$test_network_type" ]; then
        echo -n "该运营商.net的节点列表为空，正在替换为.cn的节点列表。。。"
        CN=true
        if [ -f "./speedtest-cli/speedtest" ]; then
            rm -rf ./speedtest-cli/speedtest
            (install_speedtest >/dev/null 2>&1)
        fi
        data_array=($(get_nearest_data2 "${SERVER_BASE_URL2}/${provider_list}")) >/dev/null 2>&1
        wait
        if [ ${#data_array[@]} -eq 0 ]; then
            return
        else
            unset -f speed_test
            speed_test() { speed_test2 "$@"; }
            echo -en "\r测速中                                                        \r"
            if [ "$use_all" = "true" ]; then
                test_list "${data_array[@]}"
            else
                test_list "${data_array[0]}"
            fi
        fi
    else
        if [ "$use_all" = "true" ]; then
            test_list "${data_array[@]}"
        else
            test_list "${data_array[0]}"
        fi
    fi
}

speed() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
    local ip4=$(echo "$IPV4" | tr -d '\n' | tr -d '[:space:]')
    if [[ -z "${ip4}" ]]; then
        return
    fi
    temp_head
    if [ "$test_network_type" != ".cn" ]; then
        speed_test '' 'Speedtest.net'
    fi
    test_list "${ls_sg_hk_jp[@]}"
    if [ "$en_status" = false ]; then
        check_to_cn_test "unicom.csv" "true" "${CN_Unicom[@]}"
        check_to_cn_test "telecom.csv" "true" "${CN_Telecom[@]}"
        check_to_cn_test "mobile.csv" "true" "${CN_Mobile[@]}"
    fi
}

speed2() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
    local ip4=$(echo "$IPV4" | tr -d '\n' | tr -d '[:space:]')
    if [[ -z "${ip4}" ]]; then
        return
    fi
    temp_head
    if [ "$test_network_type" != ".cn" ]; then
        speed_test '' 'Speedtest.net'
    fi
    if [ "$en_status" = false ]; then
        check_to_cn_test "unicom.csv" "false" "${CN_Unicom[0]}"
        check_to_cn_test "telecom.csv" "false" "${CN_Telecom[0]}"
        check_to_cn_test "mobile.csv" "false" "${CN_Mobile[0]}"
    fi
}

# =============== 磁盘测试 部分 ===============
Run_DiskTest_DD() {
    # 调用方式: Run_DiskTest_DD "测试文件名" "块大小" "写入次数" "测试项目名称"
    if [ ! -e /dev/null ] || [ ! -c /dev/null ] || [ ! -w /dev/null ]; then
        error_exit
        return
    fi
    mkdir -p /.tmp_LBench/DiskTest >/dev/null 2>&1
    mkdir -p ${WorkDir}/data >/dev/null 2>&1
    local Var_DiskTestResultFile="${WorkDir}/data/disktest_result"
    # 将先测试读, 后测试写
    echo -n -e " $4\t\t->\c"
    # 清理缓存, 避免影响测试结果
    sync
    if [ "${Result_Systeminfo_VMMTypeShort}" != "docker" ] && [ "${Result_Systeminfo_VMMTypeShort}" != "openvz" ] && [ "${Result_Systeminfo_VMMTypeShort}" != "lxc" ] && [ "${Result_Systeminfo_VMMTypeShort}" != "wsl" ]; then
        echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1
    fi
    # 避免磁盘压力过高, 启动测试前暂停1s
    sleep 1
    # 正式写测试
    dd if=/dev/zero of=/.tmp_LBench/DiskTest/$1 bs=$2 count=$3 oflag=direct 2>${Var_DiskTestResultFile}
    local DiskTest_WriteSpeed_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,4} kB/s|[0-9]{1,4}.[0-9]{1,2} kB/s|[0-9]{1,4} KB/s|[0-9]{1,4}.[0-9]{1,2} KB/s|[0-9]{1,4} MB/s|[0-9]{1,4}.[0-9]{1,2} MB/s|[0-9]{1,4} GB/s|[0-9]{1,4}.[0-9]{1,2} GB/s|[0-9]{1,4} TB/s|[0-9]{1,4}.[0-9]{1,2} TB/s|[0-9]{1,4} kB/秒|[0-9]{1,4}.[0-9]{1,2} kB/秒|[0-9]{1,4} KB/秒|[0-9]{1,4}.[0-9]{1,2} KB/秒|[0-9]{1,4} MB/秒|[0-9]{1,4}.[0-9]{1,2} MB/秒|[0-9]{1,4} GB/秒|[0-9]{1,4}.[0-9]{1,2} GB/秒|[0-9]{1,4} TB/秒|[0-9]{1,4}.[0-9]{1,2} TB/秒|[0-9]{1,4} bytes/sec")"
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
    if [ "${Result_Systeminfo_VMMTypeShort}" != "docker" ] && [ "${Result_Systeminfo_VMMTypeShort}" != "wsl" ]; then
        if [ -w /proc/sys/vm/drop_caches ]; then
            echo 3 >/proc/sys/vm/drop_caches >/dev/null 2>&1
        fi
    fi
    sleep 0.5
    # 正式读测试
    dd if=/.tmp_LBench/DiskTest/$1 of=/dev/null bs=$2 count=$3 iflag=direct 2>${Var_DiskTestResultFile}
    local DiskTest_ReadSpeed_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,4} kB/s|[0-9]{1,4}.[0-9]{1,2} kB/s|[0-9]{1,4} KB/s|[0-9]{1,4}.[0-9]{1,2} KB/s|[0-9]{1,4} MB/s|[0-9]{1,4}.[0-9]{1,2} MB/s|[0-9]{1,4} GB/s|[0-9]{1,4}.[0-9]{1,2} GB/s|[0-9]{1,4} TB/s|[0-9]{1,4}.[0-9]{1,2} TB/s|[0-9]{1,4} kB/秒|[0-9]{1,4}.[0-9]{1,2} kB/秒|[0-9]{1,4} KB/秒|[0-9]{1,4}.[0-9]{1,2} KB/秒|[0-9]{1,4} MB/秒|[0-9]{1,4}.[0-9]{1,2} MB/秒|[0-9]{1,4} GB/秒|[0-9]{1,4}.[0-9]{1,2} GB/秒|[0-9]{1,4} TB/秒|[0-9]{1,4}.[0-9]{1,2} TB/秒|[0-9]{1,4} bytes/sec")"
    DiskTest_ReadSpeed="$(echo "${DiskTest_ReadSpeed_ResultRAW}" | sed "s/s/s/")"
    local DiskTest_ReadTime_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,}.[0-9]{1,} s|[0-9]{1,}.[0-9]{1,} s|[0-9]{1,}.[0-9]{1,} 秒|[0-9]{1,}.[0-9]{1,} 秒")"
    DiskTest_ReadTime="$(echo ${DiskTest_ReadTime_ResultRAW} | awk '{print $1}')"
    DiskTest_ReadIOPS="$(echo ${DiskTest_ReadTime} $3 | awk '{printf "%d\n",$2/$1}')"
    DiskTest_ReadPastTime="$(echo ${DiskTest_ReadTime} | awk '{printf "%.2f\n",$1}')"
    rm -f ${Var_DiskTestResultFile}
    # 输出结果
    echo -n -e "\r $4\t\t${Font_SkyBlue}${DiskTest_WriteSpeed} (${DiskTest_WriteIOPS} IOPS, ${DiskTest_WritePastTime}s)${Font_Suffix}\t\t${Font_SkyBlue}${DiskTest_ReadSpeed} (${DiskTest_ReadIOPS} IOPS, ${DiskTest_ReadPastTime}s)${Font_Suffix}\n"
    rm -rf /.tmp_LBench/DiskTest/
}

Function_DiskTest_Fast() {
    if [ "$en_status" = true ]; then
        echo -e " ${Font_Yellow}-> Disk test in progress (4K Block/1M Block, Direct Mode)${Font_Suffix}"
    else
        echo -e " ${Font_Yellow}-> 磁盘IO测试中 (4K Block/1M Block, Direct Mode)${Font_Suffix}"
    fi
    if [ "${Result_Systeminfo_VMMType}" = "docker" ] || [ "${Result_Systeminfo_VMMType}" = "wsl" ]; then
        echo -e " ${Msg_Warning}Due to virt architecture limit, the result may affect by the cache !"
    fi
    if [ "$en_status" = true ]; then
        echo -e " ${Font_Yellow}Block Size\t\tWrite Test\t\t\t\tRead Test${Font_Suffix}"
    else
        echo -e " ${Font_Yellow}测试操作\t\t写速度\t\t\t\t\t读速度${Font_Suffix}"
    fi
    Run_DiskTest_DD "100MB.test" "4k" "25600" "100MB-4K Block"
    Run_DiskTest_DD "1GB.test" "1M" "1000" "1GB-1M Block"
    sleep 0.5
}

# =============== SysBench - 内存性能 部分 ===============
Run_SysBench_Memory() {
    # 调用方式: Run_SysBench_Memory "线程数" "测试时长(s)" "测试遍数" "测试模式(读/写)" "读写方式(顺序/随机)" "说明"
    # 变量初始化
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
    elif [ "$1" = "1" ] && [ "$4" = "write" ]; then
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
    sleep 0.5

}

Function_SysBench_Memory_Fast() {
    if [ "$en_status" = true ]; then
        echo -e " ${Font_Yellow}-> Memory Test (Fast Mode, 1-Pass @ 5sec)${Font_Suffix}"
        Run_SysBench_Memory "1" "5" "1" "read" "seq" "Single Read Test"
        Run_SysBench_Memory "1" "5" "1" "write" "seq" "Single Write Test"
    else
        echo -e " ${Font_Yellow}-> 内存测试 Test (Fast Mode, 1-Pass @ 5sec)${Font_Suffix}"
        Run_SysBench_Memory "1" "5" "1" "read" "seq" "单线程读测试"
        Run_SysBench_Memory "1" "5" "1" "write" "seq" "单线程写测试"
    fi
    sleep 0.5
}

# =============== 机器配置检测 部分 ===============
calc_disk() {
    local total_size=0
    local array=$@
    for size in ${array[@]}; do
        [ "${size}" == "0" ] && size_t=0 || size_t=$(echo ${size:0:${#size}-1})
        [ "$(echo ${size:(-1)})" == "K" ] && size=0
        [ "$(echo ${size:(-1)})" == "M" ] && size=$(awk 'BEGIN{printf "%.1f", '$size_t' / 1024}')
        [ "$(echo ${size:(-1)})" == "T" ] && size=$(awk 'BEGIN{printf "%.1f", '$size_t' * 1024}')
        [ "$(echo ${size:(-1)})" == "G" ] && size=${size_t}
        [ "$(echo ${size:(-1)})" == "E" ] && size=$(awk 'BEGIN{printf "%.1f", '$size_t' * 1024 * 1024}')
        total_size=$(awk 'BEGIN{printf "%.1f", '$total_size' + '$size'}')
    done
    echo ${total_size}
}

is_private_ipv4() {
    local ip_address=$1
    local ip_parts
    if [[ -z $ip_address ]]; then
        return 0 # 输入为空
    fi
    IFS='.' read -r -a ip_parts <<<"$ip_address"
    # 检查IP地址是否符合内网IP地址的范围
    # 去除 回环，RFC 1918，多播，RFC 6598 地址
    if [[ ${ip_parts[0]} -eq 10 ]] ||
        [[ ${ip_parts[0]} -eq 172 && ${ip_parts[1]} -ge 16 && ${ip_parts[1]} -le 31 ]] ||
        [[ ${ip_parts[0]} -eq 192 && ${ip_parts[1]} -eq 168 ]] ||
        [[ ${ip_parts[0]} -eq 127 ]] ||
        [[ ${ip_parts[0]} -eq 0 ]] ||
        [[ ${ip_parts[0]} -eq 100 && ${ip_parts[1]} -ge 64 && ${ip_parts[1]} -le 127 ]] ||
        [[ ${ip_parts[0]} -ge 224 ]]; then
        return 0 # 是内网IP地址
    else
        return 1 # 不是内网IP地址
    fi
}

check_ipv4() {
    rm -rf /tmp/ip_quality_ipv4
    IPV4=$(ip -4 addr show | grep global | awk '{print $2}' | cut -d '/' -f1 | head -n 1)
    local response
    if is_private_ipv4 "$IPV4"; then # 由于是内网IPV4地址，需要通过API获取外网地址
        IPV4=""
        local API_NET=("ipv4.ip.sb" "ipget.net" "ip.ping0.cc" "https://ip4.seeip.org" "https://api.my-ip.io/ip" "https://ipv4.icanhazip.com" "api.ipify.org")
        for p in "${API_NET[@]}"; do
            response=$(curl -s4m8 "$p")
            if [ $? -eq 0 ] && ! echo "$response" | grep -q "error"; then
                IP_API="$p"
                IPV4="$response"
                break
            fi
        done
    fi
    echo $IPV4 >/tmp/ip_quality_ipv4
}

is_private_ipv6() {
    local address=$1
    local temp="0"
    # 输入为空
    if [[ ! -n $address ]]; then
        temp="1"
    fi
    # 输入不含:符号
    if [[ -n $address && $address != *":"* ]]; then
        temp="2"
    fi
    # 检查IPv6地址是否以fe80开头（链接本地地址）
    if [[ $address == fe80:* ]]; then
        temp="3"
    fi
    # 检查IPv6地址是否以fc00或fd00开头（唯一本地地址）
    if [[ $address == fc00:* || $address == fd00:* ]]; then
        temp="4"
    fi
    # 检查IPv6地址是否以2001:db8开头（文档前缀）
    if [[ $address == 2001:db8* ]]; then
        temp="5"
    fi
    # 检查IPv6地址是否以::1开头（环回地址）
    if [[ $address == ::1 ]]; then
        temp="6"
    fi
    # 检查IPv6地址是否以::ffff:开头（IPv4映射地址）
    if [[ $address == ::ffff:* ]]; then
        temp="7"
    fi
    # 检查IPv6地址是否以2002:开头（6to4隧道地址）
    if [[ $address == 2002:* ]]; then
        temp="8"
    fi
    # 检查IPv6地址是否以2001:开头（Teredo隧道地址）
    if [[ $address == 2001:* ]]; then
        temp="9"
    fi
    if [ "$temp" -gt 0 ]; then
        # 非公网情况
        return 0
    else
        # 其他情况为公网地址
        return 1
    fi
}

check_ipv6() {
    rm -rf /tmp/ip_quality_ipv6
    IPV6=$(ip -6 addr show | grep global | awk '{print length, $2}' | sort -nr | head -n 1 | awk '{print $2}' | cut -d '/' -f1)
    local response
    if is_private_ipv6 "$IPV6"; then # 由于是内网IPV4地址，需要通过API获取外网地址
        IPV6=""
        local API_NET=("ipv6.ip.sb" "https://ipget.net" "ipv6.ping0.cc" "https://api.my-ip.io/ip" "https://ipv6.icanhazip.com")
        for p in "${API_NET[@]}"; do
            response=$(curl -sLk6m8 "$p" | tr -d '[:space:]')
            sleep 1
            if [ $? -eq 0 ] && ! echo "$response" | grep -q "error"; then
                IPV6="$response"
                break
            fi
        done
    fi
    echo $IPV6 >/tmp/ip_quality_ipv6
}

check_ip_info_by_ipinfo() {
    # ipinfo.io
    rm -rf /tmp/ipinfo
    # 获取IPv4的asn、city、region、country
    # 通过纯curl获取
    local ip_info=$(curl -s http://ipinfo.io 2>/dev/null)
    if [ $? -eq 0 ]; then
        local ip=$(echo "$ip_info" | grep -o '"ip": "[^"]*' | cut -d'"' -f4)
        local city=$(echo "$ip_info" | grep -o '"city": "[^"]*' | cut -d'"' -f4)
        local region=$(echo "$ip_info" | grep -o '"region": "[^"]*' | cut -d'"' -f4)
        local country=$(echo "$ip_info" | grep -o '"country": "[^"]*' | cut -d'"' -f4)
        local asn=$(echo "$ip_info" | awk -F'"' '/"org":/{gsub(/^[^:]*: "/, ""); gsub(/"$/, ""); print $0}')
        if [ -z "$asn" ] || echo "$asn" | grep -qE "(Comodo Secure DNS|Rate limit exceeded)|Your client does not have permission to get URL" >/dev/null 2>&1; then
            local ipv4_asn_info="None"
            local ipv4_location="None"
        else
            local ipv4_city=$(echo "$city")
            local ipv4_region=$(echo "$region")
            local ipv4_country=$(echo "$country")
            if [ -n "$asn" ] && [ -n "$ipv4_city" ] && [ -n "$ipv4_country" ]; then
                local ipv4_asn_info="${asn}"
                local ipv4_location="${ipv4_city} / ${ipv4_region} / ${ipv4_country}"
            elif [ -n "$asn" ] && [ -n "$ipv4_city" ] && [ -z "$ipv4_region" ]; then
                local ipv4_asn_info="${asn}"
                local ipv4_location="${ipv4_city} / ${ipv4_region}"
            elif [[ -n $asn && -n $ipv4_city ]]; then
                local ipv4_asn_info="${asn}"
                local ipv4_location="${ipv4_city}"
            else
                local ipv4_asn_info="None"
                local ipv4_location="None"
            fi
        fi
    else
        # 通过模拟浏览器请求获取
        local ipv4_asn=$(curl -ksL4m6 -A Mozilla ipinfo.io/org 2>/dev/null)
        if [ "$?" -ne 0 ] || echo "$ipv4_asn" | grep -qE "(Comodo Secure DNS|Rate limit exceeded)|Your client does not have permission to get URL" >/dev/null 2>&1; then
            local ipv4_asn_info="None"
            local ipv4_location="None"
        else
            local ipv4_city=$(curl -ksL4m6 -A Mozilla ipinfo.io/city 2>/dev/null)
            local ipv4_region=$(curl -ksL4m6 -A Mozilla ipinfo.io/region 2>/dev/null)
            local ipv4_country=$(curl -ksL4m6 -A Mozilla ipinfo.io/country 2>/dev/null)
            if [ -n "$ipv4_asn" ] && [ -n "$ipv4_city" ] && [ -n "$ipv4_country" ]; then
                local ipv4_asn_info="${ipv4_asn}"
                local ipv4_location="${ipv4_city} / ${ipv4_region} / ${ipv4_country}"
            elif [[ -n $ipv4_asn && -n $ipv4_city && -n $ipv4_region ]]; then
                local ipv4_asn_info="${ipv4_asn}"
                local ipv4_location="${ipv4_city} / ${ipv4_region}"
            elif [[ -n $ipv4_asn && -n $ipv4_city ]]; then
                local ipv4_asn_info="${ipv4_asn}"
                local ipv4_location="${ipv4_city}"
            else
                local ipv4_asn_info="None"
                local ipv4_location="None"
            fi
        fi
    fi
    # 去除最后一个双引号后的内容
    if [[ $ipv4_asn_info == *"\""* ]]; then
        ipv4_asn_info="${ipv4_asn_info%\"*}"
    fi
    if [[ $ipv4_location == *"\""* ]]; then
        ipv4_location="${ipv4_location%\"*}"
    fi
    if [[ $ipv6_asn_info == *"\""* ]]; then
        ipv6_asn_info="${ipv4_asn_info%\"*}"
    fi
    if [[ $ipv6_location == *"\""* ]]; then
        ipv6_location="${ipv6_location%\"*}"
    fi
    # 返回结果
    echo "$ipv4_asn_info" >>/tmp/ipinfo
    echo "$ipv4_location" >>/tmp/ipinfo
    # 获取IPv6的asn、city和region - 无 - 该站点不支持IPV6网络识别
    local ipv6_asn_info="None"
    local ipv6_location="None"
    # 返回结果
    echo "$ipv6_asn_info" >>/tmp/ipinfo
    echo "$ipv6_location" >>/tmp/ipinfo
}

check_ip_info_by_cloudflare() {
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
        local ipv4_asn_info="AS${ipv4_asn} ${ipv4_as_organization}"
        local ipv4_location="${ipv4_city} / ${ipv4_region}"
    elif [ -n "$ipv4_asn" ] && [ -n "$ipv4_as_organization" ] && [ -n "$ipv4_city" ]; then
        local ipv4_asn_info="AS${ipv4_asn} ${ipv4_as_organization}"
        local ipv4_location="${ipv4_city}"
    elif [ -n "$ipv4_asn" ] && [ -n "$ipv4_as_organization" ] && [ -n "$ipv4_region" ]; then
        local ipv4_asn_info="AS${ipv4_asn} ${ipv4_as_organization}"
        local ipv4_location="${ipv4_region}"
    else
        local ipv4_asn_info="None"
        local ipv4_location="None"
    fi
    # 去除双引号
    if [[ $ipv4_asn_info == *"\""* ]]; then
        ipv4_asn_info="${ipv4_asn_info%\"*}"
    fi
    if [[ $ipv4_location == *"\""* ]]; then
        ipv4_location="${ipv4_location%\"*}"
    fi
    # 返回结果
    echo "$ipv4_asn_info" >>/tmp/cloudflare
    echo "$ipv4_location" >>/tmp/cloudflare
    # 获取 IPv6 信息
    sleep 1
    local ipv6_output=$(curl -ksL6m6 -A Mozilla https://speed.cloudflare.com/meta 2>/dev/null)
    # 提取 IPv6 的 asn、asOrganization、city 和 region
    local ipv6_asn=$(echo "$ipv6_output" | grep -oE '"asn":[0-9]+' | grep -oE '[0-9]+')
    local ipv6_as_organization=$(echo "$ipv6_output" | grep -oE '"asOrganization":"[^"]+"' | grep -oE '":"[^"]+"' | sed 's/":"//g')
    local ipv6_city=$(echo "$ipv6_output" | grep -oE '"city":"[^"]+"' | grep -oE '":"[^"]+"' | sed 's/":"//g')
    local ipv6_region=$(echo "$ipv6_output" | grep -oE '"region":"[^"]+"' | grep -oE '":"[^"]+"' | sed 's/":"//g')
    if [ -n "$ipv6_asn" ] && [ -n "$ipv6_as_organization" ] && [ -n "$ipv6_city" ] && [ -n "$ipv6_region" ]; then
        local ipv6_asn_info="AS${ipv6_asn} ${ipv6_as_organization}"
        local ipv6_location="${ipv6_city} / ${ipv6_region}"
    elif [ -n "$ipv6_asn" ] && [ -n "$ipv6_as_organization" ] && [ -n "$ipv6_city" ]; then
        local ipv6_asn_info="AS${ipv6_asn} ${ipv6_as_organization}"
        local ipv6_location="${ipv6_city}"
    elif [ -n "$ipv6_asn" ] && [ -n "$ipv6_as_organization" ] && [ -n "$ipv6_region" ]; then
        local ipv6_asn_info="AS${ipv6_asn} ${ipv6_as_organization}"
        local ipv6_location="${ipv6_region}"
    else
        local ipv6_asn_info="None"
        local ipv6_location="None"
    fi
    # 去除双引号
    if [[ $ipv6_asn_info == *"\""* ]]; then
        ipv6_asn_info="${ipv6_asn_info%\"*}"
    fi
    if [[ $ipv6_location == *"\""* ]]; then
        ipv6_location="${ipv6_location%\"*}"
    fi
    # 返回结果
    echo "$ipv6_asn_info" >>/tmp/cloudflare
    echo "$ipv6_location" >>/tmp/cloudflare
}

check_ip_info_by_ipsb() {
    # ip.sb
    rm -rf /tmp/ipsb
    local result_ipv4=$(curl -ksL4m6 -A Mozilla https://api.ip.sb/geoip 2>/dev/null)
    if [ "$?" -ne 0 ] || echo "$result_ipv4" | grep -qE "(Comodo Secure DNS|Rate limit exceeded)|Your client does not have permission to get URL" >/dev/null 2>&1; then
        local ipv4_asn_info="None"
        local ipv4_location="None"
    else
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
            elif [ -n "$ipv4_asn" ] && [ -n "$ipv4_as_organization" ] && [ -n "$ipv4_city" ] && [ -n "$ipv4_region" ]; then
                local ipv4_asn_info="AS${ipv4_asn} ${ipv4_as_organization}"
                local ipv4_location="${ipv4_city} / ${ipv4_region}"
            elif [ -n "$ipv4_asn" ] && [ -n "$ipv4_as_organization" ] && [ -n "$ipv4_city" ] && [ -n "$ipv4_country" ]; then
                local ipv4_asn_info="AS${ipv4_asn} ${ipv4_as_organization}"
                local ipv4_location="${ipv4_city} / ${ipv4_country}"
            elif [ -n "$ipv4_asn" ] && [ -n "$ipv4_as_organization" ] && [ -n "$ipv4_region" ] && [ -n "$ipv4_country" ]; then
                local ipv4_asn_info="AS${ipv4_asn} ${ipv4_as_organization}"
                local ipv4_location="${ipv4_region} / ${ipv4_country}"
            elif [ -n "$ipv4_asn" ] && [ -n "$ipv4_as_organization" ] && { [ -n "$ipv4_city" ] || [ -n "$ipv4_region" ] || [ -n "$ipv4_country" ]; }; then
                local ipv4_asn_info="AS${ipv4_asn} ${ipv4_as_organization}"
                local ipv4_location="${ipv4_city} ${ipv4_region} ${ipv4_country}"
            else
                local ipv4_asn_info="None"
                local ipv4_location="None"
            fi
        else
            local ipv4_asn_info="None"
            local ipv4_location="None"
        fi
    fi
    # 返回结果
    echo "$ipv4_asn_info" >>/tmp/ipsb
    echo "$ipv4_location" >>/tmp/ipsb
    # 获取IPv6的asn、city、region、country
    sleep 1
    local result_ipv6=$(curl -ksL6m6 -A Mozilla https://api.ip.sb/geoip 2>/dev/null)
    if [ "$?" -ne 0 ] || echo "$result_ipv6" | grep -qE "(Comodo Secure DNS|Rate limit exceeded)|Your client does not have permission to get URL" >/dev/null 2>&1; then
        local ipv6_asn_info="None"
        local ipv6_location="None"
    else
        if [ -n "$result_ipv6" ]; then
            local ipv6_asn=$(expr "$result_ipv6" : '.*asn\":[ ]*\([0-9]*\).*')
            local ipv6_as_organization=$(expr "$result_ipv6" : '.*isp\":[ ]*\"\([^"]*\).*')
            local ipv6_city=$(echo $result_ipv6 | grep -oE '"city":"[^"]+"' | cut -d ":" -f2 | tr -d '"')
            local ipv6_region=$(echo $result_ipv6 | grep -oE '"region":"[^"]+"' | cut -d ":" -f2 | tr -d '"')
            local ipv6_country=$(echo "$result_ipv6" | grep -oP '(?<="country":")[^"]*')
            if [ -n "$ipv6_asn" ] && [ -n "$ipv6_as_organization" ] && [ -n "$ipv6_city" ] && [ -n "$ipv6_region" ] && [ -n "$ipv6_country" ]; then
                local ipv6_asn_info="AS${ipv6_asn} ${ipv6_as_organization}"
                local ipv6_location="${ipv6_city} / ${ipv6_region} / ${ipv6_country}"
            elif [ -n "$ipv6_asn" ] && [ -n "$ipv6_as_organization" ] && [ -n "$ipv6_city" ] && [ -n "$ipv6_region" ]; then
                local ipv6_asn_info="AS${ipv6_asn} ${ipv6_as_organization}"
                local ipv6_location="${ipv6_city} / ${ipv6_region}"
            elif [ -n "$ipv6_asn" ] && [ -n "$ipv6_as_organization" ] && [ -n "$ipv6_city" ] && [ -n "$ipv6_country" ]; then
                local ipv6_asn_info="AS${ipv6_asn} ${ipv6_as_organization}"
                local ipv6_location="${ipv6_city} / ${ipv6_country}"
            elif [ -n "$ipv6_asn" ] && [ -n "$ipv6_as_organization" ] && [ -n "$ipv6_region" ] && [ -n "$ipv6_country" ]; then
                local ipv6_asn_info="AS${ipv6_asn} ${ipv6_as_organization}"
                local ipv6_location="${ipv6_region} / ${ipv6_country}"
            elif [ -n "$ipv6_asn" ] && [ -n "$ipv6_as_organization" ] && { [ -n "$ipv6_city" ] || [ -n "$ipv6_region" ] || [ -n "$ipv6_country" ]; }; then
                local ipv6_asn_info="AS${ipv6_asn} ${ipv6_as_organization}"
                local ipv6_location="${ipv6_city} ${ipv6_region} ${ipv6_country}"
            else
                local ipv6_asn_info="None"
                local ipv6_location="None"
            fi
        else
            local ipv6_asn_info="None"
            local ipv6_location="None"
        fi
    fi
    # 返回结果
    echo "$ipv6_asn_info" >>/tmp/ipsb
    echo "$ipv6_location" >>/tmp/ipsb
}

check_ip_info_by_cheervision() {
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
    echo "$ipv4_asn_info" >>/tmp/cheervision
    echo "$ipv4_location" >>/tmp/cheervision
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
    echo "$ipv6_asn_info" >>/tmp/cheervision
    echo "$ipv6_location" >>/tmp/cheervision
}

get_system_info() {
    local ip4=$(echo "$IPV4" | tr -d '\n')
    arch=$(uname -m)
    if [ -n "$Result_Systeminfo_Diskinfo" ]; then
        :
    else
        disk_size1=($(LC_ALL=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem|udev|docker|snapd' | awk '{print $2}'))
        disk_size2=($(LC_ALL=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem|udev|docker|snapd' | awk '{print $3}'))
        disk_total_size=$(calc_disk "${disk_size1[@]}")
        disk_used_size=$(calc_disk "${disk_size2[@]}")
    fi
    if [ -f "/proc/cpuinfo" ]; then
        cname=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
        cores=$(awk -F: '/processor/ {core++} END {print core}' /proc/cpuinfo)
        freq=$(awk -F'[ :]' '/cpu MHz/ {print $4;exit}' /proc/cpuinfo)
        ccache=$(awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
        CPU_AES=$(cat /proc/cpuinfo | grep aes)
        CPU_VIRT=$(cat /proc/cpuinfo | grep 'vmx\|svm')
        up=$(awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days, %d hour %d min\n",a,b,c)}' /proc/uptime)
        if _exists "w"; then
            load=$(
                LANG=C
                w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//'
            )
        elif _exists "uptime"; then
            load=$(
                LANG=C
                uptime | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//'
            )
        fi
    elif [ "${Var_OSRelease}" == "freebsd" ]; then
        cname=$($sysctl_path -n hw.model)
        cores=$($sysctl_path -n hw.ncpu)
        freq=$($sysctl_path -n dev.cpu.0.freq 2>/dev/null || echo "")
        ccache=$($sysctl_path -n hw.cacheconfig 2>/dev/null | awk -F: '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' || echo "")
        CPU_AES=$($sysctl_path -a | grep -E 'crypto.aesni' | awk '{print $2}')
        CPU_VIRT=$($sysctl_path -a | grep -E 'hw.vmx|hw.svm' | awk '{print $2}')
        up=$($sysctl_path -n kern.boottime | perl -MPOSIX -nE 'if (/sec = (\d+), usec = (\d+)/) { $boottime = $1; $uptime = time() - $boottime; $days = int($uptime / 86400); $hours = int(($uptime % 86400) / 3600); $minutes = int(($uptime % 3600) / 60); say "$days days, $hours hours, $minutes minutes" }')
        if _exists "w"; then
            load=$(w | awk '{print $(NF-2), $(NF-1), $NF}' | head -n 1)
        elif _exists "uptime"; then
            load=$(uptime | awk '{print $(NF-2), $(NF-1), $NF}')
        fi
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
    if command -v free >/dev/null 2>&1; then
        if free -m | grep -q '内存'; then # 如果输出中包含 "内存" 关键词
            tram=$(free -m | awk '/内存/{print $2}')
            uram=$(free -m | awk '/内存/{print $3}')
            swap=$(free -m | awk '/交换/{print $2}')
            uswap=$(free -m | awk '/交换/{print $3}')
        else # 否则，假定输出是英文的
            tram=$(
                LANG=C
                free -m | awk '/Mem/ {print $2}'
            )
            uram=$(
                LANG=C
                free -m | awk '/Mem/ {print $3}'
            )
            swap=$(
                LANG=C
                free -m | awk '/Swap/ {print $2}'
            )
            uswap=$(
                LANG=C
                free -m | awk '/Swap/ {print $3}'
            )
        fi
    else
        tram=$($sysctl_path -n hw.physmem | awk '{printf "%.0f", $1/1024/1024}')
        uram=$($sysctl_path -n vm.stats.vm.v_active_count | awk '{printf "%.0f", $1/1024}')
        swap=$(swapinfo -k | awk 'NR>1{sum+=$2} END{printf "%.0f", sum/1024}')
        uswap=$(swapinfo -k | awk 'NR>1{sum+=$4} END{printf "%.0f", sum/1024}')
    fi
    if _exists "getconf"; then
        lbit=$(getconf LONG_BIT)
    else
        echo ${arch} | grep -q "64" && lbit="64" || lbit="32"
    fi
    kern=$(uname -r)
    if [ -z "$sysctl_path" ]; then
        tcpctrl="None"
    fi
    tcpctrl=$($sysctl_path -n net.ipv4.tcp_congestion_control 2>/dev/null)
    if [ $? -ne 0 ]; then
        if [ "$en_status" = true ]; then
            tcpctrl="TCP congestion control algorithm not set"
        else
            tcpctrl="未设置TCP拥塞控制算法"
        fi
    else
        if [ $tcpctrl == "bbr" ]; then
            :
        else
            if lsmod | grep bbr >/dev/null; then
                if [ "$en_status" = true ]; then
                    reading "Should I turn on bbr before testing? (Enter to leave it on by default) [y/n] " confirmbbr
                else
                    reading "是否要开启bbr再进行测试？(回车则默认不开启) [y/n] " confirmbbr
                fi
                echo ""
                if [ "$confirmbbr" != "y" ]; then
                    echo "net.core.default_qdisc=fq" >>"$sysctl_conf"
                    echo "net.ipv4.tcp_congestion_control=bbr" >>"$sysctl_conf"
                    $sysctl_path -p
                fi
                tcpctrl=$($sysctl_path -n net.ipv4.tcp_congestion_control 2>/dev/null)
                if [ $? -ne 0 ]; then
                    tcpctrl="None"
                fi
            fi
        fi
    fi
}

# =============== 正式输出 部分 ===============
print_intro() {
    echo "--------------------- A Bench Script By spiritlhl ----------------------"
    if [ "$en_status" = true ]; then
        echo "              Evaluation Channel: https://t.me/vps_reviews               "
        echo "VPS Fusion Monster Version：$ver"
        echo "Shell Project: https://github.com/spiritLHLS/ecs"
        echo "Go Project [recommend]: https://github.com/oneclickvirt/ecs"
    else
        echo "                   测评频道: https://t.me/vps_reviews                    "
        echo "VPS融合怪版本：$ver"
        echo "Shell项目地址：https://github.com/spiritLHLS/ecs"
        echo "Go项目地址 [推荐]：https://github.com/oneclickvirt/ecs"
    fi
}

get_first_not_none_element() {
    local array=("$@")
    for element in "${array[@]}"; do
        if [[ "$element" != "None" && -n "$element" ]]; then
            echo "$element"
            return
        fi
    done
}

run_ip_info_check() {
    _yellow "run IP information check..."
    # 并行执行并发查询IP信息
    check_ip_info_by_cloudflare &
    check_ip_info_by_ipinfo &
    check_ip_info_by_ipsb &
    check_ip_info_by_cheervision &
    wait
}

print_ip_info() {
    # 存储结果的四个列表
    local ipv4_asn_info_list=()
    local ipv4_location_list=()
    local ipv6_asn_info_list=()
    local ipv6_location_list=()
    # 遍历每个函数的结果文件，读取内容到对应的列表中，按顺序来说越往后越不准
    files=("/tmp/ipinfo" "/tmp/ipsb" "/tmp/cloudflare" "/tmp/cheervision")
    for file in "${files[@]}"; do
        {
            read -r asn_info
            read -r location
            read -r ipv6_asn_info
            read -r ipv6_location
        } <"$file"
        ipv4_asn_info_list+=("$asn_info")
        ipv4_location_list+=("$location")
        ipv6_asn_info_list+=("$ipv6_asn_info")
        ipv6_location_list+=("$ipv6_location")
    done
    # 找到每个列表中最长的第一个元素作为最终结果
    local ipv4_asn_info=$(get_first_not_none_element "${ipv4_asn_info_list[@]}")
    local ipv4_location=$(get_first_not_none_element "${ipv4_location_list[@]}")
    local ipv6_asn_info=$(get_first_not_none_element "${ipv6_asn_info_list[@]}")
    local ipv6_location=$(get_first_not_none_element "${ipv6_location_list[@]}")
    # 删除缓存文件
    for file in "${files[@]}"; do
        rm -rf ${file}
    done
    # 获取IPV6的子网掩码
    if [ -f "${TEMP_DIR}/eo6s_result" ]; then
        local ipv6_prefixlen=$(check_and_cat_file "${TEMP_DIR}/eo6s_result")
    else
        local ipv6_prefixlen=""
    fi
    # 打印最终结果
    if [ "$en_status" = true ]; then
        if [[ -n "$ipv4_asn_info" && "$ipv4_asn_info" != "None" ]]; then
            echo " IPV4 ASN          : $(_blue "$ipv4_asn_info")"
        fi
        if [[ -n "$ipv4_location" && "$ipv4_location" != "None" ]]; then
            echo " IPV4 Location     : $(_blue "$ipv4_location")"
        fi
        if [[ -n "$ipv6_asn_info" && "$ipv6_asn_info" != "None" ]]; then
            echo " IPV6 ASN          : $(_blue "$ipv6_asn_info")"
        fi
        if [[ -n "$ipv6_location" && "$ipv6_location" != "None" ]]; then
            echo " IPV6 Location     : $(_blue "$ipv6_location")"
        fi
        if [[ -n "$ipv6_prefixlen" && "$ipv6_prefixlen" != "None" ]]; then
            echo " IPV6 Subnet Mask  : $(_blue "$ipv6_prefixlen")"
        fi
    else
        if [[ -n "$ipv4_asn_info" && "$ipv4_asn_info" != "None" ]]; then
            echo " IPV4 ASN          : $(_blue "$ipv4_asn_info")"
        fi
        if [[ -n "$ipv4_location" && "$ipv4_location" != "None" ]]; then
            echo " IPV4 位置         : $(_blue "$ipv4_location")"
        fi
        if [[ -n "$ipv6_asn_info" && "$ipv6_asn_info" != "None" ]]; then
            echo " IPV6 ASN          : $(_blue "$ipv6_asn_info")"
            ipv6_condition=true
        fi
        if [[ -n "$ipv6_location" && "$ipv6_location" != "None" ]]; then
            echo " IPV6 位置         : $(_blue "$ipv6_location")"
        fi
        if [[ -n "$ipv6_prefixlen" && "$ipv6_prefixlen" != "None" && -n "$ipv6_asn_info" && "$ipv6_asn_info" != "None" ]]; then
            echo " IPV6 子网掩码     : $(_blue "$ipv6_prefixlen")"
        fi
    fi
}

print_system_info() {
    if [ "$en_status" = true ]; then
        if [ -n "$cname" ] >/dev/null 2>&1; then
            echo " Processor         : $(_blue "$cname")"
        elif [ -n "$Result_Systeminfo_CPUModelName" ] >/dev/null 2>&1; then
            echo " Processor         : $(_blue "$Result_Systeminfo_CPUModelName")"
        else
            echo " Processor         : $(_blue "Unable to detect Processor")"
        fi
        if [[ -n "$Result_Systeminfo_isPhysical" && "$Result_Systeminfo_isPhysical" = "1" ]] >/dev/null 2>&1; then
            if [ -n "$Result_Systeminfo_CPUSockets" ] && [ "$Result_Systeminfo_CPUSockets" -ne 0 ] &&
                [ -n "$Result_Systeminfo_CPUCores" ] && [ "$Result_Systeminfo_CPUCores" -ne 0 ] &&
                [ -n "$Result_Systeminfo_CPUThreads" ] && [ "$Result_Systeminfo_CPUThreads" -ne 0 ] >/dev/null 2>&1; then
                echo " CPU Numbers      : $(_blue "${Result_Systeminfo_CPUSockets} Physical CPUs, ${Result_Systeminfo_CPUCores} Total Cores, ${Result_Systeminfo_CPUThreads} Total Threads")"
            elif [ -n "$cores" ]; then
                echo " CPU Numbers       : $(_blue "$cores")"
            else
                echo " CPU Numbers       : $(_blue "Unable to detect CPU Numbers")"
            fi
        elif [[ -n "$Result_Systeminfo_isPhysical" && "$Result_Systeminfo_isPhysical" = "0" ]] >/dev/null 2>&1; then
            if [[ -n "$Result_Systeminfo_CPUThreads" && "$Result_Systeminfo_CPUThreads" -ne 0 ]] >/dev/null 2>&1; then
                echo " CPU Numbers       : $(_blue "${Result_Systeminfo_CPUThreads}")"
            elif [ -n "$cores" ] >/dev/null 2>&1; then
                echo " CPU Numbers       : $(_blue "$cores")"
            else
                echo " CPU Numbers       : $(_blue "Unable to detect CPU Numbers")"
            fi
        else
            echo " CPU Numbers       : $(_blue "$cores")"
        fi
        if [ -n "$freq" ] >/dev/null 2>&1; then
            echo " CPU Frequency     : $(_blue "$freq MHz")"
        fi
        if [ -n "$Result_Systeminfo_CPUCacheSizeL1" ] && [ -n "$Result_Systeminfo_CPUCacheSizeL2" ] && [ -n "$Result_Systeminfo_CPUCacheSizeL3" ] >/dev/null 2>&1; then
            echo " CPU Cache         : $(_blue "L1: ${Result_Systeminfo_CPUCacheSizeL1} / L2: ${Result_Systeminfo_CPUCacheSizeL2} / L3: ${Result_Systeminfo_CPUCacheSizeL3}")"
        elif [ -n "$ccache" ] >/dev/null 2>&1; then
            echo " CPU Cache         : $(_blue "$ccache")"
        fi
        [[ -z "$CPU_AES" ]] && CPU_AES="✘ Disabled" || CPU_AES="✔ Enabled"
        echo " AES-NI            : $(_blue "$CPU_AES")"
        [[ -z "$CPU_VIRT" ]] && CPU_VIRT="✘ Disabled" || CPU_VIRT="✔ Enabled"
        echo " VM-x/AMD-V        : $(_blue "$CPU_VIRT")"
        if [ -n "$Result_Systeminfo_Memoryinfo" ] >/dev/null 2>&1; then
            echo " RAM               : $(_blue "$Result_Systeminfo_Memoryinfo")"
        elif [ -n "$tram" ] && [ -n "$uram" ] >/dev/null 2>&1; then
            echo " RAM               : $(_yellow "$tram MB") $(_blue "($uram MB 已用)")"
        fi
        if [ -n "$Result_Systeminfo_Swapinfo" ] >/dev/null 2>&1; then
            echo " Swap              : $(_blue "$Result_Systeminfo_Swapinfo")"
        elif [ -n "$swap" ] && [ -n "$uswap" ] >/dev/null 2>&1; then
            echo " Swap              : $(_blue "$swap MB ($uswap MB 已用)")"
        fi
        if [ -n "$Result_Systeminfo_Diskinfo" ] >/dev/null 2>&1; then
            echo " Disk Space        : $(_blue "$Result_Systeminfo_Diskinfo")"
        else
            echo " Disk Space        : $(_yellow "$disk_total_size GB") $(_blue "($disk_used_size GB Usage)")"
        fi
        if [ -n "$Result_Systeminfo_DiskRootPath" ] >/dev/null 2>&1; then
            echo " Boot Disk         : $(_blue "$Result_Systeminfo_DiskRootPath")"
        fi
        echo " Uptime            : $(_blue "$up")"
        echo " Loads             : $(_blue "$load")"
        if [ -n "$Result_Systeminfo_OSReleaseNameFull" ] >/dev/null 2>&1; then
            echo " OS Release        : $(_blue "$Result_Systeminfo_OSReleaseNameFull")"
        elif [ -n "$DISTRO" ] >/dev/null 2>&1; then
            echo " OS Release        : $(_blue "$DISTRO")"
        fi
        echo " Arch              : $(_blue "$arch ($lbit Bit)")"
        echo " Kernel Version    : $(_blue "$kern")"
        echo " TCP Acceleration  : $(_yellow "$tcpctrl")"
        echo " VM Type           : $(_blue "$Result_Systeminfo_VMMType")"
        [[ -n "$nat_type_r" ]] && echo " NAT Type          : $(_blue "$nat_type_r")"
    else
        if [ -n "$cname" ] >/dev/null 2>&1; then
            echo " CPU 型号          : $(_blue "$cname")"
        elif [ -n "$Result_Systeminfo_CPUModelName" ] >/dev/null 2>&1; then
            echo " CPU 型号          : $(_blue "$Result_Systeminfo_CPUModelName")"
        else
            echo " CPU 型号          : $(_blue "无法检测到CPU型号")"
        fi
        if [[ -n "$Result_Systeminfo_isPhysical" && "$Result_Systeminfo_isPhysical" = "1" ]] >/dev/null 2>&1; then
            if [ -n "$Result_Systeminfo_CPUSockets" ] && [ "$Result_Systeminfo_CPUSockets" -ne 0 ] &&
                [ -n "$Result_Systeminfo_CPUCores" ] && [ "$Result_Systeminfo_CPUCores" -ne 0 ] &&
                [ -n "$Result_Systeminfo_CPUThreads" ] && [ "$Result_Systeminfo_CPUThreads" -ne 0 ] >/dev/null 2>&1; then
                echo " CPU 核心数        : $(_blue "${Result_Systeminfo_CPUSockets} 物理核心, ${Result_Systeminfo_CPUCores} 总核心, ${Result_Systeminfo_CPUThreads} 总线程数")"
            elif [ -n "$cores" ]; then
                echo " CPU 核心数        : $(_blue "$cores")"
            else
                echo " CPU 核心数        : $(_blue "无法检测到CPU核心数量")"
            fi
        elif [[ -n "$Result_Systeminfo_isPhysical" && "$Result_Systeminfo_isPhysical" = "0" ]] >/dev/null 2>&1; then
            if [[ -n "$Result_Systeminfo_CPUThreads" && "$Result_Systeminfo_CPUThreads" -ne 0 ]] >/dev/null 2>&1; then
                echo " CPU 核心数        : $(_blue "${Result_Systeminfo_CPUThreads}")"
            elif [ -n "$cores" ] >/dev/null 2>&1; then
                echo " CPU 核心数        : $(_blue "$cores")"
            else
                echo " CPU 核心数        : $(_blue "无法检测到CPU核心数量")"
            fi
        else
            echo " CPU 核心数        : $(_blue "$cores")"
        fi
        if [ -n "$freq" ] >/dev/null 2>&1; then
            echo " CPU 频率          : $(_blue "$freq MHz")"
        fi
        if [ -n "$Result_Systeminfo_CPUCacheSizeL1" ] && [ -n "$Result_Systeminfo_CPUCacheSizeL2" ] && [ -n "$Result_Systeminfo_CPUCacheSizeL3" ] >/dev/null 2>&1; then
            echo " CPU 缓存          : $(_blue "L1: ${Result_Systeminfo_CPUCacheSizeL1} / L2: ${Result_Systeminfo_CPUCacheSizeL2} / L3: ${Result_Systeminfo_CPUCacheSizeL3}")"
        elif [ -n "$ccache" ] >/dev/null 2>&1; then
            echo " CPU 缓存          : $(_blue "$ccache")"
        fi
        [[ -z "$CPU_AES" ]] && CPU_AES="\xE2\x9D\x8C Disabled" || CPU_AES="\xE2\x9C\x94 Enabled"
        echo " AES-NI指令集      : $(_blue "$CPU_AES")"
        [[ -z "$CPU_VIRT" ]] && CPU_VIRT="\xE2\x9D\x8C Disabled" || CPU_VIRT="\xE2\x9C\x94 Enabled"
        echo " VM-x/AMD-V支持    : $(_blue "$CPU_VIRT")"
        if [ -n "$Result_Systeminfo_Memoryinfo" ] >/dev/null 2>&1; then
            echo " 内存              : $(_blue "$Result_Systeminfo_Memoryinfo")"
        elif [ -n "$tram" ] && [ -n "$uram" ] >/dev/null 2>&1; then
            echo " 内存              : $(_yellow "$tram MB") $(_blue "($uram MB 已用)")"
        fi
        if [ -n "$Result_Systeminfo_Swapinfo" ] >/dev/null 2>&1; then
            echo " Swap              : $(_blue "$Result_Systeminfo_Swapinfo")"
        elif [ -n "$swap" ] && [ -n "$uswap" ] >/dev/null 2>&1; then
            echo " Swap              : $(_blue "$swap MB ($uswap MB 已用)")"
        fi
        if [ -n "$Result_Systeminfo_Diskinfo" ] >/dev/null 2>&1; then
            echo " 硬盘空间          : $(_blue "$Result_Systeminfo_Diskinfo")"
        else
            echo " 硬盘空间          : $(_yellow "$disk_total_size GB") $(_blue "($disk_used_size GB 已用)")"
        fi
        if [ -n "$Result_Systeminfo_DiskRootPath" ] >/dev/null 2>&1; then
            echo " 启动盘路径        : $(_blue "$Result_Systeminfo_DiskRootPath")"
        fi
        echo " 系统在线时间      : $(_blue "$up")"
        echo " 负载              : $(_blue "$load")"
        if [ -n "$Result_Systeminfo_OSReleaseNameFull" ] >/dev/null 2>&1; then
            echo " 系统              : $(_blue "$Result_Systeminfo_OSReleaseNameFull")"
        elif [ -n "$DISTRO" ] >/dev/null 2>&1; then
            echo " 系统              : $(_blue "$DISTRO")"
        fi
        echo " 架构              : $(_blue "$arch ($lbit Bit)")"
        echo " 内核              : $(_blue "$kern")"
        echo " TCP加速方式       : $(_yellow "$tcpctrl")"
        echo " 虚拟化架构        : $(_blue "$Result_Systeminfo_VMMType")"
        [[ -n "$nat_type_r" ]] && echo " NAT类型           : $(_blue "$nat_type_r")"
    fi
}

print_end_time() {
    end_time=$(date +%s)
    start_time_abs=$(echo $start_time | tr -d -)
    end_time_abs=$(echo $end_time | tr -d -)
    time_abs_diff=$((${end_time_abs} - ${start_time_abs}))
    time=$(echo $time_abs_diff | tr -d -)
    if [ "$en_status" = true ]; then
        if [ ${time} -gt 60 ]; then
            min=$(expr $time / 60)
            sec=$(expr $time % 60)
            echo " Total spent   : ${min} min ${sec} sec"
        else
            echo " Total spent   : ${time} sec"
        fi
        date_time=$(date)
        echo " Time          : $date_time"
    else
        if [ ${time} -gt 60 ]; then
            min=$(expr $time / 60)
            sec=$(expr $time % 60)
            echo " 总共花费      : ${min} 分 ${sec} 秒"
        else
            echo " 总共花费      : ${time} 秒"
        fi
        date_time=$(date)
        echo " 时间          : $date_time"
    fi
}

check_lmc_script() {
    mv $TEMP_DIR/media_lmc_check.sh ./
}

# =============== IP质量检测 部分 ===============
# 为true时显示对应的数字序号，否则不显示
translate_status() {
    if [[ "$1" == "false" ]]; then
        echo "No"
    elif [[ "$1" == "true" ]]; then
        echo "Yes"
    else
        echo "$1"
    fi
}

google() {
    local curl_result=$(curl -sL -m 10 "https://www.google.com/search?q=www.spiritysdx.top" -H "User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:54.0) Gecko/20100101 Firefox/54.0")
    rm -rf /tmp/ip_quality_google
    if [ "$en_status" = true ]; then
        if echo "$curl_result" | grep -q "二叉树的博客"; then
            echo "Google search feasibility: YES" >>/tmp/ip_quality_google
        else
            echo "Google search feasibility: NO" >>/tmp/ip_quality_google
        fi
    else
        if echo "$curl_result" | grep -q "二叉树的博客"; then
            echo "Google搜索可行性：YES" >>/tmp/ip_quality_google
        else
            echo "Google搜索可行性：NO" >>/tmp/ip_quality_google
        fi
    fi
}

security_check() {
    local language=$1
    cd $myvar >/dev/null 2>&1
    if [ -f "${TEMP_DIR}/securityCheck" ]; then
        chmod 777 ${TEMP_DIR}/securityCheck
    else
        return
    fi
    ${TEMP_DIR}/securityCheck -l $language | sed '1d' >>/tmp/ip_quality_security_check
}

email_check() {
    cd $myvar >/dev/null 2>&1
    if [ -f "${TEMP_DIR}/pck" ]; then
        chmod 777 ${TEMP_DIR}/pck
    else
        return
    fi
    ${TEMP_DIR}/pck | sed '1d' >>/tmp/ip_quality_email_check
}

ipcheck() {
    { google; } &
    if [ "$en_status" = true ]; then
        { security_check "en"; } &
    else
        { security_check "zh"; } &
    fi
    { email_check; } &
    wait
    check_and_cat_file "/tmp/ip_quality_security_check"
    check_and_cat_file "/tmp/ip_quality_google"
    if [ "$en_status" = true ]; then
        echo -e "-------Email-Port-Detection--Base-On-oneclickvirt/portchecker--------"
    else
        echo -e "-------------邮件端口检测--基于oneclickvirt/portchecker开源-------------"
    fi
    check_and_cat_file "/tmp/ip_quality_email_check"
    rm -rf /tmp/ip_quality_*
}

eo6s() {
    # 获取IPV6的子网掩码
    rm -rf $TEMP_DIR/eo6s_result
    local interface=$(ls /sys/class/net/ | grep -E '^(eth|en)' | head -n 1)
    if [ -n "$interface" ]; then
        local current_ipv6=$(curl -s -6 -m 5 ipv6.ip.sb)
        echo "current_ipv6: ${current_ipv6}"
        [ -z "$current_ipv6" ] && echo "None" >$TEMP_DIR/eo6s_result && return
        local new_ipv6="${current_ipv6%:*}:3"
        ip addr add ${new_ipv6}/128 dev ${interface}
        sleep 6
        local updated_ipv6=$(curl -s -6 -m 5 ipv6.ip.sb)
        echo "updated_ipv6: ${updated_ipv6}"
        ip addr del ${new_ipv6}/128 dev ${interface}
        sleep 6
        local final_ipv6=$(curl -s -6 -m 5 ipv6.ip.sb)
        echo "final_ipv6: ${final_ipv6}"
        local ipv6_prefixlen=""
        if command -v ifconfig &>/dev/null; then
            local output=$(ifconfig ${interface} | grep -oP 'inet6 (?!fe80:).*prefixlen \K\d+')
        else
            local output=$(ip -6 addr show dev ${interface} | grep -oP 'inet6 (?!fe80:).* scope global.*prefixlen \K\d+')
        fi
        local num_lines=$(echo "$output" | wc -l)
        if [ $num_lines -ge 2 ]; then
            ipv6_prefixlen=$(echo "$output" | sort -n | head -n 1)
        else
            ipv6_prefixlen=$(echo "$output" | head -n 1)
        fi
        if [ "$updated_ipv6" == "$current_ipv6" ] || [ -z "$updated_ipv6" ]; then
            echo "128" >$TEMP_DIR/eo6s_result
        else
            echo "$ipv6_prefixlen" >$TEMP_DIR/eo6s_result
        fi
    else
        echo "Unknown" >$TEMP_DIR/eo6s_result
    fi
}

cdn_urls=("http://cdn1.spiritlhl.net/" "http://cdn2.spiritlhl.net/" "http://cdn3.spiritlhl.net/" "http://cdn4.spiritlhl.net/")
ST="OvwKx5qgJtf7PZgCKbtyojSU.MTcwMTUxNzY1MTgwMw"
speedtest_ver="1.2.0"
SERVER_BASE_URL="https://raw.githubusercontent.com/spiritLHLS/speedtest.net-CN-ID/main"
SERVER_BASE_URL2="https://raw.githubusercontent.com/spiritLHLS/speedtest.cn-CN-ID/main"

pre_check() {
    trap 'error_exit' ERR
    check_update || error_exit
    check_root
    check_sudo
    check_curl
    optimized_kernel
    run_ip_info_check &
    check_ipv6 &
    check_ipv4 &
    check_ip
    check_cdn_file
    check_wget
    systemInfo_get_os_release
    check_lsof
    check_time_zone
    start_time=$(date +%s)
    Check_SysBench
    global_startup_init_action
    cd $myvar >/dev/null 2>&1
    ! _exists "wget" && error_exit && _red "Error: wget command not found.\n" && exit 1
    check_china
    wait
    IPV4=$(check_and_cat_file /tmp/ip_quality_ipv4)
    IPV6=$(check_and_cat_file /tmp/ip_quality_ipv6)
    if [ -n "$IPV6" ] && [ -n "$IPV4" ]; then
        if [ "$en_status" = true ]; then
            echo "Detecting and verifying IPV6 subnet mask size is in progress, it will take about 10~15 seconds"
        else
            echo "正在检测和验证IPV6的子网掩码大小，大概需要10~15秒"
        fi
        eo6s &
    fi
    if [ "$en_status" = true ]; then
        echo "Please wait patiently for the background tasks to finish"
    else
        echo "请耐心等待后台任务执行完毕"
    fi
    check_haveged
    check_free
    check_timeout
    check_lscpu
    check_unzip
    check_tar
    check_nc
    checknslookup
    wait
    if [ "$en_status" = true ]; then
        echo "Finish background task"
    else
        echo "后台任务执行完毕"
    fi
}

sjlleo_script() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
    if [ "$en_status" = true ]; then
        return
    fi
    cd $myvar >/dev/null 2>&1
    if [ -f $TEMP_DIR/CommonMediaTests ]; then
        mv $TEMP_DIR/CommonMediaTests ./
        echo "------------流媒体解锁--基于oneclickvirt/CommonMediaTests开源-----------"
        _yellow "以下测试的解锁地区是准确的，但是不是完整解锁的判断可能有误，这方面仅作参考使用"
        ./CommonMediaTests | grep -v 'github.com/oneclickvirt/CommonMediaTests'
        _yellow "解锁Netflix，Youtube，DisneyPlus上面和下面进行比较，不同之处自行判断"
    else
        _red "CommonMediaTests下载失败所以不进行测试"
    fi
}

cpu_judge() {
    local benchmark_type=$1
    local benchmark_name=""
    if [ "$en_status" = true ]; then
        case $benchmark_type in
        sysbench)
            benchmark_name="SysBench_CPU_Fast"
            echo "---------------------------CPU-Sysbench-Test----------------------------"
            ;;
        geekbench4)
            benchmark_name="4"
            echo "--------------------------CPU-Geekbench4-Test---------------------------"
            ;;
        geekbench5)
            benchmark_name="5"
            echo "--------------------------CPU-Geekbench5-Test---------------------------"
            ;;
        geekbench6)
            benchmark_name="6"
            echo "--------------------------CPU-Geekbench6-Test---------------------------"
            ;;
        *)
            echo "Invalid benchmark type"
            return
            ;;
        esac
    else
        case $benchmark_type in
        sysbench)
            benchmark_name="SysBench_CPU_Fast"
            echo "----------------------CPU测试--通过sysbench测试-------------------------"
            ;;
        geekbench4)
            benchmark_name="4"
            echo "-----------------CPU测试--感谢yabs开源geekbench4测试--------------------"
            ;;
        geekbench5)
            benchmark_name="5"
            echo "-----------------CPU测试--感谢yabs开源geekbench5测试--------------------"
            ;;
        geekbench6)
            benchmark_name="6"
            echo "-----------------CPU测试--感谢yabs开源geekbench6测试--------------------"
            ;;
        *)
            echo "Invalid benchmark type"
            return
            ;;
        esac
    fi
    if [ "$benchmark_type" == "sysbench" ]; then
        Function_SysBench_CPU_Fast
    else
        mv $TEMP_DIR/yabs.sh ./
        local output=$(./yabs.sh -s -- -f -i -n "-$benchmark_name" 2>&1 | tail -n +9)
        if [[ $output =~ "Single Core" ]]; then
            output=$(echo "$output" | grep -v 'curl' | sed '$d' | sed '$d' | sed '1,2d')
            echo "$output"
        else
            if [ "$en_status" = true ]; then
                echo "Test failed please replace with another"
            else
                echo "测试失败请替换另一种方式"
            fi
        fi
    fi
    cd $myvar >/dev/null 2>&1
    sleep 1
}

memory_script() {
    if command -v sysbench >/dev/null 2>&1; then
        if [ "$en_status" = true ]; then
            echo "----------------------------Memory-Test---------------------------------"
        else
            echo "---------------------内存测试--感谢lemonbench开源-----------------------"
        fi
        Function_SysBench_Memory_Fast
    fi
}

basic_script() {
    if [ "$en_status" = true ]; then
        echo "----------------------------Basic-Information---------------------------"
    else
        echo "---------------------基础信息查询--感谢所有开源项目---------------------"
    fi
    print_system_info
    print_ip_info
    # cpu和内存测试
    cd $myvar >/dev/null 2>&1
    sleep 1
    if [ "$test_base_status" = false ]; then
        if [ -z "$test_cpu_type" ] || [ "$test_cpu_type" = "sysbench" ]; then
            cpu_judge sysbench
        elif [ "$test_cpu_type" = "gb4" ]; then
            cpu_judge geekbench4
        elif [ "$test_cpu_type" = "gb5" ]; then
            cpu_judge geekbench5
        elif [ "$test_cpu_type" = "gb6" ]; then
            cpu_judge geekbench6
        fi
        memory_script
    fi
}

io1_script() {
    cd $myvar >/dev/null 2>&1
    sleep 1
    if [ "$en_status" = true ]; then
        echo "------------------------Disk-dd-Read/Write-Test-------------------------"
    else
        echo "------------------磁盘dd读写测试--感谢lemonbench开源--------------------"
    fi
    Function_DiskTest_Fast
}

io2_script() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
    cd $myvar >/dev/null 2>&1
    cp $TEMP_DIR/yabs.sh ./
    if [ "$en_status" = true ]; then
        echo "-----------------------Disk-fio-Read/Write-Test-------------------------"
    else
        echo "---------------------磁盘fio读写测试--感谢yabs开源----------------------"
    fi
    echo -en "\rRunning fio test..."
    local output=$(./yabs.sh -s -- -i -n -g 2>&1 | tail -n +9)
    if [[ $output =~ "Block Size" ]]; then
        output=$(echo "$output" | grep -v 'curl' | sed '$d' | sed '$d' | sed '1,2d')
        echo -en "\r"
        echo "$output"
    else
        echo -en "\r"
        if [ "$en_status" = true ]; then
            echo "Test failed please replace with another"
        else
            echo "测试失败请替换另一种方式"
        fi
    fi
    rm -rf yabs.sh
}

io3_script() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
    cd $myvar >/dev/null 2>&1
    if [ "$en_status" = true ]; then
        echo "-----------------------Multi-Disk-Read/Write-Test-----------------------"
    else
        echo "----------------------多盘读写测试--感谢yabs开源------------------------"
    fi
    # 获取非以vda开头的盘名称
    disk_names=$(lsblk -e 11 -n -o NAME | grep -v "vda" | grep -v "snap" | grep -v "loop")
    if [ -z "$disk_names" ]; then
        echo "No eligible disk names found. Exiting script."
        return
    fi
    # 存储盘名称和盘路径的数组
    declare -a disk_paths
    # 遍历每个盘名称并检索对应的盘路径，并将名称和路径存储到数组中
    for disk_name in $disk_names; do
        disk_path=$(df -h | awk -v disk_name="$disk_name" '$0 ~ disk_name { print $NF }')
        if [ -n "$disk_path" ]; then
            disk_paths+=("$disk_name:$disk_path")
        fi
    done
    # 遍历数组，打开对应盘路径并检测IO
    if [ ${#disk_paths[@]} -gt 0 ]; then
        for disk_path in "${disk_paths[@]}"; do
            disk_name=$(echo "$disk_path" | cut -d ":" -f 1)
            path=$(echo "$disk_path" | cut -d ":" -f 2)
            if [ -n "$path" ]; then
                cd "$path" >/dev/null 2>&1
                if [ $? -ne 0 ]; then
                    continue
                fi
                echo -e "---------------------------------"
                echo "Current disk: ${disk_name}"
                echo "Current path: ${path}"
                if [ ! -f "yabs.sh" ]; then
                    cp $TEMP_DIR/yabs.sh ./
                fi
                echo -en "\rRunning fio test..."
                local output=$(./yabs.sh -s -- -i -n -g 2>&1 | tail -n +9)
                echo -en "\r"
                if [[ $output =~ "Block Size" ]]; then
                    output=$(echo "$output" | grep -v 'curl' | sed '$d' | sed '$d' | sed '1,2d')
                    echo "$output"
                else
                    if [ "$en_status" = true ]; then
                        echo "Test failed please replace with another"
                    else
                        echo "测试失败请替换另一种方式"
                    fi
                fi
                rm -rf yabs.sh
            fi
            cd $myvar >/dev/null 2>&1
        done
        echo -e "---------------------------------"
    else
        echo "No extra disk"
        return
    fi
    rm -rf yabs.sh
}

io_judge() {
    local par="$1"
    if [ "$par" = "all" ] && [ "$test_disk_type" = "" ]; then
        io1_script
        sleep 0.5
        io2_script
        return
    elif [ "$par" = "io2" ] && [ "$test_disk_type" = "" ]; then
        io2_script
        return
    fi
    if [ "$multidisk_status" = true ]; then
        io1_script
        sleep 0.5
        io3_script
    elif [ "$test_disk_type" = "dd" ]; then
        io1_script
    elif [ "$test_disk_type" = "fio" ]; then
        io2_script
    fi
}

RegionRestrictionCheck_script() {
    if [ "$en_status" = true ]; then
        echo -e "-------------------------Streaming-Unlock-Test--------------------------"
        _yellow " The following is an IPV4 network test, if there is no IPV4 network there is no output"
        echo 0 | bash media_lmc_check.sh -E -M 4 2>/dev/null | grep -A999999 '============\[ Multination \]============' | sed '/=======================================/q'
        _yellow " The following is an IPV6 network test, if there is no IPV6 network there is no output"
        echo 0 | bash media_lmc_check.sh -E -M 6 2>/dev/null | grep -A999999 '============\[ Multination \]============' | sed '/=======================================/q'
    else
        echo -e "----------------流媒体解锁--感谢RegionRestrictionCheck开源--------------"
        _yellow " 以下为IPV4网络测试，若无IPV4网络则无输出"
        echo 0 | bash media_lmc_check.sh -M 4 2>/dev/null | grep -A999999 '============\[ Multination \]============' | sed '/=======================================/q'
        _yellow " 以下为IPV6网络测试，若无IPV6网络则无输出"
        echo 0 | bash media_lmc_check.sh -M 6 2>/dev/null | grep -A999999 '============\[ Multination \]============' | sed '/=======================================/q'
    fi
}

lmc999_script() {
    cd $myvar >/dev/null 2>&1
    if [ "$en_status" = true ]; then
        echo -e "---------------------------TikTok-Unlock-Test---------------------------"
    else
        echo -e "---------------TikTok解锁--感谢lmc999的源脚本及fscarmen PR--------------"
    fi
    local Ftmpresult=$(curl $useNIC --user-agent "${UA_Browser}" -sL -m 10 "https://www.tiktok.com/")
    if [[ "$Ftmpresult" = "curl"* ]]; then
        _red "\r Tiktok Region:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}"
        return
    fi
    local FRegion=$(echo $Ftmpresult | grep '"region":' | sed 's/.*"region"//' | cut -f2 -d'"')
    if [ -n "$FRegion" ]; then
        _green "\r Tiktok Region:\t\t${Font_Green}【${FRegion}】${Font_Suffix}"
        return
    fi
    local STmpresult=$(curl $useNIC --user-agent "${UA_Browser}" -sL -m 10 -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9" -H "Accept-Encoding: gzip" -H "Accept-Language: en" "https://www.tiktok.com" | gunzip 2>/dev/null)
    local SRegion=$(echo $STmpresult | grep '"region":' | sed 's/.*"region"//' | cut -f2 -d'"')
    if [ -n "$SRegion" ]; then
        _yellow "\r Tiktok Region:\t\t${Font_Yellow}【${SRegion}】(可能为IDC IP)${Font_Suffix}"
        return
    else
        _red "\r Tiktok Region:\t\t${Font_Red}Failed${Font_Suffix}"
        return
    fi
}

spiritlhl_script() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
    cd $myvar >/dev/null 2>&1
    if [ "$en_status" = true ]; then
        echo -e "----IP-Quality-Detection--Base-On-oneclickvirt/securityCheck---------"
        _yellow "Data for reference only, does not represent 100% accurate, if and the actual situation is not consistent with the manual query multiple database comparison"
    else
        echo -e "-------------IP质量检测--基于oneclickvirt/securityCheck使用-------------"
        _yellow "数据仅作参考，不代表100%准确，如果和实际情况不一致请手动查询多个数据库比对"
    fi
    ipcheck
}

backtrace_script() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
    if [ "$en_status" = true ]; then
        return
    fi
    cd $myvar >/dev/null 2>&1
    if [ -f "${TEMP_DIR}/backtrace" ]; then
        chmod 777 ${TEMP_DIR}/backtrace
        if [[ $ipv6_condition == true ]]; then
            curl_output="$(${TEMP_DIR}/backtrace -s=false -ipv6=true 2>&1)"
        else
            curl_output="$(${TEMP_DIR}/backtrace -s=false 2>&1)"
        fi
    else
        return
    fi
    echo -e "----------------三网回程--基于oneclickvirt/backtrace开源----------------"
    grep -sq 'sendto: network is unreachable' <<<$curl_output && _yellow "纯IPV6网络无法查询" || echo "${curl_output}" | grep -v 'github.com/oneclickvirt/backtrace' | grep -v '正在测试' | grep -v '测试完成' | grep -v 'json decode err'
}

fscarmen_route_script() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
    if [ "$en_status" = true ]; then
        return
    fi
    cd $myvar >/dev/null 2>&1
    echo -e "---------------------回程路由--感谢fscarmen开源及PR---------------------"
    rm -f /tmp/ecs/ip.test
    local test_area_4
    local test_ip_4
    local test_area_6
    local test_ip_6
    if [ "$swhc_mode" = false ]; then
        test_area_4=("你本地的IPV4地址")
        test_ip_4=("$target_ipv4")
    elif [ -n "$route_location" ] && [[ "$route_location" =~ ^(b|g|s|c)$ ]]; then
        declare -n test_area_4="test_area_$route_location"
        declare -n test_ip_4="test_ip_$route_location"
    elif [ -n "$route_location" ] && [[ "$route_location" =~ ^(b6|g6|s6)$ ]]; then
        declare -n test_area_6="test_area_$route_location"
        declare -n test_ip_6="test_ip_$route_location"
    else
        test_area_4=("${!1}")
        test_ip_4=("${!2}")
    fi
    local ip4=$(echo "$IPV4" | tr -d '\n')
    local ip6=$(echo "$IPV6" | tr -d '\n')
    # 不存在IPV4网络，存在IPV6网络，未指定使用哪个城市的三网地址测试，默认修改为使用广州三网IPV6地址
    if [[ -z "${ip4}" ]] && [[ -n "$ip6" ]] && [ -z "$route_location" ]; then
        declare -n test_area_6="test_area_g6"
        declare -n test_ip_6="test_ip_g6"
    fi
    if [[ ! -z "${ip4}" ]] && [[ "$route_location" != "b6" && "$route_location" != "g6" && "$route_location" != "s6" ]]; then
        if [ "$swhc_mode" = false ]; then
            _green "核心程序来自nexttrace，请知悉!" >/tmp/ecs/ip.test
        else
            _green "依次测试电信/联通/移动经过的地区及线路，核心程序来自nexttrace，请知悉!" >/tmp/ecs/ip.test
        fi
        for ((a = 0; a < ${#test_area_4[@]}; a++)); do
            rm -rf /tmp/ip_temp
            RESULT=$("$TEMP_DIR/$NEXTTRACE_FILE" "${test_ip_4[a]}" --nocolor 2>/dev/null)
            RESULT=$(echo "$RESULT" | grep '^[0-9 ]')
            PART_1=$(echo "$RESULT" | grep '^[0-9]\{1,2\}[ ]\+[0-9a-f]' | awk '{$1="";$2="";print}' | sed "s@^[ ]\+@@g")
            PART_2=$(echo "$RESULT" | grep '\(.*ms\)\{3\}' | sed 's/.* \([0-9*].*ms\).*ms.*ms/\1/g')
            SPACE=' '
            for ((i = 1; i <= $(echo "$PART_1" | wc -l); i++)); do
                [ "$i" -eq 10 ] && unset SPACE
                p_1=$(echo "$PART_2" | sed -n "${i}p") 2>/dev/null
                p_2=$(echo "$PART_1" | sed -n "${i}p") 2>/dev/null
                echo -e "$p_1 \t$p_2" >>/tmp/ip_temp
            done
            if [ "$swhc_mode" = false ]; then
                ori_ipv4="${test_ip_4[a]}"
                IFS='.' read -ra parts <<<"$ori_ipv4"
                if [ "${#parts[@]}" -ge 2 ]; then
                    parts[2]="xxx"
                    parts[3]="xxx"
                    new_ipv4="${parts[0]}.${parts[1]}.${parts[2]}.${parts[3]}"
                    _yellow "${test_area_4[a]} $new_ipv4" >>/tmp/ecs/ip.test
                else
                    _yellow "${test_area_4[a]} xxx.xxx.xxx.xxx" >>/tmp/ecs/ip.test
                fi
            else
                _yellow "${test_area_4[a]} ${test_ip_4[a]}" >>/tmp/ecs/ip.test
            fi
            cat /tmp/ip_temp >>/tmp/ecs/ip.test
            rm -rf /tmp/ip_temp
        done
    elif [[ -n "$ip6" ]] || [[ "$route_location" =~ ^(b6|g6|s6)$ ]]; then
        _green "依次测试电信/联通/移动经过的地区及线路，核心程序来自nexttrace，请知悉!" >/tmp/ecs/ip.test
        for ((a = 0; a < ${#test_area_6[@]}; a++)); do
            rm -rf /tmp/ip_temp
            RESULT=$("$TEMP_DIR/$NEXTTRACE_FILE" "${test_ip_6[a]}" --nocolor 2>/dev/null)
            RESULT=$(echo "$RESULT" | grep -E -v '^(NextTrace|MapTrace|\[NextTrace API\]|IP|traceroute to)')
            PART_1=$(echo "$RESULT" | grep '^[0-9]\{1,2\}[ ]\+[0-9a-f]' | awk '{$1="";$2="";print}' | sed "s@^[ ]\+@@g")
            PART_2=$(echo "$RESULT" | grep '\(.*ms\)\{3\}' | sed 's/.* \([0-9*].*ms\).*ms.*ms/\1/g')
            SPACE=' '
            for ((i = 1; i <= $(echo "$PART_1" | wc -l); i++)); do
                [ "$i" -eq 10 ] && unset SPACE
                p_1=$(echo "$PART_2" | sed -n "${i}p") 2>/dev/null
                p_2=$(echo "$PART_1" | sed -n "${i}p") 2>/dev/null
                echo -e "$p_1 \t$p_2" >>/tmp/ip_temp
            done
            _yellow "${test_area_6[a]} ${test_ip_6[a]}" >>/tmp/ecs/ip.test
            cat /tmp/ip_temp >>/tmp/ecs/ip.test
            rm -rf /tmp/ip_temp
        done
    fi
    output=$(check_and_cat_file /tmp/ecs/ip.test)
    if [ -z "${output// /}" ]; then
        echo "Hop limit"
    else
        echo "$output"
    fi
    rm -f /tmp/ecs/ip.test
}

ecs_ping() {
    cd $myvar >/dev/null 2>&1
    if [ "$en_status" = true ]; then
        return
    fi
    echo -e "-----------------------全国延迟检测--本脚本原创-------------------------"
    if [ -f "${TEMP_DIR}/ecsspeed-ping.sh" ]; then
        ping_output=$(bash ${TEMP_DIR}/ecsspeed-ping.sh 2>&1)
    else
        return
    fi
    echo "${ping_output}" | grep "|"
}

ecs_net_all_script() {
    cd $myvar >/dev/null 2>&1
    [ "$enable_speedtest" = false ] && return
    # s_time=$(date +%s)
    rm -rf ./speedtest-cli/speedlog.txt
    speed | tee ./speedtest-cli/speedlog.txt
    # e_time=$(date +%s)
    # time=$((${e_time} - ${s_time}))
    if [ -f ./speedtest-cli/speedlog.txt ]; then
        if ! grep -qE "(Speedtest.net|洛杉矶|新加坡|香港|联通|电信|移动|日本|中国)" ./speedtest-cli/speedlog.txt; then
            export speedtest_ver="1.0.0"
            rm -rf ./speedtest-cli/speedlog.txt
            rm -rf ./speedtest-cli*
            (install_speedtest >/dev/null 2>&1)
            speed
        fi
    fi
    rm -fr speedtest-cli
}

ecs_net_minal_script() {
    cd $myvar >/dev/null 2>&1
    [ "$enable_speedtest" = false ] && return
    # s_time=$(date +%s)
    rm -rf ./speedtest-cli/speedlog.txt
    speed2 | tee ./speedtest-cli/speedlog.txt
    # e_time=$(date +%s)
    # time=$((${e_time} - ${s_time}))
    if [ -f ./speedtest-cli/speedlog.txt ]; then
        if ! grep -qE "(Speedtest.net|洛杉矶|新加坡|香港|联通|电信|移动|日本|中国)" ./speedtest-cli/speedlog.txt; then
            export speedtest_ver="1.0.0"
            rm -rf ./speedtest-cli/speedlog.txt
            rm -rf ./speedtest-cli*
            (install_speedtest >/dev/null 2>&1)
            speed2
        fi
    fi
    rm -fr speedtest-cli
}

end_script() {
    next
    print_end_time
    next
}

# =============== 分区选择 部分 ===============
all_script() {
    pre_check
    if [ "$1" = "B" ]; then
        if [[ -z "${CN}" || "${CN}" != true ]]; then
            _yellow "Concurrently downloading files..."
            # besttrace
            dfiles=(gostun CommonMediaTests nexttrace backtrace securityCheck portchecker yabs media_lmc_check)
            start_downloads "${dfiles[@]}"
            _yellow "All files download successfully."
            get_system_info
            check_dnsutils
            check_ping
            ls_sg_hk_jp=($(get_nearest_data "${SERVER_BASE_URL}/ls_sg_hk_jp.csv"))
            CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
            CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
            CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
            [ "$enable_speedtest" = true ] && _yellow "checking speedtest" && install_speedtest &
            check_lmc_script &
            check_nat_type &
            clear
            print_intro
            basic_script
            wait
            ecs_net_all_script >${TEMP_DIR}/ecs_net_output.txt &
            io_judge "all"
            sjlleo_script >${TEMP_DIR}/sjlleo_output.txt &
            RegionRestrictionCheck_script >${TEMP_DIR}/RegionRestrictionCheck_output.txt &
            lmc999_script >${TEMP_DIR}/lmc999_output.txt &
            spiritlhl_script >${TEMP_DIR}/spiritlhl_output.txt &
            backtrace_script >${TEMP_DIR}/backtrace_output.txt &
            fscarmen_route_script test_area_g[@] test_ip_g[@] >${TEMP_DIR}/fscarmen_route_output.txt &
            echo "正在并发测试中，大概2~3分钟无输出，请耐心等待。。。"
            wait
            check_and_cat_file ${TEMP_DIR}/sjlleo_output.txt
            check_and_cat_file ${TEMP_DIR}/RegionRestrictionCheck_output.txt
            check_and_cat_file ${TEMP_DIR}/lmc999_output.txt
            check_and_cat_file ${TEMP_DIR}/spiritlhl_output.txt
            check_and_cat_file ${TEMP_DIR}/backtrace_output.txt
            check_and_cat_file ${TEMP_DIR}/fscarmen_route_output.txt
            check_and_cat_file ${TEMP_DIR}/ecs_net_output.txt
        else
            _yellow "Concurrently downloading files..."
            dfiles=(securityCheck portchecker ecsspeed_ping)
            start_downloads "${dfiles[@]}"
            _yellow "All files download successfully."
            get_system_info
            check_dnsutils
            check_ping
            ls_sg_hk_jp=($(get_nearest_data "${SERVER_BASE_URL}/ls_sg_hk_jp.csv"))
            CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
            CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
            CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
            [ "$enable_speedtest" = true ] && _yellow "checking speedtest" && install_speedtest &
            check_lmc_script &
            check_nat_type &
            clear
            print_intro
            basic_script
            wait
            ecs_net_all_script >${TEMP_DIR}/ecs_net_output.txt &
            io1_script
            sleep 0.5
            spiritlhl_script >${TEMP_DIR}/spiritlhl_output.txt &
            ecs_ping >${TEMP_DIR}/ecs_ping.txt &
            echo "正在并发测试中，大概2~3分钟无输出，请耐心等待。。。"
            wait
            check_and_cat_file ${TEMP_DIR}/spiritlhl_output.txt
            check_and_cat_file ${TEMP_DIR}/ecs_ping.txt
            check_and_cat_file ${TEMP_DIR}/ecs_net_output.txt
        fi
    else
        # 顺序测试
        if [[ -z "${CN}" || "${CN}" != true ]]; then
            _yellow "Concurrently downloading files..."
            # besttrace
            dfiles=(nexttrace backtrace CommonMediaTests securityCheck portchecker gostun yabs media_lmc_check)
            start_downloads "${dfiles[@]}"
            _yellow "All files download successfully."
            get_system_info
            check_dnsutils
            check_ping
            ls_sg_hk_jp=($(get_nearest_data "${SERVER_BASE_URL}/ls_sg_hk_jp.csv"))
            CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
            CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
            CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
            [ "$enable_speedtest" = true ] && _yellow "checking speedtest" && install_speedtest
            check_lmc_script
            check_nat_type
            clear
            print_intro
            basic_script
            io_judge "all"
            sjlleo_script
            RegionRestrictionCheck_script
            lmc999_script
            spiritlhl_script
            backtrace_script
            fscarmen_route_script test_area_g[@] test_ip_g[@]
            wait
            ecs_net_all_script
        else
            _yellow "Concurrently downloading files..."
            dfiles=(ecsspeed_ping securityCheck portchecker gostun)
            start_downloads "${dfiles[@]}"
            _yellow "All files download successfully."
            get_system_info
            check_dnsutils
            check_ping
            ls_sg_hk_jp=($(get_nearest_data "${SERVER_BASE_URL}/ls_sg_hk_jp.csv"))
            CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
            CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
            CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
            [ "$enable_speedtest" = true ] && _yellow "checking speedtest" && install_speedtest
            check_lmc_script
            check_nat_type
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
    # block_port_script
    end_script
}

minal_script() {
    pre_check
    get_system_info
    _yellow "Concurrently downloading files..."
    dfiles=(gostun yabs)
    start_downloads "${dfiles[@]}"
    _yellow "All files download successfully."
    check_ping
    CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
    CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
    CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
    [ "$enable_speedtest" = true ] && _yellow "checking speedtest" && install_speedtest
    check_nat_type
    clear
    print_intro
    basic_script
    io_judge "io2"
    ecs_net_minal_script
    end_script
}

minal_plus() {
    pre_check
    _yellow "Concurrently downloading files..."
    wait
    # besttrace
    dfiles=(nexttrace backtrace CommonMediaTests gostun yabs media_lmc_check)
    start_downloads "${dfiles[@]}"
    _yellow "All files download successfully."
    get_system_info
    check_lmc_script
    check_dnsutils
    check_ping
    CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
    CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
    CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
    [ "$enable_speedtest" = true ] && _yellow "checking speedtest" && install_speedtest
    check_nat_type
    clear
    print_intro
    basic_script
    io_judge "io2"
    sjlleo_script
    RegionRestrictionCheck_script
    lmc999_script
    backtrace_script
    fscarmen_route_script test_area_g[@] test_ip_g[@]
    ecs_net_minal_script
    end_script
}

minal_plus_network() {
    pre_check
    _yellow "Concurrently downloading files..."
    # besttrace
    dfiles=(nexttrace backtrace gostun yabs)
    start_downloads "${dfiles[@]}"
    _yellow "All files download successfully."
    get_system_info
    check_ping
    CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
    CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
    CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
    [ "$enable_speedtest" = true ] && _yellow "checking speedtest" && install_speedtest
    check_nat_type
    clear
    print_intro
    basic_script
    io_judge "io2"
    backtrace_script
    fscarmen_route_script test_area_g[@] test_ip_g[@]
    ecs_net_minal_script
    end_script
}

minal_plus_media() {
    pre_check
    _yellow "Concurrently downloading files..."
    dfiles=(CommonMediaTests gostun yabs media_lmc_check)
    start_downloads "${dfiles[@]}"
    _yellow "All files download successfully."
    get_system_info
    check_dnsutils
    check_lmc_script
    check_ping
    CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
    CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
    CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
    [ "$enable_speedtest" = true ] && _yellow "checking speedtest" && install_speedtest
    check_nat_type
    clear
    print_intro
    basic_script
    io_judge "io2"
    sjlleo_script
    RegionRestrictionCheck_script
    lmc999_script
    ecs_net_minal_script
    end_script
}

network_script() {
    pre_check
    _yellow "Concurrently downloading files..."
    # besttrace
    dfiles=(nexttrace backtrace securityCheck portchecker)
    start_downloads "${dfiles[@]}"
    _yellow "All files download successfully."
    check_ping
    ls_sg_hk_jp=($(get_nearest_data "${SERVER_BASE_URL}/ls_sg_hk_jp.csv"))
    CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
    CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
    CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
    [ "$enable_speedtest" = true ] && _yellow "checking speedtest" && install_speedtest
    clear
    print_intro
    spiritlhl_script
    backtrace_script
    fscarmen_route_script test_area_g[@] test_ip_g[@]
    # block_port_script
    ecs_net_all_script
    end_script
}

media_script() {
    pre_check
    _yellow "Concurrently downloading files..."
    dfiles=(CommonMediaTests media_lmc_check)
    start_downloads "${dfiles[@]}"
    _yellow "All files download successfully."
    check_dnsutils
    check_lmc_script
    clear
    print_intro
    sjlleo_script
    RegionRestrictionCheck_script
    lmc999_script
    end_script
}

hardware_script() {
    pre_check
    _yellow "Concurrently downloading files..."
    if [ "$test_base_status" = false ]; then
        dfiles=(yabs gostun)
    else
        dfiles=(gostun)
    fi
    start_downloads "${dfiles[@]}"
    _yellow "All files download successfully."
    get_system_info
    check_nat_type
    clear
    print_intro
    basic_script
    if [ "$test_base_status" = false ]; then
        io_judge "all"
    fi
    end_script
}

port_script() {
    exit 1
    pre_check
    pre_download XXXX
    get_system_info
    clear
    print_intro
    # block_port_script
    end_script
}

sw_script() {
    pre_check
    _yellow "Concurrently downloading files..."
    # besttrace
    dfiles=(nexttrace backtrace ecsspeed_ping)
    start_downloads "${dfiles[@]}"
    _yellow "All files download successfully."
    check_ping
    clear
    print_intro
    backtrace_script
    fscarmen_route_script test_area_g[@] test_ip_g[@]
    ecs_ping
    end_script
}

network_script_select() {
    pre_check
    _yellow "Concurrently downloading files..."
    # besttrace
    dfiles=(nexttrace)
    start_downloads "${dfiles[@]}"
    _yellow "All files download successfully."
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

rm_script() {
    cd $myvar >/dev/null 2>&1
    rm -rf speedtest.tgz*
    rm -rf wget-log*
    rm -rf media_lmc_check.sh*
    rm -rf CommonMediaTests
    rm -rf besttrace
    rm -rf nexttrace
    rm -rf LemonBench.Result.txt*
    rm -rf speedtest.log*
    rm -rf test
    rm -rf yabs.sh*
    rm -rf speedtest.tgz*
    rm -rf speedtest.tar.gz*
    rm -rf speedtest-cli*
    rm -rf geekbench_claim.url*
    rm -rf "$PROGRESS_DIR"
    rm -rf "$PID_FILE"
}

error_exit() {
    if [ "$en_status" = true ]; then
        echo "An error occurred during execution. Please try using https://github.com/oneclickvirt/ecs for testing instead."
    else
        echo "执行出现错误，如果有必要请使用 https://github.com/oneclickvirt/ecs 进行测试，避免环境依赖出现问题"
    fi
}

build_text() {
    cd "$myvar" >/dev/null 2>&1
    if { [ -n "${menu_mode}" ] && [ "${menu_mode}" = false ]; } ||
        { [ -n "${StartInput}" ] && { [ "${StartInput}" -eq 1 ] || [ "${StartInput}" -eq 2 ]; }; } ||
        { [ -n "${StartInput1}" ] && [ "${StartInput1}" -ge 1 ] && [ "${StartInput1}" -le 4 ]; }; then
        sed -i -e '1,/-------------------- A Bench Script By spiritlhl ---------------------/d' test_result.txt
        sed -i -e 's/\x1B\[[0-9;]\+[a-zA-Z]//g' test_result.txt
        sed -i -e '/^$/d' test_result.txt
        sed -i -e '/Preparing system for disk tests.../d' test_result.txt
        sed -i -e '/Generating fio test file.../d' test_result.txt
        sed -i -e '/Running fio random mixed R+W disk test with 4k block size.../d' test_result.txt
        sed -i -e '/Running fio random mixed R+W disk test with 64k block size.../d' test_result.txt
        sed -i -e '/Running fio random mixed R+W disk test with 512k block size.../d' test_result.txt
        sed -i -e '/Running fio random mixed R+W disk test with 1m block size.../d' test_result.txt
        tr '\r' '\n' <test_result.txt >test_result1.txt
        mv test_result1.txt test_result.txt
        sed -i -e '/^$/d' test_result.txt
        sed -i -e '/1\/1/d' test_result.txt
        sed -i -e '/Block\s*->/d' test_result.txt
        sed -i -e '/s)\s*->/d' test_result.txt
        sed -i -e '/^该运营商\|^测速中/d' test_result.txt
        sed -i -e '/^Running fio test.../d' test_result.txt
        sed -i -e '/^checking speedtest/d' test_result.txt
        # 检查文件大小是否小于 25KB
        if [ ! -s test_result.txt ]; then
            echo "The file test_result.txt is empty and has not been uploaded."
            return
        fi
        file_size=$(wc -c <"test_result.txt")
        if [ "$file_size" -ge 25600 ]; then
            echo "Files larger than 25KB (${file_size} bytes) are not uploaded."
            return
        fi
        http_short_url=$(curl --ipv4 -sL -m 10 -X POST \
            -H "Authorization: $ST" \
            -F "file=@${myvar}/test_result.txt" \
            "http://hpaste.spiritlhl.net/api/UL/upload")
        if [ $? -eq 0 ] && [ -n "$http_short_url" ] && echo "$http_short_url" | grep -q "show"; then
            file_id=$(echo "$http_short_url" | grep -o '[^/]*$')
            http_short_url="http://hpaste.spiritlhl.net/#/show/${file_id}"
            https_short_url="https://paste.spiritlhl.net/#/show/${file_id}"
        else
            # 如果 HTTP 失败，尝试 HTTPS
            https_short_url=$(curl --ipv6 -sL -m 10 -X POST \
                -H "Authorization: $ST" \
                -F "file=@${myvar}/test_result.txt" \
                "https://paste.spiritlhl.net/api/UL/upload")
            if [ $? -eq 0 ] && [ -n "$https_short_url" ] && echo "$https_short_url" | grep -q "show"; then
                file_id=$(echo "$https_short_url" | grep -o '[^/]*$')
                http_short_url="http://hpaste.spiritlhl.net/#/show/${file_id}"
                https_short_url="https://paste.spiritlhl.net/#/show/${file_id}"
            else
                http_short_url=""
                https_short_url=""
            fi
        fi
    fi
}

comprehensive_test_script_options() {
    case $StartInputc in
    1)
        wget -qO- --no-check-certificate https://raw.githubusercontent.com/oooldking/script/master/superbench.sh | bash
        break_status=true
        ;;
    2)
        curl -fsL https://ilemonra.in/LemonBenchIntl | bash -s fast
        break_status=true
        ;;
    3)
        curl -sL yabs.sh | bash
        break_status=true
        ;;
    4)
        wget -qO- bench.sh | bash
        break_status=true
        ;;
    5)
        bash <(wget -qO- git.io/ceshi)
        break_status=true
        ;;
    6)
        wget --no-check-certificate https://raw.githubusercontent.com/teddysun/across/master/unixbench.sh && chmod +x unixbench.sh && ./unixbench.sh
        break_status=true
        ;;
    7)
        wget -N --no-check-certificate https://raw.githubusercontent.com/FunctionClub/ZBench/master/ZBench-CN.sh && bash ZBench-CN.sh
        break_status=true
        ;;
    0)
        original_script
        break_status=true
        ;;
    *)
        if [ "$en_status" = true ]; then
            echo "Input error, please re-enter"
        else
            echo "输入错误，请重新输入"
        fi
        break_status=false
        ;;
    esac
}

comprehensive_test_script() {
    head_script
    if $menu_mode; then
        if [ "$en_status" = true ]; then
            _yellow "Scripts with comprehensive tests are as follows"
            echo -e "${GREEN}1.${PLAIN} superbench VPS test scripts - based on teddysun's secondary open source modifications"
            echo -e "${GREEN}2.${PLAIN} lemonbench VPS test script"
            echo -e "${GREEN}3.${PLAIN} YABS VPS Test Script"
            echo -e "${GREEN}4.${PLAIN} Bench.sh VPS test script by teddysun"
            echo -e "${GREEN}5.${PLAIN} Aniverse's a.sh VPS Test Script - Special Adaptation Dedicated Service"
            echo -e "${GREEN}6.${PLAIN} UnixBench VPS Test Script - Special Adaptation for unix Systems"
            echo -e "${GREEN}7.${PLAIN} Zbench VPS Test Script - Testing in China"
            echo " -------------"
            echo -e "${GREEN}0.${PLAIN} 回到上一级菜单"
            echo ""
        else
            _yellow "具备综合性测试的脚本如下"
            echo -e "${GREEN}1.${PLAIN} superbench VPS测试脚本-基于teddysun的二开"
            echo -e "${GREEN}2.${PLAIN} lemonbench VPS测试脚本"
            echo -e "${GREEN}3.${PLAIN} YABS VPS测试脚本-英文论坛常用"
            echo -e "${GREEN}4.${PLAIN} teddysun的bench.sh VPS测试脚本"
            echo -e "${GREEN}5.${PLAIN} Aniverse的a.sh VPS测试脚本-特殊适配独服"
            echo -e "${GREEN}6.${PLAIN} UnixBench VPS测试脚本-特殊适配unix系统"
            echo -e "${GREEN}7.${PLAIN} Zbench VPS测试脚本-国内测试"
            echo " -------------"
            echo -e "${GREEN}0.${PLAIN} 回到上一级菜单"
            echo ""
        fi
        while true; do
            if [ "$en_status" = true ]; then
                read -rp "Please enter the option number:" StartInputc
            else
                read -rp "请输入选项:" StartInputc
            fi
            comprehensive_test_script_options
            if [ "$break_status" = true ] || [ "$menu_mode" = false ]; then
                break
            fi
        done
    else
        StartInputc="$sub_of_sub_menu_option"
        comprehensive_test_script_options
    fi
}

media_test_script_options() {
    case $StartInputm in
    1)
        wget -O nf https://github.com/sjlleo/netflix-verify/releases/download/v3.1.0/nf_linux_amd64 && chmod +x nf && ./nf
        break_status=true
        ;;
    2)
        wget -O tubecheck https://cdn.jsdelivr.net/gh/sjlleo/TubeCheck/CDN/tubecheck_1.0beta_linux_amd64 && chmod +x tubecheck && clear && ./tubecheck
        break_status=true
        ;;
    3)
        wget -O dp https://github.com/sjlleo/VerifyDisneyPlus/releases/download/1.01/dp_1.01_linux_amd64 && chmod +x dp && clear && ./dp
        break_status=true
        ;;
    4)
        lmc999_script
        break_status=true
        ;;
    5)
        bash <(curl -s https://raw.githubusercontent.com/lmc999/TikTokCheck/main/tiktok.sh)
        break_status=true
        ;;
    6)
        bash <(curl -L -s check.unlock.media)
        break_status=true
        ;;
    7)
        bash <(curl -Ls unlock.moe)
        break_status=true
        ;;
    8)
        bash <(curl -Ls https://cpp.li/openai)
        break_status=true
        ;;
    9)
        bash <(curl -Ls https://bash.spiritlhl.net/openai-checker)
        break_status=true
        ;;
    0)
        original_script
        break_status=true
        ;;
    *)
        if [ "$en_status" = true ]; then
            echo "Input error, please re-enter"
        else
            echo "输入错误，请重新输入"
        fi
        break_status=false
        ;;
    esac
}

media_test_script() {
    head_script
    if $menu_mode; then
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
        while true; do
            if [ "$en_status" = true ]; then
                read -rp "Please enter the option number:" StartInputm
            else
                read -rp "请输入选项:" StartInputm
            fi
            media_test_script_options
            if [ "$break_status" = true ] || [ "$menu_mode" = false ]; then
                break
            fi
        done
    else
        StartInputm="$sub_of_sub_menu_option"
        media_test_script_options
    fi
}

network_test_script_options() {
    case $StartInputn in
    1)
        curl https://raw.githubusercontent.com/zhanghanyun/backtrace/main/install.sh -sSf | sh
        break_status=true
        ;;
    2)
        curl https://raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
        break_status=true
        ;;
    3)
        wget -qO- git.io/besttrace | bash
        break_status=true
        ;;
    4)
        bash <(curl -sSL https://raw.githubusercontent.com/spiritLHLS/ecs/main/archive/return.sh)
        break_status=true
        ;;
    5)
        bash <(curl -sSL https://raw.githubusercontent.com/spiritLHLS/ecs/main/archive/nexttrace.sh)
        break_status=true
        ;;
    6)
        wget -O jcnf.sh https://raw.githubusercontent.com/Netflixxp/jcnfbesttrace/main/jcnf.sh && bash jcnf.sh
        break_status=true
        ;;
    7)
        bash <(curl -L -Lso- https://git.io/superspeed.sh)
        break_status=true
        ;;
    8)
        bash <(curl -Lso- https://git.io/superspeed_uxh)
        break_status=true
        ;;
    9)
        bash <(curl -Lso- https://git.io/J1SEh)
        break_status=true
        ;;
    10)
        bash <(curl -L -Lso- https://bench.im/hyperspeed)
        break_status=true
        ;;
    11)
        bash <(curl -sL bash.icu/speedtest)
        break_status=true
        ;;
    12)
        curl -sL network-speed.xyz | bash
        break_status=true
        ;;
    13)
        bash <(wget -qO- bash.spiritlhl.net/ecs-net)
        break_status=true
        ;;
    14)
        bash <(wget -qO- bash.spiritlhl.net/ecs-cn)
        break_status=true
        ;;
    15)
        bash <(wget -qO- bash.spiritlhl.net/ecs-ping)
        break_status=true
        ;;
    16)
        curl https://vps789.com/public/ping24h/?remarks=from%E8%9E%8D%E5%90%88%E6%80%AA
        break_status=true
        ;;
    0)
        original_script
        break_status=true
        ;;
    *)
        if [ "$en_status" = true ]; then
            echo "Input error, please re-enter"
        else
            echo "输入错误，请重新输入"
        fi
        break_status=false
        ;;
    esac
}

network_test_script() {
    head_script
    if $menu_mode; then
        _yellow "网络测试相关的脚本如下"
        echo -e "${GREEN}1.${PLAIN} zhanghanyun的backtrace三网回程线路检测脚本"
        echo -e "${GREEN}2.${PLAIN} zhucaidan的mtr_trace三网回程线路测脚本"
        echo -e "${GREEN}3.${PLAIN} 基于besttrace回程路由测试脚本(带详情信息，可能有bug)"
        echo -e "${GREEN}4.${PLAIN} 基于besttrace回程路由测试脚本(二开整合输出，可能有bug)"
        echo -e "${GREEN}5.${PLAIN} 基于nexttrace回程路由测试脚本(第三方IP库，更推荐)"
        echo -e "${GREEN}6.${PLAIN} 由Netflixxp维护的四网路由测试脚本"
        echo -e "${GREEN}7.${PLAIN} 原始作者维护的superspeed的三网测速脚本"
        echo -e "${GREEN}8.${PLAIN} 未知作者修复的superspeed的三网测速脚本"
        echo -e "${GREEN}9.${PLAIN} 由sunpma维护的superspeed的三网测速脚本"
        echo -e "${GREEN}10.${PLAIN} 原始作者维护的hyperspeed的三网测速脚本(测速内核不开源)"
        echo -e "${GREEN}11.${PLAIN} 原始作者维护的多功能测速脚本(部分测速内核不开源)"
        echo -e "${GREEN}12.${PLAIN} 综合速度测试脚本(全球的测速节点)"
        echo -e "${GREEN}13.${PLAIN} 本人的ecs-net三网测速脚本(自动更新测速节点，对应 speedtest.net)"
        echo -e "${GREEN}14.${PLAIN} 本人的ecs-cn三网测速脚本(自动更新测速节点，对应 speedtest.cn)"
        echo -e "${GREEN}15.${PLAIN} 本人的ecs-ping三网测ping脚本(自动更新测试节点)"
        echo -e "${GREEN}16.${PLAIN} 开始三网24小时ping测试(执行后回传24小时实时更新的图片地址)"
        echo " -------------"
        echo -e "${GREEN}0.${PLAIN} 回到上一级菜单"
        echo ""
        while true; do
            if [ "$en_status" = true ]; then
                read -rp "Please enter the option number:" StartInputn
            else
                read -rp "请输入选项:" StartInputn
            fi
            network_test_script_options
            if [ "$break_status" = true ] || [ "$menu_mode" = false ]; then
                break
            fi
        done
    else
        StartInputn="$sub_of_sub_menu_option"
        network_test_script_options
    fi
}

hardware_test_script_options() {
    case $StartInputh in
    1)
        bash <(curl -sSL https://raw.githubusercontent.com/spiritLHLS/ecs/main/archive/disk_info.sh)
        break_status=true
        ;;
    2)
        bash <(curl -sSL https://raw.githubusercontent.com/spiritLHLS/ecs/main/archive/geekbench4.sh)
        break_status=true
        ;;
    3)
        bash <(curl -sSL https://raw.githubusercontent.com/spiritLHLS/ecs/main/archive/geekbench5.sh)
        break_status=true
        ;;
    4)
        bash <(curl -sSL https://raw.githubusercontent.com/spiritLHLS/ecs/main/archive/geekbench6.sh)
        break_status=true
        ;;
    5)
        bash <(curl -sSL https://raw.githubusercontent.com/spiritLHLS/ecs/main/archive/multi_disk_io_test.sh)
        break_status=true
        ;;
    0)
        original_script
        break_status=true
        ;;
    *)
        if [ "$en_status" = true ]; then
            echo "Input error, please re-enter"
        else
            echo "输入错误，请重新输入"
        fi
        break_status=false
        ;;
    esac
}

hardware_test_script() {
    head_script
    if $menu_mode; then
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
        while true; do
            if [ "$en_status" = true ]; then
                read -rp "Please enter the option number:" StartInputh
            else
                read -rp "请输入选项:" StartInputh
            fi
            hardware_test_script_options
            if [ "$break_status" = true ] || [ "$menu_mode" = false ]; then
                break
            fi
        done
    else
        StartInputh="$sub_of_sub_menu_option"
        hardware_test_script_options
    fi
}

original_script_options() {
    case $StartInput3 in
    1)
        comprehensive_test_script
        break_status=true
        ;;
    2)
        media_test_script
        break_status=true
        ;;
    3)
        network_test_script
        break_status=true
        ;;
    4)
        hardware_test_script
        break_status=true
        ;;
    0)
        start_script
        break_status=true
        ;;
    *)
        if [ "$en_status" = true ]; then
            echo "Input error, please re-enter"
        else
            echo "输入错误，请重新输入"
        fi
        break_status=false
        ;;
    esac
}

original_script() {
    head_script
    if $menu_mode; then
        _yellow "融合怪借鉴的脚本以及部分竞品脚本合集如下"
        echo -e "${GREEN}1.${PLAIN} 综合性测试脚本合集(比如yabs，superbench等)"
        echo -e "${GREEN}2.${PLAIN} 流媒体测试脚本合集(各种流媒体解锁相关)"
        echo -e "${GREEN}3.${PLAIN} 网络测试脚本合集(如三网回程和三网测速等)"
        echo -e "${GREEN}4.${PLAIN} 硬件测试脚本合集(如gb5，硬盘通电时长等)"
        echo " -------------"
        echo -e "${GREEN}0.${PLAIN} 回到主菜单"
        echo ""
        while true; do
            if [ "$en_status" = true ]; then
                read -rp "Please enter the option number:" StartInput3
            else
                read -rp "请输入选项:" StartInput3
            fi
            original_script_options
            if [ "$break_status" = true ] || [ "$menu_mode" = false ]; then
                break
            fi
        done
    else
        StartInput3="$sub_menu_option"
        original_script_options
    fi
}

simplify_script_options() {
    case $StartInput1 in
    1)
        minal_script | tee -i test_result.txt
        break_status=true
        ;;
    2)
        minal_plus | tee -i test_result.txt
        break_status=true
        ;;
    3)
        minal_plus_network | tee -i test_result.txt
        break_status=true
        ;;
    4)
        minal_plus_media | tee -i test_result.txt
        break_status=true
        ;;
    0)
        start_script
        break_status=true
        ;;
    *)
        if [ "$en_status" = true ]; then
            echo "Input error, please re-enter"
        else
            echo "输入错误，请重新输入"
        fi
        break_status=false
        ;;
    esac
}

simplify_script() {
    head_script
    if $menu_mode; then
        if [ "$en_status" = true ]; then
            _yellow "The streamlined script for the fusion monster is as follows"
            echo -e "${GREEN}1.${PLAIN} Minimalist version (system information + CPU + memory + disk IO + 4 nodes for speed test) (average run time 3 minutes)"
            echo -e "${GREEN}2.${PLAIN} Lite (System Info + CPU + RAM + Disk IO + Mikado Unlocked + Common Streams + TikTok + Backhaul + Routing + 4 nodes for speed test) (4 minutes average run time)"
            echo -e "${GREEN}3.${PLAIN} Lite Network Edition (4 nodes for system information + CPU + memory + disk IO + backhaul + routing + speed test) (average run time 4 minutes)"
            echo -e "${GREEN}4.${PLAIN} Lite unlocked version (System info + CPU + RAM + Disk IO + Gosanja unlocked + common streams + TikTok + 4 nodes for speed test) (runs for 4 minutes on average)"
            echo " -------------"
            echo -e "${GREEN}0.${PLAIN} Back to the main menu"
        else
            _yellow "融合怪的精简脚本如下"
            echo -e "${GREEN}1.${PLAIN} 极简版(系统信息+CPU+内存+磁盘IO+测速节点4个)(平均运行3分钟)"
            echo -e "${GREEN}2.${PLAIN} 精简版(系统信息+CPU+内存+磁盘IO+御三家解锁+常用流媒体+TikTok+回程+路由+测速节点4个)(平均运行4分钟)"
            echo -e "${GREEN}3.${PLAIN} 精简网络版(系统信息+CPU+内存+磁盘IO+回程+路由+测速节点4个)(平均运行4分钟)"
            echo -e "${GREEN}4.${PLAIN} 精简解锁版(系统信息+CPU+内存+磁盘IO+御三家解锁+常用流媒体+TikTok+测速节点4个)(平均运行4分钟)"
            echo " -------------"
            echo -e "${GREEN}0.${PLAIN} 回到主菜单"
        fi
        echo ""
        while true; do
            if [ "$en_status" = true ]; then
                read -rp "Please enter the option number:" StartInput1
            else
                read -rp "请输入选项:" StartInput1
            fi
            simplify_script_options
            if [ "$break_status" = true ] || [ "$menu_mode" = false ]; then
                break
            fi
        done
    else
        StartInput1="$sub_menu_option"
        simplify_script_options
    fi
}

single_item_script_options() {
    case $StartInput2 in
    1)
        network_script
        break_status=true
        ;;
    2)
        media_script
        break_status=true
        ;;
    3)
        hardware_script
        break_status=true
        ;;
    4)
        # bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/ipcheck.sh)
        bash <(wget -qO- --no-check-certificate https://cdn.spiritlhl.net/https://raw.githubusercontent.com/spiritLHLS/ecs/main/ipcheck.sh)
        break_status=true
        ;;
    5)
        port_script
        break_status=true
        ;;
    6)
        sw_script
        break_status=true
        ;;
    0)
        start_script
        break_status=true
        ;;
    *)
        if [ "$en_status" = true ]; then
            echo "Input error, please re-enter"
        else
            echo "输入错误，请重新输入"
        fi
        break_status=false
        ;;
    esac
}

single_item_script() {
    head_script
    if $menu_mode; then
        if [ "$en_status" = true ]; then
            _yellow "The single test script for fusion monster splitting is as follows"
            echo -e "${GREEN}1.${PLAIN} Networking (simplified IP quality check + triple network backhaul + triple network routing and latency + 11 speed nodes) (average run time about 6 minutes)"
            echo -e "${GREEN}2.${PLAIN} For unlocking (Gosanja unlocking + common streamer unlocking + TikTok unlocking) (average runtime 30~60 seconds)"
            echo -e "${GREEN}3.${PLAIN} Hardware (basic system information + CPU + RAM + dual disk IO test) (average run time 1½ minutes)"
            echo -e "${GREEN}4.${PLAIN} IP quality check (average runtime 10~20 seconds)"
            # echo -e "${GREEN}5.${PLAIN} Common port openings (blocked or not) (average run time about 1 minute) (bugs not fixed yet)"
            # echo -e "${GREEN}6.${PLAIN} Triple-net backhaul line + Guangzhou triple-net routing + nationwide triple-net delay (average running 1 minute 20 seconds)"
            echo " -------------"
            echo -e "${GREEN}0.${PLAIN} Back to the main menu"
        else
            _yellow "融合怪拆分的单项测试脚本如下"
            echo -e "${GREEN}1.${PLAIN} 网络方面(简化的IP质量检测+三网回程+三网路由与延迟+测速节点11个)(平均运行6分钟左右)"
            echo -e "${GREEN}2.${PLAIN} 解锁方面(御三家解锁+常用流媒体解锁+TikTok解锁)(平均运行30~60秒)"
            echo -e "${GREEN}3.${PLAIN} 硬件方面(基础系统信息+CPU+内存+双重磁盘IO测试)(平均运行1分半钟)"
            echo -e "${GREEN}4.${PLAIN} IP质量检测(15个数据库的IP检测+邮件端口检测)(平均运行10~20秒)"
            echo -e "${GREEN}5.${PLAIN} 常用端口开通情况(是否有阻断)(平均运行1分钟左右)(暂时有bug未修复)"
            echo -e "${GREEN}6.${PLAIN} 三网回程线路+广州三网路由+全国三网延迟(平均运行1分20秒)"
            echo " -------------"
            echo -e "${GREEN}0.${PLAIN} 回到主菜单"
        fi
        echo ""
        while true; do
            if [ "$en_status" = true ]; then
                read -rp "Please enter the option number:" StartInput2
            else
                read -rp "请输入选项:" StartInput2
            fi
            single_item_script_options
            if [ "$break_status" = true ] || [ "$menu_mode" = false ]; then
                break
            fi
        done
    else
        StartInput2="$sub_menu_option"
        single_item_script_options
    fi
}

my_original_script_options() {
    case $StartInput4 in
    1)
        # bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/ipcheck.sh)
        bash <(wget -qO- --no-check-certificate https://cdn.spiritlhl.net/https://raw.githubusercontent.com/spiritLHLS/ecs/main/ipcheck.sh)
        break_status=true
        ;;
    2)
        network_script_select 'g'
        break_status=true
        ;;
    3)
        network_script_select 's'
        break_status=true
        ;;
    4)
        network_script_select 'b'
        break_status=true
        ;;
    5)
        network_script_select 'c'
        break_status=true
        ;;
    6)
        bash <(curl -sSL https://github.com/spiritLHLS/ecs/raw/main/archive/return.sh)
        break_status=true
        ;;
    7)
        bash <(curl -sSL https://github.com/spiritLHLS/ecs/raw/main/archive/nexttrace.sh)
        break_status=true
        ;;
    8)
        bash <(curl -sSL https://github.com/spiritLHLS/ecs/raw/main/customizeqzcheck.sh)
        break_status=true
        ;;
    9)
        bash <(curl -sSL https://github.com/spiritLHLS/ecs/raw/main/archive/disk_info.sh)
        break_status=true
        ;;
    10)
        bash <(curl -sSL https://github.com/spiritLHLS/ecs/raw/main/archive/geekbench4.sh)
        break_status=true
        ;;
    11)
        bash <(curl -sSL https://github.com/spiritLHLS/ecs/raw/main/archive/geekbench5.sh)
        break_status=true
        ;;
    12)
        bash <(curl -sSL https://github.com/spiritLHLS/ecs/raw/main/archive/geekbench6.sh)
        break_status=true
        ;;
    13)
        bash <(wget -qO- bash.spiritlhl.net/ecs-net)
        break_status=true
        ;;
    14)
        bash <(wget -qO- bash.spiritlhl.net/ecs-cn)
        break_status=true
        ;;
    15)
        bash <(wget -qO- bash.spiritlhl.net/ecs-ping)
        break_status=true
        ;;
    16)
        bash <(curl -sSL https://raw.githubusercontent.com/spiritLHLS/ecs/main/archive/multi_disk_io_test.sh)
        break_status=true
        ;;
    17)
        bash <(curl -sSL https://raw.githubusercontent.com/oneclickvirt/gostun/main/gostun_install.sh)
        break_status=true
        ;;
    0)
        start_script
        break_status=true
        ;;
    *)
        if [ "$en_status" = true ]; then
            echo "Input error, please re-enter"
        else
            echo "输入错误，请重新输入"
        fi
        break_status=false
        ;;
    esac
}

my_original_script() {
    head_script
    if $menu_mode; then
        _yellow "本作者有原创成分的脚本如下"
        echo -e "${GREEN}1.${PLAIN} 完整的本机IP的IP质量检测(平均运行10~20秒)"
        echo -e "${GREEN}2.${PLAIN} 三网回程路由测试(预设广州)(平均运行1分钟)"
        echo -e "${GREEN}3.${PLAIN} 三网回程路由测试(预设上海)(平均运行1分钟)"
        echo -e "${GREEN}4.${PLAIN} 三网回程路由测试(预设北京)(平均运行1分钟)"
        echo -e "${GREEN}5.${PLAIN} 三网回程路由测试(预设成都)(平均运行1分钟)"
        echo -e "${GREEN}6.${PLAIN} 自定义IP的回程路由测试(基于besttrace)(准确率高，但可能有bug)"
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
        echo -e "${GREEN}17.${PLAIN} 检测本机的NAT类型"
        echo " -------------"
        echo -e "${GREEN}0.${PLAIN} 回到主菜单"
        echo ""
        while true; do
            if [ "$en_status" = true ]; then
                read -rp "Please enter the option number:" StartInput4
            else
                read -rp "请输入选项:" StartInput4
            fi
            my_original_script_options
            if [ "$break_status" = true ] || [ "$menu_mode" = false ]; then
                break
            fi
        done
    else
        StartInput4="$sub_menu_option"
        my_original_script_options
    fi
}

head_script() {
    clear
    if [ "$en_status" = true ]; then
        echo "#############################################################"
        echo -e "#          ${YELLOW}VPS Fusion Monster Server Test Script${PLAIN}            #"
        echo -e "# Version: $ver                                       #"
        echo -e "# Update log：$changeLog     #"
        echo -e "# ${GREEN}Author${PLAIN}: spiritlhl                                         #"
        echo -e "# ${GREEN}TG Channel${PLAIN}: https://t.me/vps_reviews                      #"
        echo -e "# ${GREEN}GitHub${PLAIN}: https://github.com/spiritLHLS                     #"
        echo -e "# ${GREEN}GitLab${PLAIN}: https://gitlab.com/spiritysdx                     #"
        echo "#############################################################"
        echo ""
        _green "Number of times the script was run today: ${TODAY}, Cumulative number of runs: ${TOTAL}"
        if [ "$menu_mode" = true ]; then
            _green "Please select the option number you want to use"
        fi
    else
        echo "#############################################################"
        echo -e "#                     ${YELLOW}融合怪测评脚本${PLAIN}                        #"
        echo -e "# 版本(请注意比对仓库版本更新)：$ver                  #"
        echo -e "# 更新日志：$changeLog                       #"
        echo -e "# ${GREEN}作者${PLAIN}: spiritlhl                                           #"
        echo -e "# ${GREEN}TG频道${PLAIN}: https://t.me/vps_reviews                          #"
        echo -e "# ${GREEN}GitHub${PLAIN}: https://github.com/spiritLHLS                     #"
        echo -e "# ${GREEN}GitLab${PLAIN}: https://gitlab.com/spiritysdx                     #"
        echo "#############################################################"
        echo ""
        _green "脚本当天运行次数:${TODAY}，累计运行次数:${TOTAL}"
        if [ "$menu_mode" = true ]; then
            _green "请选择你接下来要使用的脚本"
        fi
    fi
}

start_script_options() {
    case $StartInput in
    1)
        all_script "S" | tee -i test_result.txt
        break_status=true
        ;;
    2)
        all_script "B" | tee -i test_result.txt
        break_status=true
        ;;
    3)
        simplify_script
        break_status=true
        ;;
    4)
        single_item_script
        break_status=true
        ;;
    5)
        original_script
        break_status=true
        ;;
    6)
        my_original_script
        break_status=true
        ;;
    7)
        checkver
        break_status=true
        ;;
    0)
        exit 1
        break_status=true
        ;;
    *)
        if [ "$en_status" = true ]; then
            echo "Input error, please re-enter"
        else
            echo "输入错误，请重新输入"
        fi
        break_status=false
        ;;
    esac
}

start_script() {
    head_script
    if $test_base_status; then
        # 纯测系统信息
        hardware_script | tee -i test_result.txt
    elif $menu_mode; then
        if [ "$en_status" = true ]; then
            echo -e "${GREEN}1.${PLAIN} Sequential Test - Fusion Monster Complete (all items tested) (average run time 7 minutes) (recommended for machine general)"
            echo -e "${GREEN}2.${PLAIN} Parallel Test - Fusion Monster Complete (all items tested) (runs for 5 minutes on average) (Powerful machines only, do not use for normal machines)"
            echo -e "${GREEN}3.${PLAIN} Fusion Monster Lite Zone (Lite or Single Test Lite version of Fusion Monster)"
            echo -e "${GREEN}4.${PLAIN} Fusion Monster Single Zone (full version of Fusion Monster single test)"
            echo -e "${GREEN}5.${PLAIN} Third-party scripts area (various test scripts by similar authors)"
            echo -e "${GREEN}6.${PLAIN} Original area (some test scripts unique to this script)"
            echo -e "${GREEN}7.${PLAIN} Update this script"
            echo " -------------"
            echo -e "${GREEN}0.${PLAIN} Exit"
        else
            echo -e "${GREEN}1.${PLAIN} 顺序测试--融合怪完全体(所有项目都测试)(平均运行7分钟)(机器普通推荐使用)"
            echo -e "${GREEN}2.${PLAIN} 并行测试--融合怪完全体(所有项目都测试)(平均运行5分钟)(仅机器强劲可使用，机器普通勿要使用)"
            echo -e "${GREEN}3.${PLAIN} 融合怪精简区(融合怪的精简版或单项测试精简版)"
            echo -e "${GREEN}4.${PLAIN} 融合怪单项区(融合怪的单项测试完整版)"
            echo -e "${GREEN}5.${PLAIN} 第三方脚本区(同类作者的各种测试脚本)"
            echo -e "${GREEN}6.${PLAIN} 原创区(本脚本独有的一些测试脚本)"
            echo -e "${GREEN}7.${PLAIN} 更新本脚本"
            echo " -------------"
            echo -e "${GREEN}0.${PLAIN} 退出"
        fi
        echo ""
        while true; do
            if [ "$en_status" = true ]; then
                read -rp "Please enter the option number:" StartInput
            else
                read -rp "请输入选项:" StartInput
            fi
            start_script_options
            if [ "$break_status" = true ] || [ "$menu_mode" = false ]; then
                break
            fi
        done
    else
        StartInput="$main_menu_option"
        start_script_options
    fi
}

# =============== 正式执行 部分 ===============
rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR
get_system_bit
statistics_of_run_times
start_script
global_exit_action
rm_script

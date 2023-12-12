#!/usr/bin/env bash
# by spiritlhl
# from https://github.com/spiritLHLS/ecs

cd /root >/dev/null 2>&1
myvar=$(pwd)
ver="2023.12.12"
changeLog="VPS融合怪测试(集百家之长)"
start_time=$(date +%s)

# =============== 默认输入设置 ===============
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN="\033[0m"
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
swhc_mode=true
test_base_status=false
test_cpu_type=""
test_disk_type=""
build_text_status=true
multidisk_status=false
target_ipv4=""
route_location=""
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
            shift  # 移动到下一个参数
            while [ "$#" -gt 0 ] && [[ "$1" != -* ]]; do
                m_params+=("$1")
                shift
            done
        ;;
        -i)
            # 处理 -i 选项，获取IPv4地址
            menu_mode=false
            target_ipv4="$2"
            swhc_mode=false
            shift 2
        ;;
        -r)
            # 处理 -r 选项，选择测试回程路由的出口地址
            menu_mode=false
            route_location="$2"
            shift 2
        ;;
        -base)
            # 处理 -base 选项，选择仅测试系统信息
            menu_mode=false
            test_base_status=true
            shift
        ;;
        -ctype)
            # 处理 -ctype 选项，选择测试cpu使用的方式
            menu_mode=false
            test_cpu_type="$2"
            shift 2
        ;;
        -dtype)
            # 处理 -dtype 选项，选择测试磁盘使用的方式
            menu_mode=false
            test_disk_type="$2"
            shift 2
        ;;
        -banup)
            # 处理 -banup 选项，选择测试磁盘使用的方式
            menu_mode=false
            build_text_status=false
            shift
        ;;
        -h)
            echo "使用参数模式执行："
            echo "-m     必填项，指定原本menu中的选项，最多支持三层选择"
            echo "       例如执行 bash ecs.sh -m 5 1 1 将选择主菜单第5选项下的第1选项下的子选项1的脚本执行"
            echo "       (可缺省仅指定一个参数，如 -m 1 仅指定执行融合怪完全体，执行 -m 1 0 以及 -m 1 0 0 都是指定执行融合怪完全体)"
            echo "-i     可选项，可指定回程路由测试中的目标IPV4地址，可通过 ip.sb ipinfo.io 等网站获取本地IPV4地址后指定"
            echo "-r     可选项，可指定回程路由测试中的三网目标地址，可选 b g s c 分别对应 北京、广州、上海、成都 的三网地址，如 -r g 指定测试广州回程"
            echo "-base  可选项，仅测试基础的系统信息，不测试CPU、硬盘、流媒体、回程路由等内容"
            echo "-ctype 可选项，可指定通过何种方式测试cpu，可选 gb4 gb5 gb6 分别对应geekbench的4、5、6版本，无该指令则默认使用sysbench测试"
            echo "-dtype 可选项，可指定测试硬盘IO的程序，可选 dd 或 fio 前者测试快后者测试慢，无该指令则默认为都使用进行测试"
            echo "-banup 可选项，可指定强制不生成分享链接，无该指令则默认生成分享链接"
            # 更多选项待添加
            # echo "-multidisk 可指定测试多个挂载盘的IO，注意这也会测试系统盘"
            exit 1
        ;;
        *)
            echo "未知的选项: $1"
            exit 1
        ;;
    esac
done
if [ -n "$target_ipv4" ]; then
    test_area_local=("你本地的IPV4地址")
    test_ip_local=("$target_ipv4")
fi
# 在menu_mode为false时才打印信息
if [ "$menu_mode" = false ]; then
    _blue "检测到参数，使用参数模式，读取参数如下，显示4秒"
    echo "menu_mode: $menu_mode"
    echo "test_base_status: $test_base_status"
    echo "target_ipv4: $target_ipv4"
    echo "route_location: $route_location"
    echo "test_cpu_type: $test_cpu_type"
    echo "test_disk_type: $test_disk_type"
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
shorturl=""
TEMP_DIR='/tmp/ecs'
temp_file_apt_fix="${TEMP_DIR}/apt_fix.txt"
WorkDir="/tmp/.LemonBench"
test_area_g=("广州电信" "广州联通" "广州移动")
test_ip_g=("58.60.188.222" "210.21.196.6" "120.196.165.24")
test_area_s=("上海电信" "上海联通" "上海移动")
test_ip_s=("202.96.209.133" "210.22.97.1" "211.136.112.200")
test_area_b=("北京电信" "北京联通" "北京移动")
test_ip_b=("219.141.136.12" "202.106.50.1" "221.179.155.161")
test_area_c=("成都电信" "成都联通" "成都移动")
test_ip_c=("61.139.2.69" "119.6.6.6" "211.137.96.205")
test_area_6=("广东电信" "广东联通" "广东移动")
test_ip_6=("2401:1d40:3100::1" "2408:8001:3000::1" "2409:8054:306c::1")
BrowserUA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.74 Safari/537.36"

# =============== 基础信息设置 ===============
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

# =================== 其他脚本相关设置 ===================
export DEBIAN_FRONTEND=noninteractive
rm -rf test_result.txt >/dev/null 2>&1
if [ ! -d "/tmp" ]; then
    mkdir /tmp
fi

# =============== 脚本退出执行相关函数 部分 ===============
trap _exit INT QUIT TERM

_exit() {
    # 终止信号捕获 - ctrl+c
    echo -e "\n${Msg_Error}Exiting ...\n"
    _red "检测到退出操作，脚本终止！\n"
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
    Check_SysBench
    BenchFunc_Systeminfo_GetSysteminfo
    echo -e "${Msg_Info}Starting Test ..."
}

global_exit_action() {
    reset_default_sysctl >/dev/null 2>&1
    if [ "$build_text_status" = true ]; then
        build_text
        if [ -n "$shorturl" ]; then
            _green "  短链:"
            _blue "    $shorturl"
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
    running_version=$(sed -n '8s/ver="\(.*\)"/\1/p' "$0")
    curl -L "${cdn_success_url}https://raw.githubusercontent.com/spiritLHLS/ecs/main/ecs.sh" -o ecs1.sh && chmod 777 ecs1.sh
    downloaded_version=$(sed -n '8s/ver="\(.*\)"/\1/p' ecs1.sh)
    if [ "$running_version" != "$downloaded_version" ]; then
        _yellow "更新脚本从 $ver 到 $downloaded_version"
        mv ecs1.sh "$0"
        ./ecs.sh
    else
        _green "本脚本已是最新脚本无需更新"
        rm -rf ecs1.sh*
    fi
}

check_root() {
    [[ $EUID -ne 0 ]] && echo -e "${RED}请使用 root 用户运行本脚本！${PLAIN}" && exit 1
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
        _yellow "Installing net-tools to use ip command"
        ${PACKAGE_INSTALL[int]} net-tools
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

check_stun() {
    _yellow "checking stun"
    if ! command -v stun >/dev/null 2>&1; then
        _yellow "Installing stun"
        ${PACKAGE_INSTALL[int]} stun-client >/dev/null 2>&1
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
            if ! "$pip_command" install -q pystun3 >/dev/null 2>&1; then
                "$pip_command" install -q pystun3
                if [ $? -ne 0 ]; then
                    "$pip_command" install -q pystun3 --break-system-packages
                fi
            fi
        fi
    fi
    if [[ $python_command == "python" ]]; then
        checkpip
        if [[ $($python_command --version 2>&1) == Python\ 2* ]]; then
            _yellow "Installing pystun"
            if ! "$pip_command" install -q pystun >/dev/null 2>&1; then
                "$pip_command" install -q pystun
                if [ $? -ne 0 ]; then
                    "$pip_command" install -q pystun --break-system-packages
                fi
            fi
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
    cat "$file"
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
            if ! wget -O $TEMP_DIR/sysbench.zip "${cdn_success_url}https://github.com/akopytov/sysbench/archive/1.0.20.zip"; then
                echo "wget failed, trying with curl"
                curl -Lk -o $TEMP_DIR/sysbench.zip "${cdn_success_url}https://github.com/akopytov/sysbench/archive/1.0.20.zip"
            fi
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
            curl -sL -k "${cdn_success_url}https://raw.githubusercontent.com/spiritLHLS/ecs/main/archive/besttrace/2021/${BESTTRACE_FILE}" -o $TEMP_DIR/$BESTTRACE_FILE && chmod +x $TEMP_DIR/$BESTTRACE_FILE
            ;;
        nexttrace)
            NEXTTRACE_VERSION=$(curl -sSL "https://api.github.com/repos/nxtrace/Ntrace-core/releases/latest" | awk -F \" '/tag_name/{print $4}') && curl -sL -k "${cdn_success_url}https://github.com/nxtrace/Ntrace-core/releases/download/${NEXTTRACE_VERSION}/${NEXTTRACE_FILE}" -o $TEMP_DIR/$NEXTTRACE_FILE && chmod +x $TEMP_DIR/$NEXTTRACE_FILE
            ;;
        backtrace)
            wget -q -O $TEMP_DIR/backtrace.tar.gz https://github.com/zhanghanyun/backtrace/releases/latest/download/$BACKTRACE_FILE
            tar -xf $TEMP_DIR/backtrace.tar.gz -C $TEMP_DIR
            ;;
        yabsiotest)
            curl -sL -k "${cdn_success_url}https://raw.githubusercontent.com/spiritLHLS/ecs/main/archive/yabsiotest.sh" -o $TEMP_DIR/yabsiotest.sh && chmod +x $TEMP_DIR/yabsiotest.sh
            ;;
        yabs)
            curl -sL -k "${cdn_success_url}https://raw.githubusercontent.com/masonr/yet-another-bench-script/master/yabs.sh" -o $TEMP_DIR/yabs.sh && chmod +x $TEMP_DIR/yabs.sh
            sed -i '/# gather basic system information (inc. CPU, AES-NI\/virt status, RAM + swap + disk size)/,/^echo -e "IPv4\/IPv6  : $ONLINE"/d' $TEMP_DIR/yabs.sh

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
        _yellow "No CDN available, no use CDN"
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
            timeout 60 ntpd -gq
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
        chronyd -q
        systemctl start chronyd
    else
        service chronyd stop
        chronyd -q
        service chronyd start
    fi
    sleep 0.5
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
            curl -6 -ksm1 "https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2FspiritLHLS%2Fecs&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=&edge_flat=true" 2>&1
    )
    TODAY=$(expr "$COUNT" : '.*\s\([0-9]\{1,\}\)\s/.*')
    TOTAL=$(expr "$COUNT" : '.*/\s\([0-9]\{1,\}\)\s.*')
}

# =============== 基础系统信息 部分 ===============
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
    elif [ -f "/etc/freebsd-update.conf" ]; then # freebsd
        Var_OSRelease="freebsd"
    else
        Var_OSRelease="unknown" # 未知系统分支
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
        BESTTRACE_FILE=besttracemac
        NEXTTRACE_FILE=nexttrace_darwin_amd64
        ;;
    "armv7l" | "armv8" | "armv8l" | "aarch64")
        LBench_Result_SystemBit_Short="arm"
        LBench_Result_SystemBit_Full="arm"
        BESTTRACE_FILE=besttracearm
        BACKTRACE_FILE=backtrace-linux-arm64.tar.gz
        NEXTTRACE_FILE=nexttrace_linux_arm64
        ;;
    *)
        LBench_Result_SystemBit_Short="64"
        LBench_Result_SystemBit_Full="amd64"
        BESTTRACE_FILE=besttrace
        BACKTRACE_FILE=backtrace-linux-amd64.tar.gz
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
    centos | rhel | almalinux) OS_TYPE="redhat" ;;
    ubuntu) OS_TYPE="ubuntu" ;;
    debian | astra) OS_TYPE="debian" ;;
    fedora) OS_TYPE="fedora" ;;
    alpinelinux) OS_TYPE="alpinelinux" ;;
    arch) OS_TYPE="arch" ;;
    freebsd) OS_TYPE="freebsd" ;;
    *) OS_TYPE="unknown" ;;
    esac
    echo "${OS_TYPE}"
}

InstallSysbench() {
    local os_release=$1
    case "$os_release" in
    ubuntu | debian) ! apt-get install -y sysbench && apt-get --fix-broken install -y && apt-get install --no-install-recommends -y sysbench ;;
    redhat | centos) (yum -y install epel-release && yum -y install sysbench) || (dnf install epel-release -y && dnf install sysbench -y) ;;
    fedora) dnf -y install sysbench ;;
    arch) pacman -S --needed --noconfirm sysbench && pacman -S --needed --noconfirm libaio && ldconfig ;;
    freebsd) pkg install -y sysbench ;;
    alpinelinux) echo -e "${Msg_Warning}Sysbench Module not found, installing ..." && echo -e "${Msg_Warning}SysBench Current not support Alpine Linux, Skipping..." && Var_Skip_SysBench="1" ;;
    *) echo "Error: Unknown OS release: $os_release" && exit 1 ;;
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
        ! apt-get update && apt-get --fix-broken install -y && apt-get update
        ! apt-get -y install --no-install-recommends curl wget make automake libtool pkg-config libaio-dev unzip && apt-get --fix-broken install -y && apt-get -y install --no-install-recommends curl wget make automake libtool pkg-config libaio-dev unzip
    elif [ "${system}" = "fedora" ]; then
        dnf install -y wget curl gcc gcc-c++ make automake libtool pkgconfig libaio-devel
    elif [ "${system}" = "arch" ]; then
        pacman -S --needed --noconfirm wget curl gcc gcc make automake libtool pkgconfig libaio lib32-libaio
    else
        echo -e "${Msg_Warning}Unsupported operating system: ${system}"
    fi
}

# =============== CPU性能测试 部分 ===============
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
    if [ -n "${Result_Systeminfo_CPUThreads}" ] && [ "${Result_Systeminfo_CPUThreads}" -ge "2" ] >/dev/null 2>&1; then
        Run_SysBench_CPU "${Result_Systeminfo_CPUThreads}" "5" "1" "${Result_Systeminfo_CPUThreads} 线程测试(多核)得分"
    elif [ -n "${Result_Systeminfo_CPUCores}" ] && [ "${Result_Systeminfo_CPUCores}" -ge "2" ] >/dev/null 2>&1; then
        Run_SysBench_CPU "${Result_Systeminfo_CPUCores}" "5" "1" "${Result_Systeminfo_CPUCores} 线程测试(多核)得分"
    elif [ -n "${cores}" ] && [ "${cores}" -ge "2" ] >/dev/null 2>&1; then
        Run_SysBench_CPU "${cores}" "5" "1" "${cores} 线程测试(多核)得分"
    fi
}

# =============== 网速测试及延迟测试 部分 ===============
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
    local nodeName="$2"
    if [ ! -f "./speedtest-cli/speedtest" ]; then
        if [ -z "$1" ]; then
            ./speedtest-cli/speedtest-go >./speedtest-cli/speedtest.log 2>&1
        else
            ./speedtest-cli/speedtest-go --server=$1 >./speedtest-cli/speedtest.log 2>&1
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
    for ((i = 0; i < ${#list[@]}; i += 1)); do
        id=$(echo "${list[i]}" | cut -d',' -f1)
        name=$(echo "${list[i]}" | cut -d',' -f2)
        speed_test "$id" "$name"
    done
}

temp_head() {
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
                retries=$((retries + 1))
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
                retries=$((retries + 1))
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
            ./speedtest-cli/speedtest-go >./speedtest-cli/speedtest.log 2>&1
        else
            ./speedtest-cli/speedtest-go --custom-url=http://"$1"/upload.php >./speedtest-cli/speedtest.log 2>&1
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

speed() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
    local ip4=$(echo "$IPV4" | tr -d '\n' | tr -d '[:space:]')
    if [[ -z "${ip4}" ]]; then
        return
    fi
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
            (install_speedtest >/dev/null 2>&1)
        fi
        checknslookup >/dev/null 2>&1
        CN_Mobile=($(get_nearest_data2 "${SERVER_BASE_URL2}/mobile.csv")) >/dev/null 2>&1
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
    local ip4=$(echo "$IPV4" | tr -d '\n' | tr -d '[:space:]')
    if [[ -z "${ip4}" ]]; then
        return
    fi
    temp_head
    speed_test '' 'Speedtest.net'
    test_list "${CN_Unicom[0]}"
    test_list "${CN_Telecom[0]}"
    if [ ${#CN_Mobile[@]} -eq 0 ]; then
        echo -n "该运营商.net的节点列表为空，正在替换为.cn的节点列表。。。"
        CN=true
        if [ -f "./speedtest-cli/speedtest" ]; then
            rm -rf ./speedtest-cli/speedtest
            (install_speedtest >/dev/null 2>&1)
        fi
        checknslookup >/dev/null 2>&1
        CN_Mobile=($(get_nearest_data2 "${SERVER_BASE_URL2}/mobile.csv")) >/dev/null 2>&1
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
    echo -e " $4\t\t${DiskTest_WriteSpeed} (${DiskTest_WriteIOPS} IOPS, ${DiskTest_WritePastTime} s)\t\t${DiskTest_ReadSpeed} (${DiskTest_ReadIOPS} IOPS, ${DiskTest_ReadPastTime} s)" >>${WorkDir}/DiskTest/result.txt
    rm -rf /.tmp_LBench/DiskTest/
}

Function_DiskTest_Fast() {
    mkdir -p ${WorkDir}/DiskTest/ >/dev/null 2>&1
    echo -e " ${Font_Yellow}-> 磁盘IO测试中 (4K Block/1M Block, Direct Mode)${Font_Suffix}"
    echo -e " -> 磁盘IO测试中 (4K Block/1M Block, Direct Mode)\n" >>${WorkDir}/DiskTest/result.txt
    if [ "${Result_Systeminfo_VMMType}" = "docker" ] || [ "${Result_Systeminfo_VMMType}" = "wsl" ]; then
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
        local asn=$(echo "$ip_info" | grep -o '"org": "[^"]*' | cut -d'"' -f4)
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
            elif [[ -n $ipv4_asn && -n $ipv4_city ]]; then
                local ipv4_asn_info="${ipv4_asn}"
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
    else
        local ipv4_asn_info="None"
        local ipv4_location="None"
    fi
    # 去除双引号
    if [[ $ipv4_asn_info == *"\""* ]]; then
        ipv4_asn_info="${ipv4_asn_info//\"/}"
    fi
    if [[ $ipv4_location == *"\""* ]]; then
        ipv4_location="${ipv4_location//\"/}"
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
    else
        local ipv6_asn_info="None"
        local ipv6_location="None"
    fi
    # 去除双引号
    if [[ $ipv6_asn_info == *"\""* ]]; then
        ipv6_asn_info="${ipv6_asn_info//\"/}"
    fi
    if [[ $ipv6_location == *"\""* ]]; then
        ipv6_location="${ipv6_location//\"/}"
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
        tcpctrl="未设置TCP拥塞控制算法"
    else
        if [ $tcpctrl == "bbr" ]; then
            :
        else
            if lsmod | grep bbr >/dev/null; then
                reading "是否要开启bbr再进行测试？(回车则默认不开启) [y/n] " confirmbbr
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
    if [[ ! -z "${ip4}" ]]; then
        check_stun
        if command -v stun >/dev/null 2>&1; then
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
                if command -v pystun3 >/dev/null 2>&1; then
                    result=$(pystun3 </dev/null)
                    nat_type_r=$(echo "$result" | grep -oP 'NAT Type:\s*\K.*')
                    if echo "$nat_type_r" | grep -qE "Blocked"; then
                        nat_type_r="无法检测"
                    fi
                elif command -v pystun >/dev/null 2>&1; then
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
            if command -v pystun3 >/dev/null 2>&1; then
                result=$(pystun3 </dev/null)
                nat_type_r=$(echo "$result" | grep -oP 'NAT Type:\s*\K.*')
            elif command -v pystun >/dev/null 2>&1; then
                result=$(pystun </dev/null)
                nat_type_r=$(echo "$result" | grep -oP 'NAT Type:\s*\K.*')
            fi
        fi
        if echo "$nat_type_r" | grep -qE "BlockedorcouldnotreachSTUNserver|Blocked or could not reach STUN server"; then
            nat_type_r="无法检测"
        fi
    else
        nat_type_r="无法检测"
    fi
}

# =============== 正式输出 部分 ===============
print_intro() {
    echo "--------------------- A Bench Script By spiritlhl ----------------------"
    echo "                   测评频道: https://t.me/vps_reviews                    "
    echo "版本：$ver"
    echo "更新日志：$changeLog                       "
}

get_first_non_empty_element() {
    local array=("$@")
    for element in "${array[@]}"; do
        if [[ "$element" != "None" ]]; then
            echo "$element"
            break
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
    files=("/tmp/ipinfo" "/tmp/cloudflare" "/tmp/ipsb" "/tmp/cheervision")
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
    local ipv4_asn_info=$(get_first_non_empty_element "${ipv4_asn_info_list[@]}")
    local ipv4_location=$(get_first_non_empty_element "${ipv4_location_list[@]}")
    local ipv6_asn_info=$(get_first_non_empty_element "${ipv6_asn_info_list[@]}")
    local ipv6_location=$(get_first_non_empty_element "${ipv6_location_list[@]}")
    # 删除缓存文件
    for file in "${files[@]}"; do
        rm -rf ${file}
    done
    # 获取IPV6的子网掩码
    local ipv6_prefixlen=$(check_and_cat_file "${TEMP_DIR}/eo6s_result")
    # 打印最终结果
    if [[ -n "$ipv4_asn_info" && "$ipv4_asn_info" != "None" ]]; then
        echo " IPV4 ASN          : $(_blue "$ipv4_asn_info")"
    fi
    if [[ -n "$ipv4_location" && "$ipv4_location" != "None" ]]; then
        echo " IPV4 位置         : $(_blue "$ipv4_location")"
    fi
    if [[ -n "$ipv6_asn_info" && "$ipv6_asn_info" != "None" ]]; then
        echo " IPV6 ASN          : $(_blue "$ipv6_asn_info")"
    fi
    if [[ -n "$ipv6_location" && "$ipv6_location" != "None" ]]; then
        echo " IPV6 位置         : $(_blue "$ipv6_location")"
    fi
    if [[ -n "$ipv6_prefixlen" && "$ipv6_prefixlen" != "None" ]]; then
        echo " IPV6 子网掩码     : $(_blue "$ipv6_prefixlen")"
    fi
}

print_system_info() {
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
    if [ -n "$Result_Systeminfo_Diskinfo" ] >/dev/null 2>&1; then
        echo " 硬盘空间          : $(_blue "$Result_Systeminfo_Diskinfo")"
    else
        echo " 硬盘空间          : $(_yellow "$disk_total_size GB") $(_blue "($disk_used_size GB 已用)")"
    fi
    if [ -n "$Result_Systeminfo_DiskRootPath" ] >/dev/null 2>&1; then
        echo " 启动盘路径        : $(_blue "$Result_Systeminfo_DiskRootPath")"
    fi
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
    echo " 系统在线时间      : $(_blue "$up")"
    echo " 负载              : $(_blue "$load")"
    if [ -n "$Result_Systeminfo_OSReleaseNameFull" ] >/dev/null 2>&1; then
        echo " 系统              : $(_blue "$Result_Systeminfo_OSReleaseNameFull")"
    elif [ -n "$DISTRO" ] >/dev/null 2>&1; then
        echo " 系统              : $(_blue "$DISTRO")"
    fi
    [[ -z "$CPU_AES" ]] && CPU_AES="\xE2\x9D\x8C Disabled" || CPU_AES="\xE2\x9C\x94 Enabled"
    echo " AES-NI指令集      : $(_blue "$CPU_AES")"
    [[ -z "$CPU_VIRT" ]] && CPU_VIRT="\xE2\x9D\x8C Disabled" || CPU_VIRT="\xE2\x9C\x94 Enabled"
    echo " VM-x/AMD-V支持    : $(_blue "$CPU_VIRT")"
    echo " 架构              : $(_blue "$arch ($lbit Bit)")"
    echo " 内核              : $(_blue "$kern")"
    echo " TCP加速方式       : $(_yellow "$tcpctrl")"
    echo " 虚拟化架构        : $(_blue "$Result_Systeminfo_VMMType")"
    [[ -n "$nat_type_r" ]] && echo " NAT类型           : $(_blue "$nat_type_r")"
}

print_end_time() {
    end_time=$(date +%s)
    start_time_abs=$(echo $start_time | tr -d -)
    end_time_abs=$(echo $end_time | tr -d -)
    time_abs_diff=$((${end_time_abs} - ${start_time_abs}))
    time=$(echo $time_abs_diff | tr -d -)
    if [ ${time} -gt 60 ]; then
        min=$(expr $time / 60)
        sec=$(expr $time % 60)
        echo " 总共花费      : ${min} 分 ${sec} 秒"
    else
        echo " 总共花费      : ${time} 秒"
    fi
    date_time=$(date)
    echo " 时间          : $date_time"
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

# ipinfo数据库 ①
ipinfo() {
    rm -rf /tmp/ip_quality_ipinfo*
    local ip="$1"
    local output=$(curl -sL -m 10 -v "https://ipinfo.io/widget/demo/${ip}" -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36" -H "Referer: https://ipinfo.io" 2>/dev/null)
    local temp_output=$(echo "$output" | sed -e '/^*/d' -e '/^>/d' -e '/^  CApath/d')
    local type_output=$(echo "$temp_output" | awk -F'"type":' '{print $2}' | awk -F'"' '{print $2}' | sed '/^\s*$/d')
    local asn_type=$(echo "$type_output" | sed -n '1p')
    local company_type=$(echo "$type_output" | sed -n '2p')
    local vpn=$(echo "$temp_output" | grep -o '"vpn": .*,' | cut -d' ' -f2 | tr -d '",')
    local proxy=$(echo "$temp_output" | grep -o '"proxy": .*,' | cut -d' ' -f2 | tr -d '",')
    local tor=$(echo "$temp_output" | grep -o '"tor": .*,' | cut -d' ' -f2 | tr -d '",')
    local relay=$(echo "$temp_output" | grep -o '"relay": .*,' | cut -d' ' -f2 | tr -d '",')
    local hosting=$(echo "$temp_output" | grep -o '"hosting": .*,' | cut -d' ' -f2 | tr -d '",')
    echo "$asn_type" >/tmp/ip_quality_ipinfo_usage_type
    echo "$company_type" >/tmp/ip_quality_ipinfo_company_type
    echo "$vpn" >/tmp/ip_quality_ipinfo_vpn
    echo "$proxy" >/tmp/ip_quality_ipinfo_proxy
    echo "$tor" >/tmp/ip_quality_ipinfo_tor
    echo "$relay" >/tmp/ip_quality_ipinfo_icloud_relay
    echo "$hosting" >/tmp/ip_quality_ipinfo_hosting
}

# scamalytics数据库 ②
scamalytics_ipv4() {
    local ip="$1"
    rm -rf /tmp/ip_quality_scamalytics_ipv4*
    local context=$(curl -sL -H "Referer: https://scamalytics.com" -m 10 "https://scamalytics.com/ip/$ip")
    if [[ "$?" -ne 0 ]]; then
        return
    fi
    local temp1=$(echo "$context" | grep -oP '(?<=>Fraud Score: )[^<]+')
    # 欺诈分数
    if [ -n "$temp1" ]; then
        echo "$temp1" >>/tmp/ip_quality_scamalytics_ipv4_score
    else
        return
    fi
    local temp2=$(echo "$context" | grep -oP '(?<=<div).*?(?=</div>)' | tail -n 6)
    local nlist=("vpn" "tor" "datacenter" "public_proxy" "web_proxy" "search_engine_robot")
    local status_t2
    for element in $temp2; do
        if echo "$element" | grep -q "score" >/dev/null 2>&1; then
            status_t2=1
            break
        else
            status_t2=2
            break
        fi
    done
    local i=0
    if ! [ "$status_t2" -eq 1 ]; then
        while read -r temp3; do
            if [[ -n "$temp3" ]]; then
                echo "${temp3#*>}" >>/tmp/ip_quality_scamalytics_ipv4_${nlist[$i]}
                i=$((i + 1))
            fi
        done <<<"$(echo "$temp2" | sed 's/<[^>]*>//g' | sed 's/^[[:blank:]]*//g')"
    fi
}

# scamalytics数据库 ②
scamalytics_ipv6() {
    local ip="$1"
    rm -rf /tmp/ip_quality_scamalytics_ipv6*
    local context=$(curl -sL -H "Referer: https://scamalytics.com" -m 10 "https://scamalytics.com/ip/$ip")
    if [[ "$?" -ne 0 ]]; then
        return
    fi
    local temp1=$(echo "$context" | grep -oP '(?<=>Fraud Score: )[^<]+')
    # 欺诈分数
    if [ -n "$temp1" ]; then
        echo "$temp1" >>/tmp/ip_quality_scamalytics_ipv6_score
    else
        return
    fi
    local temp2=$(echo "$context" | grep -oP '(?<=<div).*?(?=</div>)' | tail -n 6)
    local nlist=("vpn" "tor" "datacenter" "public_proxy" "web_proxy" "search_engine_robot")
    local status_t2
    for element in $temp2; do
        if echo "$element" | grep -q "score" >/dev/null 2>&1; then
            status_t2=1
            break
        else
            status_t2=2
            break
        fi
    done
    local i=0
    if ! [ "$status_t2" -eq 1 ]; then
        while read -r temp3; do
            if [[ -n "$temp3" ]]; then
                echo "${temp3#*>}" >>/tmp/ip_quality_scamalytics_ipv6_${nlist[$i]}
                i=$((i + 1))
            fi
        done <<<"$(echo "$temp2" | sed 's/<[^>]*>//g' | sed 's/^[[:blank:]]*//g')"
    fi
}

# virustotal数据库 ③
virustotal() {
    local ip="$1"
    rm -rf /tmp/ip_quality_virustotal*
    local api_keys=(
        "401e74a0a76ff4a5c2462177bfe54d1fb71a86a97031a3a5b461eb9fe06fa9a5"
        "e6184c04de532cd5a094f3fd6b3ce36cd187e41e671b5336fd69862257d07a9a"
        "9929218dcd124c19bcee49ecd6d7555213de0e8f27d407cc3e85c92c3fc2508e"
        "bcc1f94cc4ec1966f43a5552007d6c4fa3461cec7200f8d95053ebeeecc68afa"
    )
    local api_key=${api_keys[$RANDOM % ${#api_keys[@]}]}
    local output=$(curl -s --request GET --url "https://www.virustotal.com/api/v3/ip_addresses/$ip" --header "x-apikey:$api_key")
    result=$(echo "$output" | awk -F"[,:}]" '{
        for(i=1;i<=NF;i++){
            if($i~/\042timeout\042/){
                exit
            } else if($i~/\042harmless\042/){
                print $(i+1)
            } else if($i~/\042malicious\042/){
                print $(i+1)
            } else if($i~/\042suspicious\042/){
                print $(i+1)
            } else if($i~/\042undetected\042/){
                print $(i+1)
            }
        }
    }' | sed 's/\"//g')
    # 黑名单记录统计:(有多少黑名单网站有记录)
    if [[ -n "$result" ]] && [[ -n "$(echo "$result" | awk 'NF')" ]]; then
        echo "$result" | sed 's/ //g' | awk 'NR==1' >/tmp/ip_quality_virustotal_harmlessness_records
        echo "$result" | sed 's/ //g' | awk 'NR==2' >/tmp/ip_quality_virustotal_malicious_records
        echo "$result" | sed 's/ //g' | awk 'NR==3' >/tmp/ip_quality_virustotal_suspicious_records
        echo "$result" | sed 's/ //g' | awk 'NR==4' >/tmp/ip_quality_virustotal_no_records
    fi
}

cloudflare() {
    local status=0
    local context1
    rm -rf /tmp/ip_quality_cloudflare_risk
    for ((i = 1; i <= 100; i++)); do
        context1=$(curl -sL -m 10 "https://cf-threat.sukkaw.com/hello.json?threat=$i")
        if [[ "$context1" != *"pong!"* ]]; then
            echo "Cloudflare威胁得分高于10为爬虫或垃圾邮件发送者,高于40有严重不良行为(如僵尸网络等),数值一般不会大于60" >>/tmp/ip_quality_cloudflare_risk
            echo "Cloudflare威胁得分：$i" >>/tmp/ip_quality_cloudflare_risk
            local status=1
            break
        fi
    done
    if [[ $i == 100 && $status == 0 ]]; then
        echo "Cloudflare威胁得分(0为低风险): 0" >>/tmp/ip_quality_cloudflare_risk
    fi
}

# abuseipdb数据库 ④ IP2Location数据库 ⑤
abuse_ipv4() {
    local ip="$1"
    local score
    local usageType
    rm -rf /tmp/ip_quality_abuseipdb_ipv4*
    local context2=$(curl -sL -H "$head" -m 10 "https://api.abuseipdb.com/api/v2/check?ipAddress=${ip}")
    if [[ "$context2" == *"abuseConfidenceScore"* ]]; then
        score=$(echo "$context2" | grep -o '"abuseConfidenceScore":[^,}]*' | sed 's/.*://')
        echo "$score" >/tmp/ip_quality_abuseipdb_ipv4_score
        usageType=$(grep -oP '"usageType":\s*"\K[^"]+' <<<"$context2" | sed 's/\\\//\//g')
        if [ -z "$usageType" ]; then
            usageType="Unknown (Maybe Fixed Line ISP)"
        fi
        echo "$usageType" >/tmp/ip_quality_ip2location_ipv4_usage_type
    fi
}

# abuseipdb数据库 ④ IP2Location数据库 ⑤
abuse_ipv6() {
    local ip="$1"
    local score
    local usageType
    rm -rf /tmp/ip_quality_abuseipdb_ipv6*
    local context2=$(curl -sL -H "$head" -m 10 "https://api.abuseipdb.com/api/v2/check?ipAddress=${ip}")
    if [[ "$context2" == *"abuseConfidenceScore"* ]]; then
        score=$(echo "$context2" | grep -o '"abuseConfidenceScore":[^,}]*' | sed 's/.*://')
        echo "$score" >/tmp/ip_quality_abuseipdb_ipv6_score
        usageType=$(grep -oP '"usageType":\s*"\K[^"]+' <<<"$context2" | sed 's/\\\//\//g')
        if [ -z "$usageType" ]; then
            usageType="Unknown (Maybe Fixed Line ISP)"
        fi
        echo "$usageType" >/tmp/ip_quality_ip2location_ipv6_usage_type
    fi
}

# ip-api数据库 ⑥
ipapi() {
    local ip=$1
    local mobile
    local tp1
    local proxy
    local tp2
    local hosting
    local tp3
    rm -rf /tmp/ip_quality_ipapi*
    local context4=$(curl -sL -m 10 "http://ip-api.com/json/$ip?fields=mobile,proxy,hosting")
    if [[ "$context4" == *"mobile"* ]]; then
        mobile=$(echo "$context4" | grep -o '"mobile":[^,}]*' | sed 's/.*://;s/"//g')
        tp1=$(translate_status ${mobile})
        echo "$tp1" >>/tmp/ip_quality_ip_api_mobile
        proxy=$(echo "$context4" | grep -o '"proxy":[^,}]*' | sed 's/.*://;s/"//g')
        tp2=$(translate_status ${proxy})
        echo "$tp2" >>/tmp/ip_quality_ip_api_proxy
        hosting=$(echo "$context4" | grep -o '"hosting":[^,}]*' | sed 's/.*://;s/"//g')
        tp3=$(translate_status ${hosting})
        echo "$tp3" >>/tmp/ip_quality_ip_api_datacenter
    fi
}

# ipwhois数据库 ⑦
ipwhois() {
    local ip="$1"
    rm -rf /tmp/ip_quality_ipwhois*
    local url="https://ipwhois.app/widget.php?ip=${ip}&lang=en"
    local response=$(curl -s -X GET "$url" \
        -H "Host: ipwhois.app" \
        -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/116.0" \
        -H "Accept: */*" \
        -H "Accept-Language: zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2" \
        -H "Accept-Encoding: gzip, deflate, br" \
        -H "Origin: https://ipwhois.io" \
        -H "Connection: keep-alive" \
        -H "Referer: https://ipwhois.io/" \
        -H "Sec-Fetch-Dest: empty" \
        -H "Sec-Fetch-Mode: cors" \
        -H "Sec-Fetch-Site: cross-site")
    if [[ "$?" -ne 0 ]]; then
        return
    fi
    security_section=$(echo "$response" | grep -o '"security":{[^}]*}')
    anonymous=$(echo "$security_section" | awk -F'"anonymous":' '{print $2}' | cut -d',' -f1)
    proxy=$(echo "$security_section" | awk -F'"proxy":' '{print $2}' | cut -d',' -f1)
    vpn=$(echo "$security_section" | awk -F'"vpn":' '{print $2}' | cut -d',' -f1)
    tor=$(echo "$security_section" | awk -F'"tor":' '{print $2}' | cut -d',' -f1)
    hosting=$(echo "$security_section" | awk -F'"hosting":' '{print $2}' | cut -d',' -f1 | sed 's/}//')
    echo "$anonymous" >>/tmp/ip_quality_ipwhois_anonymous
    echo "$proxy" >>/tmp/ip_quality_ipwhois_proxy
    echo "$vpn" >>/tmp/ip_quality_ipwhois_vpn
    echo "$tor" >>/tmp/ip_quality_ipwhois_tor
    echo "$hosting" >>/tmp/ip_quality_ipwhois_hosting
}

# ipregistry数据库 ⑧
ipregistry() {
    rm -rf /tmp/ip_quality_ipregistry*
    local ip="$1"
    local api_keys=(
        "ing7l12cxp6jaahw"
        "r208izz0q0icseks"
        "szh9vdbsf64ez2bk"
        "vum97powo0pxshko"
        "m7irmmf8ey12rx7o"
        "nd2chql8jm9f7gxa"
        "9mbbr52gsds5xtyb"
        "0xjh6xmh6j0jwsy6"
    )
    local api_key=${api_keys[$RANDOM % ${#api_keys[@]}]}
    local response
    response=$(curl -sL -H "Origin: https://ipregistry.co" -H "Referer: https://ipregistry.co" --header "Content-Type: application/json" -m 10 "https://api.ipregistry.co/${ip}?hostname=true&key=sb69ksjcajfs4c" 2>/dev/null)
    if [ $? -ne 0 ]; then
        response=$(curl -sL -m 10 "https://api.ipregistry.co/${ip}?key=${api_keys}" 2>/dev/null)
    fi
    local company_type=$(echo "$response" | grep -oE '"company":\{"domain":"[^"]+","name":"[^"]+","type":"[^"]+"}' | sed 's/.*"type":"\([^"]*\)".*/\1/')
    local connection_type=$(echo "$response" | grep -oE '"connection":\{"asn":[0-9]+,"domain":"[^"]+","organization":"[^"]+","route":"[^"]+","type":"[^"]+"}' | sed 's/.*"type":"\([^"]*\)".*/\1/')
    local abuser=$(echo "$response" | grep -o '"is_abuser":[a-zA-Z]*' | awk -F':' '{print $2}')
    local attacker=$(echo "$response" | grep -o '"is_attacker":[a-zA-Z]*' | awk -F':' '{print $2}')
    local bogon=$(echo "$response" | grep -o '"is_bogon":[a-zA-Z]*' | awk -F':' '{print $2}')
    local cloud_provider=$(echo "$response" | grep -o '"is_cloud_provider":[a-zA-Z]*' | awk -F':' '{print $2}')
    local proxy=$(echo "$response" | grep -o '"is_proxy":[a-zA-Z]*' | awk -F':' '{print $2}')
    local relay=$(echo "$response" | grep -o '"is_relay":[a-zA-Z]*' | awk -F':' '{print $2}')
    local tor=$(echo "$response" | grep -o '"is_tor":[a-zA-Z]*' | awk -F':' '{print $2}')
    local tor_exit=$(echo "$response" | grep -o '"is_tor_exit":[a-zA-Z]*' | awk -F':' '{print $2}')
    local vpn=$(echo "$response" | grep -o '"is_vpn":[a-zA-Z]*' | awk -F':' '{print $2}')
    local anonymous=$(echo "$response" | grep -o '"is_anonymous":[a-zA-Z]*' | awk -F':' '{print $2}')
    local threat=$(echo "$response" | grep -o '"is_threat":[a-zA-Z]*' | awk -F':' '{print $2}')
    echo "$company_type" >/tmp/ip_quality_ipregistry_company_type
    echo "$connection_type" >/tmp/ip_quality_ipregistry_usage_type
    echo "$abuser" >/tmp/ip_quality_ipregistry_abuser
    echo "$attacker" >/tmp/ip_quality_ipregistry_attacker
    echo "$bogon" >/tmp/ip_quality_ipregistry_bogon
    echo "$cloud_provider" >/tmp/ip_quality_ipregistry_cloud_provider
    echo "$proxy" >/tmp/ip_quality_ipregistry_proxy
    echo "$relay" >/tmp/ip_quality_ipregistry_icloud_relay
    echo "$tor" >/tmp/ip_quality_ipregistry_tor
    echo "$tor_exit" >/tmp/ip_quality_ipregistry_tor_exit
    echo "$vpn" >/tmp/ip_quality_ipregistry_vpn
    echo "$anonymous" >/tmp/ip_quality_ipregistry_anonymous
    echo "$threat" >/tmp/ip_quality_ipregistry_threat
}

# ipdata数据库 ⑨
ipdata() {
    rm -rf /tmp/ip_quality_ipdata*
    local ip="$1"
    local api_keys=(
        "47c090ef820c47af56b382bb08ba863dbd84a0b10b80acd0dd8deb48"
        "c6d4d04d5f11f2cd0839ee03c47c58621d74e361c945b5c1b4f668f3"
    )
    local api_key=${api_keys[$RANDOM % ${#api_keys[@]}]}
    response=$(curl -sL -m 10 "https://api.ipdata.co/${ip}?api-key=${api_key}" 2>/dev/null)
    local usage_type=$(echo "$response" | grep -o '"type": "[^"]*' | cut -d'"' -f4)
    local tor=$(grep -o '"is_tor": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local icloud_relay=$(grep -o '"is_icloud_relay": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local proxy=$(grep -o '"is_proxy": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local datacenter=$(grep -o '"is_datacenter": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local anonymous=$(grep -o '"is_anonymous": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local attacker=$(grep -o '"is_known_attacker": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local abuser=$(grep -o '"is_known_abuser": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local threat=$(grep -o '"is_threat": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local bogon=$(grep -o '"is_bogon": \w\+' <<<"$response" | cut -d ' ' -f 2)
    echo "$usage_type" >/tmp/ip_quality_ipdata_usage_type
    echo "$tor" >/tmp/ip_quality_ipdata_tor
    echo "$icloud_relay" >/tmp/ip_quality_ipdata_icloud_relay
    echo "$proxy" >/tmp/ip_quality_ipdata_proxy
    echo "$datacenter" >/tmp/ip_quality_ipdata_datacenter
    echo "$anonymous" >/tmp/ip_quality_ipdata_anonymous
    echo "$attacker" >/tmp/ip_quality_ipdata_attacker
    echo "$abuser" >/tmp/ip_quality_ipdata_abuser
    echo "$threat" >/tmp/ip_quality_ipdata_threat
    echo "$bogon" >/tmp/ip_quality_ipdata_bogon
}

# ipgeolocation数据库 ⑩
ipgeolocation() {
    rm -rf /tmp/ip_quality_ipgeolocation*
    local ip="$1"
    local api_keys=(
        "0d4f60641cd9b95ff5ac9b4d866a0655"
        "7C5384E65E3B5B520A588FB8F9281719"
        "4E191A613023EA66D24E35E41C870D3B"
        "3D07E2EAAF55940AF44734C3F2AC7C1A"
        "32D24DBFB5C3BFFDEF5FE9331F93BA5B"
        "28cc35ee8608480fa7087be0e435320c"
    )
    local api_key=${api_keys[$RANDOM % ${#api_keys[@]}]}
    local response=$(curl -sL -m 10 "https://api.ip2location.io/?key=${api_key}&ip=${ip}" 2>/dev/null)
    local is_proxy=$(echo "$response" | grep -o '"is_proxy":\s*false\|true' | cut -d ":" -f2)
    is_proxy=$(echo "$is_proxy" | tr -d '"')
    echo "$is_proxy" >/tmp/ip_quality_ipgeolocation_proxy
}

google() {
    local curl_result=$(curl -sL -m 10 "https://www.google.com/search?q=www.spiritysdx.top" -H "User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:54.0) Gecko/20100101 Firefox/54.0")
    rm -rf /tmp/ip_quality_google
    if echo "$curl_result" | grep -q "二叉树的博客"; then
        echo "Google搜索可行性：YES" >>/tmp/ip_quality_google
    else
        echo "Google搜索可行性：NO" >>/tmp/ip_quality_google
    fi
}

local_port_25() {
    local host=$1
    local port=$2
    rm -rf /tmp/ip_quality_local_port_25
    nc -z -w5 $host $port >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "  本地: Yes" >>/tmp/ip_quality_local_port_25
    else
        echo "  本地: No" >>/tmp/ip_quality_local_port_25
    fi
}

check_email_service() {
    local service=$1
    local host=""
    local port=25
    local expected_response="220"
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
    local response=$(echo -e "QUIT\r\n" | nc -w6 $host $port 2>/dev/null)
    if [[ $response == *"$expected_response"* ]]; then
        echo "  $service: Yes" >>/tmp/ip_quality_check_email_service
    else
        echo "  $service：No" >>/tmp/ip_quality_check_email_service
    fi
}

combine_result_of_ip_quality() {
    check_and_cat_file /tmp/ip_quality_local_port_25 >>/tmp/ip_quality_check_port_25
    check_and_cat_file /tmp/ip_quality_check_email_service >>/tmp/ip_quality_check_port_25
}

check_port_25() {
    rm -rf /tmp/ip_quality_check_port_25
    rm -rf /tmp/ip_quality_check_email_service
    rm -rf /tmp/ip_quality_local_port_25
    echo "端口25检测:" >>/tmp/ip_quality_check_port_25
    { local_port_25 "localhost" 25; } &
    check_email_service "163邮箱"
    if [[ $(cat /tmp/ip_quality_check_email_service) == *"No"* ]]; then
        wait
        combine_result_of_ip_quality
        return
    else
        check_email_service "gmail邮箱"
        if [[ $(cat /tmp/ip_quality_check_email_service) == *"No"* ]]; then
            wait
            combine_result_of_ip_quality
            return
        else
            { check_email_service "outlook邮箱"; } &
            { check_email_service "yandex邮箱"; } &
            { check_email_service "qq邮箱"; } &
        fi
    fi
    wait
    combine_result_of_ip_quality
}

ipcheck() {
    _blue "以下为各数据库编号，输出结果后将自带数据库来源对应的编号"
    _blue "ipinfo数据库 ①  | scamalytics数据库 ②  | virustotal数据库 ③  | abuseipdb数据库 ④  | ip2location数据库   ⑤"
    _blue "ip-api数据库 ⑥  | ipwhois数据库     ⑦  | ipregistry数据库 ⑧  | ipdata数据库    ⑨  | ipgeolocation数据库 ⑩"
    local ip4=$(echo "$IPV4" | tr -d '\n')
    local ip6=$(echo "$IPV6" | tr -d '\n')
    if [[ -z "${ip4}" ]] && [[ ! -z "${ip6}" ]]; then
        echo "以下为IPV6检测"
    fi
    { ipinfo "$ip4"; } &
    { scamalytics_ipv4 "$ip4"; } &
    { virustotal "$ip4"; } &
    { abuse_ipv4 "$ip4"; } &
    { ipapi "$ip4"; } &
    { ipwhois "$ip4"; } &
    { ipregistry "$ip4"; } &
    { ipdata "$ip4"; } &
    { ipgeolocation "$ip4"; } &
    { google; } &
    if command -v nc >/dev/null; then
        { check_port_25; } &
    fi
    if [[ -n "$ip6" ]]; then
        { scamalytics_ipv6 "$ip6"; } &
        { abuse_ipv6 "$ip6"; } &
    fi
    wait
    # 预处理部分类型
    rm -rf /tmp/ip_quality_scamalytics_ipv4_proxy
    local public_proxy_4=$(check_and_cat_file '/tmp/ip_quality_scamalytics_ipv4_public_proxy')
    local web_proxy_4=$(check_and_cat_file '/tmp/ip_quality_scamalytics_ipv4_web_proxy')
    if [ -n "$public_proxy_4" ] && [ -n "$web_proxy_4" ]; then
        if [ "$public_proxy_4" = "Yes" ] || [ "$web_proxy_4" = "Yes" ]; then
            echo "Yes" >/tmp/ip_quality_scamalytics_ipv4_proxy
        else
            echo "No" >/tmp/ip_quality_scamalytics_ipv4_proxy
        fi
    fi
    local score_2_4=$(check_and_cat_file '/tmp/ip_quality_scamalytics_ipv4_score')
    if [[ -n "$score_2_4" ]]; then
        echo "欺诈分数(越低越好): $score_2_4②"
    fi
    local score_4_4=$(check_and_cat_file '/tmp/ip_quality_abuseipdb_ipv4_score')
    if [[ -n "$score_4_4" ]]; then
        echo "abuse得分(越低越好): $score_4_4④"
    fi
    echo "IP类型: "
    local ip_quality_filename_data=("/tmp/ip_quality_ipinfo_" "/tmp/ip_quality_scamalytics_ipv4_" "/tmp/ip_quality_ip2location_ipv4_" "/tmp/ip_quality_ip_api_" "/tmp/ip_quality_ipwhois_" "/tmp/ip_quality_ipregistry_" "/tmp/ip_quality_ipdata_" "/tmp/ip_quality_ipgeolocation_")
    local serial_number=("①" "②" "⑤" "⑥" "⑦" "⑧" "⑨" "⑩")
    local project_data=("usage_type" "company_type" "cloud_provider" "datacenter" "mobile" "proxy" "vpn" "tor" "tor_exit" "search_engine_robot" "anonymous" "attacker" "abuser" "threat" "icloud_relay" "bogon")
    local project_translate_data=("使用类型" "公司类型" "云服务提供商" "数据中心" "移动网络" "代理" "VPN" "TOR" "TOR出口" "搜索引擎机器人" "匿名代理" "攻击方" "滥用者" "威胁" "iCloud中继" "未分配IP")
    declare -A project_translate
    for ((i = 0; i < ${#project_data[@]}; i++)); do
        project_translate[${project_data[i]}]=${project_translate_data[i]}
    done
    for project in "${project_data[@]}"; do
        content=""
        no_appear=0
        yes_appear=0
        for ((i = 0; i < ${#ip_quality_filename_data[@]}; i++)); do
            file_content=$(check_and_cat_file "${ip_quality_filename_data[i]}${project}")
            if [ -n "$file_content" ]; then
                if [ "$project" = "usage_type" ] || [ "$project" = "company_type" ]; then
                    content+="${file_content}${serial_number[i]}"
                    content+=" "
                else
                    file_status=$(translate_status ${file_content})
                    if [ "$file_status" = "No" ]; then
                        if [ $no_appear -eq 0 ]; then
                            content+="  "
                            content+="No"
                            no_appear=1
                        fi
                    elif [ "$file_status" = "Yes" ]; then
                        if [ $yes_appear -eq 0 ]; then
                            content+="  "
                            content+="Yes"
                            yes_appear=1
                        fi
                    fi
                    content+="${serial_number[i]}"
                fi
                content+=" "
            fi
        done
        if [ -n "$content" ]; then
            echo "  ${project_translate[$project]}(${project}):${content}"
        fi
    done
    local score_3_1=$(check_and_cat_file '/tmp/ip_quality_virustotal_harmlessness_records')
    local score_3_2=$(check_and_cat_file '/tmp/ip_quality_virustotal_malicious_records')
    local score_3_3=$(check_and_cat_file '/tmp/ip_quality_virustotal_suspicious_records')
    local score_3_4=$(check_and_cat_file '/tmp/ip_quality_virustotal_no_records')
    if [ -n "$score_3_1" ] && [ -n "$score_3_2" ] && [ -n "$score_3_3" ] && [ -n "$score_3_4" ]; then
        echo "黑名单记录统计(有多少个黑名单网站有记录): 无害$score_3_1 恶意$score_3_2 可疑$score_3_3 未检测$score_3_4 ③"
    fi
    check_and_cat_file "/tmp/ip_quality_google"
    check_and_cat_file "/tmp/ip_quality_check_port_25"
    if [[ ! -z "${ip6}" ]]; then
        if [[ ! -z "${ip4}" ]] && [[ ! -z "${ip6}" ]]; then
            echo "------以下为IPV6检测------"
        fi
        local score_2_6=$(check_and_cat_file '/tmp/ip_quality_scamalytics_ipv6_score')
        if [[ -n "$score_2_6" ]]; then
            echo "欺诈分数(越低越好): $score_2_6②"
        fi
        local score_4_6=$(check_and_cat_file '/tmp/ip_quality_abuseipdb_ipv6_score')
        if [[ -n "$score_4_6" ]]; then
            echo "abuse得分(越低越好): $score_4_6④"
        fi
        local usage_type_6=$(check_and_cat_file '/tmp/ip_quality_ip2location_ipv6_usage_type')
        if [[ -n "$usage_type_6" ]]; then
            echo "IP类型: $usage_type_6⑤"
        fi
    fi
    rm -rf /tmp/ip_quality_*
}

eo6s(){
    # 获取IPV6的子网掩码
    rm -rf $TEMP_DIR/eo6s_result
    local interface=$(ls /sys/class/net/ | grep -v "$(ls /sys/devices/virtual/net/)")
    local current_ipv6=$(curl -s -6 -m 5 ipv6.ip.sb)
    # echo ${current_ipv6}
    local new_ipv6="${current_ipv6%:*}:3"
    ip addr add ${new_ipv6}/128 dev ${interface}
    sleep 6
    local updated_ipv6=$(curl -s -6 -m 5 ipv6.ip.sb)
    # echo ${updated_ipv6}
    ip addr del ${new_ipv6}/128 dev ${interface}
    sleep 6
    local final_ipv6=$(curl -s -6 -m 5 ipv6.ip.sb)
    # echo ${final_ipv6}
    local ipv6_prefixlen=""
    local output=$(ifconfig ${interface} | grep -oP 'inet6 [^f][^e][^8][^0].*prefixlen \K\d+')
    local num_lines=$(echo "$output" | wc -l)
    if [ $num_lines -ge 2 ]; then
        ipv6_prefixlen=$(echo "$output" | sort -n | head -n 1)
    else
        ipv6_prefixlen=$(echo "$output" | head -n 1)
    fi
    if [ "$updated_ipv6" == "$current_ipv6" ] || [ -z "$updated_ipv6" ]; then
        echo "128">$TEMP_DIR/eo6s_result
    else
        echo "$ipv6_prefixlen">$TEMP_DIR/eo6s_result
    fi
}

cdn_urls=("https://cdn0.spiritlhl.top/" "http://cdn3.spiritlhl.net/" "http://cdn1.spiritlhl.net/" "https://ghproxy.com/" "http://cdn2.spiritlhl.net/")
ST="OvwKx5qgJtf7PZgCKbtyojSU.MTcwMTUxNzY1MTgwMw"
head='key: e88362808d1219e27a786a465a1f57ec3417b0bdeab46ad670432b7ce1a7fdec0d67b05c3463dd3c'
speedtest_ver="1.2.0"
SERVER_BASE_URL="https://raw.githubusercontent.com/spiritLHLS/speedtest.net-CN-ID/main"
SERVER_BASE_URL2="https://raw.githubusercontent.com/spiritLHLS/speedtest.cn-CN-ID/main"

pre_check() {
    check_update
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
    global_startup_init_action
    cd $myvar >/dev/null 2>&1
    ! _exists "wget" && _red "Error: wget command not found.\n" && exit 1
    check_china
    wait
    IPV4=$(check_and_cat_file /tmp/ip_quality_ipv4)
    IPV6=$(check_and_cat_file /tmp/ip_quality_ipv6)
    if [ -n "$IPV6" ] && [ -n "$IPV4" ]; then
        echo "正在检测和验证IPV6的子网掩码大小，大概需要10~15秒"
        eo6s &
    fi
    echo "请耐心等待后台任务执行完毕"
    check_haveged
    check_free
    check_lscpu
    check_unzip
    check_tar
    check_nc
    wait

}

sjlleo_script() {
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

cpu_script_with_sysbench(){
    echo "---------------------CPU测试--感谢lemonbench开源------------------------"
    Function_SysBench_CPU_Fast
    cd $myvar >/dev/null 2>&1
    sleep 1
}

cpu_script_with_geekbench4(){
    echo "-----------------CPU测试--感谢yabs开源geekbench4测试--------------------"
    mv $TEMP_DIR/yabs.sh ./
    local output=$(./yabs.sh -s -- -f -i -n -4 | tail -n +9)
    if [[ $output =~ "Single Core" ]]; then
        output=$(echo "$output" | grep -v 'curl' | sed '$d' | sed '$d' | sed '1,2d' )
        echo "$output"
    else
        echo "测试失败请替换另一种方式"
    fi
    cd $myvar >/dev/null 2>&1
    sleep 1
}

cpu_script_with_geekbench5(){
    echo "-----------------CPU测试--感谢yabs开源geekbench5测试--------------------"
    mv $TEMP_DIR/yabs.sh ./
    local output=$(./yabs.sh -s -- -f -i -n -5 | tail -n +9)
    if [[ $output =~ "Single Core" ]]; then
        output=$(echo "$output" | grep -v 'curl' | sed '$d' | sed '$d' | sed '1,2d')
        echo "$output"
    else
        echo "测试失败请替换另一种方式"
    fi
    cd $myvar >/dev/null 2>&1
    sleep 1
}

cpu_script_with_geekbench6(){
    echo "-----------------CPU测试--感谢yabs开源geekbench6测试--------------------"
    mv $TEMP_DIR/yabs.sh ./
    local output=$(./yabs.sh -s -- -f -i -n -6 | tail -n +9)
    if [[ $output =~ "Single Core" ]]; then
        output=$(echo "$output" | grep -v 'curl' | sed '$d' | sed '$d' | sed '1,2d')
        echo "$output"
    else
        echo "测试失败请替换另一种方式"
    fi
    cd $myvar >/dev/null 2>&1
    sleep 1
}

memory_script(){
    echo "---------------------内存测试--感谢lemonbench开源-----------------------"
    Function_SysBench_Memory_Fast
}

basic_script() {
    echo "---------------------基础信息查询--感谢所有开源项目---------------------"
    print_system_info
    print_ip_info
    # cpu和内存测试
    cd $myvar >/dev/null 2>&1
    sleep 1
    if [ "$test_base_status" = false ]; then
        if [ "$test_cpu_type" = "" ]; then
            cpu_script_with_sysbench
        elif [ "$test_cpu_type" = "gb4" ]; then
            cpu_script_with_geekbench4
        elif [ "$test_cpu_type" = "gb5" ]; then
            cpu_script_with_geekbench5
        elif [ "$test_cpu_type" = "gb6" ]; then
            cpu_script_with_geekbench6
        fi
        memory_script
    fi
}

io1_script() {
    cd $myvar >/dev/null 2>&1
    sleep 1
    echo "------------------磁盘dd读写测试--感谢lemonbench开源--------------------"
    Function_DiskTest_Fast
}

io2_script() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
    cd $myvar >/dev/null 2>&1
    mv $TEMP_DIR/yabsiotest.sh ./
    echo "---------------------磁盘fio读写测试--感谢yabs开源----------------------"
    bash yabsiotest.sh 2>/dev/null
    rm -rf yabsiotest.sh
}

RegionRestrictionCheck_script() {
    echo -e "----------------流媒体解锁--感谢RegionRestrictionCheck开源--------------"
    _yellow " 以下为IPV4网络测试，若无IPV4网络则无输出"
    echo 0 | bash media_lmc_check.sh -M 4 2>/dev/null | grep -A999999 '============\[ Multination \]============' | sed '/=======================================/q'
    _yellow " 以下为IPV6网络测试，若无IPV6网络则无输出"
    echo 0 | bash media_lmc_check.sh -M 6 2>/dev/null | grep -A999999 '============\[ Multination \]============' | sed '/=======================================/q'
}

lmc999_script() {
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

spiritlhl_script() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
    cd $myvar >/dev/null 2>&1
    echo -e "-------------------欺诈分数以及IP质量检测--本脚本原创-------------------"
    _yellow "数据仅作参考，不代表100%准确，如果和实际情况不一致请手动查询多个数据库比对"
    ipcheck
}

backtrace_script() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
    cd $myvar >/dev/null 2>&1
    if [ -f "${TEMP_DIR}/backtrace" ]; then
        chmod 777 ${TEMP_DIR}/backtrace
        curl_output=$(${TEMP_DIR}/backtrace 2>&1)
    else
        return
    fi
    echo -e "----------------三网回程--感谢zhanghanyun/backtrace开源-----------------"
    grep -sq 'sendto: network is unreachable' <<<$curl_output && _yellow "纯IPV6网络无法查询" || echo "${curl_output}" | grep -v 'github.com/zhanghanyun/backtrace' | grep -v '正在测试' | grep -v '测试完成' | grep -v 'json decode err'
}

fscarmen_route_script() {
    [ "${Var_OSRelease}" = "freebsd" ] && return
    cd $myvar >/dev/null 2>&1
    echo -e "---------------------回程路由--感谢fscarmen开源及PR---------------------"
    rm -f /tmp/ecs/ip.test
    if [ "$swhc_mode" = false ]; then
        local test_area=("你本地的IPV4地址")
        local test_ip=("$target_ipv4")
    elif [ -n "$route_location" ]; then
        local test_area
        local test_ip
        declare -n test_area="test_area_$route_location"
        declare -n test_ip="test_ip_$route_location"
    else
        local test_area=("${!1}")
        local test_ip=("${!2}")
    fi
    local ip4=$(echo "$IPV4" | tr -d '\n')
    local ip6=$(echo "$IPV6" | tr -d '\n')
    if [[ ! -z "${ip4}" ]]; then
        if [ "$swhc_mode" = false ]; then
            _green "核心程序来自ipip.net或nexttrace，请知悉!" >/tmp/ecs/ip.test
        else
            _green "依次测试电信/联通/移动经过的地区及线路，核心程序来自ipip.net或nexttrace，请知悉!" >/tmp/ecs/ip.test
        fi
        for ((a = 0; a < ${#test_area[@]}; a++)); do
            "$TEMP_DIR/$BESTTRACE_FILE" "${test_ip[a]}" -g cn 2>/dev/null | sed "s/^[ ]//g" | sed "/^[ ]/d" | sed '/ms/!d' | sed "s#.* \([0-9.]\+ ms.*\)#\1#g" >>/tmp/ip_temp
            if [ ! -s "/tmp/ip_temp" ] || grep -q "http: 403" /tmp/ip_temp || grep -q "error" /tmp/ip_temp 2>/dev/null; then
                rm -rf /tmp/ip_temp
                RESULT=$("$TEMP_DIR/$NEXTTRACE_FILE" "${test_ip[a]}" --color 2>/dev/null)
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
            fi
            if [ "$swhc_mode" = false ]; then
                ori_ipv4="${test_ip[a]}"
                IFS='.' read -ra parts <<<"$ori_ipv4"
                if [ "${#parts[@]}" -ge 2 ]; then
                    parts[2]="xxx"
                    parts[3]="xxx"
                    new_ipv4="${parts[0]}.${parts[1]}.${parts[2]}.${parts[3]}"
                    _yellow "${test_area[a]} $new_ipv4" >>/tmp/ecs/ip.test
                else
                    _yellow "${test_area[a]} xxx.xxx.xxx.xxx" >>/tmp/ecs/ip.test
                fi
            else
                _yellow "${test_area[a]} ${test_ip[a]}" >>/tmp/ecs/ip.test
            fi
            cat /tmp/ip_temp >>/tmp/ecs/ip.test
            rm -rf /tmp/ip_temp
        done
    elif [[ -n "$ip6" ]]; then
        _green "依次测试电信/联通/移动经过的地区及线路，核心程序来自nexttrace，请知悉!" >/tmp/ecs/ip.test
        for ((a = 0; a < ${#test_area_6[@]}; a++)); do
            rm -rf /tmp/ip_temp
            RESULT=$("$TEMP_DIR/$NEXTTRACE_FILE" "${test_ip_6[a]}" --color 2>/dev/null)
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
    s_time=$(date +%s)
    rm -rf ./speedtest-cli/speedlog.txt
    speed | tee ./speedtest-cli/speedlog.txt
    e_time=$(date +%s)
    time=$((${e_time} - ${s_time}))
    if ! grep -qE "(Speedtest.net|洛杉矶|新加坡|香港|联通|电信|移动|日本|中国)" ./speedtest-cli/speedlog.txt; then
        export speedtest_ver="1.0.0"
        rm -rf ./speedtest-cli/speedlog.txt
        rm -rf ./speedtest-cli*
        (install_speedtest >/dev/null 2>&1)
        speed
    fi
    rm -fr speedtest-cli
}

ecs_net_minal_script() {
    cd $myvar >/dev/null 2>&1
    s_time=$(date +%s)
    rm -rf ./speedtest-cli/speedlog.txt
    speed2 | tee ./speedtest-cli/speedlog.txt
    e_time=$(date +%s)
    time=$((${e_time} - ${s_time}))
    if ! grep -qE "(Speedtest.net|洛杉矶|新加坡|香港|联通|电信|移动|日本|中国)" ./speedtest-cli/speedlog.txt; then
        export speedtest_ver="1.0.0"
        rm -rf ./speedtest-cli/speedlog.txt
        rm -rf ./speedtest-cli*
        (install_speedtest >/dev/null 2>&1)
        speed2
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
            dfiles=(yabsiotest yabs dp nf tubecheck media_lmc_check besttrace nexttrace backtrace)
            for dfile in "${dfiles[@]}"; do
                { pre_download ${dfile}; } &
            done
            get_system_info
            check_dnsutils
            check_ping
            ls_sg_hk_jp=($(get_nearest_data "${SERVER_BASE_URL}/ls_sg_hk_jp.csv"))
            CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
            CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
            CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
            _yellow "checking speedtest" && install_speedtest &
            check_lmc_script &
            clear
            print_intro
            basic_script
            wait
            ecs_net_all_script >${TEMP_DIR}/ecs_net_output.txt &
            if [ "$test_disk_type" = "" ]; then
                io1_script
                sleep 0.5
                io2_script
            elif [ "$test_disk_type" = "dd" ]; then
                io1_script
            elif [ "$test_disk_type" = "fio" ]; then
                io2_script
            fi
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
            dfiles=(ecsspeed_ping)
            for dfile in "${dfiles[@]}"; do
                { pre_download ${dfile}; } &
            done
            get_system_info
            check_dnsutils
            check_ping
            ls_sg_hk_jp=($(get_nearest_data "${SERVER_BASE_URL}/ls_sg_hk_jp.csv"))
            CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
            CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
            CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
            _yellow "checking speedtest" && install_speedtest &
            check_lmc_script &
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
        if [[ -z "${CN}" || "${CN}" != true ]]; then
            pre_download yabsiotest yabs dp nf tubecheck media_lmc_check besttrace nexttrace backtrace
            get_system_info
            check_dnsutils
            check_ping
            ls_sg_hk_jp=($(get_nearest_data "${SERVER_BASE_URL}/ls_sg_hk_jp.csv"))
            CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
            CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
            CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
            _yellow "checking speedtest" && install_speedtest
            check_lmc_script
            clear
            print_intro
            basic_script
            if [ "$test_disk_type" = "" ]; then
                io1_script
                sleep 0.5
                io2_script
            elif [ "$test_disk_type" = "dd" ]; then
                io1_script
            elif [ "$test_disk_type" = "fio" ]; then
                io2_script
            fi
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
            check_dnsutils
            check_ping
            ls_sg_hk_jp=($(get_nearest_data "${SERVER_BASE_URL}/ls_sg_hk_jp.csv"))
            CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
            CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
            CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
            _yellow "checking speedtest" && install_speedtest
            check_lmc_script
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

minal_script() {
    pre_check
    get_system_info
    pre_download yabsiotest yabs
    check_ping
    CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
    CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
    CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
    _yellow "checking speedtest" && install_speedtest
    clear
    print_intro
    basic_script
    io2_script
    ecs_net_minal_script
    end_script
}

minal_plus() {
    pre_check
    pre_download yabsiotest yabs dp nf tubecheck media_lmc_check besttrace nexttrace backtrace
    get_system_info
    check_lmc_script
    check_dnsutils
    check_ping
    CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
    CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
    CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
    _yellow "checking speedtest" && install_speedtest
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

minal_plus_network() {
    pre_check
    pre_download yabsiotest yabs besttrace nexttrace backtrace
    get_system_info
    check_ping
    CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
    CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
    CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
    _yellow "checking speedtest" && install_speedtest
    clear
    print_intro
    basic_script
    io2_script
    backtrace_script
    fscarmen_route_script test_area_g[@] test_ip_g[@]
    ecs_net_minal_script
    end_script
}

minal_plus_media() {
    pre_check
    pre_download yabsiotest yabs dp nf tubecheck media_lmc_check
    get_system_info
    check_dnsutils
    check_lmc_script
    check_ping
    CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
    CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
    CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
    _yellow "checking speedtest" && install_speedtest
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

network_script() {
    pre_check
    pre_download besttrace nexttrace backtrace
    check_ping
    ls_sg_hk_jp=($(get_nearest_data "${SERVER_BASE_URL}/ls_sg_hk_jp.csv"))
    CN_Unicom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Unicom.csv"))
    CN_Telecom=($(get_nearest_data "${SERVER_BASE_URL}/CN_Telecom.csv"))
    CN_Mobile=($(get_nearest_data "${SERVER_BASE_URL}/CN_Mobile.csv"))
    _yellow "checking speedtest" && install_speedtest
    clear
    print_intro
    spiritlhl_script
    backtrace_script
    fscarmen_route_script test_area_g[@] test_ip_g[@]
    # fscarmen_port_script
    ecs_net_all_script
    end_script
}

media_script() {
    pre_check
    pre_download dp nf tubecheck media_lmc_check
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
    pre_download yabsiotest yabs
    get_system_info
    clear
    print_intro
    basic_script
    if [ "$test_base_status" = false ]; then
        if [ "$test_disk_type" = "" ]; then
            io1_script
            sleep 0.5
            io2_script
        elif [ "$test_disk_type" = "dd" ]; then
            io1_script
        elif [ "$test_disk_type" = "fio" ]; then
            io2_script
        fi
    fi
    end_script
}

port_script() {
    pre_check
    pre_download XXXX
    get_system_info
    clear
    print_intro
    # fscarmen_port_script
    end_script
}

sw_script() {
    pre_check
    pre_download besttrace nexttrace backtrace ecsspeed_ping
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
    pre_download besttrace nexttrace
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
    rm -rf dp
    rm -rf nf
    rm -rf tubecheck
    rm -rf besttrace
    rm -rf nexttrace
    rm -rf LemonBench.Result.txt*
    rm -rf speedtest.log*
    rm -rf test
    rm -rf yabsiotest.sh*
    rm -rf yabs.sh*
    rm -rf speedtest.tgz*
    rm -rf speedtest.tar.gz*
    rm -rf speedtest-cli*
    rm -rf geekbench_claim.url*
}

build_text() {
    cd $myvar >/dev/null 2>&1
    if { [ -n "${menu_mode}" ] && [ "${menu_mode}" = false ]; } || { [ -n "${StartInput}" ] && [ "${StartInput}" -eq 1 ]; } || { [ -n "${StartInput}" ] && [ "${StartInput}" -eq 2 ]; } || { [ -n "${StartInput1}" ] && [ "${StartInput1}" -ge 1 ] && [ "${StartInput1}" -le 4 ]; }; then
        sed -i -e '1,/-------------------- A Bench Script By spiritlhl ---------------------/d' test_result.txt
        # 下面这个删除在FreeBSD中也删的不干净
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
        if [ -s test_result.txt ]; then
            if grep -q -- "---------------------磁盘fio读写测试--感谢yabs开源----------------------" "test_result.txt"; then
                sed -i '/---------------------磁盘fio读写测试--感谢yabs开源----------------------/a Block Size | 4k            (IOPS) | 64k           (IOPS)' "test_result.txt"
            fi
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
        bash <(curl -L -Lso- https://cdn.jsdelivr.net/gh/misaka-gh/misakabench@master/misakabench.sh)
        break_status=true
        ;;
    4)
        curl -sL yabs.sh | bash
        break_status=true
        ;;
    5)
        wget -qO- bench.sh | bash
        break_status=true
        ;;
    6)
        bash <(wget -qO- git.io/ceshi)
        break_status=true
        ;;
    7)
        wget -N --no-check-certificate https://raw.githubusercontent.com/FunctionClub/ZBench/master/ZBench-CN.sh && bash ZBench-CN.sh
        break_status=true
        ;;
    8)
        wget --no-check-certificate https://raw.githubusercontent.com/teddysun/across/master/unixbench.sh && chmod +x unixbench.sh && ./unixbench.sh
        break_status=true
        ;;
    0)
        original_script
        break_status=true
        ;;
    *) 
        echo "输入错误，请重新输入"
        break_status=false
        ;;
    esac
}

comprehensive_test_script() {
    head_script
    if $menu_mode; then
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
        while true; do
            read -rp "请输入选项:" StartInputc
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
        echo "输入错误，请重新输入"
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
            read -rp "请输入选项:" StartInputm
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
        bash <(curl -sSL https://raw.githubusercontent.com/spiritLHLS/ecs/main/return.sh)
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
        curl -sL network-speed.xyz | bash
        break_status=true
        ;;
    12)
        bash <(wget -qO- bash.spiritlhl.net/ecs-net)
        break_status=true
        ;;
    13)
        bash <(wget -qO- bash.spiritlhl.net/ecs-cn)
        break_status=true
        ;;
    14)
        bash <(wget -qO- bash.spiritlhl.net/ecs-ping)
        break_status=true
        ;;
    0)
        original_script
        break_status=true
        ;;
    *) 
        echo "输入错误，请重新输入"
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
        while true; do
            read -rp "请输入选项:" StartInputn
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
        echo "输入错误，请重新输入"
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
            read -rp "请输入选项:" StartInputh
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
        echo "输入错误，请重新输入"
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
            read -rp "请输入选项:" StartInput3
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
        echo "输入错误，请重新输入"
        break_status=false
        ;;
    esac
}

simplify_script() {
    head_script
    if $menu_mode; then
        _yellow "融合怪的精简脚本如下"
        echo -e "${GREEN}1.${PLAIN} 极简版(系统信息+CPU+内存+磁盘IO+测速节点4个)(平均运行3分钟)"
        echo -e "${GREEN}2.${PLAIN} 精简版(系统信息+CPU+内存+磁盘IO+御三家解锁+常用流媒体+TikTok+回程+路由+测速节点4个)(平均运行4分钟)"
        echo -e "${GREEN}3.${PLAIN} 精简网络版(系统信息+CPU+内存+磁盘IO+回程+路由+测速节点4个)(平均运行4分钟)"
        echo -e "${GREEN}4.${PLAIN} 精简解锁版(系统信息+CPU+内存+磁盘IO+御三家解锁+常用流媒体+TikTok+测速节点4个)(平均运行4分钟)"
        echo " -------------"
        echo -e "${GREEN}0.${PLAIN} 回到主菜单"
        echo ""
        while true; do
            read -rp "请输入选项:" StartInput1
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
        bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/qzcheck.sh)
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
        echo "输入错误，请重新输入"
        break_status=false
        ;;
    esac
}

single_item_script() {
    head_script
    if $menu_mode; then
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
        while true; do
            read -rp "请输入选项:" StartInput2
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
        bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/qzcheck.sh)
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
        bash <(curl -sSL https://github.com/spiritLHLS/ecs/raw/main/return.sh)
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
    0)
        start_script
        break_status=true
        ;;
    *) 
        echo "输入错误，请重新输入"
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
        while true; do
            read -rp "请输入选项:" StartInput4
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
    echo "#############################################################"
    echo -e "#                     ${YELLOW}融合怪测评脚本${PLAIN}                        #"
    echo "# 版本(请注意比对仓库版本更新)：$ver                  #"
    echo "# 更新日志：$changeLog                       #"
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
        echo "输入错误，请重新输入"
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
        echo -e "${GREEN}1.${PLAIN} 顺序测试--融合怪完全体(所有项目都测试)(平均运行7分钟)(机器普通推荐使用)"
        echo -e "${GREEN}2.${PLAIN} 并行测试--融合怪完全体(所有项目都测试)(平均运行5分钟)(仅机器强劲可使用，机器普通勿要使用)"
        echo -e "${GREEN}3.${PLAIN} 融合怪精简区(融合怪的精简版或单项测试精简版)"
        echo -e "${GREEN}4.${PLAIN} 融合怪单项区(融合怪的单项测试完整版)"
        echo -e "${GREEN}5.${PLAIN} 第三方脚本区(同类作者的各种测试脚本)"
        echo -e "${GREEN}6.${PLAIN} 原创区(本脚本独有的一些测试脚本)"
        echo -e "${GREEN}7.${PLAIN} 更新本脚本"
        echo " -------------"
        echo -e "${GREEN}0.${PLAIN} 退出"
        echo ""
        while true; do
            read -rp "请输入选项:" StartInput
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
statistics_of_run-times
start_script
global_exit_action
rm_script

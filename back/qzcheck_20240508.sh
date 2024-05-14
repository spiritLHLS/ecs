#!/usr/bin/env bash
#by spiritlhl
#from https://github.com/spiritLHLS/ecs

cd /root >/dev/null 2>&1
myvar=$(pwd)
ver="2024.05.14"
changeLog="IP质量测试，由频道 https://t.me/vps_reviews 原创"
temp_file_apt_fix="/tmp/apt_fix.txt"
shorturl=""
REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "alpine")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Alpine")
PACKAGE_UPDATE=("apt -y update" "apt -y update" "yum -y update" "yum -y update" "apk update -f")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "apk add -f")
CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")
utf8_locale=$(locale -a 2>/dev/null | grep -i -m 1 -E "UTF-8|utf8")
if [[ -z "$utf8_locale" ]]; then
    echo "No UTF-8 locale found"
else
    export LC_ALL="$utf8_locale"
    export LANG="$utf8_locale"
    export LANGUAGE="$utf8_locale"
    echo "Locale set to $utf8_locale"
fi
for i in "${CMD[@]}"; do
    SYS="$i" && [[ -n $SYS ]] && break
done
for ((int = 0; int < ${#REGEX[@]}; int++)); do
    if [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]]; then
        SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
    fi
done
if [ ! -d "/tmp" ]; then
    mkdir /tmp
fi

red() {
    echo -e "\033[31m\033[01m$1\033[0m"
}
green() {
    echo -e "\033[32m\033[01m$1\033[0m"
}
yellow() {
    echo -e "\033[33m\033[01m$1\033[0m"
}
_red() { echo -e "\033[31m\033[01m$@\033[0m"; }
_green() { echo -e "\033[32m\033[01m$@\033[0m"; }
_yellow() { echo -e "\033[33m\033[01m$@\033[0m"; }
_blue() { echo -e "\033[36m\033[01m$@\033[0m"; }

trap _exit INT QUIT TERM
_exists() {
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

_exit() {
    _red "\n检测到退出操作，脚本终止！\n"
    # clean up
    rm -fr benchtest_*
    exit 1
}

checkroot() {
    [[ $EUID -ne 0 ]] && echo -e "${RED}请使用 root 用户运行本脚本！${PLAIN}" && exit 1
}

checkupdate() {
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

checkdnsutils() {
    _yellow "Installing dnsutils"
    if [ "${release}" == "centos" ]; then
        yum -y install dnsutils >/dev/null 2>&1
        yum -y install bind-utils >/dev/null 2>&1
    elif [ "${release}" == "arch" ]; then
        pacman -S --noconfirm --needed bind >/dev/null 2>&1
    else
        ${PACKAGE_INSTALL[int]} dnsutils >/dev/null 2>&1
    fi
}

checkcurl() {
    if ! which curl >/dev/null; then
        _yellow "Installing curl"
        ${PACKAGE_INSTALL[int]} curl
    fi
    if [ $? -ne 0 ]; then
        apt-get -f install >/dev/null 2>&1
        ${PACKAGE_INSTALL[int]} curl
    fi
}

checkwget() {
    if ! which wget >/dev/null; then
        _yellow "Installing wget"
        ${PACKAGE_INSTALL[int]} wget
    fi
}

checknc() {
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

print_intro() {
    echo "-------------------- A Bench Script By spiritlhl ---------------------"
    echo "                   测评频道: https://t.me/vps_reviews                    "
    echo "版本：$ver"
    echo "更新日志：$changeLog"
}

next() {
    echo -en "\r"
    [ "${Var_OSRelease}" = "freebsd" ] && printf "%-72s\n" "-" | tr ' ' '-' && return
    printf "%-72s\n" "-" | sed 's/\s/-/g'
}

print_end_time() {
    end_time=$(date +%s)
    time=$((${end_time} - ${start_time}))
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

is_private_ipv4() {
    local ip_address=$1
    local ip_parts
    if [[ -z $ip_address ]]; then
        return 0 # 输入为空
    fi
    IFS='.' read -r -a ip_parts <<<"$ip_address"
    # 检查IP地址是否符合内网IP地址的范围
    # 去除 回环，REC 1918，多播 地址
    if [[ ${ip_parts[0]} -eq 10 ]] ||
        [[ ${ip_parts[0]} -eq 172 && ${ip_parts[1]} -ge 16 && ${ip_parts[1]} -le 31 ]] ||
        [[ ${ip_parts[0]} -eq 192 && ${ip_parts[1]} -eq 168 ]] ||
        [[ ${ip_parts[0]} -eq 127 ]] ||
        [[ ${ip_parts[0]} -eq 0 ]] ||
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
    # 检查IPv6地址是否以fe80开头(链接本地地址)
    if [[ $address == fe80:* ]]; then
        temp="3"
    fi
    # 检查IPv6地址是否以fc00或fd00开头(唯一本地地址)
    if [[ $address == fc00:* || $address == fd00:* ]]; then
        temp="4"
    fi
    # 检查IPv6地址是否以2001:db8开头(文档前缀)
    if [[ $address == 2001:db8* ]]; then
        temp="5"
    fi
    # 检查IPv6地址是否以::1开头(环回地址)
    if [[ $address == ::1 ]]; then
        temp="6"
    fi
    # 检查IPv6地址是否以::ffff:开头(IPv4映射地址)
    if [[ $address == ::ffff:* ]]; then
        temp="7"
    fi
    # 检查IPv6地址是否以2002:开头(6to4隧道地址)
    if [[ $address == 2002:* ]]; then
        temp="8"
    fi
    # 检查IPv6地址是否以2001:开头(Teredo隧道地址)
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
        else
            local ipv4_asn_info="None"
            local ipv4_location="None"
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
    # 打印最终结果
    if [[ -n "$ipv4_asn_info" && "$ipv4_asn_info" != "None" ]]; then
        echo "IPV4 ASN : $(_blue "$ipv4_asn_info")"
    fi
    if [[ -n "$ipv4_location" && "$ipv4_location" != "None" ]]; then
        echo "IPV4 位置: $(_blue "$ipv4_location")"
    fi
    if [[ -n "$ipv6_asn_info" && "$ipv6_asn_info" != "None" ]]; then
        echo "IPV6 ASN : $(_blue "$ipv6_asn_info")"
    fi
    if [[ -n "$ipv6_location" && "$ipv6_location" != "None" ]]; then
        echo "IPV6 位置: $(_blue "$ipv6_location")"
    fi
}

check_and_cat_file() {
    # 检测到文件存在再输出
    local file="$1"
    if [[ -f "$file" ]]; then
        cat "$file"
    fi
}

ST="OvwKx5qgJtf7PZgCKbtyojSU.MTcwMTUxNzY1MTgwMw"

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
    local nlist=("vpn" "tor" "datacenter" "public_proxy" "web_proxy" "crawler")
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
    local nlist=("vpn" "tor" "datacenter" "public_proxy" "web_proxy" "crawler")
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
    local api_keys=()
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

# abuseipdb数据库 ④ IP2Location数据库 ⑤
abuse_ipv4() {
    local ip="$1"
    local score
    local usageType
    rm -rf /tmp/ip_quality_abuseipdb_ipv4*
    local api_heads=()
    local head=${api_heads[$RANDOM % ${#api_heads[@]}]}
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
    local api_heads=()
    local head=${api_heads[$RANDOM % ${#api_heads[@]}]}
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
ip_api() {
    local ip=$1
    local mobile
    local tp1
    local proxy
    local tp2
    local hosting
    local tp3
    rm -rf /tmp/ip_quality_ip_api*
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
    local url="https://ipwhois.io/widget?ip=${ip}&lang=en"
    local response=$(curl -s "$url" --compressed \
        -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0" \
        -H "Accept: */*" \
        -H "Accept-Language: zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2" \
        -H "Accept-Encoding: gzip, deflate, br" \
        -H "Connection: keep-alive" \
        -H "Referer: https://ipwhois.io/" \
        -H "Sec-Fetch-Dest: empty" \
        -H "Sec-Fetch-Mode: cors" \
        -H "Sec-Fetch-Site: same-origin" \
        -H "TE: trailers")
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
    local api_keys=()
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
    local api_keys=()
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
    local api_keys=()
    local api_key=${api_keys[$RANDOM % ${#api_keys[@]}]}
    local response=$(curl -sL -m 10 "https://api.ip2location.io/?key=${api_key}&ip=${ip}" 2>/dev/null)
    local is_proxy=$(echo "$response" | grep -o '"is_proxy":\s*false\|true' | cut -d ":" -f2)
    is_proxy=$(echo "$is_proxy" | tr -d '"')
    echo "$is_proxy" >/tmp/ip_quality_ipgeolocation_proxy
}

# ipapiis数据库 ⑪
ipapiis_ipv4() {
    rm -rf /tmp/ip_quality_ipapiis_ipv4_*
    local ip="$1"
    local response=$(curl -sL -m 10 "https://api.ipapi.is/?q=${ip}" 2>/dev/null)
    local company_type=$(echo "$response" | sed -n 's/.*"type": "\(.*\)".*/\1/p' | head -n 1)
    local usage_type=$(echo "$response" | sed -n 's/.*"type": "\(.*\)".*/\1/p' | tail -n 1)
    local abuser_score=$(echo "$response" | sed -n 's/.*"abuser_score": "\(.*\)".*/\1/p' | head -n 1)
    local bogon=$(grep -o '"is_bogon": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local mobile=$(grep -o '"is_mobile": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local crawler=$(grep -o '"is_crawler": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local datacenter=$(grep -o '"is_datacenter": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local tor=$(grep -o '"is_tor": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local proxy=$(grep -o '"is_proxy": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local vpn=$(grep -o '"is_vpn": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local abuser=$(grep -o '"is_abuser": \w\+' <<<"$response" | cut -d ' ' -f 2)
    echo "$company_type" >/tmp/ip_quality_ipapiis_ipv4_company_type
    echo "$usage_type" >/tmp/ip_quality_ipapiis_ipv4_usage_type
    echo "$abuser_score" >/tmp/ip_quality_ipapiis_ipv4_score
    echo "$bogon" >/tmp/ip_quality_ipapiis_ipv4_bogon
    echo "$mobile" >/tmp/ip_quality_ipapiis_ipv4_mobile
    echo "$crawler" >/tmp/ip_quality_ipapiis_ipv4_crawler
    echo "$datacenter" >/tmp/ip_quality_ipapiis_ipv4_datacenter
    echo "$tor" >/tmp/ip_quality_ipapiis_ipv4_tor
    echo "$proxy" >/tmp/ip_quality_ipapiis_ipv4_proxy
    echo "$vpn" >/tmp/ip_quality_ipapiis_ipv4_vpn
    echo "$abuser" >/tmp/ip_quality_ipapiis_ipv4_abuser
}

# ipapiis数据库 ⑪
ipapiis_ipv6() {
    rm -rf /tmp/ip_quality_ipapiis_ipv6_*
    local ip="$1"
    local response=$(curl -sL -m 10 "https://api.ipapi.is/?q=${ip}" 2>/dev/null)
    local company_type=$(echo "$response" | sed -n 's/.*"type": "\(.*\)".*/\1/p' | head -n 1)
    local usage_type=$(echo "$response" | sed -n 's/.*"type": "\(.*\)".*/\1/p' | tail -n 1)
    local abuser_score=$(echo "$response" | sed -n 's/.*"abuser_score": "\(.*\)".*/\1/p' | tail -n 1)
    # local bogon=$(grep -o '"is_bogon": \w\+' <<<"$response" | cut -d ' ' -f 2)
    # local mobile=$(grep -o '"is_mobile": \w\+' <<<"$response" | cut -d ' ' -f 2)
    # local crawler=$(grep -o '"is_crawler": \w\+' <<<"$response" | cut -d ' ' -f 2)
    # local datacenter=$(grep -o '"is_datacenter": \w\+' <<<"$response" | cut -d ' ' -f 2)
    # local tor=$(grep -o '"is_tor": \w\+' <<<"$response" | cut -d ' ' -f 2)
    # local proxy=$(grep -o '"is_proxy": \w\+' <<<"$response" | cut -d ' ' -f 2)
    # local vpn=$(grep -o '"is_vpn": \w\+' <<<"$response" | cut -d ' ' -f 2)
    # local abuser=$(grep -o '"is_abuser": \w\+' <<<"$response" | cut -d ' ' -f 2)
    echo "$company_type" >/tmp/ip_quality_ipapiis_ipv6_company_type
    echo "$usage_type" >/tmp/ip_quality_ipapiis_ipv6_usage_type
    echo "$abuser_score" >/tmp/ip_quality_ipapiis_ipv6_score
    # echo "$bogon" >/tmp/ip_quality_ipapiis_ipv6_bogon
    # echo "$mobile" >/tmp/ip_quality_ipapiis_ipv6_mobile
    # echo "$crawler" >/tmp/ip_quality_ipapiis_ipv6_crawler
    # echo "$datacenter" >/tmp/ip_quality_ipapiis_ipv6_datacenter
    # echo "$tor" >/tmp/ip_quality_ipapiis_ipv6_tor
    # echo "$proxy" >/tmp/ip_quality_ipapiis_ipv6_proxy
    # echo "$vpn" >/tmp/ip_quality_ipapiis_ipv6_vpn
    # echo "$abuser" >/tmp/ip_quality_ipapiis_ipv6_abuser
}

# ipapicom数据库 ⑫
ipapicom_ipv4() {
    rm -rf /tmp/ip_quality_ipapicom*
    local ip="$1"
    local response=$(curl -sL -m 10 "https://ipapi.com/ip_api.php?ip=${ip}" 2>/dev/null)
    local proxy=$(grep -o '"is_proxy": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local crawler=$(grep -o '"is_crawler": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local tor=$(grep -o '"is_tor": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local threat_level=$(grep -o '"threat_level": "[^"]\+"' <<<"$response" | cut -d '"' -f 4)
    echo "$crawler" >/tmp/ip_quality_ipapicom_ipv4_crawler
    echo "$tor" >/tmp/ip_quality_ipapicom_ipv4_tor
    echo "$proxy" >/tmp/ip_quality_ipapicom_ipv4_proxy
    echo "$threat_level" >/tmp/ip_quality_ipapicom_ipv4_threat_level
}

# ipapicom数据库 ⑫
ipapicom_ipv6() {
    rm -rf /tmp/ip_quality_ipapicom*
    local ip="$1"
    local response=$(curl -sL -m 10 "https://ipapi.com/ip_api.php?ip=${ip}" 2>/dev/null)
    local proxy=$(grep -o '"is_proxy": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local crawler=$(grep -o '"is_crawler": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local tor=$(grep -o '"is_tor": \w\+' <<<"$response" | cut -d ' ' -f 2)
    local threat_level=$(grep -o '"threat_level": "[^"]\+"' <<<"$response" | cut -d '"' -f 4)
    echo "$crawler" >/tmp/ip_quality_ipapicom_ipv6_crawler
    echo "$tor" >/tmp/ip_quality_ipapicom_ipv6_tor
    echo "$proxy" >/tmp/ip_quality_ipapicom_ipv6_proxy
    echo "$threat_level" >/tmp/ip_quality_ipapicom_ipv6_threat_level
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
    local ip4=$(echo "$IPV4" | tr -d '\n')
    local ip6=$(echo "$IPV6" | tr -d '\n')
    { ipapiis_ipv4 "$ip4"; } &
    { ipapicom_ipv4 "$ip4"; } &
    { scamalytics_ipv4 "$ip4"; } &
    { abuse_ipv4 "$ip4"; } &
    { google; } &
    { ipinfo "$ip4"; } &
    { virustotal "$ip4"; } &
    { ip_api "$ip4"; } &
    { ipwhois "$ip4"; } &
    { ipregistry "$ip4"; } &
    { ipdata "$ip4"; } &
    { ipgeolocation "$ip4"; } &
    if command -v nc >/dev/null; then
        { check_port_25; } &
    fi
    if [[ -n "$ip6" ]]; then
        { ipapiis_ipv6 "$ip6"; } &
        { ipapicom_ipv6 "$ip6"; } &
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
    # 得分和等级合并同一行
    local temp_text=""
    local score_2_4=$(check_and_cat_file '/tmp/ip_quality_scamalytics_ipv4_score')
    if [[ -z "$score_2_4" ]]; then
        temp_text+="欺诈分数(越低越好): $score_14_4⑪  "
    fi
    local score_4_4=$(check_and_cat_file '/tmp/ip_quality_abuseipdb_ipv4_score')
    local score_11_4=$(check_and_cat_file '/tmp/ip_quality_ipapiis_ipv4_score')
    if [[ -n "$score_4_4" && -n "$score_11_4" ]]; then
        temp_text+="abuse得分(越低越好): $score_4_4⑤  $score_11_4⑪  "
    elif [[ -n "$score_4_4" && -z "$score_11_4" ]]; then
        temp_text+="abuse得分(越低越好): $score_4_4⑤  "
    elif [[ -n "$score_11_4" && -z "$score_5_4" ]]; then
        temp_text+="abuse得分(越低越好): $score_11_4⑪  "
    fi
    local threat_12_4=$(check_and_cat_file '/tmp/ip_quality_ipapicom_ipv4_threat_level')
    if [[ -n "$threat_12_4" ]]; then
        temp_text+="威胁等级: $threat_12_4②  "
    fi
    echo "$temp_text"
    echo "IP类型: "
    local ip_quality_filename_data=("/tmp/ip_quality_ipinfo_" "/tmp/ip_quality_scamalytics_ipv4_" "/tmp/ip_quality_ip2location_ipv4_" "/tmp/ip_quality_ip_api_" "/tmp/ip_quality_ipwhois_" "/tmp/ip_quality_ipregistry_" "/tmp/ip_quality_ipdata_" "/tmp/ip_quality_ipgeolocation_" "/tmp/ip_quality_ipapiis_ipv4_" "/tmp/ip_quality_ipapicom_ipv4_")
    local serial_number=("①" "②" "⑤" "⑥" "⑦" "⑧" "⑨" "⑩" "⑪" "⑫" "⑬" "⑭")
    local project_data=("usage_type" "company_type" "cloud_provider" "datacenter" "mobile" "proxy" "vpn" "tor" "tor_exit" "crawler" "anonymous" "attacker" "abuser" "threat" "icloud_relay" "bogon")
    local project_translate_data=("使用类型" "公司类型" "云服务提供商" "数据中心" "移动网络" "代理" "VPN" "TOR" "TOR出口" "爬虫" "匿名代理" "攻击方" "滥用者" "威胁" "iCloud中继" "未分配IP")
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
    wait
    if [[ -n "$ip6" ]]; then
        echo "------以下为IPV6检测------"
        temp_text=""
        local score_2_6=$(check_and_cat_file '/tmp/ip_quality_scamalytics_ipv6_score')
        if [[ -n "$score_2_6" ]]; then
            temp_text+="欺诈分数(越低越好): $score_2_6②  "
        fi
        local score_4_6=$(check_and_cat_file '/tmp/ip_quality_abuseipdb_ipv6_score')
        local score_11_6=$(check_and_cat_file '/tmp/ip_quality_ipapiis_ipv6_score')
        if [[ -n "$score_4_6" && -n "$score_11_6" ]]; then
            temp_text+="abuse得分(越低越好): $score_4_6⑤  $score_11_6⑪  "
        elif [[ -n "$score_4_6" && -z "$score_11_6" ]]; then
            temp_text+="abuse得分(越低越好): $score_4_6⑤  "
        elif [[ -n "$score_11_6" && -z "$score_5_6" ]]; then
            temp_text+="abuse得分(越低越好): $score_11_6⑪  "
        fi
        local threat_12_6=$(check_and_cat_file '/tmp/ip_quality_ipapicom_ipv6_threat_level')
        if [[ -n "$threat_12_6" ]]; then
            temp_text+="威胁等级: $threat_12_6②  "
        fi
        echo "$temp_text"
        local usage_type_5_6=$(check_and_cat_file '/tmp/ip_quality_ip2location_ipv6_usage_type')
        local usage_type_11_6=$(check_and_cat_file '/tmp/ip_quality_ipapiis_ipv6_usage_type')
        if [[ -n "$usage_type_5_6" && -n "$usage_type_11_6" ]]; then
            echo "IP类型: $usage_type_5_6⑤  $usage_type_11_6⑪"
        elif [[ -n "$usage_type_5_6" && -z "$usage_type_11_6" ]]; then
            echo "IP类型: $usage_type_5_6⑤"
        elif [[ -n "$usage_type_11_6" && -z "$usage_type_5_6" ]]; then
            echo "IP类型: $usage_type_11_6⑪"
        fi
    fi
    rm -rf /tmp/ip_quality_*
}

build_text() {
    cd $myvar >/dev/null 2>&1
    awk '/-------------------- A Bench Script By spiritlhl ---------------------/{flag=1} flag; /^$/{flag=0}' qzcheck_result.txt >temp.txt && mv temp.txt qzcheck_result.txt
    sed -i -e 's/\x1B\[[0-9;]\+[a-zA-Z]//g' qzcheck_result.txt
    sed -i -e '/^$/d' qzcheck_result.txt
    sed -i 's/\r//' qzcheck_result.txt
    if [ -s qzcheck_result.txt ]; then
        shorturl=$(curl --ipv4 -sL -m 10 -X POST -H "Authorization: $ST" \
            -H "Format: RANDOM" \
            -H "Max-Views: 0" \
            -H "UploadText: true" \
            -H "Content-Type: multipart/form-data" \
            -H "No-JSON: true" \
            -F "file=@${myvar}/qzcheck_result.txt" \
            "https://paste.spiritlhl.net/api/upload")
        if [ $? -ne 0 ]; then
            shorturl=$(curl --ipv6 -sL -m 10 -X POST -H "Authorization: $ST" \
                -H "Format: RANDOM" \
                -H "Max-Views: 0" \
                -H "UploadText: true" \
                -H "Content-Type: multipart/form-data" \
                -H "No-JSON: true" \
                -F "file=@${myvar}/qzcheck_result.txt" \
                "https://paste.spiritlhl.net/api/upload")
        fi
    fi
}

main() {
    IPV4=$(check_and_cat_file /tmp/ip_quality_ipv4)
    IPV6=$(check_and_cat_file /tmp/ip_quality_ipv6)
    clear
    start_time=$(date +%s)
    print_intro
    yellow "数据仅作参考，不代表100%准确，IP类型如果不一致请手动查询多个数据库比对"
    echo -e "-----------------端口检测以及IP质量检测--本频道独创-------------------"
    _blue "以下为各数据库编号，输出结果后将自带数据库来源对应的编号"
    _blue "ipinfo数据库  ① | scamalytics数据库 ②  | virustotal数据库  ③ | abuseipdb数据库 ④  | ip2location数据库   ⑤"
    _blue "ip-api数据库  ⑥ | ipwhois数据库     ⑦  | ipregistry数据库  ⑧ | ipdata数据库    ⑨  | ipgeolocation数据库 ⑩"
    _blue "ipapiis数据库 ⑪ | ipapicom数据库    ⑫  "
    print_ip_info
    ipcheck
    next
    print_end_time
    next
}

checkupdate
checkroot
checkwget
checkcurl
check_ipv4 &
check_ipv6 &
checknc
wait
rm -rf qzcheck_result.txt
run_ip_info_check
! _exists "wget" && _red "Error: wget command not found.\n" && exit 1
! _exists "free" && _red "Error: free command not found.\n" && exit 1
main | tee -i qzcheck_result.txt
build_text
if [ -n "$shorturl" ]; then
    _green "  短链:"
    _blue "    $shorturl"
fi
rm -rf wget-log*

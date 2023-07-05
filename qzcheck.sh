#!/usr/bin/env bash
#by spiritlhl
#from https://github.com/spiritLHLS/ecs


ver="2023.07.04"
changeLog="IP质量测试，由频道 https://t.me/vps_reviews 原创"

red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}

temp_file_apt_fix="/tmp/apt_fix.txt"
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

checkdnsutils() {
    _yellow "Installing dnsutils"
    if [ "${release}" == "centos" ]; then
        yum -y install dnsutils > /dev/null 2>&1
        yum -y install bind-utils > /dev/null 2>&1
    elif [ "${release}" == "arch" ]; then
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

print_intro() {
    echo "--------------------- A Bench Script By spiritlhl --------------------"
    echo "                   测评频道: https://t.me/vps_reviews                    "
    echo "版本：$ver"
    echo "更新日志：$changeLog"
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
      break
    fi
  done
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

head='key: e88362808d1219e27a786a465a1f57ec3417b0bdeab46ad670432b7ce1a7fdec0d67b05c3463dd3c'

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

checkupdate
checkroot
checkwget
checkcurl
checknc
check_ipv4
! _exists "wget" && _red "Error: wget command not found.\n" && exit 1
! _exists "free" && _red "Error: free command not found.\n" && exit 1
ip4=$(curl -s4m8 "$IP_API")
ip6=$(curl -s6m8 -k ip.sb | tr -d '[:space:]')
ip4=$(echo "$ip4" | tr -d '\n')
ip6=$(echo "$ip6" | tr -d '\n')
# clear
start_time=$(date +%s)
print_intro
echo -e "-----------------端口检测以及IP质量检测--本频道独创-------------------"
yellow "数据仅作参考，不代表100%准确，IP类型如果不一致请手动查询多个数据库比对"
scamalytics "$ip4"
virustotal "$ip4"
ip234 "$ip4"
ipapi "$ip4"
abuse "$ip4"
cloudflare
google
if command -v nc >/dev/null; then
    check_port_25
fi
if [[ -n "$ip6" ]]; then
  echo "------以下为IPV6检测------"
  scamalytics "$ip6"
  abuse "$ip6"
fi
next
print_end_time
next
rm -rf wget-log*

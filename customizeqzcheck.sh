#!/usr/bin/env bash
#by spiritlhl
#from https://github.com/spiritLHLS/ecs

ver="2023.06.27"
changeLog="IP质量测试，由频道 https://t.me/vps_reviews 原创"

red() {
    echo -e "\033[31m\033[01m$1\033[0m"
}

green() {
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow() {
    echo -e "\033[33m\033[01m$1\033[0m"
}
reading() { read -rp "$(green "$1")" "$2"; }
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
    echo "正在更新包管理源"
    if [ "${release}" == "centos" ]; then
        yum update >/dev/null 2>&1
    else
        apt-get update >/dev/null 2>&1
    fi

}

checkupdate() {
    echo "正在更新包管理源"
    if [ "${release}" == "centos" ]; then
        yum update >/dev/null 2>&1
        yum install dos2unix -y
    else
        apt-get update >/dev/null 2>&1
        apt install dos2unix -y
    fi

}

checkdnsutils() {
    if [ ! -e '/usr/bin/dnsutils' ]; then
        echo "正在安装 dnsutils"
        if [ "${release}" == "centos" ]; then
            # 	                    yum update > /dev/null 2>&1
            yum -y install dnsutils >/dev/null 2>&1
        else
            # 	                    apt-get update > /dev/null 2>&1
            apt-get -y install dnsutils >/dev/null 2>&1
        fi

    fi
}

checkcurl() {
    if [ ! -e '/usr/bin/curl' ]; then
        echo "正在安装 Curl"
        if [ "${release}" == "centos" ]; then
            # 	                yum update > /dev/null 2>&1
            yum -y install curl >/dev/null 2>&1
        else
            # 	                apt-get update > /dev/null 2>&1
            apt-get -y install curl >/dev/null 2>&1
        fi
    fi
}

checkwget() {
    if [ ! -e '/usr/bin/wget' ]; then
        echo "正在安装 Wget"
        if [ "${release}" == "centos" ]; then
            # 	                yum update > /dev/null 2>&1
            yum -y install wget >/dev/null 2>&1
        else
            # 	                apt-get update > /dev/null 2>&1
            apt-get -y install wget >/dev/null 2>&1
        fi
    fi
}

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
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
    for element in $temp2; do
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
                i=$((i + 1))
            fi
        done <<<"$(echo "$temp2" | sed 's/<[^>]*>//g' | sed 's/^[[:blank:]]*//g')"
    fi
}

virustotal() {
    local ip="$1"
    local api_keys=()
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
        usageType=$(grep -oP '"usageType":\s*"\K[^"]+' <<<"$context2" | sed 's/\\\//\//g')
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
    risk=$(grep -oP '(?<="score":)[^,}]+' <<<"$context5")
    if [[ -n "$risk" ]]; then
        echo "ip234数据库："
        echo "  欺诈分数(越低越好)：$risk"
    else
        return
    fi
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
    yellow "数据仅作参考，不代表100%准确，IP类型如果不一致请手动查询多个数据库比对"
    scamalytics "$ip4"
    virustotal "$ip4"
    ip234 "$ip4"
    ipapi "$ip4"
    abuse "$ip4"
    next
}

checkupdate
checkroot
checkwget
checkcurl
! _exists "wget" && _red "Error: wget command not found.\n" && exit 1
! _exists "free" && _red "Error: free command not found.\n" && exit 1
clear
start_time=$(date +%s)
main
print_end_time
next
rm -rf wget-log*

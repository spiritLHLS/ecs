#!/usr/bin/env bash
#by spiritlhl
#From https://github.com/spiritLHLS/ecs
#2024.07.07

cd /root >/dev/null 2>&1
myvar=$(pwd)
ver="2024.07.07"
changeLog="IP质量测试，由频道 https://t.me/vps_reviews 原创"
temp_file_apt_fix="/tmp/apt_fix.txt"
shorturl=""
REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "alpine")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Alpine")
PACKAGE_UPDATE=("apt -y update" "apt -y update" "yum -y update" "yum -y update" "apk update -f")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "apk add -f")
CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")
utf8_locale=$(locale -a 2>/dev/null | grep -i -m 1 -E "UTF-8|utf8")
SYS="${CMD[0]}"
if [[ -z "$utf8_locale" ]]; then
    echo "No UTF-8 locale found"
else
    export LC_ALL="$utf8_locale"
    export LANG="$utf8_locale"
    export LANGUAGE="$utf8_locale"
    echo "Locale set to $utf8_locale"
fi
[[ -n $SYS ]] || exit 1
for ((int = 0; int < ${#REGEX[@]}; int++)); do
    if [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]]; then
        SYSTEM="${RELEASE[int]}"
        [[ -n $SYSTEM ]] && break
    fi
done

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

rm -rf securityCheck
os=$(uname -s)
arch=$(uname -m)

print_intro() {
    echo "-------------------- A Bench Script By spiritlhl ---------------------"
    echo "                   测评频道: https://t.me/vps_reviews                    "
    echo "版本：$ver"
    echo "更新日志：$changeLog"
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

build_text() {
    cd $myvar >/dev/null 2>&1
    awk '/-------------------- A Bench Script By spiritlhl ---------------------/{flag=1} flag; /^$/{flag=0}' sc_result.txt >temp.txt && mv temp.txt sc_result.txt
    sed -i -e 's/\x1B\[[0-9;]\+[a-zA-Z]//g' sc_result.txt
    sed -i -e '/^$/d' sc_result.txt
    sed -i 's/\r//' sc_result.txt
    if [ -s sc_result.txt ]; then
        shorturl=$(curl --ipv4 -sL -m 10 -X POST -H "Authorization: $ST" \
            -H "Format: RANDOM" \
            -H "Max-Views: 0" \
            -H "UploadText: true" \
            -H "Content-Type: multipart/form-data" \
            -H "No-JSON: true" \
            -F "file=@${myvar}/sc_result.txt" \
        "https://paste.spiritlhl.net/api/upload")
        if [ $? -ne 0 ]; then
            shorturl=$(curl --ipv6 -sL -m 10 -X POST -H "Authorization: $ST" \
                -H "Format: RANDOM" \
                -H "Max-Views: 0" \
                -H "UploadText: true" \
                -H "Content-Type: multipart/form-data" \
                -H "No-JSON: true" \
                -F "file=@${myvar}/sc_result.txt" \
            "https://paste.spiritlhl.net/api/upload")
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
        echo "CDN available, using CDN"
    else
        echo "No CDN available, no use CDN"
    fi
}

pre_download() {
    case $os in
        Linux)
            case $arch in
                "x86_64" | "x86" | "amd64" | "x64")
                    wget -O securityCheck "${cdn_success_url}https://github.com/oneclickvirt/securityCheck/releases/download/output/securityCheck-linux-amd64"
                    wget -O pck "${cdn_success_url}https://github.com/oneclickvirt/portchecker/releases/download/output/portchecker-linux-amd64"
                ;;
                "i386" | "i686")
                    wget -O securityCheck "${cdn_success_url}https://github.com/oneclickvirt/securityCheck/releases/download/output/securityCheck-linux-386"
                    wget -O pck "${cdn_success_url}https://github.com/oneclickvirt/portchecker/releases/download/output/portchecker-linux-386"
                ;;
                "armv7l" | "armv8" | "armv8l" | "aarch64")
                    wget -O securityCheck "${cdn_success_url}https://github.com/oneclickvirt/securityCheck/releases/download/output/securityCheck-linux-arm64"
                    wget -O pck "${cdn_success_url}https://github.com/oneclickvirt/portchecker/releases/download/output/portchecker-linux-arm64"
                ;;
                *)
                    echo "Unsupported architecture: $arch"
                    exit 1
                ;;
            esac
        ;;
        Darwin)
            case $arch in
                "x86_64" | "x86" | "amd64" | "x64")
                    wget -O securityCheck "${cdn_success_url}https://github.com/oneclickvirt/securityCheck/releases/download/output/securityCheck-darwin-amd64"
                    wget -O pck "${cdn_success_url}https://github.com/oneclickvirt/portchecker/releases/download/output/portchecker-darwin-amd64"
                ;;
                "i386" | "i686")
                    wget -O securityCheck "${cdn_success_url}https://github.com/oneclickvirt/securityCheck/releases/download/output/securityCheck-darwin-386"
                    wget -O pck "${cdn_success_url}https://github.com/oneclickvirt/portchecker/releases/download/output/portchecker-darwin-386"
                ;;
                "armv7l" | "armv8" | "armv8l" | "aarch64")
                    wget -O securityCheck "${cdn_success_url}https://github.com/oneclickvirt/securityCheck/releases/download/output/securityCheck-darwin-arm64"
                    wget -O pck "${cdn_success_url}https://github.com/oneclickvirt/portchecker/releases/download/output/portchecker-darwin-arm64"
                ;;
                *)
                    echo "Unsupported architecture: $arch"
                    exit 1
                ;;
            esac
        ;;
        FreeBSD)
            case $arch in
                amd64)
                    wget -O securityCheck "${cdn_success_url}https://github.com/oneclickvirt/securityCheck/releases/download/output/securityCheck-freebsd-amd64"
                    wget -O pck "${cdn_success_url}https://github.com/oneclickvirt/portchecker/releases/download/output/portchecker-freebsd-amd64"
                ;;
                "i386" | "i686")
                    wget -O securityCheck "${cdn_success_url}https://github.com/oneclickvirt/securityCheck/releases/download/output/securityCheck-freebsd-386"
                    wget -O pck "${cdn_success_url}https://github.com/oneclickvirt/portchecker/releases/download/output/portchecker-freebsd-386"
                ;;
                "armv7l" | "armv8" | "armv8l" | "aarch64")
                    wget -O securityCheck "${cdn_success_url}https://github.com/oneclickvirt/securityCheck/releases/download/output/securityCheck-freebsd-arm64"
                    wget -O pck "${cdn_success_url}https://github.com/oneclickvirt/portchecker/releases/download/output/portchecker-freebsd-arm64"
                ;;
                *)
                    echo "Unsupported architecture: $arch"
                    exit 1
                ;;
            esac
        ;;
        *)
            echo "Unsupported operating system: $os"
            exit 1
        ;;
    esac
}

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
    if [ -f "securityCheck" ]; then
        chmod 777 securityCheck
    else
        return
    fi
    ./securityCheck -l $language -e yes | sed '1d' >>/tmp/ip_quality_security_check
}

email_check(){
    cd $myvar >/dev/null 2>&1
    if [ -f "pck" ]; then
        chmod 777 pck
    else
        return
    fi
    ./pck | sed '1d' >>/tmp/ip_quality_email_check
}

ST="OvwKx5qgJtf7PZgCKbtyojSU.MTcwMTUxNzY1MTgwMw"

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

main() {
    cdn_urls=("https://cdn0.spiritlhl.top/" "http://cdn3.spiritlhl.net/" "http://cdn1.spiritlhl.net/" "http://cdn2.spiritlhl.net/" "https://fd.spiritlhl.workers.dev/")
    check_cdn_file
    pre_download
    chmod 777 securityCheck
    clear
    start_time=$(date +%s)
    print_intro
    _yellow "数据仅作参考，不代表100%准确，IP类型如果不一致请手动查询多个数据库比对"
    echo -e "-------------IP质量检测--基于oneclickvirt/securityCheck使用-------------"
    ipcheck
    next
    print_end_time
    next
}

main | tee -i sc_result.txt
build_text
if [ -n "$shorturl" ]; then
    _green "  短链:"
    _blue "    $shorturl"
fi
rm -rf wget-log*
rm -rf securityCheck*

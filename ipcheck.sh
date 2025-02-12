#!/usr/bin/env bash
#by spiritlhl
#From https://github.com/spiritLHLS/ecs
#2025.02.12

cd /root >/dev/null 2>&1
myvar=$(pwd)
ver="2025.02.12"
changeLog="IP质量测试，由频道 https://t.me/vps_reviews 原创"
temp_file_apt_fix="/tmp/apt_fix.txt"
shorturl=""
REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "alpine")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Alpine")
PACKAGE_UPDATE=("apt -y update" "apt -y update" "yum -y update" "yum -y update" "apk update -f")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "apk add -f")
CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")
rm -rf sc_result.txt

# 安全的清屏函数
clear_screen() {
    if [ -t 1 ]; then
        tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
    fi
}

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
    if [[ -f "$file" ]]; then
        if [[ -s "$file" ]] && [[ "$(grep -vE '^\s*$' "$file")" ]]; then
            if ! grep -q "error" "$file"; then
                cat "$file"
            fi
        fi
    fi
}

format_output() {
    local file="$1"
    sed -i 's/\x1B\[[0-9;]*[JKmsu]//g' "$file"
    sed -i 's/^\[H//' "$file"
    if ! grep -q "A Bench Script By spiritlhl" "$file"; then
        sed -i '1i\-------------------- A Bench Script By spiritlhl ---------------------' "$file"
    fi
}

build_text() {
    cd $myvar >/dev/null 2>&1
    if [ -f "sc_result.txt" ]; then
        format_output "sc_result.txt"
        awk '/-------------------- A Bench Script By spiritlhl ---------------------/{flag=1} flag; /^$/{flag=0}' sc_result.txt >temp.txt && mv temp.txt sc_result.txt
        sed -i -e 's/\x1B\[[0-9;]\+[a-zA-Z]//g' sc_result.txt
        sed -i -e '/^$/d' sc_result.txt
        sed -i 's/\r//' sc_result.txt
        # 检查文件大小是否小于 25KB
        if [ ! -s sc_result.txt ]; then
            echo "The file sc_result.txt is empty and has not been uploaded."
            return
        fi
        file_size=$(wc -c <"sc_result.txt")
        if [ "$file_size" -ge 25600 ]; then
            echo "Files larger than 25KB (${file_size} bytes) are not uploaded."
            return
        fi
        if [ -s sc_result.txt ]; then
            http_short_url=$(curl --ipv4 -sL -m 10 -X POST \
                -H "Authorization: $ST" \
                -F "file=@${myvar}/sc_result.txt" \
                "http://hpaste.spiritlhl.net/api/UL/upload")
            if [ $? -eq 0 ] && [ -n "$http_short_url" ] && echo "$http_short_url" | grep -q "show"; then
                file_id=$(echo "$http_short_url" | grep -o '[^/]*$')
                shorturl="https://paste.spiritlhl.net/#/show/${file_id}"
            else
                https_short_url=$(curl --ipv6 -sL -m 10 -X POST \
                    -H "Authorization: $ST" \
                    -F "file=@${myvar}/sc_result.txt" \
                    "https://paste.spiritlhl.net/api/UL/upload")
                if [ $? -eq 0 ] && [ -n "$https_short_url" ] && echo "$https_short_url" | grep -q "show"; then
                    file_id=$(echo "$https_short_url" | grep -o '[^/]*$')
                    shorturl="https://paste.spiritlhl.net/#/show/${file_id}"
                else
                    shorturl=""
                fi
            fi
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
        ./securityCheck -l $language -e yes | sed '1d' >>/tmp/ip_quality_security_check
    fi
}

email_check() {
    cd $myvar >/dev/null 2>&1
    if [ -f "pck" ]; then
        chmod 777 pck
        ./pck | sed '1d' >>/tmp/ip_quality_email_check
    fi
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
    {
        google
        if [[ $? -ne 0 ]]; then
            echo "Google检测执行失败" >>/tmp/ip_quality_google
        fi
    } &

    if [ "$en_status" = true ]; then
        {
            security_check "en"
            if [[ $? -ne 0 ]]; then
                echo "Security check failed" >>/tmp/ip_quality_security_check
            fi
        } &
    else
        {
            security_check "zh"
            if [[ $? -ne 0 ]]; then
                echo "安全检查执行失败" >>/tmp/ip_quality_security_check
            fi
        } &
    fi

    {
        email_check
        if [[ $? -ne 0 ]]; then
            echo "邮件端口检测执行失败" >>/tmp/ip_quality_email_check
        fi
    } &

    # 等待所有后台任务完成
    wait

    # 检查并显示结果
    local has_output=false

    if [ -f "/tmp/ip_quality_security_check" ]; then
        check_and_cat_file "/tmp/ip_quality_security_check"
        has_output=true
    fi

    if [ -f "/tmp/ip_quality_google" ]; then
        check_and_cat_file "/tmp/ip_quality_google"
        has_output=true
    fi

    if [ "$en_status" = true ]; then
        echo -e "-------Email-Port-Detection--Base-On-oneclickvirt/portchecker--------"
    else
        echo -e "-------------邮件端口检测--基于oneclickvirt/portchecker开源-------------"
    fi

    if [ -f "/tmp/ip_quality_email_check" ]; then
        check_and_cat_file "/tmp/ip_quality_email_check"
        has_output=true
    fi

    # 如果没有任何输出，输出错误信息
    if [ "$has_output" = false ]; then
        echo "警告: 未能获取到任何检测结果"
    fi

    # 清理临时文件
    rm -rf /tmp/ip_quality_*
}

main() {
    cdn_urls=("http://cdn1.spiritlhl.net/" "http://cdn2.spiritlhl.net/" "http://cdn3.spiritlhl.net/" "http://cdn4.spiritlhl.net/")
    check_cdn_file
    pre_download
    chmod 777 securityCheck 2>/dev/null
    # 清屏
    clear_screen
    start_time=$(date +%s)
    print_intro
    _yellow "数据仅作参考，不代表100%准确，IP类型如果不一致请手动查询多个数据库比对"
    echo -e "-------------IP质量检测--基于oneclickvirt/securityCheck使用-------------"
    # 执行检测并保存到临时文件
    temp_output=$(mktemp)
    ipcheck | tee "$temp_output"
    # 检查输出
    if [ ! -s "$temp_output" ]; then
        echo "警告: 首次检测结果为空，正在重试..."
        sleep 2
        ipcheck | tee "$temp_output"
    fi
    rm -f "$temp_output"
    next
    print_end_time
    next
}

: >sc_result.txt
main | tee -i sc_result.txt
build_text
if [ -n "$shorturl" ]; then
    _green "  短链:"
    _blue "    $shorturl"
fi
rm -rf wget-log*
rm -rf securityCheck*

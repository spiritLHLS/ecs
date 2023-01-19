#!/usr/bin/env bash
_red() { echo -e "\033[31m\033[01m$@\033[0m"; }
_green() { echo -e "\033[32m\033[01m$@\033[0m"; }
_yellow() { echo -e "\033[33m\033[01m$@\033[0m"; }
_blue() { echo -e "\033[36m\033[01m$@\033[0m"; }
reading(){ read -rp "$(green "$1")" "$2"; }
TEMP_FILE='ip.test'
fscarmen_route_script(){
    rm -f $TEMP_FILE
    IP_4=$(curl -ks4m8 -A Mozilla https://api.ip.sb/geoip) &&
    WAN_4=$(expr "$IP_4" : '.*ip\":[ ]*\"\([^"]*\).*') &&
    ASNORG_4=$(expr "$IP_4" : '.*isp\":[ ]*\"\([^"]*\).*') &&
    _blue "IPv4 ASN: $ASNORG_4" >> $TEMP_FILE
    IP_6=$(curl -ks6m8 -A Mozilla https://api.ip.sb/geoip) &&
    WAN_6=$(expr "$IP_6" : '.*ip\":[ ]*\"\([^"]*\).*') &&
    ASNORG_6=$(expr "$IP_6" : '.*isp\":[ ]*\"\([^"]*\).*') &&
    _blue "IPv6 ASN: $ASNORG_6" >> $TEMP_FILE
    local ARCHITECTURE="$(uname -m)"
        case $ARCHITECTURE in
        x86_64 )  local FILE=besttrace;;
        aarch64 ) local FILE=besttracearm;;
        i386 )    local FILE=besttracemac;;
        * ) _red " 只支持 AMD64、ARM64、Mac 使用，问题反馈:[https://github.com/fscarmen/tools/issues] " && return;;
        esac
    curl -s -L -k "${cdn_success_url}https://github.com/fscarmen/tools/raw/main/besttrace/${FILE}" -o $FILE && chmod +x $FILE &>/dev/null
    _green "依次测试电信，联通，移动经过的地区及线路，核心程序来由: ipip.net ，请知悉!" >> $TEMP_FILE
    ./"$FILE" "$ip" -g cn | sed "s/^[ ]//g" | sed "/^[ ]/d" | sed '/ms/!d' | sed "s#.* \([0-9.]\+ ms.*\)#\1#g" >> $TEMP_FILE
    cat $TEMP_FILE
    rm -f $TEMP_FILE
}

[[ -z "$ip" || $ip = '[DESTINATION_IP]' ]] && reading "\n 请输入目的地 IP: " ip
yellow "\n 检测中，请稍等片刻。\n"
fscarmen_route_script

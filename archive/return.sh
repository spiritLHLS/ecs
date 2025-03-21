#!/usr/bin/env bash
_red() { echo -e "\033[31m\033[01m$@\033[0m"; }
_green() { echo -e "\033[32m\033[01m$@\033[0m"; }
_yellow() { echo -e "\033[33m\033[01m$@\033[0m"; }
_blue() { echo -e "\033[36m\033[01m$@\033[0m"; }
reading(){ read -rp "$(_green "$1")" "$2"; }
translate(){ [[ -n "$1" ]] && curl -ksm8 "http://fanyi.youdao.com/translate?&doctype=json&type=AUTO&i=${1//[[:space:]]/}" | cut -d \" -f18 2>/dev/null; }
TEMP_FILE='ip.test'
utf8_locale=$(locale -a 2>/dev/null | grep -i -m 1 -E "UTF-8|utf8")
if [[ -z "$utf8_locale" ]]; then
  echo "No UTF-8 locale found"
else
  export LC_ALL="$utf8_locale"
  export LANG="$utf8_locale"
  export LANGUAGE="$utf8_locale"
  echo "Locale set to $utf8_locale"
fi

check_dependencies(){ for c in $@; do
type -p $c >/dev/null 2>&1 || (_yellow " 安装 $c 中…… " && ${PACKAGE_INSTALL[b]} "$c") || (_yellow " 先升级软件库才能继续安装 \$c，时间较长，请耐心等待…… " && ${PACKAGE_UPDATE[b]} && ${PACKAGE_INSTALL[b]} "$c")
! type -p $c >/dev/null 2>&1 && _yellow " 安装 \$c 失败，脚本中止，问题反馈:[https://github.com/fscarmen/tools/issues] " && exit 1; done; }

fscarmen_route_script(){
    rm -f $TEMP_FILE
    local ARCHITECTURE="$(uname -m)"
        case $ARCHITECTURE in
        x86_64 )  local FILE=besttrace;;
        aarch64 ) local FILE=besttracearm;;
        i386 )    local FILE=besttracemac;;
        * ) _red " 只支持 AMD64、ARM64、Mac 使用，问题反馈:[https://github.com/fscarmen/tools/issues] " && return;;
        esac
    curl -s -L -k "https://github.com/fscarmen/tools/raw/main/besttrace/${FILE}" -o $FILE && chmod +x $FILE &>/dev/null
    _green "依次测试电信，联通，移动经过的地区及线路，核心程序来由: ipip.net ，请知悉!" >> $TEMP_FILE
    ./"$FILE" "$ip" -g cn 2>/dev/null | sed "s/^[ ]//g" | sed "/^[ ]/d" | sed '/ms/!d' | sed "s#.* \([0-9.]\+ ms.*\)#\1#g" >> $TEMP_FILE
    cat $TEMP_FILE
    rm -f $TEMP_FILE
}

ARCHITECTURE="$(arch)"
# 多方式判断操作系统，试到有值为止。只支持 Debian 10/11、Ubuntu 18.04/20.04 或 CentOS 7/8 ,如非上述操作系统，退出脚本
if [[ $ARCHITECTURE = i386 ]]; then
  sw_vesrs 2>/dev/null | grep -qvi macos && _red " 本脚本只支持 Debian、Ubuntu、CentOS、Alpine 或者 macOS 系统,问题反馈:[https://github.com/fscarmen/warp_unlock/issues] " && exit 1
  b=0
  SYSTEM='macOS'
  PACKAGE_INSTALL=("brew install")
else
  CMD=(	"$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)"
      	"$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)"
	"$(lsb_release -sd 2>/dev/null)"
	"$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)"
	"$(grep . /etc/redhat-release 2>/dev/null)"
	"$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')"
	)

  REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|amazon linux|alma|rocky")
  RELEASE=("Debian" "Ubuntu" "CentOS")
  PACKAGE_UPDATE=("apt -y update" "apt -y update" "yum -y update")
  PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install")

  for a in "${CMD[@]}"; do
	  SYS="$a" && [[ -n $SYS ]] && break
  done
  
  for ((b=0; b<${#REGEX[@]}; b++)); do
	[[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[b]} ]] && SYSTEM="${RELEASE[b]}" && break
  done
fi

[[ -z $SYSTEM ]] && _red " 本脚本只支持 Debian、Ubuntu、CentOS、Alpine 或者 macOS 系统,问题反馈:[https://github.com/fscarmen/warp_unlock/issues] " && exit 1

check_dependencies curl sudo

main() {
    [[ -z "$ip" || $ip = '[DESTINATION_IP]' ]] && reading "\n 请输入目的地 IP: " ip
    _yellow "\n 检测中，请稍等片刻。\n"
    # 遍历本机可以使用的 IP API 服务商
  API_NET=("ip.sb" "ipget.net" "ip.ping0.cc" "https://ip4.seeip.org" "https://api.my-ip.io/ip" "https://ipv4.icanhazip.com" "api.ipify.org")
    API_URL=("api.ip.sb/geoip" "ifconfig.co/json")
    API_ASN=("isp" "asn_org")
    for ((p=0; p<${#API_NET[@]}; p++)); do ping -c1 -W1 ${API_NET[p]} >/dev/null 2>&1 && IP_API="${API_NET[p]}" && break; done

    IP_4=$(curl -s4m5 -A Mozilla https://${API_URL[p]}) &&
    WAN_4=$(expr "$IP_4" : '.*ip\":[ ]*\"\([^"]*\).*')
    if [ -n "$WAN_4" ]; then
      COUNTRY_4E=$(expr "$IP_4" : '.*country\":[ ]*\"\([^"]*\).*')
      COUNTRY_4=$(translate "$COUNTRY_4E")
      ASNORG_4=$(expr "$IP_4" : '.*'${API_ASN[p]}'\":[ ]*\"\([^"]*\).*')
      TYPE_4=$(curl -4m5 -sSL https://www.abuseipdb.com/check/$WAN_4 2>/dev/null | grep -A2 '<th>Usage Type</th>' | tail -n 1 | sed "s@Data Center/Web Hosting/Transit@数据中心@;s@Fixed Line ISP@家庭宽带@;s@Commercial@商业宽带@;s@Mobile ISP@移动流量@;s@Content Delivery Network@内容分发网络(CDN)@;s@Search Engine Spider@搜索引擎蜘蛛@;s@University/College/School@教育网@;s@Unknown@未知@")
      _green " IPv4: $WAN_4\t\t 地区: $COUNTRY_4\t 类型: $TYPE_4\t ASN: $ASNORG_4\n"
    fi

    IP_6=$(curl -s6m5 -A Mozilla https://${API_URL[p]}) &&
    WAN_6=$(expr "$IP_6" : '.*ip\":[ ]*\"\([^"]*\).*') &&
    if [ -n "$WAN_6" ]; then
      COUNTRY_6E=$(expr "$IP_6" : '.*country\":[ ]*\"\([^"]*\).*')
      COUNTRY_6=$(translate "$COUNTRY_6E")
      ASNORG_6=$(expr "$IP_6" : '.*'${API_ASN[p]}'\":[ ]*\"\([^"]*\).*')
      TYPE_6=$(curl -6m5 -sSL https://www.abuseipdb.com/check/$WAN_6 2>/dev/null | grep -A2 '<th>Usage Type</th>' | tail -n 1 | sed "s@Data Center/Web Hosting/Transit@数据中心@;s@Fixed Line ISP@家庭宽带@;s@Commercial@商业宽带@;s@Mobile ISP@移动流量@;s@Content Delivery Network@内容分发网络(CDN)@;s@Search Engine Spider@搜索引擎蜘蛛@;s@University/College/School@教育网@;s@Unknown@未知@")
      _green " IPv6: $WAN_6\t 地区: $COUNTRY_6\t 类型: $TYPE_6\t ASN: $ASNORG_6\n"
    fi

    [[ $ip =~ '.' && -z "$IP_4" ]] && red " VPS 没有 IPv4 网络，不能查 $ip\n" && exit 1
    [[ $ip =~ ':' && -z "$IP_6" ]] && red " VPS 没有 IPv6 网络，不能查 $ip\n" && exit 1
    fscarmen_route_script
}

main

#!/bin/bash
# by https://github.com/spiritLHLS/ecs
# by spiritlhls
# 2023.08.26

_red() { echo -e "\033[31m\033[01m$@\033[0m"; }
_green() { echo -e "\033[32m\033[01m$@\033[0m"; }
_yellow() { echo -e "\033[33m\033[01m$@\033[0m"; }
_blue() { echo -e "\033[36m\033[01m$@\033[0m"; }
reading() { read -rp "$(_green "$1")" "$2"; }
translate() { [[ -n "$1" ]] && curl -ksm8 "http://fanyi.youdao.com/translate?&doctype=json&type=AUTO&i=${1//[[:space:]]/}" | cut -d \" -f18 2>/dev/null; }
TEMP_FILE='ip.test'

check_dependencies() { for c in $@; do
  type -p $c >/dev/null 2>&1 || (_yellow " 安装 $c 中…… " && ${PACKAGE_INSTALL[b]} "$c") || (_yellow " 先升级软件库才能继续安装 \$c，时间较长，请耐心等待…… " && ${PACKAGE_UPDATE[b]} && ${PACKAGE_INSTALL[b]} "$c")
  ! type -p $c >/dev/null 2>&1 && _yellow " 安装 \$c 失败，脚本中止，问题反馈:[https://github.com/fscarmen/tools/issues] " && exit 1
done; }

ARCHITECTURE="$(arch)"
case "$ARCHITECTURE" in
"x86_64" | "amd64")
  FILE=nexttrace_linux_amd64
  ;;
"armv7l" | "armv8" | "armv8l" | "aarch64")
  FILE=nexttrace_linux_arm64
  ;;
"i386" | "i686")
  FILE=nexttrace_darwin_amd64
  ;;
*)
  red " 本脚本只支持 AMD64、ARM64、i386 和 i686 使用，问题反馈:[https://github.com/fscarmen/tools/issues] " && exit 1
  ;;
esac

# 多方式判断操作系统，试到有值为止。只支持 Debian、Ubuntu 或 CentOS， 如非上述操作系统，退出脚本
if [ -s /etc/os-release ]; then
  SYS="$(grep -i pretty_name /etc/os-release | cut -d \" -f2)"
elif [ $(type -p hostnamectl) ]; then
  SYS="$(hostnamectl | grep -i system | cut -d : -f2)"
elif [ $(type -p lsb_release) ]; then
  SYS="$(lsb_release -sd)"
elif [ -s /etc/lsb-release ]; then
  SYS="$(grep -i description /etc/lsb-release | cut -d \" -f2)"
elif [ -s /etc/redhat-release ]; then
  SYS="$(grep . /etc/redhat-release)"
elif [ -s /etc/issue ]; then
  SYS="$(grep . /etc/issue | cut -d '\' -f1 | sed '/^[ ]*$/d')"
fi
REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|amazon linux|alma|rocky")
RELEASE=("Debian" "Ubuntu" "CentOS")
PACKAGE_UPDATE=("apt -y update" "apt -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install")
for ((b = 0; b < ${#REGEX[@]}; b++)); do
  [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[b]} ]] && SYSTEM="${RELEASE[b]}" && break
done

[ -z "$SYSTEM" ] && _red " 本脚本只支持 Debian、Ubuntu 或者 CentOS 系统,问题反馈:[https://github.com/fscarmen/tools/issues] " && exit 1

check_dependencies curl sudo
clear

# 头部信息
_green "\n使用 nexttrace 前请务必放低预期，如果追求的是数据的精确，请选择 besttrace"
_green "原始仓库说明：https://github.com/sjlleo/nexttrace/blob/main/README_zh_CN.md"
_green "本人仅制作了shell脚本，具体核心程序来源于上面的原始仓库"
# 读取IP
while true; do
  [[ -z "$ip" || $ip = '[DESTINATION_IP]' ]] && reading "\n请输入目的地 IP或网址: " ip
  if [[ $ip =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]] || [[ $ip =~ ^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:))$ ]] || (echo $ip | grep -E -q '^(http|https|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'); then
    break
  fi
  echo "请输入有效的 IP 或网址"
done

# 下载 nexttrace 主程序
if [ ! -e $FILE ]; then
  VERSION=$(curl -sSL "https://api.github.com/repos/nxtrace/Ntrace-core/releases/latest" | awk -F \" '/tag_name/{print $4}')
  curl -sLO https://github.com/nxtrace/Ntrace-core/releases/download/$VERSION/$FILE
  chmod +x "$FILE" >/dev/null 2>&1
fi

# 查路由
RESULT=$(./"$FILE" "$ip" -g cn 2>/dev/null)
PART_1=$(echo "$RESULT" | grep '^[0-9]\{1,2\}[ ]\+[0-9a-f]' | awk '{$1="";$2="";print}' | sed "s@^[ ]\+@@g")
PART_2=$(echo "$RESULT" | grep '\(.*ms\)\{3\}' | sed 's/.* \([0-9*].*ms\).*ms.*ms/\1/g')
SPACE=' '
for ((i = 1; i <= $(echo "$PART_1" | wc -l); i++)); do
  [ "$i" -eq 10 ] && unset SPACE
  p_1=$(echo "$PART_2" | sed -n "${i}p") 2>/dev/null
  p_2=$(echo "$PART_1" | sed -n "${i}p") 2>/dev/null
  echo -e "$p_1 \t$p_2"
done

# 执行完成，删除 nexttrace 主程序
rm -f $FILE

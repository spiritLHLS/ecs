#!/usr/bin/env bash
TEMP_FILE='ip.temp'
red(){ echo -e "\033[31m\033[01m$1\033[0m"; }
green(){ echo -e "\033[32m\033[01m$1\033[0m"; }
reading(){ read -rp "$(green "$1")" "$2"; }

ARCHITECTURE="$(arch)"
case $ARCHITECTURE in
  x86_64 )  FILE=besttrace;;
  aarch64 ) FILE=besttracearm;;
  i386 )    FILE=besttracemac;;
  * ) red " 只支持 AMD64、ARM64、Mac 使用，问题反馈:[https://github.com/fscarmen/tools/issues] " && exit 1;;
esac

# green " 本脚说明：测 VPS ——> 对端 经过的地区及线路，填本地IP就是测回程，核心程序来由: https://www.ipip.net/ ，请知悉！"
[[ ! -e $FILE ]] && wget -q https://github.com/fscarmen/tools/raw/main/besttrace/$FILE >/dev/null 2>&1
chmod 777 $FILE >/dev/null 2>&1
sudo ./"$FILE" "$1" -g cn > $TEMP_FILE
green "$(cat $TEMP_FILE | sed "s/.*\*\(.*局域网\)/\1/g" | sed "s/.*AS[0-9]*//g" | sed "/\*$/d;/^$/d;1d" | uniq | awk '{printf("%d.%s\n"),NR,$0}')"
rm -f $TEMP_FILE

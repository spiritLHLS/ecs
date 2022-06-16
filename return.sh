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

[[ ! -e $FILE ]] && wget -q https://github.com/fscarmen/tools/raw/main/besttrace/$FILE >/dev/null 2>&1
chmod 777 $FILE >/dev/null 2>&1
sudo ./"$FILE" "$1" -g cn > $TEMP_FILE
green "$(cat $TEMP_FILE | cut -d \* -f2 | sed "s/.*\(  AS[0-9]\)/\1/" | sed "/\*$/d;/^$/d;1d" | uniq | awk '{printf("%d.%s\n"),NR,$0}')"
rm -f $TEMP_FILE

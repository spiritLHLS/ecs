#!/usr/bin/env bash

REGEX=("debian|astra" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "fedora" "arch" "freebsd")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Fedora" "Arch" "FreeBSD")
PACKAGE_UPDATE=("! apt-get update && apt-get --fix-broken install -y && apt-get update" "apt-get update" "yum -y update" "yum -y update" "yum -y update" "pacman -Sy" "pkg update")
PACKAGE_INSTALL=("apt-get -y install" "apt-get -y install" "yum -y install" "yum -y install" "yum -y install" "pacman -Sy --noconfirm --needed" "pkg install -y")
PACKAGE_REMOVE=("apt-get -y remove" "apt-get -y remove" "yum -y remove" "yum -y remove" "yum -y remove" "pacman -Rsc --noconfirm" "pkg delete")
PACKAGE_UNINSTALL=("apt-get -y autoremove" "apt-get -y autoremove" "yum -y autoremove" "yum -y autoremove" "yum -y autoremove" "" "pkg autoremove")
CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')" "$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(uname -s)")
SYS="${CMD[0]}"
[[ -n $SYS ]] || exit 1
for ((int = 0; int < ${#REGEX[@]}; int++)); do
    if [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]]; then
        SYSTEM="${RELEASE[int]}"
        [[ -n $SYSTEM ]] && break
    fi
done
${PACKAGE_INSTALL[int]} net-tools
interface=$(ls /sys/class/net/ | grep -v "$(ls /sys/devices/virtual/net/)")
current_ipv6=$(curl -s -6 -m 6 ipv6.ip.sb)
echo ${current_ipv6}
new_ipv6="${current_ipv6%:*}:3"
ip addr add ${new_ipv6}/128 dev ${interface}
sleep 5
updated_ipv6=$(curl -s -6 -m 6 ipv6.ip.sb)
echo ${updated_ipv6}
ip addr del ${new_ipv6}/128 dev ${interface}
final_ipv6=$(curl -s -6 -m 6 ipv6.ip.sb)
echo ${final_ipv6}
ipv6_prefixlen=""
output=$(ifconfig ${interface} | grep -oP 'inet6 [^f][^e][^8][^0].*prefixlen \K\d+')
num_lines=$(echo "$output" | wc -l)
if [ $num_lines -ge 2 ]; then
    ipv6_prefixlen=$(echo "$output" | sort -n | head -n 1)
else
    ipv6_prefixlen=$(echo "$output" | head -n 1)
fi
if [ "$updated_ipv6" == "$current_ipv6" ]; then
    echo "IPV6 子网掩码: 128"
else
    echo "IPV6 子网掩码: $ipv6_prefixlen"
fi


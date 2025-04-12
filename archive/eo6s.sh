#!/usr/bin/env bash
# by spiritlhl
# from https://github.com/spiritLHLS/ecs
# 2025.04.12
# curl -L https://raw.githubusercontent.com/spiritLHLS/ecs/main/archive/eo6s.sh -o eo6s.sh && chmod +x eo6s.sh && bash eo6s.sh


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
${PACKAGE_INSTALL[int]} net-tools # 无后续维护了
${PACKAGE_INSTALL[int]} iproute2
ipv6_prefixlen=$(ip -6 addr show | grep global | awk '{print length, $2}' | sort -nr | head -n 1 | awk '{print $2}' | cut -d '/' -f2)
if [ -z "$ipv6_prefixlen" ] || ! echo "$ipv6_prefixlen" | grep -Eq '^[0-9]+$'; then
    exit 0
elif [ "$ipv6_prefixlen" -eq 128 ]; then
    echo "IPV6 子网掩码: 128"
    exit 0
fi
# interface=$(ls /sys/class/net/ | grep -v "$(ls /sys/devices/virtual/net/)" | grep -E '^(eth|en)' | head -n 1)
interface=$(ls /sys/class/net/ | grep -E '^(eth|en)' | head -n 1)
current_ipv6=$(curl -s -6 -m 5 ipv6.ip.sb)
echo "current_ipv6: ${current_ipv6}"
[ -z "$current_ipv6" ] && exit 1
new_ipv6="${current_ipv6%:*}:3"
ip addr add ${new_ipv6}/128 dev ${interface}
sleep 5
updated_ipv6=$(curl -s -6 -m 5 ipv6.ip.sb)
echo "updated_ipv6: ${updated_ipv6}"
ip addr del ${new_ipv6}/128 dev ${interface}
sleep 5
final_ipv6=$(curl -s -6 -m 5 ipv6.ip.sb)
echo "final_ipv6: ${final_ipv6}"
# ipv6_prefixlen=""
# if command -v ifconfig &> /dev/null; then
#     output=$(ifconfig ${interface} | grep -oP 'inet6 (?!fe80:).*prefixlen \K\d+')
# else
#     output=$(ip -6 addr show dev ${interface} | grep -oP 'inet6 (?!fe80:).* scope global.*prefixlen \K\d+')
# fi
# num_lines=$(echo "$output" | wc -l)
# if [ $num_lines -ge 2 ]; then
#     ipv6_prefixlen=$(echo "$output" | sort -n | head -n 1)
# else
#     ipv6_prefixlen=$(echo "$output" | head -n 1)
# fi
if [ "$updated_ipv6" == "$current_ipv6" ] || [ -z "$updated_ipv6" ]; then
    echo "IPV6 子网掩码: 128"
else
    echo "IPV6 子网掩码: $ipv6_prefixlen"
fi

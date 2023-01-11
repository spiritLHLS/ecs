#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PURPLE="\033[0;35m"
CYAN='\033[0;36m'
ENDC='\033[0m'

check_wget() {
    if  [ ! -e '/usr/bin/wget' ]; then
        echo "请先安装 wget" && exit 1
    fi
}

check_bimc() {
    if  [ ! -e './bimc' ]; then
        echo "正在获取组件"
        arch=$(uname -m)
        if [ "${arch}" == "i686" ]; then
            arch="i586"
        fi
        wget --no-check-certificate -qO bimc https://bench.im/bimc > /dev/null 2>&1
        chmod +x bimc
    fi
}

print_info() {
    echo "——————————————————————————————————————————————————————————————————————"
}



get_options() {
    echo -e "  测速类型:    ${GREEN}1.${ENDC} 全国三网测速    ${GREEN}2.${ENDC} 东南西北中      ${GREEN}0.${ENDC} 北上广"
    echo -e "               ${GREEN}3.${ENDC} 全国电信节点    ${GREEN}4.${ENDC} 全国联通节点    ${GREEN}5.${ENDC} 全国移动节点"
    echo -e "               ${GREEN}6.${ENDC} 区域电信节点    ${GREEN}7.${ENDC} 区域联通节点    ${GREEN}8.${ENDC} 区域移动节点"
    while :; do read -p "  请选择测速类型(默认: 1): " selection
        if [[ "$selection" == "" ]]; then
            selection=1
            break
        elif [[ ! $selection =~ ^[0-8]$ ]]; then
            echo -e "  ${RED}输入错误${ENDC}, 请输入正确的数字!"
        else
            break   
        fi
    done
    while :; do read -p "  启用八线程测速(留空禁用): " multi
        if [[ "$multi" != "" ]]; then
            thread=" -m"
            break
        else
            thread=""
            break 
        fi
    done
}


speed_test(){
    local nodeType=$1
    local nodeLocation=$2
    local nodeISP=$3
    local extra=$4
    local server=$(echo "$5"| base64 -d)
    local name=$(./bimc "$nodeLocation" -n)

    printf "\r${GREEN}%-7s${YELLOW}%s%s${GREEN}%s${CYAN}%s%-11s${CYAN}%s%-11s${GREEN}%-9s${PURPLE}%-7s${ENDC}" "${nodeType}"  "${nodeISP}" "|" "${name}" "↑ " "..." "↓ " "..." "..." "..."

    output=$(./bimc $server $ul$thread $extra)
    local upload="$(echo "$output" | cut -n -d ',' -f1)"
    local download="$(echo "$output" | cut -n -d ',' -f2)"
    local latency="$(echo "$output" | cut -n -d ',' -f3)"
    local jitter="$(echo "$output" | cut -n -d ',' -f4)"
            
    printf "\r${GREEN}%-7s${YELLOW}%s%s${GREEN}%s${CYAN}%s%s${CYAN}%s%s${GREEN}%s${PURPLE}%s${ENDC}\n" "${nodeType}"  "${nodeISP}" "|" "${name}" "↑ " "${upload}" "↓ " "${download}" "${latency}" "${jitter}"
}

run_test() {
    [[ ${selection} == 2 ]] && exit 1

    echo "——————————————————————————————————————————————————————————————————————"
    echo "协议   测速服务器信息       上传/Mbps    下载/Mbps    延迟/ms  抖动/ms"
    start=$(date +%s) 

    if [[ ${selection} == 0 ]]; then
        speed_test 'HTTP' '北京' '电信' '' 'MjE5LjE0MS4xNTAuMTY2OjgwOTI='
        speed_test 'HTTP' '上海' '电信' '' 'MTAxLjk1LjE0NC4yMDU6ODA5Mg=='
        speed_test 'HTTP' '广州' '电信' '' 'NjEuMTQ0LjYuMTg6ODA5Mg=='

        speed_test 'HTTP' '北京' '联通' '' 'NjEuMTM1LjIxNC41NDo4MDky'
        speed_test 'HTTP' '上海' '联通' '' 'MjEwLjUxLjU3LjEwOjgwOTI='
        speed_test 'HTTP' '广州' '联通' '' 'MjE4LjEwNy44LjE4OjgwOTI='

        speed_test 'HTTP' '北京' '移动' '' 'MTExLjEzLjYwLjMzOjgwOTI='
        speed_test 'HTTP' '上海' '移动' '' 'MTE3LjEzNS4xMjMuMzQ6ODA5Mg=='
        speed_test 'HTTP' '广州' '移动' '' 'MTgzLjIzMi42NS44NTo4MDky'
    fi

    if [[ ${selection} == 1 ]] || [[ ${selection} == 3 ]]; then
        speed_test 'HTTP' '哈尔滨' '电信' '' 'MTEyLjEwMC4xMTYuODY6ODA5Mg=='
        speed_test 'HTTP' '长春' '电信' '' 'MzYuNDkuODguMTk0OjgwOTI='
        speed_test 'HTTP' '沈阳' '电信' '' 'NTkuNDYuMzQuNTA6ODA5Mg=='
        speed_test 'HTTP' '北京' '电信' '' 'MjE5LjE0MS4xNTAuMTY2OjgwOTI='
        speed_test 'HTTP' '天津' '电信' '' 'MjE5LjE1MC44Ni4yNTA6ODA5Mg=='
        speed_test 'HTTP' '石家庄' '电信' '' 'MjIyLjIyMi4xMjcuNDI6ODA5Mg=='
        speed_test 'HTTP' '太原' '电信' '' 'NTkuNDkuMTA5LjI0Mjo4MDky'
        speed_test 'HTTP' '济南' '电信' '' 'NTguNTYuMTE4LjEyNjo4MDky'
        speed_test 'HTTP' '郑州' '电信' '' 'MTcxLjguMTUwLjEzODo4MDky'
        speed_test 'HTTP' '上海' '电信' '' 'MTAxLjk1LjE0NC4yMDU6ODA5Mg=='
        speed_test 'HTTP' '杭州' '电信' '' 'MTgzLjEyOS4xODguMjA2OjgwOTI='
        speed_test 'HTTP' '南京' '电信' '' 'MjE4LjIuMTIyLjI0Njo4MDky'
        speed_test 'HTTP' '合肥' '电信' '' 'NjAuMTY4LjExMS4yOjgwOTI='
        speed_test 'HTTP' '武汉' '电信' '' 'MjAyLjEwMy4zOC43NDo4MDky'
        speed_test 'HTTP' '南昌' '电信' '' 'MTE3LjIxLjc1LjIxMDo4MDky'
        speed_test 'HTTP' '长沙' '电信' '' 'MjIyLjI0Ny4zMC4yNDY6ODA5Mg=='
        speed_test 'HTTP' '福州' '电信' '' 'NjEuMTU0LjguMzg6ODA5Mg=='
        speed_test 'HTTP' '广州' '电信' '' 'NjEuMTQ0LjYuMTg6ODA5Mg=='
        speed_test 'HTTP' '南宁' '电信' '' 'MTEzLjEyLjY5LjIxODo4MDky'
        speed_test 'HTTP' '海口' '电信' '' 'MjAyLjEwMC4yMTUuOTQ6ODA5Mg=='
        speed_test 'HTTP' '昆明' '电信' '' 'MTE2LjI0OS41OC4yMDI6ODA5Mg=='
        speed_test 'HTTP' '贵阳' '电信' '' 'MjIyLjg1LjIxNi4yOjgwOTI='
        speed_test 'HTTP' '西安' '电信' '' 'MjIyLjkxLjE0Ny43ODo4MDky'
        speed_test 'HTTP' '重庆' '电信' '' 'MjIyLjE4MS4xNS4yNjo4MDky'
        speed_test 'HTTP' '成都' '电信' '' 'MTI1LjY5Ljg3LjE5NDo4MDky'
        speed_test 'HTTP' '兰州' '电信' '' 'NjEuMTc4LjY1LjkwOjgwOTI='
        speed_test 'HTTP' '西宁' '电信' '' 'MjIzLjIyMS4yNDAuMjAyOjgwOTI='
        speed_test 'HTTP' '银川' '电信' '' 'MjIyLjc1LjE2Mi4yMDI6ODA5Mg=='
        speed_test 'HTTP' '呼和浩特' '电信' '' 'MTIzLjE3OC4yMTguMTk0OjgwOTI='
        speed_test 'HTTP' '拉萨' '电信' '' 'MjAyLjk4LjIzMC4yMjY6ODA5Mg=='
        speed_test 'HTTP' '乌鲁木齐' '电信' '' 'MjIyLjgzLjIwLjkwOjgwOTI='
    fi

    if [[ ${selection} == 2 ]] || [[ ${selection} == 6 ]]; then
        speed_test 'HTTP' '北京' '电信' '' 'MjE5LjE0MS4xNTAuMTY2OjgwOTI='
        speed_test 'HTTP' '天津' '电信' '' 'MjE5LjE1MC44Ni4yNTA6ODA5Mg=='
        speed_test 'HTTP' '石家庄' '电信' '' 'MjIyLjIyMi4xMjcuNDI6ODA5Mg=='

        speed_test 'HTTP' '上海' '电信' '' 'MTAxLjk1LjE0NC4yMDU6ODA5Mg=='
        speed_test 'HTTP' '杭州' '电信' '' 'MTgzLjEyOS4xODguMjA2OjgwOTI='
        speed_test 'HTTP' '南京' '电信' '' 'MjE4LjIuMTIyLjI0Njo4MDky'

        speed_test 'HTTP' '广州' '电信' '' 'NjEuMTQ0LjYuMTg6ODA5Mg=='
        speed_test 'HTTP' '福州' '电信' '' 'NjEuMTU0LjguMzg6ODA5Mg=='
        speed_test 'HTTP' '南宁' '电信' '' 'MTEzLjEyLjY5LjIxODo4MDky'

        speed_test 'HTTP' '武汉' '电信' '' 'MjAyLjEwMy4zOC43NDo4MDky'
        speed_test 'HTTP' '南昌' '电信' '' 'MTE3LjIxLjc1LjIxMDo4MDky'
        speed_test 'HTTP' '长沙' '电信' '' 'MjIyLjI0Ny4zMC4yNDY6ODA5Mg=='

        speed_test 'HTTP' '西安' '电信' '' 'MjIyLjkxLjE0Ny43ODo4MDky'
        speed_test 'HTTP' '重庆' '电信' '' 'MjIyLjE4MS4xNS4yNjo4MDky'
        speed_test 'HTTP' '成都' '电信' '' 'MTI1LjY5Ljg3LjE5NDo4MDky'
    fi

    if [[ ${selection} == 1 ]] || [[ ${selection} == 4 ]]; then
        speed_test 'HTTP' '哈尔滨' '联通' '' 'MTEzLjQuNjguNDI6ODA5Mg=='
        speed_test 'HTTP' '长春' '联通' '' 'MjIyLjE2MS4yMjMuMTQ2OjgwOTI='
        speed_test 'HTTP' '沈阳' '联通' '' 'MjE4LjYwLjU4LjM0OjgwOTI='
        speed_test 'HTTP' '北京' '联通' '' 'NjEuMTM1LjIxNC41NDo4MDky'
        speed_test 'HTTP' '天津' '联通' '' 'NjEuMTM2LjI2LjE2Mjo4MDky'
        speed_test 'HTTP' '石家庄' '联通' '' 'NjEuMjQwLjE1OS42Mjo4MDky'
        speed_test 'HTTP' '太原' '联通' '' 'MjIxLjIwNC41LjI0Njo4MDky'
        speed_test 'HTTP' '济南' '联通' '' 'NjAuMjE3LjIyOS4xOTU6ODA5Mg=='
        speed_test 'HTTP' '郑州' '联通' '' 'NjEuNTIuMjUxLjMwOjgwOTI='
        speed_test 'HTTP' '上海' '联通' '' 'MjEwLjUxLjU3LjEwOjgwOTI='
        speed_test 'HTTP' '杭州' '联通' '' 'MTAxLjY5LjI1NC4yMDY6ODA5Mg=='
        # 无南京
        speed_test 'HTTP' '合肥' '联通' '' 'MTEyLjEzMi4yMzAuMTU0OjgwOTI='
        speed_test 'HTTP' '武汉' '联通' '' 'MjEwLjUxLjIxNS41ODo4MDky'
        speed_test 'HTTP' '南昌' '联通' '' 'MTE4LjIxMi4xMzIuMTYyOjgwOTI='
        speed_test 'HTTP' '长沙' '联通' '' 'MTEwLjUzLjE2Mi4yMDM6ODA5Mg=='
        speed_test 'HTTP' '福州' '联通' '' 'NTguMjIuMTA0LjI4OjgwOTI='
        speed_test 'HTTP' '广州' '联通' '' 'MjE4LjEwNy44LjE4OjgwOTI='
        speed_test 'HTTP' '南宁' '联通' '' 'MjIxLjcuMTM1LjI1NDo4MDky'
        speed_test 'HTTP' '海口' '联通' '' 'MTEzLjU5LjM0LjExMzo4MDky'
        speed_test 'HTTP' '昆明' '联通' '' 'MjIxLjMuMTMxLjIxODo4MDky'
        speed_test 'HTTP' '贵阳' '联通' '' 'MjIxLjEzLjM0Ljc0OjgwOTI='
        speed_test 'HTTP' '西安' '联通' '' 'MTI0Ljg5Ljg1LjE5MDo4MDky'
        speed_test 'HTTP' '重庆' '联通' '' 'MTEzLjIwNC4zNS4xNTQ6ODA5Mg=='
        speed_test 'HTTP' '成都' '联通' '' 'MTE5LjYuOTAuMTU4OjgwOTI='
        speed_test 'HTTP' '兰州' '联通' '' 'MTE1Ljg1LjE5Mi4xMDo4MDky'
        speed_test 'HTTP' '西宁' '联通' '' 'MjIxLjIwNy41Ni45NDo4MDky'
        speed_test 'HTTP' '银川' '联通' '' 'NDIuNjMuMS4yNTQ6ODA5Mg=='
        speed_test 'HTTP' '呼和浩特' '联通' '' 'MTE2LjExMy42OS4xOTQ6ODA5Mg=='
        speed_test 'HTTP' '拉萨' '联通' '' 'MjIxLjEzLjY0LjM3OjgwOTI='
        speed_test 'HTTP' '乌鲁木齐' '联通' '' 'NjAuMTMuMTMzLjE1MDo4MDky'
    fi

    if [[ ${selection} == 2 ]] || [[ ${selection} == 7 ]]; then
        speed_test 'HTTP' '北京' '联通' '' 'NjEuMTM1LjIxNC41NDo4MDky'
        speed_test 'HTTP' '天津' '联通' '' 'NjEuMTM2LjI2LjE2Mjo4MDky'
        speed_test 'HTTP' '石家庄' '联通' '' 'NjEuMjQwLjE1OS42Mjo4MDky'

        speed_test 'HTTP' '上海' '联通' '' 'MjEwLjUxLjU3LjEwOjgwOTI='
        speed_test 'HTTP' '杭州' '联通' '' 'MTAxLjY5LjI1NC4yMDY6ODA5Mg=='
        speed_test 'HTTP' '合肥' '联通' '' 'MTEyLjEzMi4yMzAuMTU0OjgwOTI='

        speed_test 'HTTP' '福州' '联通' '' 'NTguMjIuMTA0LjI4OjgwOTI='
        speed_test 'HTTP' '广州' '联通' '' 'MjE4LjEwNy44LjE4OjgwOTI='
        speed_test 'HTTP' '南宁' '联通' '' 'MjIxLjcuMTM1LjI1NDo4MDky'

        speed_test 'HTTP' '武汉' '联通' '' 'MjEwLjUxLjIxNS41ODo4MDky'
        speed_test 'HTTP' '南昌' '联通' '' 'MTE4LjIxMi4xMzIuMTYyOjgwOTI='
        speed_test 'HTTP' '长沙' '联通' '' 'MTEwLjUzLjE2Mi4yMDM6ODA5Mg=='

        speed_test 'HTTP' '西安' '联通' '' 'MTI0Ljg5Ljg1LjE5MDo4MDky'
        speed_test 'HTTP' '重庆' '联通' '' 'MTEzLjIwNC4zNS4xNTQ6ODA5Mg=='
        speed_test 'HTTP' '成都' '联通' '' 'MTE5LjYuOTAuMTU4OjgwOTI='
    fi

    if [[ ${selection} == 1 ]] || [[ ${selection} == 5 ]]; then
        speed_test 'HTTP' '哈尔滨' '移动' '' 'MTExLjQwLjI0Ny42OjgwOTI='
        speed_test 'HTTP' '长春' '移动' '' 'MTExLjI2LjEzOS4zMDo4MDky'
        speed_test 'HTTP' '沈阳' '移动' '' 'MjIxLjE4MC4yNDEuMzQ6ODA5Mg=='
        speed_test 'HTTP' '北京' '移动' '' 'MTExLjEzLjYwLjMzOjgwOTI='
        speed_test 'HTTP' '天津' '移动' '' 'MTE3LjEzMS4yMTUuMTM5OjgwOTI='
        speed_test 'HTTP' '石家庄' '移动' '' 'MTExLjExLjI2LjEyNjo4MDky'
        speed_test 'HTTP' '太原' '移动' '' 'MTgzLjIwMy4yMTcuMjU0OjgwOTI='
        speed_test 'HTTP' '济南' '移动' '' 'MTIwLjE5Mi44My4xNDY6ODA5Mg=='
        speed_test 'HTTP' '郑州' '移动' '' 'MTIwLjE5NC4wLjE0OjgwOTI='
        speed_test 'HTTP' '上海' '移动' '' 'MTE3LjEzNS4xMjMuMzQ6ODA5Mg=='
        speed_test 'HTTP' '杭州' '移动' '' 'MTExLjEuMzQuMTIzOjgwOTI='
        speed_test 'HTTP' '南京' '移动' '' 'MTgzLjIwNy44MS4xNDI6ODA5Mg=='
        speed_test 'HTTP' '合肥' '移动' '' 'MTEyLjI5LjAuMTkwOjgwOTI='
        speed_test 'HTTP' '武汉' '移动' '' 'MTExLjQ3LjI0My4xOTc6ODA5Mg=='
        speed_test 'HTTP' '南昌' '移动' '' 'MjIzLjgyLjEzNy41OjgwOTI='
        speed_test 'HTTP' '长沙' '移动' '' 'MTExLjguOS4xNDk6ODA5Mg=='
        speed_test 'HTTP' '福州' '移动' '' 'MTEyLjUwLjI1MC41ODo4MDky'
        speed_test 'HTTP' '广州' '移动' '' 'MTgzLjIzMi42NS44NTo4MDky'
        speed_test 'HTTP' '南宁' '移动' '' 'MTExLjEyLjc5LjI1MDo4MDky'
        speed_test 'HTTP' '海口' '移动' '' 'MjIxLjE4Mi4xMjguMTk4OjgwOTI='
        speed_test 'HTTP' '昆明' '移动' '' 'MTgzLjIyNC4zMi4yNTQ6ODA5Mg=='
        speed_test 'HTTP' '贵阳' '移动' '' 'MTE3LjEzNS4yMDAuMjQ2OjgwOTI='
        speed_test 'HTTP' '西安' '移动' '' 'MTIwLjE5Mi4yNDMuMTkwOjgwOTI='
        speed_test 'HTTP' '重庆' '移动' '' 'MjE4LjIwMS4xLjI0OTo4MDky'
        speed_test 'HTTP' '成都' '移动' '' 'MjE4LjIwMy4yNTAuMTA6ODA5Mg=='
        speed_test 'HTTP' '兰州' '移动' '' 'MTE3LjE1Ni4yNDEuMjA2OjgwOTI='
        speed_test 'HTTP' '西宁' '移动' '' 'MTExLjEyLjIwOS44Mjo4MDky'
        speed_test 'HTTP' '银川' '移动' '' 'MjExLjEzOC42Mi4xMjY6ODA5Mg=='
        speed_test 'HTTP' '呼和浩特' '移动' '' 'MTExLjU2LjE3LjE5NDo4MDky'
        speed_test 'HTTP' '拉萨' '移动' '' 'MTExLjExLjE5OS42OjgwOTI='
        speed_test 'HTTP' '乌鲁木齐' '移动' '' 'MTE3LjE5MS4xNC4xMTg6ODA5Mg=='
    fi

    if [[ ${selection} == 2 ]] || [[ ${selection} == 8 ]]; then
        speed_test 'HTTP' '北京' '移动' '' 'MTExLjEzLjYwLjMzOjgwOTI='
        speed_test 'HTTP' '天津' '移动' '' 'MTE3LjEzMS4yMTUuMTM5OjgwOTI='
        speed_test 'HTTP' '石家庄' '移动' '' 'MTExLjExLjI2LjEyNjo4MDky'

        speed_test 'HTTP' '上海' '移动' '' 'MTE3LjEzNS4xMjMuMzQ6ODA5Mg=='
        speed_test 'HTTP' '杭州' '移动' '' 'MTExLjEuMzQuMTIzOjgwOTI='
        speed_test 'HTTP' '南京' '移动' '' 'MTgzLjIwNy44MS4xNDI6ODA5Mg=='

        speed_test 'HTTP' '广州' '移动' '' 'MTgzLjIzMi42NS44NTo4MDky'
        speed_test 'HTTP' '福州' '移动' '' 'MTEyLjUwLjI1MC41ODo4MDky'
        speed_test 'HTTP' '南宁' '移动' '' 'MTExLjEyLjc5LjI1MDo4MDky'

        speed_test 'HTTP' '武汉' '移动' '' 'MTExLjQ3LjI0My4xOTc6ODA5Mg=='
        speed_test 'HTTP' '南昌' '移动' '' 'MjIzLjgyLjEzNy41OjgwOTI='
        speed_test 'HTTP' '长沙' '移动' '' 'MTExLjguOS4xNDk6ODA5Mg=='

        speed_test 'HTTP' '西安' '移动' '' 'MTIwLjE5Mi4yNDMuMTkwOjgwOTI='
        speed_test 'HTTP' '重庆' '移动' '' 'MjE4LjIwMS4xLjI0OTo4MDky'
        speed_test 'HTTP' '成都' '移动' '' 'MjE4LjIwMy4yNTAuMTA6ODA5Mg=='
    fi

    end=$(date +%s)
    echo -e "\r——————————————————————————————————————————————————————————————————————"

    if [[ "$thread" == "" ]]; then
        echo -ne "  单线程"
    else
        echo -ne "  多线程"
    fi

    time=$(( $end - $start ))
    if [[ $time -gt 60 ]]; then
        min=$(expr $time / 60)
        sec=$(expr $time % 60)
        echo -e "测试完成, 本次测速耗时: ${min} 分 ${sec} 秒"
    else
        echo -e "测试完成, 本次测速耗时: ${time} 秒"
    fi
    echo -ne "  当前时间: "
    echo $(TZ=Asia/Shanghai date --rfc-3339=seconds)
}

run_all() {
    check_wget;
    check_bimc;
    clear
    print_info;
    get_options;
    run_test;
    rm -rf bimc
}

LANG=C
run_all

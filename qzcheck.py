# -*- coding: utf-8 -*-
import requests
import subprocess
import re
import random


def excuteCommand(com):
    ex = subprocess.Popen(com, stdout=subprocess.PIPE, shell=True)
    out, err = ex.communicate()
    statusofssh = ex.wait()
    # print("cmd in:", com)
    # print("cmd out: ", out.decode())
    return out.decode()


def scamalytics(ip):
    try:
        context = requests.get(f"https://scamalytics.com/ip/{ip}",
                               timeout=10).text
        temp1 = re.findall(f">Fraud Score: (.*?)</div", context)[0]
        print(f"欺诈分数(越低越好)：{temp1}")
        temp2 = re.findall(f"<div(.*?)div>", context)[-6:]
        nlist = ["匿名代理", "Tor出口节点", "服务器IP", "公共代理", "网络代理", "搜索引擎机器人"]
        for i, j in zip(temp2, nlist):
            temp3 = re.findall(f"\">(.*?)</", i)[0]
            print(f"{j}: {temp3}")
    except:
        pass


def cloudflare():
    try:
        status = 0
        for i in range(1, 101):
            try:
                context1 = requests.get(
                    f"https://cf-threat.sukkaw.com/hello.json?threat={str(i)}",
                    timeout=10).text
                try:
                    if "pong!" not in context1:
                        print(
                            "Cloudflare威胁得分高于10为爬虫或垃圾邮件发送者,高于40有严重不良行为(如僵尸网络等),数值一般不会大于60"
                        )
                        print("Cloudflare威胁得分：", str(i))
                        status = 1
                        break
                except:
                    pass
            except:
                status = -1
                pass
        if i == 100 and status == 0:
            print("Cloudflare威胁得分(0为低风险): 0")
    except:
        pass


def abuse(ip):
    try:
        try:
            context2 = requests.get(
                f"https://api.abuseipdb.com/api/v2/check?ipAddress={ip}",
                headers=head,
                timeout=10)
        except:
            for i in keys_list:
                head["key"] = keys_list[random.randint(0, len(keys_list))]
                try:
                    context2 = requests.get(
                        f"https://api.abuseipdb.com/api/v2/check?ipAddress={ip}",
                        headers=head,
                        timeout=10)
                    break
                except:
                    pass
        print("IP类型：", str(context2.json()["data"]["usageType"]))
        print("abuse得分：", str(context2.json()["data"]["abuseConfidenceScore"]))
    except Exception as e:
        print(e)


def google():
    try:
        with open("gdlog", "r") as fp:
            context3 = fp.read()
        if "https" in context3:
            print("Google搜索可行性：yes")
        else:
            print("Google搜索可行性：no")
    except:
        print("Google搜索可行性：no")


keys_list = [
    "e0ea0d2980ae971b27af40040769cc6db60a34e02f1c517d67db7e05efe3183a26a3bc959f1656cf"
]
head = {
    "Accept":
    "application/json",
    "key":
    "c515467669330390a935a974506eef7f9e27d89e81f5835649711a858bdd7c0b61a6d9386e74ce24"
}

ip4 = excuteCommand("curl -sm8 ip.sb").replace("\n", "").replace(" ", "")
ip6 = excuteCommand("curl -s6m8 ip.gs -k").replace("\n", "").replace(" ", "")
scamalytics(ip4)
cloudflare()
abuse(ip4)
google()
if ip6 != "":
    print("------以下为IPV6检测------")
    scamalytics(ip6)
    abuse(ip6)

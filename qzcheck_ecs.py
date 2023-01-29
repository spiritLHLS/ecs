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

def translate_status(status):
    if status == False:
        return "No"
    elif status == True:
        return "Yes"

def scamalytics(ip):
    print("scamalytics数据库:")
    try:
        context = requests.get(f"https://scamalytics.com/ip/{ip}",
                               timeout=10).text
        temp1 = re.findall(f">Fraud Score: (.*?)</div", context)[0]
        print(f"  欺诈分数(越低越好)：{temp1}")
        temp2 = re.findall(f"<div(.*?)div>", context)[-6:]
        nlist = ["匿名代理", "Tor出口节点", "服务器IP", "公共代理", "网络代理", "搜索引擎机器人"]
        for i, j in zip(temp2, nlist):
            temp3 = re.findall(f"\">(.*?)</", i)[0]
            print(f"  {j}: {temp3}")
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
        print("abuseipdb数据库-abuse得分：",
              str(context2.json()["data"]["abuseConfidenceScore"]))
        print("IP类型:")
        print("  IP2Location数据库: ", str(context2.json()["data"]["usageType"]))
    except Exception as e:
        pass
        # print(f"abuseipdb数据库IP类型：未知，爆错{e}")
        #print(e)


def ping0(ip):
    try:
        try:
            context3 = requests.get(f"https://ip.ping0.cc/ip/{ip}", timeout=10)
        except:
            pass
        try:
            if "IP 类型:              " in str(context3.text):
                temp = str(context3.text).split('span')
                for k in temp:
                    #print(k)
                    if "IP 类型:              " in k:
                        res = re.findall(f'IP 类型:              (.*?)"',
                                         k)[0].replace("\\", "")
                        res = res.replace("rn", "")
                        print(f"  ping0数据库: {res}")
        except:
            type_list = []
            if '家庭宽带IP' in str(context3.text) and str(
                    context3.text).count('家庭宽带IP') == 3:
                type_list.append("家庭宽带IP")
            if 'IDC机房IP' in str(context3.text) and str(
                    context3.text).count('IDC机房IP') == 3:
                type_list.append("IDC机房IP")
            ct = ""
            for kk in type_list:
                ct = ct + kk
            print(f"  ping0数据库: {ct}")
    except Exception as e:
        pass
        # print(f"ping0数据库IP类型：未知，爆错{e}")
        # print(e)


def liveipmap(ip):
    try:
        try:
            context4 = excuteCommand(
                f"curl -sm8 https://www.liveipmap.com/?ip={ip}")
        except:
            pass
        try:
            # print(context4)
            if "Usage Type" in context4:
                temp = context4.split('tr')
                for k in temp:
                    if "Usage Type" in k:
                        res = k.split("<td>")[1].split('>')[2].split('<')[0]
                        print(f"  liveipmap数据库：{res}")
        except:
            pass
    except Exception as e:
        pass
        # print(f"liveipmap数据库IP类型：未知，爆错{e}")
        # print(e)


def ipapi(ip):
    try:
        context = requests.get(
            f"http://ip-api.com/json/{ip}?fields=mobile,proxy,hosting",
            timeout=10).json()
        try:
            context['mobile']
            print("ip-api数据库:")
            print(f"  手机流量: {translate_status(context['mobile'])}")
            context['proxy']
            print(f"  代理服务: {translate_status(context['proxy'])}")
            context['hosting']
            print(f"  数据中心: {translate_status(context['hosting'])}")
        except:
            pass
    except:
        pass


def google():
    try:
        with open("gdlog", "r") as fp:
            context3 = fp.read()
        if "https" in context3:
            print("Google搜索可行性：YES")
        else:
            print("Google搜索可行性：NO")
    except:
        print("Google搜索可行性：未知")

keys_list = [
  "e0ea0d2980ae971b27af40040769cc6db60a34e02f1c517d67db7e05efe3183a26a3bc959f1656cf"
]
head = {
  "Accept":
  "application/json",
  "key":
  "e88362808d1219e27a786a465a1f57ec3417b0bdeab46ad670432b7ce1a7fdec0d67b05c3463dd3c"
}

ip4 = excuteCommand("curl -s4m8 -k ip.sb").replace("\n", "").replace(" ", "")
ip6 = excuteCommand("curl -s6m8 -k api.ipify.org").replace("\n", "").replace(" ", "")
print("------以下为IPV4检测------")
scamalytics(ip4)
ipapi(ip4)
abuse(ip4)
liveipmap(ip4)
ping0(ip4)
google()
if ip6 != "":
  print("------以下为IPV6检测------")
  scamalytics(ip6)
  abuse(ip6)

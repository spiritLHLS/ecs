# -*- coding: utf-8 -*-
import urllib.request
import subprocess
import re, sys
import json
import random


ip4 = str(sys.argv[1])

keys_list = [
    "e0ea0d2980ae971b27af40040769cc6db60a34e02f1c517d67db7e05efe3183a26a3bc959f1656cf"
]

head = {
    "Accept":
    "application/json",
    "key": "e88362808d1219e27a786a465a1f57ec3417b0bdeab46ad670432b7ce1a7fdec0d67b05c3463dd3c"
}

def excuteCommand(com):
    ex = subprocess.Popen(com, stdout=subprocess.PIPE, shell=True)
    out, err = ex.communicate()
    statusofssh = ex.wait()
    # print("cmd in:", com)
    # print("cmd out: ", out.decode())
    return out.decode()

def get_page_text(url, return_type='txt', headers=head):
    req = urllib.request.Request(url, headers=headers)
    response = urllib.request.urlopen(req, timeout=10)
    if return_type == 'txt':
        text = response.read().decode('utf-8')
        return text
    elif return_type == 'json':
        json_data = response.read().decode('utf-8')
        data = json.loads(json_data)
        return data
        
def translate_status(status):
    if status == False:
        return "No"
    elif status == True:
        return "Yes"

def scamalytics(ip):
    print("scamalytics数据库:")
    try:
        context = get_page_text(f"https://scamalytics.com/ip/{ip}")
        temp1 = re.findall(f">Fraud Score: (.*?)</div", context)[0]
        print(f"  欺诈分数(越低越好)：{temp1}")
        temp2 = re.findall(f"<div(.*?)div>", context)[-6:]
        nlist = ["匿名代理", "Tor出口节点", "服务器IP", "公共代理", "网络代理", "搜索引擎机器人"]
        for i, j in zip(temp2, nlist):
            temp3 = re.findall(f"\">(.*?)</", i)[0]
            print(f"  {j}: {temp3}")
    except:
        pass

def abuse(ip):
    try:
        try:
            context2 = get_page_text(f"https://api.abuseipdb.com/api/v2/check?ipAddress={ip}", "json")
        except:
            for i in keys_list:
                head["key"] = keys_list[random.randint(0, len(keys_list))]
                try:
                    context2 = get_page_text(f"https://api.abuseipdb.com/api/v2/check?ipAddress={ip}", "json")
                    break
                except:
                    pass
        print("abuseipdb数据库-abuse得分：",
              str(context2["data"]["abuseConfidenceScore"]))
        print("IP类型:")
        print("  IP2Location数据库: ", str(context2["data"]["usageType"]))
    except Exception as e:
        pass
        # print(f"abuseipdb数据库IP类型：未知，爆错{e}")
        #print(e)

def liveipmap(ip):
    try:
        try:
            context3 = get_page_text(f"https://www.liveipmap.com/?ip={ip}")
        except:
            pass
        try:
            if "Usage Type" in context3:
                temp = context3.split('tr')
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
        context4 = get_page_text(f"http://ip-api.com/json/{ip}?fields=mobile,proxy,hosting", "json")
        try:
            context4['mobile']
            print("ip-api数据库:")
            print(f"  手机流量: {translate_status(context4['mobile'])}")
            context4['proxy']
            print(f"  代理服务: {translate_status(context4['proxy'])}")
            context4['hosting']
            print(f"  数据中心: {translate_status(context4['hosting'])}")
        except:
            pass
    except:
        pass

def ip234(ip):
  try:
    try:
      context5 = get_page_text(f"http://ip234.in/fraud_check?ip={ip}", "json")
    except:
      pass
    risk = context5["data"]["score"]
    print(f"ip234数据库：")
    print(f"  欺诈分数(越低越好)：{risk}")
  except:
    pass

scamalytics(ip4)
ip234(ip4)
ipapi(ip4)
abuse(ip4)
liveipmap(ip4)

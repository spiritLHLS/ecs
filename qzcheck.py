import requests
import subprocess
import re

def excuteCommand(com):
    ex = subprocess.Popen(com, stdout=subprocess.PIPE, shell=True)
    out, err = ex.communicate()
    status = ex.wait()
    # print("cmd in:", com)
    # print("cmd out: ", out.decode())
    return out.decode()

ip = excuteCommand("curl -sm8 ip.sb").replace("\n", "").replace(" ", "")
context = requests.get(f"https://scamalytics.com/ip/{ip}", timeout=30).text
temp1 = re.findall(f">Fraud Score: (.*?)</div", context)[0]
print(f"欺诈分数(越低越好)：{temp1}")
temp2 = re.findall(f"<div(.*?)div>", context)[-6:]
nlist = ["匿名代理", "Tor出口节点", "服务器IP", "公共代理", "网络代理", "搜索引擎机器人"]
for i, j in zip(temp2, nlist):
    temp3 = re.findall(f"\">(.*?)</", i)[0]
    print(f"{j}: {temp3}")
for i in range(0, 101):
    try:
        context1 = requests.get(f"https://cf-threat.sukkaw.com/hello.json?threat={str(i)}", timeout=1).json["ping"]
        if "pong!" not in context1:
            print("0判定为低风险,高于10判定为爬虫或者垃圾邮件发送者,高于40判定为有严重不良行为的IP(如僵尸网络等),这个数值一般不会大于60")
            print("Cloudflare威胁得分：", context1)
            break
    except:
        pass
        

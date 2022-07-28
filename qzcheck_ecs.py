import requests
import subprocess
import re
import random


def excuteCommand(com):
    ex = subprocess.Popen(com, stdout=subprocess.PIPE, shell=True)
    out, err = ex.communicate()
    status = ex.wait()
    # print("cmd in:", com)
    # print("cmd out: ", out.decode())
    return out.decode()


keys_list = [
    "e0ea0d2980ae971b27af40040769cc6db60a34e02f1c517d67db7e05efe3183a26a3bc959f1656cf"
]
head = {
    "Accept":
    "application/json",
    "key":
    "c515467669330390a935a974506eef7f9e27d89e81f5835649711a858bdd7c0b61a6d9386e74ce24"
}

ip = excuteCommand("curl -sm8 ip.sb").replace("\n", "").replace(" ", "")
try:
  context = requests.get(f"https://scamalytics.com/ip/{ip}", timeout=6).text
  temp1 = re.findall(f">Fraud Score: (.*?)</div", context)[0]
  print(f"欺诈分数(越低越好)：{temp1}")
  temp2 = re.findall(f"<div(.*?)div>", context)[-6:]
  nlist = ["匿名代理", "Tor出口节点", "服务器IP", "公共代理", "网络代理", "搜索引擎机器人"]
  for i, j in zip(temp2, nlist):
      temp3 = re.findall(f"\">(.*?)</", i)[0]
      print(f"{j}: {temp3}")
except:
  pass
try:
    try:
        context2 = requests.get(
            f"https://api.abuseipdb.com/api/v2/check?ipAddress={ip}",
            headers=head, timeout=6)
    except:
        for i in keys_list:
            head["key"] = keys_list[random.randint(0,len(keys_list))]
            try:
                context2 = requests.get(
                    f"https://api.abuseipdb.com/api/v2/check?ipAddress={ip}",
                    headers=head, timeout=6)
                break
            except:
                pass
    print("IP类型：", str(context2.json()["data"]["usageType"]))
    print("abuse得分：", str(context2.json()["data"]["abuseConfidenceScore"]))
except Exception as e:
    print(e)

try:
    with open("gdlog", "r") as fp:
        context3 = fp.read()
    if "https" in context3:
        print("Google搜索可行性：yes")
    else:
        print("Google搜索可行性：no")
except:
    print("Google搜索可行性：no")

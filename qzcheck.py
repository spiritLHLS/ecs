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
context = requests.get(f"https://scamalytics.com/ip/{ip}").text
temp1 = re.findall(f">Fraud Score: (.*?)</div", context)[0]
print(f"欺诈分数：{temp1}")
temp2 = re.findall(f"<div(.*?)div>", context)[-6:]
nlist = ["匿名代理", "Tor出口节点", "服务器IP", "公共代理", "网络代理", "搜索引擎机器人"]
for i, j in zip(temp2, nlist):
    temp3 = re.findall(f"\">(.*?)</", i)[0]
    print(f"{j}: {temp3}")

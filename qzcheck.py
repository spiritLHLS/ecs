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


keys_list = [
    "e0ea0d2980ae971b27af40040769cc6db60a34e02f1c517d67db7e05efe3183a26a3bc959f1656cf",
    "24d3a4c5d7a8044396c1075a39d9ec68336c8ff14897087b06f4f147d3d8a69e7acee7e1d4d64a66",
    "19a74f48e2b914e9db81d99475f876dbd4c590377d9c9b6602327c321a8e81fff0aa2237b6d6b588",
    "d8dc9983dc9b8364f5208f6b706dcbed4dda697e9a6cf922636a49c6b865054aaf70c75ee5147939",
    "e8681e21ea36a0b0454ccc354ff8306043c41c4c69409b6b32be3444bfa5f65e8ca72d407ec8dc77",
    "a2534807b8b0a5a79072839dcae54e65dd999d9273553bfca05c094a073c11972aed748682c23b83",
    "5e2850ef5a64344c01a8a9449926b95c6656f56f3bb8dfca8c5979527f55c253d154f8b33478904c",
    "1018e1b356b388aaea95492c751fa6b5a4dea1333d613815d4cb13df9231a93b9e01b3a69e3b8fe5",
    "124edb2bed9ea9c6500f6d66945cefda615036d8cf757a4e0a55ffe27caf09a5a702be4e578dbe7f",
    "24e3e65211041dae64bfb027c01171d6abec513c2126e8b1980c3b7cf214ae5d3cb271f3dc5bce88",
    "940dd2873b7be63f14a65b015729162151a31048e69401f21ee46103a9ca09fdae066f2ca2a30780",
    "fa2da98d20d5ba360434132d812504c5e43846596e90a1e28221df473068348ccb70f52a0edb8463",
    "1c32060ffde880e02f141ada773d8b9ec746dc0f9d5016e7431c9358e4f9f8917c39f33d6e2fcda9",
    "6f2826532336cbb65f038f3abd2893b15e4fb568d32e9989003647277274380a9e607372324ddb66",
    "56348a879ca27fd5912ffcb2e7e86d78cd9d099e7c79f29e2a16e09888d471c1cf1fa23a638c40cb"
]
head = {
    "Accept":
    "application/json",
    "key":
    "c515467669330390a935a974506eef7f9e27d89e81f5835649711a858bdd7c0b61a6d9386e74ce24"
}

ip = excuteCommand("curl -sm8 ip.sb").replace("\n", "").replace(" ", "")
context = requests.get(f"https://scamalytics.com/ip/{ip}", timeout=30).text
temp1 = re.findall(f">Fraud Score: (.*?)</div", context)[0]
print(f"欺诈分数(越低越好)：{temp1}")
temp2 = re.findall(f"<div(.*?)div>", context)[-6:]
nlist = ["匿名代理", "Tor出口节点", "服务器IP", "公共代理", "网络代理", "搜索引擎机器人"]
for i, j in zip(temp2, nlist):
    temp3 = re.findall(f"\">(.*?)</", i)[0]
    print(f"{j}: {temp3}")
status = 0
for i in range(1, 101):
    try:
        context1 = requests.get(
            f"https://cf-threat.sukkaw.com/hello.json?threat={str(i)}",
            timeout=1).text
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
try:
    try:
        context2 = requests.get(
            f"https://api.abuseipdb.com/api/v2/check?ipAddress={ip}",
            headers=head)
    except:
        for i in keys_list:
            head["key"] = i
            try:
                context2 = requests.get(
                    f"https://api.abuseipdb.com/api/v2/check?ipAddress={ip}",
                    headers=head)
                break
            except:
                pass
    print("IP类型：", str(context2.json()["data"]["usageType"]))
    print("abuse得分：", str(context2.json()["data"]["abuseConfidenceScore"]))
except Exception as e:
    print(e)

try:
    with open("./gdlog.txt", "r") as fp:
        context3 = fp.read()
    print(context3)
    if "https://www.spiritysdx.top/" in context3:
        print("Google搜索可行性：yes")
    else:
        print("Google搜索可行性：no")
except:
    print("Google搜索可行性：no")

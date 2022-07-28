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

context = excuteCommand("curl -fsL -o ./t.sh.x https://github.com/lmc999/TikTokCheck/raw/main/t.sh.x && chmod +x ./t.sh.x && ./t.sh.x && rm ./t.sh.x").split("\n")
try:
    context1 = [i for i in context if "Tiktok Region" in i][0].replace(" ","").split(":")[2].replace("\t","")
except:
    context1 = "NO"
print("TikTok解锁区域：", context1)

import sys
import os
import time
import subprocess

def excuteCommand(com):
    ex = subprocess.Popen(com, stdout=subprocess.PIPE, shell=True)
    out, err  = ex.communicate()
    status = ex.wait()
    # print("cmd in:", com)
    # print("cmd out: ", out.decode())
    return out.decode()


ip = str(sys.argv[1])
os.system("rm -rf return.sh >/dev/null 2>&1")
time.sleep(1)
os.system("wget https://raw.githubusercontent.com/spiritLHLS/ecs/main/return.sh >/dev/null 2>&1")
time.sleep(3)
os.system("chmod 777 return.sh >/dev/null 2>&1")
time.sleep(0.5)
temp = excuteCommand(f"./return.sh {ip}").split("\n")
tp1 = []
status = 0
for i in temp:
    if "traceroute" in i:
        status = 1
    elif status == 1:
        tp1.append(i)
count = 0
temp_lists = []
ttpp = []
for i in tp1:
    if count%3 == 0:
        for j in ttpp:
            if len(j) > 1:
                temp_lists.append(j)
                break
        ttpp = []
    ttpp.append(i.split("ms"))
    count += 1
if ttpp != []:
    for j in ttpp:
        if len(j) > 1:
            temp_lists.append(j)
            break
temps = []
tep = ""
count = 0
tpe = ""
for i in temp_lists:
    if tep != i[1]:
        temps.append((i[1], temp_lists.count(i)))
        tpe = i
    tep = i[1]
if tpe != temp_lists[-1]:
    temps.append((temp_lists[-1][1], temp_lists.count(temp_lists[-1])))
news_temps = []
for i in temps:
    if "*" not in i:
        if i not in news_temps:
            news_temps.append(i)
    else:
        news_temps.append(i)
msg = "  本机地址\n"
for i in news_temps:
    msg = msg + i[0] + f",{i[1]}次" + "\n"
print(msg)
os.system("rm -rf return.sh")


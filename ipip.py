import subprocess
import sys

ip = str(sys.argv[1])
# r = os.popen('bash <(curl -sSL https://raw.githubusercontent.com/fscarmen/tools/main/return.sh) '+ip)
r = subprocess.run(f'bash <(curl -sSL https://raw.githubusercontent.com/fscarmen/tools/main/return.sh) {ip}', shell=True, capture_output=True, text=True)
temp = str(r.stdout).split("\n")
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
msg = "  本机地址\n"
for i in temps:
    msg = msg + i[0] + f",{i[1]}次" + "\n"
print(msg)


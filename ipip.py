import subprocess
import sys

ip = str(sys.argv[1])
ret = subprocess.run(f'bash <(curl -sSL https://raw.githubusercontent.com/fscarmen/tools/main/return.sh) {ip}', shell=True, capture_output=True, text=True)
temp = ret.stdout.split("\n")
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
msg = "  本机地址\n"
for i in temp_lists:
    msg = msg + i[1] + "\n"
try:
    print(msg)
except:
    print(msg.encode("utf-8").decode("latin1"))


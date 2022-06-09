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
            if len(j) > 3:
                temp_lists.append(j)
        ttpp = []
    ttpp.append(i.split(" "))
    count += 1
if ttpp != []:
    for j in ttpp:
        if len(j) > 3:
            temp_lists.append(j)
ASNS = []
countrys = []
location = []
nets = []
yys = []
for i in temp_lists:
    if i[0] != "":
        try:
            ASNS.append(i[7])
        except:
            ASNS.append("")
        try:
            countrys.append(i[9])
        except:
            countrys.append("")
        try:
            location.append(i[11])
        except:
            location.append("")
        try:
            nets.append(i[12])
        except:
            nets.append("")
        try:
            yys.append(i[13])
        except:
            yys.append("")
    else:
        try:
            if i[8] == "":
                if i[7][0:2] == "ms":
                    ASNS.append(i[7][2:])
                else:
                    ASNS.append(i[7])
                try:
                    countrys.append(i[9])
                except:
                    countrys.append("")
            else:
                ASNS.append(i[8])
                try:
                    countrys.append(i[10])
                except:
                    countrys.append("")
        except:
            ASNS.append("")
        try:
            location.append(i[12])
        except:
            location.append("")
        try:
            nets.append(i[13])
        except:
            nets.append("")
        try:
            yys.append(i[14])
        except:
            yys.append("")
msg = "本机地址\n"
for i, j, k, l, m in zip(ASNS,countrys,location,nets,yys):
    if i != "":
        tpp = f"{i},{j}{k}{l}{m}"
    else:
        tpp = f"{i}{j}{k}{l}{m}"
    if tpp == "," or tpp == "":
        msg = msg + "*\n"
    else:
        msg = msg + tpp + "\n"
print(msg)


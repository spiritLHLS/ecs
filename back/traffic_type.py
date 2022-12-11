import requests
import re


ip = str(sys.argv[1])
headers = {
  "User-Agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:101.0) Gecko/20100101 Firefox/101.0"
}
res = requests.get(f"https://ping.pe/{ip}",headers = headers,allow_redirects=True).text
text1 = re.findall(f'document.cookie="antiflood=(.*?)"',res)
antiflood = text1[0].split(";")[0]
headers["Cookie"] = "antiflood=" + antiflood
res2 = requests.get(f"https://ping.pe/{ip}",headers = headers,allow_redirects=True).text
temp = res2.split("\n")
for i in temp:
  if "id='page-div'" in i:
    result1 = i.split("<b>")[0].split("</a>")[-1].split(" ")[-2][1:-1]
print(result1)

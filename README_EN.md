# ecs

[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2FspiritLHLS%2Fecs&count_bg=%2357DEFF&title_bg=%23000000&icon=cliqz.svg&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://www.spiritlhl.net/)

[<img src="https://api.gitsponsors.com/api/badge/img?id=501535202" height="20">](https://api.gitsponsors.com/api/badge/link?p=haU3VlXCDVRGPfHZE5aj8w8TKG5twqbYUa3jtSjEzkLfg4Q9TY32mTyF8RyNmnCsp1NADZHpPEhh3aKZ039SVg1DhsoX7gsoTK2dMkHlCVVrrqx82KH/ppUK/8ryOqfjpqPCBCduftYP5VNUNidMJw==)

## Language

[中文文档](README.md) | [English Docs](README_EN.md)

## Foreword

**If there is a system/architecture that is not listed in this project, or if there is a bug that cannot be detected in this project's test, or if the test does not want to magically change the local configuration and wants to minimize the environment changes, or if you want to have a more comprehensive test.**

**Please try [https://github.com/oneclickvirt/ecs](https://github.com/oneclickvirt/ecs/blob/master/README_EN.md) for testing**

Support system:

Ubuntu 18+, Debian 8+, Centos 7+, Fedora 33+, Almalinux 8.5+, OracleLinux 8+, RockyLinux 8+, AstraLinux CE, Arch

Semi-support system:

FreeBSD(Prerequisites implemented```pkg install -y curl bash```)，Armbian

Support Architecture:

amd64(x86_64)、arm64、i386、arm

Support geography:

Anywhere you can connect to the Internet

PS: Considering the demand of universal testing for multi-system and multi-architecture, the Shell version of Fusion Monster is no longer for new feature development, only for maintenance, and the tests have been refactored to Golang version ([https://github.com/oneclickvirt/ecs](https://github.com/oneclickvirt/ecs/blob/master/README_EN.md)).

# Menu
- [Foreword](#Foreword)
- [Menu](#Menu)
- [VPS_Fusion_Monster_Server_Test_Script](#VPS_Fusion_Monster_Server_Test_Script)
  - [Fusion_Monster_command](#Fusion_Monster_command)
    - [Forms_of_interaction](#Forms_of_interaction)
    - [Forms_of_No-interaction](#Forms_of_No-interaction)
  - [IP_Quality_Inspection](#IP_Quality_Inspection)
  - [Fusion_Monster_Description](#Fusion_Monster_Description)
  - [Fusion_Monster_Function](#Fusion_Monster_Function)
- [Friendly_link](#Friendly_link)
  - [Review_Channel](#Review_Channel)
    - [https://t.me/vps\_reviews](#httpstmevps_reviews)
- [Stargazers_over_time](#Stargazers_over_time)
- [Thanks](#Thanks)

<a id="top"></a>
------
<a id="artical_1"></a>

# VPS_Fusion_Monster_Server_Test_Script

## Fusion_Monster_command

### Forms_of_interaction

```bash
curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh -en
```

OR

```bash
curl -L https://github.com/spiritLHLS/ecs/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh -en
```

OR

```
bash <(wget -qO- bash.spiritlhl.net/ecs) -en
```

### Forms_of_No-interaction

```bash
curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh -en -m 1
```

OR

```bash
curl -L https://github.com/spiritLHLS/ecs/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh -en -m 1
```

OR

```
curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh
```

Download the script file and use something like

```bash
bash ecs.sh -en -m 1
```

Such a parameterized command specifies the option to execute

The following is a description of the parameters:

| Command | Item | Description | Remarks |
| ---- | ---- | ----------- | ---- |
| -m | Mandatory | Specify the corresponding option in the original menu, supports up to three levels of selection, e.g. executing ```bash ecs.sh -m 5 1 1``` will select the script to execute under sub-option 1 of option 1 of option 5 in the main menu | Specify only one parameter by default, e.g. executing ``` -m 1``` will only specify to execute the fusion monsters' complete body, executing ```-m 1 0``` and ```-m 1 0 0``` will both specify to execute the fusion monsters' complete body. and ``` -m 1 0 0``` both specify execution of the full fusion monster |
| -en | Optional | Forces output to English | Without this command, Chinese output is used by default |
| -i | Optional | Specifies the target IPV4 address for the backhaul routing test | Specify the local IPV4 address after obtaining it from ```ip.sb```, ```ipinfo.io```, etc. |
| -base | Optional | Specifies that only the base system information is tested | Without this command, the default is to test according to the combination of menu options |
| -ctype | optional | Specifies the method to test the cpu, options are ```gb4```, ```gb5```, ```gb6``` corresponding to geeksbench version 4, 5, 6 respectively | Without this command, the default is to use sysbench |
| -dtype | Optional | Specifies the program to test the IO of the hard disk, options are ```dd```, ```fio```, the former is faster and the latter is slower | Without this command, the default is to use all tests |
| -mdisk | Optional | Specify to test the IO of multiple mounted disks | Note that this command includes testing the system disk | -stype | -mdisk | Optional | Specifies to test the IO of multiple mounted disks.
| -bansp | Optional | Specify to force no speed test | Without this command, the default is to test speed | -banup | Optional | Specify to force no speed test | Without this command, the default is to test speed | -banup | Optional | Specify to force no speed test | Without this command, the default is to test speed
| -banup | Optional | Specify to force no sharing links to be generated | Without this command, sharing links will be generated by default | -banup | Optional | Specify to force no sharing links to be generated | Without this command, sharing links will be generated by default

## IP_Quality_Inspection

- IP quality inspection with multiple database lookups and blacklist lookups
- With ``IPV4`` and ``IPV6`` inspection, including ASN and address lookups.

```bash
bash <(wget -qO- bash.spiritlhl.net/ecs-ipcheck)
```

OR

```bash
bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/spiritLHLS/ecs/main/ipcheck.sh)
```

OR

Pre-installation is required ```dos2unxi```

```bash
wget -qO ipcheck.sh --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/ipcheck.sh
dos2unix ipcheck.sh
bash ipcheck.sh
```

## Fusion_Monster_Description

The fusion monster script is best executed under the /root path to avoid all sorts of weird problems

The result of the fusion monster is saved in ```test_result.txt``` under the current path, which can be executed in ```screen``` or ```tmux```, first log out of SSH and log in for a period of time before checking the file.

**Sometimes want to test some of the configuration of the machine is extremely pull across the above so that the implementation of this can be avoided IO or CPU is too much garbage caused by the test process of the SSH connection interruption, will not test half of the nothing, if the screen in the display of the garbled, but also no problem, to share the link in the results are not garbled**

The full version and lite version of Fusion Monster will automatically upload the results to pastebin and send back the sharing link when finished, if you want to quit halfway through the test, then press ```Ctrl+C``` at the same time to terminate the test, and then it will automatically quit and delete the remaining files.

Use **CDN** to accelerate the server environment installation and prefabricated file downloads

Explanation of Fusion Monster test and content explanation of some test results (recommended view for first time users):
<details>

In addition to the original content has been marked, all the remaining partitions are borrowed and optimized and modified version, not the same as the original corresponding scripts

All tests have considered the use of parallel testing, and in some parts of the use of the technology, optimized than the normal sequential execution of 2 ~ 3 minutes, belong to the unique, no test has the same kind of technology for the time being

The system basic information test incorporates a number of other part of my own patch test (systl, NAT type detection, concurrent ASN detection, etc.), it should be the most comprehensive and most common at present

CPU test default use sysbench test score, not yabs gb4 or gb5 (although the default is not gekbench but you can specify the common version of gekbench through the command to test), the former is just a simple calculation of the number of primes to test the speed of the fast, the latter gekbench is a comprehensive test system to count the weighted score!

The use of sysbench test score is the number of events processed per second, this indicator whether in the strong or weak performance of the server can be quickly measured, while many of the geekbench is not measured or very slow at least 2 minutes and a half

CPU test single-core sysbench score of more than 5000 can be counted in the first tier, 4000 to 5000 points counted in the second tier, every 1000 points counted in a class, see for yourself in which class it!

AMD's 7950x single-core full-blooded performance score of 6500 or so, AMD's 5950x single-core full-blooded performance score of 5700 or so, Intel's ordinary CPU (E5 and so on) in the 1000 ~ 800 or so, less than 500 single-core CPU can be said to be the performance of the more rotten!

IO test included two kinds, from lemonbench's dd disk test and yabs's fio disk test, a comprehensive view will be better, the former may be biased error but the test speed is fast without hard disk size limitations, the latter a little more realistic but the test speed is slow with hard disk as well as memory size limitations

Streaming media test included two kinds, a go compiled binaries and a shell script version, both have their own advantages and disadvantages, compared with each other to see it

The tiktok test has two versions, superbench and lmc999, which is invalid at any time may be updated to one of the versions, to the latest script shall prevail

Backhaul routing test selected GO compiled binary version and friends PR version, I did optimization to adapt to multiple IP lists and integration of some of the queries

IP quality testing is purely original, if there are bugs or more database sources can be raised in the issues, the daily look at the IP2Location database IP type can be, which can be reached by the mailbox on port 25, you can build the post office

Fusion Monster's IP Quality Check is simplified and doesn't query Cloudflare's Threat Score, the IP Quality Check in the Personal Originals section is the full version (or the command listed in the repository description for that IP Quality Check is also the full version).

Speed test using self-written speed test script, try to use the latest nodes and the latest components for speed test, and there is a spare third-party go version of the speed test kernel, so as to self-update the speed test node list, adaptive system environment speed test.

Other third-party scripts are summarized in the third-party script area, which has the same type of scripts by different authors of a variety of competing scripts, if the fusion of blame can not make you satisfied or there is an error, you can look at that part!

Original script area is a personal original part, something can also look at, may update some off the beaten path or unique scripts.

VPS test, VPS speed test, VPS comprehensive performance test, VPS backhaul line test, VPS streaming test and all the test fusion script, this script can be fusion of all fusion.

</details>

**[Back to top](https://github.com/spiritLHLS/ecs/blob/main/README_EN.md#top)**

## Fusion_Monster_Function

- [x] Free combination of test direction and individual tests and collection of third-party scripts, Fusion Monster tests are self-optimized and repaired, and are different from the original scripts.
- [x] Basic information query - thanks to [bench.sh](https://github.com/teddysun/across/blob/master/bench.sh), [superbench.sh](https://www.oldking.net/350.html ), [yabs](https://github.com/masonr/yet-another-bench-script), [lemonbench](https://github.com/LemonBench/LemonBench) open source, I organize the modification and optimization, with the original version of are not consistent
- [x] CPU test - thanks to [lemonbench](https://github.com/LemonBench/LemonBench) and [yabs](https://github.com/masonr/yet-another-bench-script) open source. I organize, modify and optimize
- [x] Memory test - thanks to [lemonbench](https://github.com/LemonBench/LemonBench) open source, I organize the modification optimization
- [x] disk dd read/write test - thanks to [lemonbench](https://github.com/LemonBench/LemonBench) open source, I organize the modified optimization!
- [x] Hard disk fio read and write test - thanks to [yabs](https://github.com/masonr/yet-another-bench-script) open source, I organize the modified optimization
- [x] Mikado streaming unlock test - thanks to [sjlleo's binary file](https://github.com/sjlleo?tab=repositories), I modify the finishing optimized
- [x] Streaming media unlocking test - thanks to [RegionRestrictionCheck](https://github.com/lmc999/RegionRestrictionCheck) open source, I organize, modify and optimize the
- [x] Tiktok unlock - Thanks to [TikTokCheck](https://github.com/lmc999/TikTokCheck) open source, I organize modified to optimize the
- [x] Backhaul routing and bandwidth type detection (business wide/home wide/data center) - by [fscarmen](https://github.com/fscarmen) PR as well as my technical ideas to provide, I modify the optimization maintenance
- [x] IP quality and port 25 detection (including IPV4 and IPV6) - this script is original, thanks to the Internet to provide the query resources
- [x] speedtest speed test - use self-writing [ecsspeed](https://github.com/spiritLHLS/ecsspeed) warehouse, automatically update the speed test server ID, once and for all to solve the problem of always have to manually update the speed test ID!

# Friendly_link

## Review_Channel

### https://t.me/vps_reviews

**[Back to top](https://github.com/spiritLHLS/ecs/blob/main/README_EN.md#top)**

# Screenshot

![图片](https://github.com/spiritLHLS/ecs/assets/103393591/0acecaea-8cbc-43a0-9262-e2fa157fb8e9)

![图片](https://github.com/spiritLHLS/ecs/assets/103393591/d25713e1-eeb0-48c0-9d6f-6ac1a0f6b6df)

![图片](https://github.com/spiritLHLS/ecs/assets/103393591/1b578739-4809-4ab0-8187-b860a502c8d9)

![图片](https://github.com/spiritLHLS/ecs/assets/103393591/010d4e5d-561e-4aa3-8313-e592f29405d1)

![图片](https://github.com/spiritLHLS/ecs/assets/103393591/bfe775ad-323c-4f6e-8d81-fcf787644653)

# Stargazers_over_time

[![Stargazers over time](https://starchart.cc/spiritLHLS/ecs.svg)](https://starchart.cc/spiritLHLS/ecs)

# Thanks

Thanks [ipinfo.io](https://ipinfo.io) [ip.sb](https://ip.sb) [cheervision.co](https://cheervision.co) [cip.cc](http://www.cip.cc) [scamalytics.com](https://scamalytics.com) [abuseipdb.com](https://www.abuseipdb.com/) [virustotal.com](https://www.virustotal.com/) [ip2location.com](ip2location.com/) [ip-api.com](https://ip-api.com) [ipregistry.co](https://ipregistry.co/) [ipdata.co](https://ipdata.co/) [ipgeolocation.io](https://ipgeolocation.io) [ipwhois.io](https://ipwhois.io) [ipapi.com](https://ipapi.com/) [ipapi.is](https://ipapi.is/) [ipqualityscore.com](https://www.ipqualityscore.com/) [bigdatacloud.com](https://www.bigdatacloud.com/) ~~[ipip.net](https://en.ipip.net)~~ ~~[abstractapi.com](https://abstractapi.com/)~~ and so on. They provide APIs for testing, thanks to the query resources provided by various sites on the Internet.

Thanks to all the open source projects for providing the original test scripts.

Thanks

<a href="https://h501.io/?from=69" target="_blank">
  <img src="https://github.com/spiritLHLS/ecs/assets/103393591/dfd47230-2747-4112-be69-b5636b34f07f" alt="h501">
</a>

provided  hosting to support this open source project.

Thanks also to the following platforms for editorial and testing support.

![PyCharm logo](https://resources.jetbrains.com/storage/products/company/brand/logos/PyCharm.png)

**[Back to top](https://github.com/spiritLHLS/ecs/blob/main/README_EN.md#top)**

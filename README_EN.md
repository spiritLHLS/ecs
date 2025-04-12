# ecs

[![Hits](https://hits.spiritlhl.net/ecs.svg?action=hit&title=Hits&title_bg=%23555555&count_bg=%2324dde1&edge_flat=false)](https://hits.spiritlhl.net)

## Language

[中文文档](README.md) | [English Docs](README_EN.md) | [日本語ドキュメント](README_JP.md)

## Introduction
**If you encounter any of the following situations:**
- **Systems/architectures not listed in this project**
- **Bugs in the testing process of this project**
- **Desire to minimize environment changes without modifying local configuration**
- **Need for more comprehensive testing**

**Please try [https://github.com/oneclickvirt/ecs](https://github.com/oneclickvirt/ecs/blob/master/README_EN.md) for testing**

### Compatibility Information

| Category | Supported Options |
|----------|------------------|
| **Fully Supported Systems** | Ubuntu 18+, Debian 8+, Centos 7+, Fedora 33+, Almalinux 8.5+, OracleLinux 8+, RockyLinux 8+, AstraLinux CE, Arch |
| **Partially Supported Systems** | FreeBSD (prerequisite: run `pkg install -y curl bash`), Armbian |
| **Supported Architectures** | amd64 (x86_64), arm64, i386, arm |
| **Supported Regions** | **All regions with internet connectivity** |

**Note:** Due to the need for testing across multiple systems and architectures, the Shell version of this multi-system solution will no longer receive new feature development and will only be maintained. All testing functions have been reconstructed in Golang version ([https://github.com/oneclickvirt/ecs](https://github.com/oneclickvirt/ecs/blob/master/README_EN.md)), with minimal additional environmental dependencies and absolutely no third-party shell file references.

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
| -mdisk | Optional | Specify to test the IO of multiple mounted disks | Note that this command includes testing the system disk | -stype | -mdisk | Optional | Specifies to test the IO of multiple mounted disks, only the system disk tested by default
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

This project is best executed in the `/root` path to avoid environmental dependency issues. It automatically updates package managers by default and should not be used in production environments. It's recommended to use the Go version mentioned earlier to ensure your local configuration remains unchanged.

The results of the "fusion monster" are saved in `test_result.txt` in the current directory. You can run it in `screen` or `tmux`, and you can exit the SSH login and check the file after some time to avoid test interruptions caused by unstable SSH connections.

**Sometimes when testing machines with extremely poor configurations, executing it this way can prevent SSH connection interruptions caused by outdated IO or CPU. If screen displays garbled characters, it's not a problem - the shared link results will not contain garbled text.**

Both the complete and simplified versions of the fusion monster will automatically upload results to pastebin and return a sharing link upon completion. If you want to exit during testing, press `Ctrl+C` to terminate the test. This will automatically exit and delete residual environment dependency files.

Example of testing the worst performing machine (completed in 47 minutes): [Link](https://github.com/spiritLHLS/ecs/blob/main/lowpage/README.md)

Although this project has built-in **CDN** support for **domestic** and **international** acceleration of server test environment installation and pre-made file downloads, loading may be slower in mainland China due to CDN connectivity or bandwidth limitations.

**For first-time users of this project, it is recommended to check the instructions: [Jump to](https://github.com/oneclickvirt/ecs/blob/master/README_NEW_USER.md)**

Other information:

<details>
<summary>Click to expand</summary>

Except for the original content marked, all other sections are borrowed and optimized versions, different from the original corresponding scripts.

All detection methods have been considered for parallel testing, and this technique has been used in some components, optimizing 2-3 minutes compared to normal sequential execution.

The system basic information test combines multiple sources with self-patched detection parts (sysctl, NAT type detection, concurrent ASN detection, etc.).

CPU testing uses sysbench scoring by default, not yabs' gb4 or gb5 (although geekbench isn't the default, you can specify common geekbench versions for testing via commands). Related explanations can be found in the Q&A at the end of the Go version fusion monster description.

IO testing includes two types: dd disk testing from lemonbench and fio disk testing from yabs. The former may have larger errors but tests quickly with no disk size limitations, while the latter is more accurate but slower with disk and memory size limitations.

Streaming media testing includes two types: a go-compiled binary file and a shell script version. Each has its own advantages and disadvantages; compare them as needed.

TikTok testing has both superbench and lmc999 versions. If one becomes ineffective, it may be updated to either version; refer to the latest script.

Return route testing uses a GO-compiled binary version and a PR version from a friend. Optimizations have been made to adapt to multiple IP lists and merge partial queries.

IP quality detection is completely original. If there are bugs or additional database sources, please raise them in issues. Generally, check the IP type in the IP2Location database. If port 25 is accessible for email, you can set up a post office.

The fusion monster's IP quality detection is simplified without querying Cloudflare threat scores. The personal original section's IP quality detection (or the IP quality detection command listed in the repository description) is the complete version.

Three-network speed testing uses a self-written script with the latest nodes and components when possible, along with backup third-party go version testing cores, providing self-updating speed test node lists and adaptive system environment testing.

Other third-party scripts are categorized in the third-party script section, where you can find various competitive scripts of the same type from different authors. If the fusion monster doesn't satisfy you or has errors, you can check that section.

The original script section contains personally created parts which may be worth checking occasionally for updates on niche or unique scripts.

VPS testing, VPS speed testing, VPS comprehensive performance testing, VPS return route testing, VPS streaming media testing, and all other test fusion scripts - this script integrates everything that can be integrated.

</details>

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

# Screenshot

<details>
<summary>Click to show</summary>

![图片](https://github.com/spiritLHLS/ecs/assets/103393591/0acecaea-8cbc-43a0-9262-e2fa157fb8e9)

![图片](https://github.com/spiritLHLS/ecs/assets/103393591/d25713e1-eeb0-48c0-9d6f-6ac1a0f6b6df)

![图片](https://github.com/spiritLHLS/ecs/assets/103393591/1b578739-4809-4ab0-8187-b860a502c8d9)

![图片](https://github.com/spiritLHLS/ecs/assets/103393591/010d4e5d-561e-4aa3-8313-e592f29405d1)

![图片](https://github.com/spiritLHLS/ecs/assets/103393591/bfe775ad-323c-4f6e-8d81-fcf787644653)

</details>

# Stargazers_over_time

[![Stargazers over time](https://starchart.cc/spiritLHLS/ecs.svg)](https://starchart.cc/spiritLHLS/ecs)

# Thanks

Thanks [ipinfo.io](https://ipinfo.io) [ip.sb](https://ip.sb) [cheervision.co](https://cheervision.co) [scamalytics.com](https://scamalytics.com) [abuseipdb.com](https://www.abuseipdb.com/) [virustotal.com](https://www.virustotal.com/) [ip2location.com](https://ip2location.com/) [ip-api.com](https://ip-api.com) [ipregistry.co](https://ipregistry.co/) [ipdata.co](https://ipdata.co/) [ipgeolocation.io](https://ipgeolocation.io) [ipwhois.io](https://ipwhois.io) [ipapi.com](https://ipapi.com/) [ipapi.is](https://ipapi.is/) [ipqualityscore.com](https://www.ipqualityscore.com/) [bigdatacloud.com](https://www.bigdatacloud.com/) and so on. They provide APIs for testing, thanks to the query resources provided by various sites on the Internet.

Thanks to all the open source projects for providing the original test scripts.

Thanks

<a href="https://h501.io/?from=69" target="_blank">
  <img src="https://github.com/spiritLHLS/ecs/assets/103393591/dfd47230-2747-4112-be69-b5636b34f07f" alt="h501">
</a>

provided  hosting to support this open source project.

Thanks also to the following platforms for editorial and testing support.

![PyCharm logo](https://resources.jetbrains.com/storage/products/company/brand/logos/PyCharm.png)



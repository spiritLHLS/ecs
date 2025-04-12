# ecs

[![Hits](https://hits.spiritlhl.net/ecs.svg?action=hit&title=Hits&title_bg=%23555555&count_bg=%2324dde1&edge_flat=false)](https://hits.spiritlhl.net)

## 语言

[中文文档](README.md) | [English Docs](README_EN.md) | [日本語ドキュメント](README_JP.md)

## 前言

**如果遇到以下情况：**
- **本项目未列出的系统/架构**
- **本项目测试有BUG测不出来**
- **测试不想要魔改本机配置想要最小化环境变动**
- **想要测试更全面**

**请尝试 [https://github.com/oneclickvirt/ecs](https://github.com/oneclickvirt/ecs) 进行测试**

### 兼容性信息

| 类别 | 支持选项 |
|----------|------------------|
| **完全支持的系统** | Ubuntu 18+, Debian 8+, Centos 7+, Fedora 33+, Almalinux 8.5+, OracleLinux 8+, RockyLinux 8+, AstraLinux CE, Arch |
| **半支持系统** | FreeBSD (前提已执行 `pkg install -y curl bash`)，Armbian |
| **支持架构** | amd64 (x86_64)、arm64、i386、arm |
| **支持地域** | **能连得上网都支持** |

**注意：** 考虑到多系统多架构的普遍测试的需求，融合怪的Shell版本不再做新功能开发，仅作维护，各项测试已重构为Golang版本 ([https://github.com/oneclickvirt/ecs](https://github.com/oneclickvirt/ecs))，尽量无额外的环境依赖，完全无第三方shell文件引用。

# 目录
- [前言](#前言)
- [目录](#目录)
- [融合怪测评脚本](#融合怪测评脚本)
  - [部分服务器运行测试有各类bug一键修复后再测试](#部分服务器运行测试有各类bug一键修复后再测试)
  - [更新](#更新)
  - [融合怪命令](#融合怪命令)
    - [交互形式](#交互形式)
    - [无交互形式-参数模式](#无交互形式-参数模式)
  - [IP质量检测](#ip质量检测)
  - [融合怪说明](#融合怪说明)
  - [融合怪功能](#融合怪功能)
- [友链](#友链)
  - [测评频道](#测评频道)
    - [https://t.me/vps\_reviews](#httpstmevps_reviews)
  - [自动更新测速服务器节点列表的网络基准测试脚本](#自动更新测速服务器节点列表的网络基准测试脚本)
    - [https://github.com/spiritLHLS/ecsspeed](#httpsgithubcomspiritlhlsecsspeed)
- [脚本概况](#脚本概况)
- [Stargazers over time](#stargazers-over-time)
- [致谢](#致谢)

<a id="top"></a>
------
<a id="artical_1"></a>

# 融合怪测评脚本

## 部分服务器运行测试有各类bug一键修复后再测试

一键修复各种系统原生bug的仓库：

https://github.com/spiritLHLS/one-click-installation-script

如若还有系统bug请到上面仓库的issues反馈，脚本原生BUG该仓库issues反馈

## 更新

2025.04.12

- 根据 https://github.com/oneclickvirt/backtrace 更新，添加对IPV6路由的线路检测
- 修复当出现内核错误时，测速不再继续尝试执行
- 修改测速优先级测速，优先使用go版本重构的测速，避免官方编译的内核版本问题
- 修复当 /dev/null 不可用时，依然测试IO的问题
- 修复当子网掩码为128时还进行ipv6的子网掩码长度测试的问题

历史更新日志：[跳转](https://github.com/spiritLHLS/ecs/blob/main/CHANGELOG.md)

## 融合怪命令

### 交互形式

```bash
curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
```

或

```bash
curl -L https://github.com/spiritLHLS/ecs/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
```

或

```
bash <(wget -qO- bash.spiritlhl.net/ecs)
```

或

```
bash <(wget -qO- ecs.0s.hk)
```

或

```
bash <(wget -qO- ecs.12345.ing)
```

### 无交互形式-参数模式

```bash
curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh -m 1
```

或

```bash
curl -L https://github.com/spiritLHLS/ecs/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh -m 1
```

或通过

```
curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh
```

下载文件后使用类似

```bash
bash ecs.sh -m 1
```

这样的参数命令指定选项执行

以下为参数说明：

| 指令 | 项目 | 说明 | 备注 |
| ---- | ---- | ----------- | ---- |
| -m | 必填项 | 可指定原本menu中的对应选项，最多支持三层选择，例如执行```bash ecs.sh -m 5 1 1```将选择主菜单第5选项下的第1选项下的子选项1的脚本执行 | 可缺省仅指定一个参数，如```-m 1```仅指定执行融合怪完全体，执行```-m 1 0```以及```-m 1 0 0```都是指定执行融合怪完全体 |
| -en | 可选项 | 可指定强制输出为英文 | 无该指令则默认使用中文输出 |
| -i | 可选项 | 可指定回程路由测试中的目标IPV4地址 | 可通过```ip.sb```、```ipinfo.io```等网站获取本地IPV4地址后指定 |
| -r | 可选项 | 可指定回程路由测试中的目标IPV4地址，可选```b``` ```g``` ```s``` ```c``` 分别对应```北京```、```广州```、```上海、```成都``` | 如```-r b```指定测试北京回程(三网) |
|   |   | 可指定仅测试IPV6三网，可选 ```b6``` ```g6``` ```s6``` 分别对应 ```北京```、```广州```、```上海``` 的三网的IPV6地址 | 如```-r b6``` 指定测试北京IPV6地址回程(三网) |
| -base | 可选项 | 可指定仅测试基础的系统信息 | 无该指令则默认按照menu选项的组合测试 |
| -ctype | 可选项 | 可指定通过何种方式测试cpu，可选```gb4```、```gb5```、```gb6```分别对应```geekbench```的```4```、```5```、```6```版本 | 无该指令则默认使用```sysbench```测试 |
| -dtype | 可选项 | 可指定测试硬盘IO的程序，可选```dd```、```fio```，前者测试快后者测试慢 | 无该指令则默认都使用进行测试 |
| -mdisk | 可选项 | 可指定测试多个挂载盘的IO | 注意本指令包含测试系统盘，无该指令默认仅测试系统盘 |
| -stype | 可选项 | 可指定使用```.cn```还是```.net```的数据进行测速 | 无该指令则默认使用```.net```数据测速优先，不可用时才替换为```.cn```数据 |
| -bansp | 可选项 | 可指定强制不测试网速 | 无该指令则默认测试网速 |
| -banup | 可选项 | 可指定强制不生成分享链接 | 无该指令则默认生成分享链接 |

## IP质量检测

- IP质量检测，含15家数据库查询，含DNS黑名单查询
- 含 ```IPV4``` 和 ```IPV6``` 检测，含ASN和地址查询
- 含邮件端口检测

```bash
bash <(wget -qO- bash.spiritlhl.net/ecs-ipcheck)
```

或

```bash
bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/spiritLHLS/ecs/main/ipcheck.sh)
```

或

需要事先安裝```dos2unix```

```bash
wget -qO ipcheck.sh --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/ipcheck.sh
dos2unix ipcheck.sh
bash ipcheck.sh
```

## 融合怪说明

本项目最好在```/root```路径下执行，避免产生环境依赖问题，本项目默认自动更新包管理器，不要在生产环境中使用，建议使用前文提及的Go版本确保不会变动本机配置。

融合怪的执行结果保存在当前路径下的```test_result.txt```中，可在```screen```或```tmux```中执行，可先退出SSH登录过一段时间后再查看文件，避免ssh不稳定导致的测试中断。

**有时候想要测一些配置极其拉跨的机器时，上面这样执行这样可以避免IO或者CPU过于陈旧导致测试过程中的SSH连接中断，假如screen中显示乱码也有没问题，分享链接中的结果是不带乱码的。**

融合怪的完整版和精简版运行完毕会自动上传结果到pastebin并回传分享链接，如果测一半想要退出，那么按```Ctrl+C```同时按下可终止测试，此时会自动退出删除残余的环境依赖文件。

最垃圾的机器测试的例子(跑了47分钟测完)：[跳转](https://github.com/spiritLHLS/ecs/blob/main/lowpage/README.md)

虽然本项目内置使用**CDN**支持**国内**和**国外**加速服务器测试环境安装和预制文件下载，但中国境内受CDN连通性或带宽限制加载可能会比较缓慢。

**本项目初次使用建议查看说明：[跳转](https://github.com/oneclickvirt/ecs/blob/master/README_NEW_USER.md)**

其他说明：

<details>
<summary>展开查看</summary>

除已标注的原创内容，其余所有分区均为借鉴并进行优化修改后的版本，与原始对应的脚本不一样。

所有检测都有考虑过使用并行测试，并在部分环节使用了该技术，比正常的顺序执行优化了2~3分钟。

系统基础信息测试融合了多家还有自修补的部分检测(systl、NAT类型检测，并发ASN检测等)。

CPU测试默认使用sysbench测试得分，不是yabs的gb4或gb5(虽然默认不是geekbench但可以通过指令指定geekbench常见版本进行测试)，相关说明见Go版本融合怪说明末尾的QA。

IO测试收录了两种，来源于lemonbench的dd磁盘测试和yabs的fio磁盘测试，综合来看会比较好，前者可能误差偏大但测试速度快无硬盘大小限制，后者真实一点但测试速度慢有硬盘以及内存大小限制。

流媒体测试收录了两种，一个是go编译的二进制文件和一个shell脚本版本，二者各有优劣，互相对比看即可。

tiktok测试有superbench和lmc999两种版本，哪个失效了随时可能更新为其中一种版本，以最新的脚本为准。

回程路由测试选用的GO编译的二进制版本和朋友PR的版本，本人做了优化适配多个IP列表以及融合部分查询。

IP质量检测纯原创，如有bug或者更多数据库来源可在issues中提出，日常看IP2Location数据库的IP类型即可，其中的25端口邮箱可达，则可搭建邮局。

融合怪的IP质量检测是简化过的，没有查询Cloudflare的威胁得分，个人原创区的IP质量检测才是完整版(或者仓库说明中列出的那个IP质量检测的命令也是完整版)。

三网测速使用自写的测速脚本，尽量使用最新节点最新组件进行测速，且有备用第三方go版本测速内核，做到自更新测速节点列表，自适应系统环境测速。

其他第三方脚本归纳到了第三方脚本区，里面有同类型脚本不同作者的各种竞品脚本，如果融合怪不能使你满意或者有错误，可以看看那部分。

原创脚本区是个人原创的部分，有事没事也可以看看，可能会更新某些偏门或者独到的脚本。

VPS测试，VPS测速，VPS综合性能测试，VPS回程线路测试，VPS流媒体测试等所有测试融合的脚本，本脚本能融合的都融合了。

</details>

## 融合怪功能

- [x] 自由组合测试方向和单项测试以及合集收录第三方脚本，融合怪各项测试均自优化修复过，与原始脚本均不同
- [x] 基础信息查询--感谢[bench.sh](https://github.com/teddysun/across/blob/master/bench.sh)、[superbench.sh](https://www.oldking.net/350.html)、[yabs](https://github.com/masonr/yet-another-bench-script)、[lemonbench](https://github.com/LemonBench/LemonBench)开源，本人整理修改优化，同原版均不一致
- [x] CPU测试--感谢[lemonbench](https://github.com/LemonBench/LemonBench)和[yabs](https://github.com/masonr/yet-another-bench-script)开源，本人整理修改优化
- [x] 内存测试--感谢[lemonbench](https://github.com/LemonBench/LemonBench)开源，本人整理修改优化
- [x] 磁盘dd读写测试--感谢[lemonbench](https://github.com/LemonBench/LemonBench)开源，本人整理修改优化
- [x] 硬盘fio读写测试--感谢[yabs](https://github.com/masonr/yet-another-bench-script)开源，本人整理修改优化
- [x] 御三家流媒体解锁测试--感谢[netflix-verify](https://github.com/sjlleo/netflix-verify)、[VerifyDisneyPlus](https://github.com/sjlleo/VerifyDisneyPlus)、[TubeCheck](https://github.com/sjlleo/TubeCheck)开源，本人整理修改维护[CommonMediaTests](https://github.com/oneclickvirt/CommonMediaTests)使用
- [x] 常用流媒体解锁测试--感谢[RegionRestrictionCheck](https://github.com/lmc999/RegionRestrictionCheck)开源，本人整理修改优化
- [x] Tiktok解锁--感谢[TikTokCheck](https://github.com/lmc999/TikTokCheck)开源，本人整理修改优化
- [x] 三网回程以及路由延迟--感谢[zhanghanyun/backtrace](https://github.com/zhanghanyun/backtrace)开源，本人整理修改维护[oneclickvirt/backtrace](https://github.com/oneclickvirt/backtrace)使用
- [x] 回程路由及带宽类型检测(商宽/家宽/数据中心)--由[fscarmen](https://github.com/fscarmen)的PR以及本人的技术思路提供，本人修改优化维护
- [x] IP质量(含IPV4和IPV6)与邮件端口检测--使用[oneclickvirt/securityCheck](https://github.com/oneclickvirt/securityCheck)和[oneclickvirt/portchecker](https://github.com/oneclickvirt/portchecker)进行测试，感谢互联网提供的查询资源
- [x] speedtest测速--使用自写[ecsspeed](https://github.com/spiritLHLS/ecsspeed)仓库，自动更新测速服务器ID，一劳永逸解决老是要手动更新测速ID的问题

# 友链

## 测评频道

### https://t.me/vps_reviews

## 自动更新测速服务器节点列表的网络基准测试脚本

### https://github.com/spiritLHLS/ecsspeed


# 脚本概况

<details>
<summary>展开查看</summary>

主界面：

![图片](https://github.com/spiritLHLS/ecs/assets/103393591/051f1a83-ecd6-4713-af2f-c8b494e33c7f)

选项1融合怪完全体(实际有高亮颜色显示，截图问题暂无显示，以实际运行结果为准)：

![图片](https://github.com/spiritLHLS/ecs/assets/103393591/6dfab873-39fd-44ac-90e0-d3b82720fc04)
![图片](https://github.com/spiritLHLS/ecs/assets/103393591/62b2d8e1-497d-4329-aa00-cd56f732f28a)
![图片](https://github.com/spiritLHLS/ecs/assets/103393591/77b79eb9-1b2a-448b-bf83-0ecec8529515)
![图片](https://github.com/spiritLHLS/ecs/assets/103393591/350c7323-39a5-4caf-8bf2-c3fde045fa64)
![图片](https://github.com/spiritLHLS/ecs/assets/103393591/5cbaf73c-308e-4147-9a8c-638cfede3440)
![图片](https://github.com/spiritLHLS/ecs/assets/103393591/903c0b19-b93c-4739-80f6-944992cb0640)
![图片](https://github.com/spiritLHLS/ecs/assets/103393591/58bc4f72-415b-4b47-a98d-4329ab31fd3e)

选项6原创区：

![图片](https://github.com/spiritLHLS/ecs/assets/103393591/393db695-5c94-41a9-9b02-812ad9d64967)

</details>

# Stargazers over time

[![Stargazers over time](https://starchart.cc/spiritLHLS/ecs.svg)](https://starchart.cc/spiritLHLS/ecs)

# 致谢

感谢 [ipinfo.io](https://ipinfo.io) [ip.sb](https://ip.sb) [cheervision.co](https://cheervision.co) [scamalytics.com](https://scamalytics.com) [abuseipdb.com](https://www.abuseipdb.com/) [virustotal.com](https://www.virustotal.com/) [ip2location.com](https://ip2location.com/) [ip-api.com](https://ip-api.com) [ipregistry.co](https://ipregistry.co/) [ipdata.co](https://ipdata.co/) [ipgeolocation.io](https://ipgeolocation.io) [ipwhois.io](https://ipwhois.io) [ipapi.com](https://ipapi.com/) [ipapi.is](https://ipapi.is/) [ipqualityscore.com](https://www.ipqualityscore.com/) [bigdatacloud.com](https://www.bigdatacloud.com/) 等网站提供的API进行检测，感谢互联网各网站提供的查询资源

感谢所有开源项目提供的原始测试脚本

感谢

<a href="https://h501.io/?from=69" target="_blank">
  <img src="https://github.com/spiritLHLS/ecs/assets/103393591/dfd47230-2747-4112-be69-b5636b34f07f" alt="h501">
</a>

提供的免费托管支持本开源项目

同时感谢以下平台提供编辑和测试支持

![PyCharm logo](https://resources.jetbrains.com/storage/products/company/brand/logos/PyCharm.png)



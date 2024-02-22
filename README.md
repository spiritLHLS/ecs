# ecs

[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2FspiritLHLS%2Fecs&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)

## 语言

[中文文档](README.md) | [English Docs](README_EN.md)

## 前言

支持系统：

Ubuntu 18+, Debian 8+, Centos 7+, Fedora 33+, Almalinux 8.5+, OracleLinux 8+, RockyLinux 8+, AstraLinux CE, Arch

半支持系统：

FreeBSD(前提已执行```pkg install -y curl bash```)，Armbian

<details>

部分问题：
  
Armbian系统部分检测和测试暂不支持，部分会编码错误

FreeBSD系统的CPU测试目前是残废的，有些东西显示有问题

FreeBSD系统的sed命令类似alpine而不是debian，很多命令的sed需要修改，有大问题

</details>

支持架构：

基本都支持，无论是本地服务器还是云端服务器

支持地域：

能连得上网都支持

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

2024.02.22

- 优化系统查询命令，仅查询必要信息

历史更新日志：[跳转](https://github.com/spiritLHLS/ecs/blob/main/CHANGELOG.md)

**[返回顶部](https://github.com/spiritLHLS/ecs#top)**

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
| -mdisk | 可选项 | 可指定测试多个挂载盘的IO | 注意本指令包含测试系统盘 |
| -stype | 可选项 | 可指定使用```.cn```还是```.net```的数据进行测速 | 无该指令则默认使用```.net```数据测速优先，不可用时才替换为```.cn```数据 |
| -bansp | 可选项 | 可指定强制不测试网速 | 无该指令则默认测试网速 |
| -banup | 可选项 | 可指定强制不生成分享链接 | 无该指令则默认生成分享链接 |

## IP质量检测

- IP质量检测，含多家数据库查询，含黑名单查询
- 含 ```IPV4``` 和 ```IPV6``` 检测，含ASN和地址查询
- 含25端口的邮箱可达性检测，如果某个邮箱可达，则可搭建邮局

```bash
bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/qzcheck.sh)
```

或

```bash
bash <(wget -qO- bash.spiritlhl.net/ecs-ipcheck)
```

或

```bash
bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/spiritLHLS/ecs/main/qzcheck.sh)
```

## 融合怪说明

融合怪脚本最好在 /root 路径下执行，避免各种奇奇怪怪的问题

融合怪的执行结果保存在当前路径下的```test_result.txt```中，可在```screen```或```tmux```中执行，先退出SSH登录过一段时间后再查看文件

**有时候想要测一些配置极其拉跨的机器时，上面这样执行这样可以避免IO或者CPU过于垃圾导致的测试过程中的SSH连接中断，就不会测一半啥都没了，假如screen中显示乱码，也没问题，分享链接中的结果是不带乱码的**

融合怪的完整版和精简版运行完毕会自动上传结果到pastebin并回传分享链接，如果测一半想要退出，那么按```Ctrl+C```同时按下可终止测试，此时会自动退出删除残余文件

最烂机器测试的例子(跑了47分钟一样测完)：[跳转](https://github.com/spiritLHLS/ecs/blob/main/lowpage/README.md)

使用**CDN**已支持**国内**和**国外**加速服务器环境安装和预制文件下载，但国内受CDN连通性或国内机器带宽大小的限制加载可能会慢很多

融合怪测试说明以及部分测试结果的内容解释(初次使用推荐查看)：
<details>

除了已标注的原创内容，其余所有分区均为借鉴并进行优化修改后的版本，与原始对应的脚本不一样

所有检测都有考虑过使用并行测试，并在部分环节使用了该技术，比正常的顺序执行优化了2~3分钟，属于是独有的，暂无哪家的测试有同类技术

系统基础信息测试融合了多家还有我自己修补的部分检测(systl、NAT类型检测，并发ASN检测等)，应该是目前最全面最通用的了

CPU测试默认使用sysbench测试得分，不是yabs的gb4或gb5(虽然默认不是geekbench但可以通过指令指定geekbench常见版本进行测试)，前者只是简单的计算质数测试速度快，后者geekbench是综合测试系统算加权得分

使用sysbench测试得分是每秒处理的事件数目，这个指标无论在强还是弱性能的服务器上都能迅速测出来，而geekbench很多是测不动或者速度很慢起码2分半钟

CPU测试单核sysbench得分在5000以上的可以算第一梯队，4000到5000分算第二梯队，每1000分算一档，自己看看自己在哪个档位吧

AMD的7950x单核满血性能得分在6500左右，AMD的5950x单核满血性能得分5700左右，Intel普通的CPU(E5之类的)在1000~800左右，低于500的单核CPU可以说是性能比较烂的了

IO测试收录了两种，来源于lemonbench的dd磁盘测试和yabs的fio磁盘测试，综合来看会比较好，前者可能误差偏大但测试速度快无硬盘大小限制，后者真实一点但测试速度慢有硬盘以及内存大小限制

流媒体测试收录了两种，一个是go编译的二进制文件和一个shell脚本版本，二者各有优劣，互相对比看即可

tiktok测试有superbench和lmc999两种版本，哪个失效了随时可能更新为其中一种版本，以最新的脚本为准

回程路由测试选用的GO编译的二进制版本和朋友PR的版本，本人做了优化适配多个IP列表以及融合部分查询

IP质量检测纯原创，如有bug或者更多数据库来源可在issues中提出，日常看IP2Location数据库的IP类型即可，其中的25端口邮箱可达，则可搭建邮局

融合怪的IP质量检测是简化过的，没有查询Cloudflare的威胁得分，个人原创区的IP质量检测才是完整版(或者仓库说明中列出的那个IP质量检测的命令也是完整版)

三网测速使用自写的测速脚本，尽量使用最新节点最新组件进行测速，且有备用第三方go版本测速内核，做到自更新测速节点列表，自适应系统环境测速

其他第三方脚本归纳到了第三方脚本区，里面有同类型脚本不同作者的各种竞品脚本，如果融合怪不能使你满意或者有错误，可以看看那部分

原创脚本区是个人原创的部分，有事没事也可以看看，可能会更新某些偏门或者独到的脚本

VPS测试，VPS测速，VPS综合性能测试，VPS回程线路测试，VPS流媒体测试等所有测试融合的脚本，本脚本能融合的都融合了

</details>

**[返回顶部](https://github.com/spiritLHLS/ecs#top)**

## 融合怪功能

- [x] 自由组合测试方向和单项测试以及合集收录第三方脚本，融合怪各项测试均自优化修复过，与原始脚本均不同
- [x] 基础信息查询--感谢[bench.sh](https://github.com/teddysun/across/blob/master/bench.sh)、[superbench.sh](https://www.oldking.net/350.html)、[yabs](https://github.com/masonr/yet-another-bench-script)、[lemonbench](https://github.com/LemonBench/LemonBench)开源，本人整理修改优化，同原版均不一致
- [x] CPU测试--感谢[lemonbench](https://github.com/LemonBench/LemonBench)和[yabs](https://github.com/masonr/yet-another-bench-script)开源，本人整理修改优化
- [x] 内存测试--感谢[lemonbench](https://github.com/LemonBench/LemonBench)开源，本人整理修改优化
- [x] 磁盘dd读写测试--感谢[lemonbench](https://github.com/LemonBench/LemonBench)开源，本人整理修改优化
- [x] 硬盘fio读写测试--感谢[yabs](https://github.com/masonr/yet-another-bench-script)开源，本人整理修改优化
- [x] 御三家流媒体解锁测试--感谢[sjlleo的二进制文件](https://github.com/sjlleo?tab=repositories)，本人修改整理优化
- [x] 常用流媒体解锁测试--感谢[RegionRestrictionCheck](https://github.com/lmc999/RegionRestrictionCheck)开源，本人整理修改优化
- [x] Tiktok解锁--感谢[TikTokCheck](https://github.com/lmc999/TikTokCheck)开源，本人整理修改优化
- [x] 三网回程以及路由延迟--感谢[zhanghanyun/backtrace](https://github.com/zhanghanyun/backtrace)开源，本人整理修改
- [x] 回程路由及带宽类型检测(商宽/家宽/数据中心)--由[fscarmen](https://github.com/fscarmen)的PR以及本人的技术思路提供，本人修改优化维护
- [x] IP质量与25端口检测(含IPV4和IPV6)--本脚本独创，感谢互联网提供的查询资源
- [x] speedtest测速--使用自写[ecsspeed](https://github.com/spiritLHLS/ecsspeed)仓库，自动更新测速服务器ID，一劳永逸解决老是要手动更新测速ID的问题

# 友链

## 测评频道

### https://t.me/vps_reviews

## 自动更新测速服务器节点列表的网络基准测试脚本

### https://github.com/spiritLHLS/ecsspeed

**[返回顶部](https://github.com/spiritLHLS/ecs#top)**

# 脚本概况

主界面：

![图片](https://github.com/spiritLHLS/ecs/assets/103393591/051f1a83-ecd6-4713-af2f-c8b494e33c7f)

选项1融合怪完全体：

![图片](https://github.com/spiritLHLS/ecs/assets/103393591/a769cb11-b416-4d40-a78c-265549bc4d49)
![图片](https://github.com/spiritLHLS/ecs/assets/103393591/291854bf-4760-4a7f-8fad-33a114a2ba46)
![图片](https://github.com/spiritLHLS/ecs/assets/103393591/6cad0c32-2409-4a92-b2c7-435f8eb66b3c)
![图片](https://github.com/spiritLHLS/ecs/assets/103393591/e5e486e8-0791-43d6-919e-63b420cec022)
![图片](https://github.com/spiritLHLS/ecs/assets/103393591/7296621e-76c0-41f1-bd9c-e3e696301dcc)
![图片](https://github.com/spiritLHLS/ecs/assets/103393591/08289d71-9f91-4597-bcb1-0909622e16d4)
![图片](https://github.com/spiritLHLS/ecs/assets/103393591/3a53758e-5fab-4fc5-a0b6-651c2f6b79a3)

选项6原创区：

![图片](https://github.com/spiritLHLS/ecs/assets/103393591/393db695-5c94-41a9-9b02-812ad9d64967)


**[返回顶部](https://github.com/spiritLHLS/ecs#top)**

# Stargazers over time

[![Stargazers over time](https://starchart.cc/spiritLHLS/ecs.svg)](https://starchart.cc/spiritLHLS/ecs)

# 致谢

感谢 [ipinfo.io](https://ipinfo.io) [ip.sb](https://ip.sb) [cheervision.co](https://cheervision.co) [ipip.net](https://en.ipip.net) [cip.cc](http://www.cip.cc) [scamalytics.com](https://scamalytics.com) [abuseipdb.com](https://www.abuseipdb.com/) [virustotal.com](https://www.virustotal.com/) [ip2location.com](ip2location.com/) [ip-api.com](https://ip-api.com) [ipregistry.co](https://ipregistry.co/) [ipdata.co](https://ipdata.co/) [ipgeolocation.io](https://ipgeolocation.io) [ipwhois.io](https://ipwhois.io) 等网站提供的API进行检测，感谢互联网各网站提供的查询资源

感谢所有开源项目提供的原始测试脚本

感谢

<a href="https://h501.io/?from=69" target="_blank">
  <img src="https://github.com/spiritLHLS/ecs/assets/103393591/dfd47230-2747-4112-be69-b5636b34f07f" alt="h501">
</a>

提供的免费托管支持本开源项目

同时感谢以下平台提供编辑和测试支持

![PyCharm logo](https://resources.jetbrains.com/storage/products/company/brand/logos/PyCharm.png)

**[返回顶部](https://github.com/spiritLHLS/ecs#top)**

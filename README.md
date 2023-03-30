# ecs

支持系统：Ubuntu 18+，Debian 8+，centos 7+，Fedora 22+，Almalinux 8.5+, Arch

### 融合怪测评脚本

#### 交互形式

```bash
bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh)
```

或

```bash
bash <(wget -qO- --no-check-certificate https://github.com/spiritLHLS/ecs/raw/main/ecs.sh)
```

#### 无交互形式

```bash
echo 1 | bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh)
```

或

```bash
echo 1 | bash <(wget -qO- --no-check-certificate https://github.com/spiritLHLS/ecs/raw/main/ecs.sh)
```

#### 说明

融合怪的执行结果保存在```/root```下的test_result.txt中，运行完毕可用```cat test_result.txt```查看记录

**有时候想要测一些配置极其拉跨的机器时，推荐使用screen挂起执行融合怪**

**然后你可以关闭SSH连接，等待一段时间后使用```cat test_result.txt```查看运行的实时状况**

**这样可以避免IO或者CPU过于垃圾导致的测试过程中的SSH连接中断，就不会测一半啥都没了**

最烂机器测试的例子(跑了47分钟一样测完)：[跳转](https://github.com/spiritLHLS/ecs/blob/main/lowpage/README.md)

使用**CDN**加速理论上已支持**国内**和**国外**服务器测试，但国内受CDN口子或国内机器口子的限制会加载慢很多

融合怪测试说明以及部分测试结果的内容解释(初次使用推荐查看)：

<details>
除了已标注的原创内容，其余所有分区均为借鉴并进行优化修改后的版本，与原版本可能有部分不同

系统基础信息测试融合了三家还有我自己修补的部分检测(systl和virt)，应该是目前最全面的了

CPU测试使用sysbench测试得分，不是yabs的gb4或gb5，前者只是简单的计算质数测试速度快，后者geekbench是综合测试算加权得分，不是同一种东西，别互相比较了，没有任何用处

CPU测试单核得分在5000以上的可以算第一梯队，4000到5000分算第二梯队，每1000分算一档，自己看看自己在哪个档位吧

AMD 5950x单核满血性能得分5700左右，intel普通的CPU在1000~800左右，低于600的单核CPU可以算是超开的厉害的了

IO测试收录了两种，来源于lemonbench的dd磁盘测试和yabs的fio磁盘测试，综合来看会比较好，前者可能误差偏大，后者真实一点

流媒体测试收录了两种，一个是go编译的二进制文件和一个shell脚本版本，二者作者有独到之处，互相对比看即可

tiktok测试有superbench和lmc999两种版本，哪个失效了随时可能更新为其中一种版本，以最新的脚本为准

回程路由测试选用的GO编译的二进制版本和朋友pr的版本，本人只做了优化适配多个IP列表

IP质量检测纯个人原创，使用python编写，如有bug或者更多数据库来源可在issues中提出，目前ping0数据库全显示的是IDC的IP，不是很准，日常看IP2Location数据库的IP类型即可

融合怪的IP质量检测是简化过的，没有查询Cloudflare的威胁得分，个人原创区的IP质量检测才是完整版(或者仓库说明中列出的那个IP质量检测的命令也是完整版)

三网测速融合了两家的脚本，我自己也更新了节点ID列表，尽量做到三网以及国外有代表性的节点有测试

其他第三方脚本我归纳到了第三方脚本区，里面有同类型脚本不同作者的各种脚本，如果融合怪不能使你满意或者有错误，可以看看那部分

原创脚本区是个人原创的部分，有事没事也可以看看，可能会更新某些偏门或者独到的脚本

VPS测试，VPS测速，VPS综合性能测试，VPS回程线路测试，VPS流媒体测试等所有测试融合的脚本，仅此一家。

</details>

### 纯测IP质量(IP黑还是白)(含IPV4和IPV6)

```bash
bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/qzcheck.sh)
```

或

```bash
bash <(wget -qO- --no-check-certificate https://github.com/spiritLHLS/ecs/raw/main/qzcheck.sh)
```

### 部分服务器运行测试有各类bug一键修复后再测试

一键修复各种bug的仓库：

https://github.com/spiritLHLS/one-click-installation-script

如若还有bug请到上面仓库的issues反映

# 待解决事项

移动测速节点已更新，琢磨新东西中一劳永逸解决老是要手动更新的问题 - 待添加

CDN下载文件不稳定导致部分链接下载文件失效 - 待修复增加重复检测

sjlleo的nf查询不支持ARM架构机器查询 - 待修复

端口检测(检测是否被墙) - 待修复

运行完毕自动上传结果到pastebin - 待添加

# 更新

2023.03.30 脚本运行还没选择就进行了部分组件的安装的逻辑问题已解决，组件只在选择完毕后进行安装，删除无效的ping0数据库，增加ip234数据库，优化了IP质量查询的函数减少了模块依赖，替换IP质量检测的V6检测平台，支持V6的地址进行检测，升级sysbench由1.0.17到1.0.20版本

历史更新日志：[跳转](https://github.com/spiritLHLS/ecs/blob/main/CHANGELOG.md)

# 功能

- [x] 自由组合测试方向和单项测试以及合集收录第三方脚本--原创
- [x] 基础系统信息--感谢teddysun和superbench和yabs开源，本人修改整理优化
- [x] CPU测试--感谢lemonbench开源，本人修改整理优化
- [x] 内存测试--感谢lemonbench开源
- [x] 磁盘IO读写测试--感谢lemonbench开源，本人修改整理优化
- [x] 硬盘IO读写测试--感谢yabs开源[项目](https://github.com/masonr/yet-another-bench-script)，本人修改整理优化
- [x] 御三家流媒体解锁--感谢sjlleo的[二进制文件](https://github.com/sjlleo?tab=repositories)，本人修改整理优化
- [x] 常用流媒体解锁--感谢RegionRestrictionCheck的[项目](https://github.com/lmc999/RegionRestrictionCheck)，本人修改整理优化
- [x] Tiktok解锁--感谢lmc999的[项目](https://github.com/lmc999/TikTokCheck)，本人修改整理优化
- [x] OpenAI检测--感谢missuo提供的[项目](https://github.com/missuo/OpenAI-Checker),本人修改整理
- [x] 三网回程以及路由延迟--感谢zhanghanyun/backtrace开源[项目](https://github.com/zhanghanyun/backtrace),本人修改整理
- [x] 回程路由以及带宽类型检测(商宽/家宽/数据中心)--由fscarmen的PR以及本人的技术思路提供，本人修改整理优化
- [ ] 端口检测(检测是否被墙)--由fscarmen的PR以及本人的技术思路提供 - 待修复
- [x] IP质量检测(检测IP白不白)(含IPV4和IPV6)--本人独创，感谢互联网提供的查询资源
- [x] speedtest测速--由teddysun和superspeed的开源以及个人整理
- [x] 全国网络延迟测试--感谢IPASN开源，本人修改整理优化

# 测评频道

## https://t.me/vps_reviews

# 脚本概况

![](https://github.com/spiritLHLS/ecs/raw/main/page/1.png)
![](https://github.com/spiritLHLS/ecs/raw/main/page/2.png)
![](https://github.com/spiritLHLS/ecs/raw/main/page/3.png)
![](https://github.com/spiritLHLS/ecs/raw/main/page/4.png)
![](https://github.com/spiritLHLS/ecs/raw/main/page/5.png)
![](https://github.com/spiritLHLS/ecs/raw/main/page/6.png)
![](https://github.com/spiritLHLS/ecs/raw/main/page/7.png)

本作者原创区选项

![](https://github.com/spiritLHLS/ecs/raw/main/page/yuanchuang.png)

## Stargazers over time

[![Stargazers over time](https://starchart.cc/spiritLHLS/ecs.svg)](https://starchart.cc/spiritLHLS/ecs)

## 感谢

![PyCharm logo](https://resources.jetbrains.com/storage/products/company/brand/logos/PyCharm.png)

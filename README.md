# ecs

支持系统：Ubuntu 18+，Debian 8+，centos 7+，Fedora，Almalinux 8.5+

### 融合怪测评脚本

```bash
bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh)
```

或

```bash
bash <(wget -qO- --no-check-certificate https://github.com/spiritLHLS/ecs/raw/main/ecs.sh)
```

### 纯测IP质量(IP黑还是白)(含IPV4和IPV6)

```bash
bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/qzcheck.sh)
```

或

```bash
bash <(wget -qO- --no-check-certificate https://github.com/spiritLHLS/ecs/raw/main/qzcheck.sh)
```

# bug待修复

lemonbench测试中的IO读写有时候过高脱离实际，修复时间未知

lemonbench测试中的CPU测试依赖Python第三方包，低版本系统不兼容，修复时间未知

端口测试自动获取ssh的端口进行连通性测试替换默认端口测试，修复时间未知

# 更新

2022.08.31 增加三网路由延迟，Tiktok解锁测试提速

2022.09.23 增加全国网络延迟测试，新增两个原始版本的三网测速的选项

2022.10.02 重新划分测试区域，含借鉴脚本的原始脚本选项和原创脚本选项，如果本脚本不好用，可以试试原始脚本

2022.11.04 更新替换Tiktok检测脚本为superbench脚本，暂时移除端口检测，第三方脚本增加Geekbench选项，修改部分分区描述

2022.12.11 不再使用ip.gs改用api.ipify.org进行IP识别

2022.12.12 新增两个IP类型数据库，IP检测已包含三个数据库，修复debian10系统apt源broken的问题，内置```apt --fix-broken install -y```，修复centos8的源失效问题，自动替换新源下载```AppStream```，新增支持Almalinux系统

2022.12.13 流媒体检测部分远程调用最新脚本不再直接使用老脚本函数，检测准确度提升，替换部分github的raw链接使用cf的cdn链接加速下载，融合怪脚本所需运行时长缩减

2022.12.14 非致命性bug后续很长一段时间内不再更新本脚本，所有非致命性bug已修复，第三方脚本增加两个三网回程线路检测脚本，原创区新增自定义IP的IP质量检测脚本，融合怪的执行结果保存在```/root```下的test_result.txt中，运行完毕可用```cat test_result.txt```查看记录

# 功能

- [x] 自由组合测试方面和单项测试--原创
- [x] 基础系统信息--感谢teddysun和misakabench和yabs开源，本人修改整理
- [x] CPU测试--感谢lemonbench开源
- [x] 内存测试--感谢lemonbench开源
- [x] 磁盘IO读写测试--感谢lemonbench开源
- [x] 硬盘IO读写测试--感谢yabs开源
- [x] 御三家流媒体解锁--感谢sjlleo的二进制文件
- [x] 常用流媒体解锁--感谢RegionRestrictionCheck开源
- [x] Tiktok解锁--感谢superbench的开源
- [x] 三网回程以及路由延迟--感谢zhanghanyun/backtrace开源
- [x] 回程路由以及带宽类型检测(商宽/家宽/数据中心)--由fscarmen的PR以及本人的技术思路提供
- [x] 端口检测(检测是否被墙)--由fscarmen的PR以及本人的技术思路提供
- [x] IP质量检测(检测IP白不白)(含IPV4和IPV6)--本人独创，感谢互联网提供的查询资源
- [x] speedtest测速--由teddysun和superspeed的开源以及个人整理
- [x] 全国网络延迟测试--感谢IPASN开源

# 测评频道

# https://t.me/vps_reviews

# 脚本概况

![](https://github.com/spiritLHLS/ecs/raw/main/page/zhuye.png)
![](https://github.com/spiritLHLS/ecs/raw/main/page/1.png)
![](https://github.com/spiritLHLS/ecs/raw/main/page/2.png)
![](https://github.com/spiritLHLS/ecs/raw/main/page/3.png)
![](https://github.com/spiritLHLS/ecs/raw/main/page/4.png)
![](https://github.com/spiritLHLS/ecs/raw/main/page/5.png)
![](https://github.com/spiritLHLS/ecs/raw/main/page/6.png)

原创区选项

![](https://github.com/spiritLHLS/ecs/raw/main/page/yc.png)

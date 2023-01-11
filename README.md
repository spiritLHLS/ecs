# ecs

支持系统：Ubuntu 18+，Debian 8+，centos 7+，Fedora，Almalinux 8.5+, Arch

### 融合怪测评脚本

```bash
bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh)
```

或

```bash
bash <(wget -qO- --no-check-certificate https://github.com/spiritLHLS/ecs/raw/main/ecs.sh)
```

融合怪的执行结果保存在```/root```下的test_result.txt中，运行完毕可用```cat test_result.txt```查看记录

使用**CDN**加速理论上已支持**国内**和**国外**服务器测试，但国内受CDN口子或国内机器口子的限制会加载慢很多

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

# bug待修复

硬件测试合集未添加更多脚本，待添加，添加时间未知

脚本使用CDN加速以支持国内服务器测试，但速度不理想，待修复，修复时间未知

部分OVZ和KVM服务器测试三网回程和硬盘读写仍然有BUG，估算是配置过于拉跨导致的(IO或者CPU)，待修复，修复时间未知

# 更新

2023.01.11 由于部分新服务器刚开机不自启动bbr，现脚本询问是否需要启动了bbr后再进行测试(前提是服务器自身已安装bbr但未启动，未安装则不询问，已启动也不询问)，第三方脚本重新分区并整合为合集，相同类型脚本在同合集中，自行选择，部分脚本描述细微更改。

历史更新日志：[跳转](https://github.com/spiritLHLS/ecs/blob/main/CHANGELOG.md)

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

![](https://github.com/spiritLHLS/ecs/raw/main/page/1.png)
![](https://github.com/spiritLHLS/ecs/raw/main/page/2.png)
![](https://github.com/spiritLHLS/ecs/raw/main/page/3.png)
![](https://github.com/spiritLHLS/ecs/raw/main/page/4.png)
![](https://github.com/spiritLHLS/ecs/raw/main/page/5.png)
![](https://github.com/spiritLHLS/ecs/raw/main/page/6.png)
![](https://github.com/spiritLHLS/ecs/raw/main/page/7.png)

原创区选项

![](https://github.com/spiritLHLS/ecs/raw/main/page/yuanchuang.png)

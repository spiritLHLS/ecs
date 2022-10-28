# ecs

### 融合怪测评脚本

```bash
bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh)
```

或

```bash
bash <(wget -qO- --no-check-certificate https://github.com/spiritLHLS/ecs/raw/main/ecs.sh)
```

### 纯测路由端口，不测其他

```bash
bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/route.sh)
```

或

```bash
bash <(wget -qO- --no-check-certificate https://github.com/spiritLHLS/ecs/raw/main/route.sh)
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

ping.pe 增加了cloudflare的5秒盾抗ddos，本脚本未适配，同期cloudflare更新了防护页面，暂无新工具绕过，修复时间未知

分区部分描述模糊难以理解，修复时间未知

lemonbench测试中的IO读写有时候过高脱离实际，修复时间未知

端口测试自动获取ssh的端口进行连通性测试替换默认端口测试，修复时间未知

~~三网测速国内节点暂时失效，未替换其他脚本，修复时间未知~~ 又自动好了，speedtest掉线一天后好了

# 更新

2022.08.31 增加三网路由延迟，Tiktok解锁测试提速

2022.09.23 增加全国网络延迟测试，新增两个原始版本的三网测速的选项

2022.10.02 重新划分测试区域，含借鉴脚本的原始脚本选项和原创脚本选项，如果本脚本不好用，可以试试原始脚本

# 功能

- [x] 自由组合测试方面和单项测试--原创
- [x] 基础系统信息--感谢teddysun和misakabench和yabs开源，本人修改整理
- [x] CPU测试--感谢lemonbench开源
- [x] 内存测试--感谢lemonbench开源
- [x] 磁盘IO读写测试--感谢lemonbench开源
- [x] 硬盘IO读写测试--感谢yabs开源
- [x] 御三家流媒体解锁--感谢sjlleo的二进制文件
- [x] 常用流媒体解锁--感谢RegionRestrictionCheck开源
- [x] Tiktok解锁--感谢lmc999的二进制文件以及fscarmen的PR
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

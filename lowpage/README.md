哪怕是最烂的服务器也能测，就是慢了点，有更烂的欢迎投稿

测这种配置极其拉跨的机器时，推荐使用screen挂起执行融合怪

然后你可以关闭SSH连接，等待一段时间后使用```cat test_result.txt```查看运行的实时状况

这样可以避免IO或者CPU过于垃圾导致的测试过程中的SSH连接中断，就不会测一半啥都没了

下面这个示例测了47分钟，一样能跑完测评

![](https://github.com/spiritLHLS/ecs/raw/main/lowpage/1.png)
![](https://github.com/spiritLHLS/ecs/raw/main/lowpage/2.png)
![](https://github.com/spiritLHLS/ecs/raw/main/lowpage/3.png)
![](https://github.com/spiritLHLS/ecs/raw/main/lowpage/4.png)
![](https://github.com/spiritLHLS/ecs/raw/main/lowpage/5.png)
![](https://github.com/spiritLHLS/ecs/raw/main/lowpage/6.png)

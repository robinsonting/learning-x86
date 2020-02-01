# learning-x86
exercise 《x86汇编语言：从实模式到保护模式》

* rtc中断，是用bochs实验的，但跳的太快了，开始以为哪里写错了，但对比示例程序，甚至直接运行示例程序还是一样的表现，后参考了网上一片[帖子](https://www.kancloud.cn/digest/protectedmode/121461)，作者也有同样的问题，所以用qemu运行，发现很稳定，基本可以判定是bochs的问题，抑或bochs的配置有问题？可以在bochsrc中配置
    ```
    clock: sync=slowdown
    ```
    但效果也不是很好

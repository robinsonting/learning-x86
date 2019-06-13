### 监测点4.2

1. 按照习题代码编译后的二进制代码是不可运行的，参考了[x86-asm-book-source](https://github.com/lichuang/x86-asm-book-source)才搞
定，具体见4-2.asm
2. 没有找到作者的FixVhdWr工具，尝试[x86-asm-book-source](https://github.com/lichuang/x86-asm-book-source)说的VBoxManage也会
报错，可用VirtualBox新建vhd后（注意要设置的小一点否则不好编辑），手工修改前512字节即可
3. 这时可直接启动，就可以看到asm的显示
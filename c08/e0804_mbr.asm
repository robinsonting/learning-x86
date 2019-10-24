; 目的：模拟从硬盘读取程序
; 效果：目标程序加载到0x1000段

section mbr vstart=0x7c00

            mov ax, 0x1000
            mov ds, ax                      ; 设置数据段，以下读取的硬盘数据存放于此段
            mov ax, 0
            mov ss, ax
            xor sp, sp

            mov di, 0x0001                  ; 扇区号低16位
            mov si, 0x0000                  ; 扇区号高12位，12 ～ 15位，必须为0
            xor bx, bx                      ; 保存读取数据的基址
            call read_one_sector

            mov ax, [0]                     ; 读取"程序"的长度
            mov dx, [2]

            mov bx, 512
            div bx

            dec ax                          ; 先减去1，因为已经读取过一次硬盘了
            cmp dx, 0
            je @1
            inc ax
    @1:
            cmp ax, 0
            je user_program

            mov cx, ax
    load:
            mov ax, ds
            add ax, 0x0020
            mov ds, ax
            inc di
            xor bx, bx
            call read_one_sector
            loop load

    user_program:                           ; 模拟用户程序
            jmp $

    ; 读取1个扇区的数据
    read_one_sector:
            push ax
            push bx
            push cx
            push dx

            ; step 1: 读取1个扇区数据
            mov dx, 0x1f2
            mov al, 1
            out dx, al

            ; step 2: 写入LBA扇区号0x0000001
            inc dx
            mov ax, di
            out dx, al      ; 0x1f3 <- 0 ~ 7

            inc dx
            mov al, ah      ; 因为out dx, ah是非法
            out dx, al      ; 0x1f4 <- 8 ~ 15

            inc dx
            mov ax, si
            out dx, al      ; 0x1f5 <- 16 ~ 23

            inc dx
            or ax, 0xe000   ; 高4位的e，0x1110，第4位表示主硬盘（从硬盘为1），第5和7位固定为1，第6位表示LBA（CHS为0）
            mov al, ah
            out dx, al      ; 0x1f6 <- 24 ~ 27，低4位与0x1f3 ~ 0x1f5共28位，组成了LBA扇区号

            ; step 3: 写入读指令
            inc dx          ; 0x1f7
            mov al, 0x20
            out dx, al

        waits:
            ; step 4: 检查硬盘是否就绪
            in al, dx
            and al, 0x88
            cmp al, 0x08
            jnz waits

            ; step 5: 读取数据（只不过增加了打印到屏幕的部分）
            mov cx, 256     ; 256个word
            mov dx, 0x1f0
        read:
            in ax, dx
            mov [bx], ax
            add bx, 2
            loop read

            pop dx
            pop cx
            pop bx
            pop ax

            ret

            times 510 - ($ - $$)    db 0
                                    db 0x55, 0xaa

section program vstart=0
    length: dd 511
            times 512 - ($ - length)    db 0
    test1   db 1
            times 512 - ($ - test1)     db 0
    test2   db 2
            times 512 - ($ - test2)     db 0

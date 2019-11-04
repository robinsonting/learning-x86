            program_lba_start equ 100

section mbr vstart=0x7c00

            mov ax, 0
            mov ss, ax
            mov sp, ax                      ; 设置栈段和栈帧

            mov ax, [cs:program_physical_address]
            mov dx, [cs:program_physical_address + 2]
            mov bx, 16
            div bx
            mov ds, ax                      ; 求出了加载用户程序的数据段地址

            mov di, program_lba_start       ; 扇区号低16位
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

            push ds                         ; 这里一定要保护ds，否则后面会乱
            mov cx, ax
    load:
            mov ax, ds
            add ax, 0x0020
            mov ds, ax
            inc di
            xor bx, bx
            call read_one_sector
            loop load
            pop ds

    user_program:
            mov ax, [6]
            mov dx, [8]
            call calc_section_address
            mov [6], ax                 ; 计算用户程序入口段地址

            mov cx, [0x0a]              ; 开始重定位用户程序各个段地址
            mov bx, 0x0c
    relocate:
            mov ax, [bx]
            mov dx, [bx + 2]
            call calc_section_address
            mov [bx], ax
            add bx, 4
            loop relocate

            jmp far [4]

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

    calc_section_address:
            push dx

            add ax, [cs:program_physical_address]
            adc dx, [cs:program_physical_address + 2]   ; 这里一个是add一个adc，外部加载程序的段地址，这里结合实际加载的段地址，一起求出段地址
            shr ax, 4
            ror dx, 4
            and dx, 0xf000
            or ax, dx

            pop dx

            ret

    program_physical_address:
            dd 0x10000

            times 510 - ($ - $$)    db 0
                                    db 0x55, 0xaa

; 目的：对用户程序重定位
; 效果：定义好的段地址，由编译的汇编地址重定位成了加载后的段地址

section mbr vstart=0x7c00

            mov ax, 0
            mov ss, ax
            mov sp, ax                      ; 设置栈段和栈帧

            mov ax, [cs:program_physical_address]
            mov dx, [cs:program_physical_address + 2]
            mov bx, 16
            div bx
            mov ds, ax                      ; 求出了加载用户程序的数据段地址

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
            mov dx, [bx + 0x02]
            call calc_section_address
            mov [bx], ax
            add bx, 4
            loop relocate

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

; 这里先这样了，由于和mbr写在了一起，偏移都是相对于mbr段的，应该统一减去mbr段的长度，但这不是本实验的重点，故忽略
section header align=16 vstart=0
    program_length:
            dd program_end - program_length         ; 程序总长度[0x00]
    code_entry:                                     ; 入口点
            dw start                                ; 偏移地址[0x04]
            dd section.code.start                   ; 段地址[0x06]
    relloc_table_length:                            ; 重定位表长度[0x0a]
            dw (header_end - code_section) / 4

    code_section:
            dd section.code.start                   ; 代码段地址[0x0c]
    data_section:
            dd section.data.start                   ; 数据段地址[0x10]
    stack_section:
            dd section.stack.start                  ; 栈段地址[0x14]

    header_end:

section code align=16 vstart=0
    start:
            mov ax, [stack_section]
            mov ss, ax
            mov sp, stack_end

section data align=16 vstart=0
    text:
            db '  This is NASM - the famous Netwide Assembler. '
            db 'Back at SourceForge and in intensive development! '
            db 'Get the current versions from http://www.nasm.us/.'
            db 0x0d,0x0a,0x0d,0x0a
            db '  Example code for calculate 1+2+...+1000:',0x0d,0x0a,0x0d,0x0a
            db '     xor dx,dx',0x0d,0x0a
            db '     xor ax,ax',0x0d,0x0a
            db '     xor cx,cx',0x0d,0x0a
            db '  @@:',0x0d,0x0a
            db '     inc cx',0x0d,0x0a
            db '     add ax,cx',0x0d,0x0a
            db '     adc dx,0',0x0d,0x0a
            db '     inc cx',0x0d,0x0a
            db '     cmp cx,1000',0x0d,0x0a
            db '     jle @@',0x0d,0x0a
            db '     ... ...(Some other codes)',0x0d,0x0a,0x0d,0x0a
            db '  The above contents is written by LeeChung. '
            db '2011-05-06'
            db 0

section stack align=16 vstart=0
            resb 256
    stack_end:

section tail align=16
    program_end:

section header align=16 vstart=0
    program_length:
            dd program_end                          ; 程序总长度[0x00]
    code_entry:                                     ; 入口点，参见jmp far的说明，这条指令会改变CS:IP
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
    print_string:
            mov cl, [bx]
            or cl, cl       ; 我写的是cmp cl, 0，参考作者代码，是否因为都是寄存器操作所以更快？
            jz .exit_print_string
            call print_char
            inc bx
            jmp print_string
            
        .exit_print_string:
            ret
        
    print_char:
            push ax
            push bx
            push es

            mov ax, 0xb800
            mov es, ax
            mov ah, 0x07
            mov al, cl
            call get_cursor
        .if_0d:
            cmp cl, 0x0d
            jne .if_0a
            call print_0d
            jmp .set_cursor
        .if_0a:
            cmp cl, 0x0a
            jne .if_other
            add di, 80
            jmp .scroll
        .if_other:
            shl di, 1
            mov [es:di], ax
            shr di, 1
            inc di
        
        .scroll:
            cmp di, 2000
            jle .set_cursor
            call scroll
        
        .set_cursor:
            call set_cursor

            pop es
            pop bx
            pop ax

            ret

    print_0d:
            push ax
            push bx
            push dx

            mov ax, di
            mov bx, 80
            xor dx, dx
            div bx
            sub di, dx

            pop dx
            pop bx
            pop ax

            ret

    scroll:
            push ax
            push bx
            push cx
            push si
            push ds

            mov ax, 0xb800
            mov ds, ax          ; 这句很重要，否则就不是移动的0xb800区域的数据
            mov es, ax

            cld
            mov di, 0
            mov si, 160
            mov cx, 2000 - 80
            rep movsw

            mov bx, di
            mov cx, 80
        .cls:
            mov word [es:bx], 0x0720    ; 黑底白字的空格
            add bx, 2
            loop .cls

            shr di, 1

            pop ds
            pop si
            pop cx
            pop bx
            pop ax

            ret

    get_cursor:
            push ax
            push dx

            mov dx, 0x3d4
            mov al, 0xe
            out dx, al
            mov dx, 0x3d5
            in al, dx
            mov ah, al

            mov dx, 0x3d4
            mov al, 0xf
            out dx, al
            mov dx, 0x3d5
            in al, dx

            mov di, ax

            pop dx
            pop ax

            ret

    set_cursor:
            push ax
            push dx
            push bx

            mov bx, di
            mov dx, 0x3d4
            mov al, 0xe
            out dx, al
            mov dx, 0x3d5
            mov al, bh
            out dx, al

            mov dx, 0x3d4
            mov al, 0xf
            out dx, al
            mov dx, 0x3d5
            mov al, bl
            out dx, al

            pop bx
            pop dx
            pop ax
            
            ret
    
    rtc:
            push ax
            push bx
            push cx
            push dx
            push es

        .is_ready:
            mov al, 0x0a
            or al, 0x80
            out 0x70, al
            in al, 0x71
            test al, 0x80
            jnz .is_ready

        .read_time:
            xor al, al
            or al, 0x80
            out 0x70, al
            in al, 0x71
            push ax                             ;秒

            mov al, 2
            or al, 0x80
            out 0x70, al
            in al, 0x71
            push ax                             ;分
                        
            mov al, 4
            or al, 0x80
            out 0x70, al
            in al, 0x71
            push ax                             ;时

            mov al, 0x0c                        ;寄存器C的索引。且开放NMI 
            out 0x70, al
            in al, 0x71                         ;读一下RTC的寄存器C，否则只发生一次中断
                                                ;此处不考虑闹钟和周期性中断的情况
            
            mov ax, 0xb800
            mov es, ax

            pop ax
            call bcd_to_ascii
            mov bx, 12*160 + 36*2               ;从屏幕上的12行36列开始显示

            mov [es:bx],ah
            mov [es:bx+2],al                    ;显示两位小时数字

            mov al, ':'
            mov [es:bx+4],al                    ;显示分隔符':'
            not byte [es:bx+5]                  ;反转显示属性 

            pop ax
            call bcd_to_ascii
            mov [es:bx+6],ah
            mov [es:bx+8],al                    ;显示两位分钟数字

            mov al,':'
            mov [es:bx+10],al                   ;显示分隔符':'
            not byte [es:bx+11]                 ;反转显示属性

            pop ax
            call bcd_to_ascii
            mov [es:bx+12],ah
            mov [es:bx+14],al                   ;显示两位小时数字
            
            mov al, 0x20                        ;中断结束命令EOI 
            out 0xa0, al                        ;向从片发送 
            out 0x20, al                        ;向主片发送 

            pop es
            pop dx
            pop cx
            pop bx
            pop ax

            iret
    
    bcd_to_ascii:                               ;BCD码转ASCII
                                                ;输入：AL=bcd码
                                                ;输出：AX=ascii
            mov ah,al                           ;分拆成两个数字 
            and al,0x0f                         ;仅保留低4位 
            add al,0x30                         ;转换成ASCII 

            shr ah,4                            ;逻辑右移4位 
            and ah,0x0f                        
            add ah,0x30

            ret

    start:
            mov ax, [stack_section]
            mov ss, ax
            mov sp, stack_pointer

            mov ax, [data_section]
            mov ds, ax

            mov bx, init_msg
            call print_string

            mov bx, install_msg
            call print_string

            mov al, 0x70
            mov bl, 4
            mul bl
            mov bx, ax

            cli

            push es
            mov ax, 0
            mov es, ax
            mov word [es:bx], rtc
            mov word [es:bx + 2], cs
            pop es

            mov al, 0x0b                    ;RTC寄存器B
            or al, 0x80                     ;阻断NMI
            out 0x70, al
            mov al, 0x12                    ;设置寄存器B，禁止周期性中断，开放更
            out 0x71, al                    ;新结束后中断，BCD码，24小时制

            mov al, 0x0c
            out 0x70, al
            in al, 0x71                     ;读RTC寄存器C，复位未决的中断状态
            
            in al, 0xa1                     ;读8259从片的IMR寄存器 
            and al, 0xfe                    ;清除bit 0(此位连接RTC)
            out 0xa1, al                    ;写回此寄存器 

            sti

            mov bx, done_msg
            call print_string

            mov bx, tip
            call print_string

            mov cx,0xb800
            mov ds,cx
            mov byte [12*160 + 33*2],'@'       ;屏幕第12行，35列

        .idle:
            hlt                                ;使CPU进入低功耗状态，直到用中断唤醒
            not byte [12*160 + 33*2+1]         ;反转显示属性 
            jmp .idle

section data align=16 vstart=0
    init_msg:
            db 'Starting...', 0xd, 0xa, 0
    install_msg:
            db 'Installing a new interrupt 70H', 0xd, 0xa, 0
    done_msg:
            db 'Done.', 0xd, 0xa, 0xd, 0xa, 0
    tip:
            db 'Clock is now working.', 0

section stack align=16 vstart=0
            resb 256
    stack_pointer:

section tail
    program_end:
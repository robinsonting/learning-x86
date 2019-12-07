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
            jmp .exit_print_char
        .if_0a:
            cmp cl, 0x0a
            jne .if_other
            add di, 80
            cmp di, 2000
            jle .exit_print_char
            call scroll
            jmp .exit_print_char
        .if_other:
            shl di, 1
            mov [es:di], ax
            shr di, 1
            inc di
        
        .exit_print_char:
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

    start:
            mov ax, [stack_section]
            mov ss, ax
            mov sp, stack_end

            mov ax, [data_section]
            mov ds, ax
            mov bx, text
            call print_string

            jmp $

section data align=16 vstart=0
    text:
            db 0x0a
            db '  This is NASM - the famous Netwide Assembler. '
            db 'Back at SourceForge and in intensive development! '
            db 'Get the current versions from http://www.nasm.us/.'
            db 0x0d, 0x0a, 0x0d, 0x0a
            db '  Example code for calculate 1 + 2 + ... + 1000 = ', 0x0d, 0x0a, 0x0d, 0x0a
            db '     xor dx, dx', 0x0d, 0x0a
            db '     xor ax, ax', 0x0d, 0x0a
            db '     xor cx, cx', 0x0d, 0x0a
            db '  @@:', 0x0d, 0x0a
            db '     inc cx', 0x0d, 0x0a
            db '     add ax, cx', 0x0d, 0x0a
            db '     adc dx, 0', 0x0d, 0x0a
            db '     inc cx', 0x0d, 0x0a
            db '     cmp cx, 1000', 0x0d, 0x0a
            db '     jle @@', 0x0d, 0x0a
            db '     ... ...(Some other codes)', 0x0d, 0x0a, 0x0d, 0x0a
            db '  The above contents is written by LeeChung. ', 0x0d, 0x0a, 0x0d, 0x0a
            db '                                                                        5/6/2011'
            db 0x0d, 0x0a
            db 0

section stack align=16 vstart=0
            resb 256
    stack_end:

section tail align=16
    program_end:
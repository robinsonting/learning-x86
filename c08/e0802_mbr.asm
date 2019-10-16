; 目的：实操从硬盘读取数据
; 效果：打印"1 + 2 + 3 + ... + 1000 = "

section mbr vstart=0x7c00
    ; step 1: 读取1个扇区数据
    mov dx, 0x1f2
    mov al, 1
    out dx, al

    ; step 2: 写入LBA扇区号0x0000001
    mov dx, 0x1f3
    mov al, 1
    out dx, al      ; 往端口0x1f3写入1

    inc dx          ; 0x1f4
    mov al, 0
    out dx, al      ; 0x1f4 <- 0x00

    inc dx          ; 0x1f5
    out dx, al      ; 0x1f5 <- 0x00

    inc dx          ; 0x1f6
    mov al, 0xe0    ; 0x1f6 <- 0xe0，低4位与0x1f3 ~ 0x1f5共28位，组成了LBA扇区号，
                    ; 高4位的e，0x1110，第4位表示主硬盘（从硬盘为1），第5和7位固定为1，第6位表示LBA（CHS为0）
    out dx, al

    ; step 3: 写入读指令
    inc dx          ; 0x1f7
    mov al, 0x20
    out dx, al

    ; step 4: 检查硬盘是否就绪
waits:
    in al, dx
    and al, 0x88
    cmp al, 0x08
    jnz waits

    ; step 5: 读取数据（只不过增加了打印到屏幕的部分）
    mov ax, 0xb800
    mov es, ax
    mov di, 0xb40
    mov bx, 0x07
    mov cx, text_end - text
    mov dx, 0x1f0
read:
    in ax, dx
    mov [es:di], al
    inc di
    mov [es:di], bx
    inc di
    mov [es:di], ah
    inc di
    mov [es:di], bx
    inc di
    loop read

    jmp $

times 510 - ($ - $$) db 0
    db 0x55, 0xaa

text:
    db '1 + 2 + 3 + ... + 1000 = '
text_end:
times 512 - ($ - text) db 0
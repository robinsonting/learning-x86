    jmp near start

text:
    db '1 + 2 + 3 + ... + 100 = '

start:
    mov ax, 0x07c0
    mov ds, ax

    mov ax, 0xb800
    mov es, ax

    mov ax, 0
    mov cx, 100
sum:
    add ax, cx
    loop sum

    xor cx, cx
    mov ss, cx
    xor sp, sp
    mov bx, 10
divide:
    xor dx, dx
    div bx
    or dl, 0x30                 ; 原先我写的是add dl, 0x30，认为or的写法是“小伎俩”，但考虑or的运算速度“应该”比add快，所以作为转10进制的场景中，应该是更优的做法
    mov dh, 0x07                ; 这里不像下面的mov ah, 0x07可以放在循环外，因为xor dx, dx会连高位也重置
    push dx
    cmp ax, 0
    jne divide

    mov bx, text
    mov si, (start - text - 1)
    mov ah, 0x07
prepare:
    mov al, [bx + si]
    push ax
    dec si                      ; 初始化si为start - text - 1，与dec si和jns prepare是一套组合
    jns prepare

    mov di, 0xb40
print:
    pop ax
    mov [es:di], ax
    add di, 2
    cmp sp, 0
    jne print

    jmp $

    times 510 - ($ - $$) db 0
    db 0x55, 0xaa

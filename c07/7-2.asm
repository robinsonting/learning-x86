; 计算1 + 2 + ... + 1000 = ?
; 一个是adc的应用
; 一个是div除法的应用，16位除法的被除数可以是32位的，但要保证商不能超过0xffff，
; 7-1的版本中有xor dx, dx，实验发现，并不是必须把dx置零，但由于进行了除法后，保存余数，所以div后，还是需要置零
    jmp near start

text:
    db '1 + 2 + 3 + ... + 1000 = '

start:
    mov ax, 0x07c0
    mov ds, ax

    mov ax, 0xb800
    mov es, ax

    mov ax, 0
    mov dx, 0
    mov cx, 1000
sum:
    add ax, cx
    adc dx, 0
    loop sum

    xor cx, cx
    mov ss, cx
    xor sp, sp
    mov bx, 10
divide:
    div bx
    or dl, 0x30                 ; 原先我写的是add dl, 0x30，认为or的写法是“小伎俩”，但考虑or的运算速度“应该”比add快，所以作为转10进制的场景中，应该是更优的做法
    mov dh, 0x07                ; 这里不像下面的mov ah, 0x07可以放在循环外，因为xor dx, dx会连高位也重置
    push dx
    xor dx, dx
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

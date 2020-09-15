%include "kernel.inc"
[bits 32]
SECTION .data

prefix_16 db '0x',0
put_int_buffer dq 0

SECTION .text
;===========put_char======================
;功能描述:把栈中的一个字符打印到屏幕光标处
;输入:待打印字的字符
;=========================================
global put_char ;声明全局函数
global put_str
global put_int
put_char:

pushad ;push all double
mov ax,SELECTOR_VIDEO 
mov gs,ax

;get high 8bits
mov dx,0x3d4
mov al,0x0e
out dx,al
mov dx,0x3d5
in al,dx
mov ah,al

;read low 8bits
mov dx,0x3d4
mov al,0x0f
out dx,al
mov dx,0x3d5
in al,dx

;save cursor location
mov bx,ax

mov ecx,[esp+36]

cmp cl,0xd
jz .is_carriage_return

cmp cl,0xa
jz .is_linefeed

cmp cl,0x8
jz .is_backspace

jmp .other_char

;-------------------
.is_backspace:
    dec bx
    shl bx,1

    mov byte [gs:bx],0x20 ;用空格代替 原先字符
    inc bx
    mov byte [gs:bx],0x07  ;黑底白字
    shr bx,1 ;余数抛弃
    jmp .set_cursor
;------------------
.other_char:
    shl bx,1

    mov [gs:bx],cl
    inc bx
    mov byte [gs:bx],0x07
    inc bx
    shr bx,1
    cmp bx,2000
    jl .set_cursor
;-----------------
;字符超过2000，换行
.is_carriage_return:
.is_linefeed:

    xor edx,edx
    mov ax,bx
    mov si,80
    div si 

sub bx,dx  ;减余数

.is_carriage_return_end:
    add bx,80
    cmp bx,2000

.is_linefeed_end:
    jl .set_cursor
.roll_screen:
    cld
    mov ecx,960  ;2000-80 =1920;1920*2/4 =960
    mov esi,0xc00b80a0
    mov edi,0xc00b8000
    rep movsd

    mov ebx,3840
    mov ecx,80

.clean_last_line:
    mov word [gs:ebx],0x0720
    add ebx,2
    loop .clean_last_line
    mov bx,1920

.set_cursor:

    mov dx,0x03d4
    mov al,0x0e
    out dx,al
    mov dx,0x03d5
    mov al,bh
    out dx,al

    mov dx,0x03d4
    mov al,0x0f
    out dx,al
    mov dx,0x03d5
    mov al,bl
    out dx,al
.put_char_done:
    popad
    ret

put_str:
;------------------------
;  调用put_char打印字符串
;  输入:栈中的字符串地址
;-------------------------
    push ebx
    push ecx
    xor ecx,ecx
    mov ebx,[esp+12]
.go_on:
    mov cl,[ebx]
    cmp cl,0
    jz .str_over
    push ecx
    call put_char
    add esp,4
    inc ebx
    jmp .go_on
    
.str_over:
    pop ecx
    pop ebx 
    ret

;--------------------
;输出数字
;输入:栈中待打印数字

;-------------------
put_int:
    pushad
    mov ebp, esp
    mov eax, [ebp + 4 * 9]
    mov edx, eax
    mov edi, 7
    mov ecx, 8
    mov ebx, put_int_buffer

.16based_4bits:
    and edx, 0x0000000F
    cmp edx, 9
    jg .is_A2F
    add edx, '0'
    jmp .store

.is_A2F:
    sub edx, 10
    add edx, 'A'

.store:
    mov [ebx + edi], dl
    dec edi
    shr eax, 4
    mov edx, eax
    loop .16based_4bits

.ready_print:
    inc edi

.skip_prefix_0:
    cmp edi, 8
    je .full0

.go_on_skip:
    mov cl, [put_int_buffer + edi]
    inc edi
    cmp cl, '0'
    je .skip_prefix_0
    dec edi

    push prefix_16
    call put_str
    add esp,4
    jmp .put_each_num

.full0:
    mov cl, '0'
.put_each_num:
    push ecx
    call put_char
    add esp, 4
    inc edi
    mov cl, [put_int_buffer + edi]
    cmp edi, 8
    jl .put_each_num
    popad
    ret


%include "kernel.inc"
[bits 32]
SECTION .text
;===========put_char======================
;功能描述:把栈中的一个字符打印到屏幕光标处
;输入:待打印字的字符
;=========================================
global put_char ;声明全局函数
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
mov al,ah

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

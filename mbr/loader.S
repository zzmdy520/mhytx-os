%include "boot.inc"

SECTION loader vstart=LOADER_BASE_ADDR
mov sp,0x7c00
mov ax,0xb800
mov es,ax

;int 0x10 功能号 0x06 功能:上卷窗口
mov ax,0600h
mov bx,0700h
mov dx,184fh
int 10h
;输出信息
mov byte [es:0x00],'m'
mov byte [es:0x01],0x8d
mov byte [es:0x02],'y'
mov byte [es:0x03],0x8d
mov byte [es:0x04],'l'
mov byte [es:0x05],0x8d
mov byte [es:0x06],'o'
mov byte [es:0x07],0x8d
mov byte [es:0x08],'d'
mov byte [es:0x09],0x8d
mov byte [es:0x0a],'e'
mov byte [es:0x0b],0x8d
mov byte [es:0x0c],'r'
mov byte [es:0x0d],0x8d
Hlt
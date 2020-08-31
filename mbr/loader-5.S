%include "boot.inc"

LOADER_STACK_TOP equ LOADER_BASE_ADDR
SECTION loader align=16 vstart=LOADER_BASE_ADDR
jmp loader_start

;======================================
;***********定义段描述符*****************
;======================================

GDT_BASE: dd 0x00000000
	  dd 0x00000000

CODE_DESC: dd 0x0000FFFF
  	   dd DESC_CODE_HIGH4

DATA_STACK_DESC:dd 0x0000FFFF
		dd DESC_DATA_HIGH4

VIDEO_DESC:  dd 0x8000_0007
	     dd DESC_VIDEO_HIGH4 

GDT_SIZE equ $-GDT_BASE
GDT_LIMIT equ GDT_SIZE-1
times 60 dq 0;预留描述符空位

;定义选择子
SELECTOR_CODE equ (0x0001<<3)+TI_GDT+RPL0
SELECTOR_DATA equ (0x0002<<3)+TI_GDT+RPL0
SELECTOR_VIDEO equ (0x0003<<3)+TI_GDT+RPL0

;gdtr寄存器
gdt_ptr dw GDT_LIMIT
        dd GDT_BASE
;======================================
;定义获取内存信息变量
total_mem_bytes dd 0 ;0xb09
;ards表
ards dd 0
times 30 dd 0 

loader_start:
;=====获取内存信息========
xor ebx,ebx                 ;set ebx = 0,quickly than mov ebx,0
mov di,ards 
mov edx,SMAP

;read info of mem
.e820_mem_get_loop:
    mov eax,0x0000e820
    mov ecx,20
    int 0x15
    mov ecx,ards
    mov eax,[ecx]
    add eax,[ecx+8]
    cmp eax,[total_mem_bytes]
    jng .next_loop
    mov [total_mem_bytes],eax
    .next_loop:    
    cmp ebx,0
    jnz .e820_mem_get_loop 
;*****忽略其他方式********
;=====获取内存信息========

mov sp,LOADER_BASE_ADDR

;int 0x10 功能号 0x06 功能:上卷窗口
mov ax,0600h
mov bx,0700h
mov dx,184fh
int 10h


;输出信息
mov byte [gs:0x00],'M'
mov byte [gs:0x01],0x8d
mov byte [gs:0x02],'y'
mov byte [gs:0x03],0x8d
mov byte [gs:0x04],'L'
mov byte [gs:0x05],0x8d
mov byte [gs:0x06],'o'
mov byte [es:0x07],0x8d
mov byte [gs:0x08],'d'
mov byte [gs:0x09],0x8d
mov byte [gs:0x0a],'e'
mov byte [gs:0x0b],0x8d
mov byte [gs:0x0c],'r'
mov byte [gs:0x0d],0x8d

;====open A20=====
in al,0x92
or al,0000_0010B
out 0x92,al
;====load gdt====
lgdt [gdt_ptr]
;====set cr0=====
mov eax,cr0
or eax,0x000000001
mov cr0,eax

jmp dword SELECTOR_CODE:p_mode_start; 刷新流水线

[bits 32]
p_mode_start:
mov ax,SELECTOR_DATA
mov ds,ax
mov es,ax
mov ss,ax
mov esp,LOADER_STACK_TOP
mov ax,SELECTOR_VIDEO
mov gs,ax

mov byte [gs:160],'p'
hlt

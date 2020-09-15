%include "boot.inc"

SECTION MBR vstart=0x7c00
mov ax,cs
mov ds,cx
mov es,ax
mov ss,ax
mov fs,ax
mov sp,0x7c00
mov ax,0xb800
mov gs,ax

;int 0x10 功能号 0x06 功能:上卷窗口
mov ax,0600h
mov bx,0700h
mov dx,184fh
int 10h
;输出信息
mov byte [gs:0x00],'m'
mov byte [gs:0x01],0x8d
mov byte [gs:0x02],'y'
mov byte [gs:0x03],0x8d
mov byte [gs:0x04],'m'
mov byte [gs:0x05],0x8d
mov byte [gs:0x06],'b'
mov byte [gs:0x07],0x8d
mov byte [gs:0x08],'r'
mov byte [gs:0x0a],0x8d

mov eax,LOADER_START_SECTOR ;起始扇区lba地址
mov bx,LOADER_BASE_ADDR	    ;写入的内存地址
mov cx,4		    ;写入扇区数
call rd_disk_m_16

jmp LOADER_BASE_ADDR        ;跳转到加载器
;------------------------------------------
;功能:读取硬盘n个扇区
rd_disk_m_16:
;------------------------------------------
;step 1:选择通道，向该通道 **sector count**寄存器中写入带操作的扇区数
push cx
push eax

mov dx,0x1f2
mov al,cl  ;除了data端口，其他都是8位寄存器
out dx,al ;out只能用dx和ax、al

;step 2:往该通道的三个lba寄存器写入扇区起始地址的低24位。
pop eax  ;恢复eax寄存器内容

; LBA low
mov dx,0x1f3
out dx,al

;LBA mid
mov cl,8
shr eax,cl ;shr移位大于1，放入cl中
mov dx,0x1f4
out dx,al

;LBA high
shr eax,cl
mov dx,0x1f5
out dx,al

;step 3:device位及lba高位
shr eax,cl
and al,0x0f
or al,0xe0 ;1110_0000 设置7～4位为lba模式
mov dx,0x1f6
out dx,al

;step 4:command寄存器写操作命令
mov dx,0x1f7
mov al,0x20
out dx,al

;step 5:检测硬盘状态
.not_ready:          ;端口没准备好
nop;减少对磁盘工作的打扰，相当于sleep
in al,dx
and al,0x88 ;1000_1000
cmp al,0x08 ;准备好了and操作后应该为0000_1000
jne .not_ready

;step 6:read data
pop cx;恢复cx寄存器
mov ax,cx
mov dx,256
mul dx
mov cx,ax
;cx为读取的扇区数，一个扇区512字节，一次读入1个字，共需要cx*512/2。

mov dx,0x1f0
.read_data:
in ax,dx
mov [bx],ax
add bx,2
loop .read_data
ret

times 510-($-$$) db 0
db 0x55,0xaa


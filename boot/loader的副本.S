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
global total_mem_bytes dd 0 ;0xb09
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
p_mode_start: ;0xc42
mov ax,SELECTOR_DATA
mov ds,ax
mov es,ax
mov ss,ax
mov esp,LOADER_STACK_TOP
mov ax,SELECTOR_VIDEO
mov gs,ax

; -------------------------   加载kernel  ----------------------
mov eax, KERNEL_START_SECTOR        ; kernel.bin所在的扇区号
mov ebx, KERNEL_START_ADDR       ; 从磁盘读出后，写入到ebx指定的地址
mov ecx, 200			       ; 读入的扇区数

call rd_disk_m_32 
mov byte [gs:0x0e],'V'
mov byte [gs:0x0f],0x8d

call steup_page 
sgdt [gdt_ptr]
mov ebx,[gdt_ptr+2]
or dword [ebx+0x18+4],0xc0000000
add dword [gdt_ptr+2],0xc0000000
add esp,0xc0000000
mov eax,PAGE_DIR_TABLE_ADDR
mov cr3,eax

mov eax,cr0
or eax,0x80000000
mov cr0,eax

lgdt [gdt_ptr] ;0xcb7
jmp SELECTOR_CODE:enter_kernel	  ;强制刷新流水线,更新gdt

enter_kernel: 
   mov byte [gs:160],'v'
   call kernel_init
   mov esp, 0xc009f000

jmp KERNEL_ENTRY_ADDR

mov byte [gs:162],'v'
hlt
;-----------------   将kernel.bin中的segment拷贝到编译的地址   -----------
kernel_init:
   xor eax, eax
   xor ebx, ebx		;ebx记录程序头表地址
   xor ecx, ecx		;cx记录程序头表中的program header数量
   xor edx, edx		;dx 记录program header尺寸,即e_phentsize

   mov dx, [KERNEL_START_ADDR + 42]	  ; 偏移文件42字节处的属性是e_phentsize,表示program header大小
   mov ebx, [KERNEL_START_ADDR + 28]   ; 偏移文件开始部分28字节的地方是e_phoff,表示第1 个program header在文件中的偏移量
					  ; 其实该值是0x34,不过还是谨慎一点，这里来读取实际值
   add ebx, KERNEL_START_ADDR
   mov cx, [KERNEL_START_ADDR + 44]    ; 偏移文件开始部分44字节的地方是e_phnum,表示有几个program header
.each_segment:
   cmp byte [ebx + 0], PT_NULL		  ; 若p_type等于 PT_NULL,说明此program header未使用。
   je .PTNULL

   ;为函数memcpy压入参数,参数是从右往左依然压入.函数原型类似于 memcpy(dst,src,size)
   push dword [ebx + 16]		  ; program header中偏移16字节的地方是p_filesz,压入函数memcpy的第三个参数:size
   mov eax, [ebx + 4]			  ; 距程序头偏移量为4字节的位置是p_offset
   add eax, KERNEL_START_ADDR	  ; 加上kernel.bin被加载到的物理地址,eax为该段的物理地址
   push eax				  ; 压入函数memcpy的第二个参数:源地址
   push dword [ebx + 8]			  ; 压入函数memcpy的第一个参数:目的地址,偏移程序头8字节的位置是p_vaddr，这就是目的地址
   call mem_cpy				  ; 调用mem_cpy完成段复制 0xd1b
   add esp,12				  ; 清理栈中压入的三个参数
.PTNULL:
   add ebx, edx				  ; edx为program header大小,即e_phentsize,在此ebx指向下一个program header 
   loop .each_segment
   ret


;----------  逐字节拷贝 mem_cpy(dst,src,size) ------------
;输入:栈中三个参数(dst,src,size)
;输出:无
;---------------------------------------------------------
mem_cpy:		      
   
   cld
   push ebp
   mov ebp, esp
   push ecx		   ; rep指令用到了ecx，但ecx对于外层段的循环还有用，故先入栈备份
   mov edi, [ebp + 8]	   ; dst
   mov esi, [ebp + 12]	   ; src
   mov ecx, [ebp + 16]	   ; size
   rep movsb		   ; 逐字节拷贝
   ;恢复环境
   pop ecx		
   pop ebp
   ret


;-----创建页目录页表-------
steup_page:
    mov ecx,4096
    mov esi,0
.clear_page_dir:
mov byte [PAGE_DIR_TABLE_ADDR+esi],0
    inc esi
    loop .clear_page_dir

.create_pde:  ;0xcb7
    mov eax,PAGE_DIR_TABLE_ADDR
    add eax,0x1000
    mov ebx,eax

    or eax,PG_US_U|PG_RW_W|PG_P
    mov [PAGE_DIR_TABLE_ADDR],eax ;目录项0
    mov [PAGE_DIR_TABLE_ADDR+0xc00],eax ;为操作系统分配共享页
    ;让最后一个页目录表项指向目录表自己的位置
    sub eax,0x1000
    mov [PAGE_DIR_TABLE_ADDR+4092],eax
;创建页表项
mov ecx,256   ;1M低端内存,1m/4k = 256
mov esi,0
mov edx,PG_US_U|PG_RW_W|PG_P

.create_pte:
    mov[ebx+esi*4],edx
    add edx,4096
    inc esi
    loop .create_pte
;创建内核其pde
    mov eax,PAGE_DIR_TABLE_ADDR
    add eax,0x2000     ;0xcf5

    or eax,PG_US_U|PG_RW_W|PG_P
    mov ebx,PAGE_DIR_TABLE_ADDR
    mov ecx,254
    mov esi,769
.create_kernel_pde:
    mov [ebx+4*esi],eax
    inc esi
    add eax,0x1000
    
    loop .create_kernel_pde
    ret
    

;-------------------------------------------------------------------------------
			   ;功能:读取硬盘n个扇区
rd_disk_m_32:	   
      mov esi,eax	   ; 备份eax
      mov di,cx		   ; 备份扇区数到di
;读写硬盘:
;第1步：设置要读取的扇区数
      mov dx,0x1f2
      mov al,cl
      out dx,al            ;读取的扇区数

      mov eax,esi	   ;恢复ax

;第2步：将LBA地址存入0x1f3 ~ 0x1f6

      ;LBA地址7~0位写入端口0x1f3
      mov dx,0x1f3                       
      out dx,al                          

      ;LBA地址15~8位写入端口0x1f4
      mov cl,8
      shr eax,cl
      mov dx,0x1f4
      out dx,al

      ;LBA地址23~16位写入端口0x1f5
      shr eax,cl
      mov dx,0x1f5
      out dx,al

      shr eax,cl
      and al,0x0f	   ;lba第24~27位
      or al,0xe0	   ; 设置7～4位为1110,表示lba模式
      mov dx,0x1f6
      out dx,al

;第3步：向0x1f7端口写入读命令，0x20 
      mov dx,0x1f7
      mov al,0x20                        
      out dx,al

;第4步：检测硬盘状态
  .not_ready:		   
      nop
      in al,dx
      and al,0x88	   ;第4位为1表示硬盘控制器已准备好数据传输,第7位为1表示硬盘忙
      cmp al,0x08
      jnz .not_ready	   ;若未准备好,继续等。

;第5步：从0x1f0端口读数据
      mov ax, di	   ;以下从硬盘端口读数据用insw指令更快捷,不过尽可能多的演示命令使用,
			   ;在此先用这种方法,在后面内容会用到insw和outsw等

      mov dx, 256	   ;di为要读取的扇区数,一个扇区有512字节,每次读入一个字,共需di*512/2次,所以di*256
      mul dx
      mov cx, ax	   
      mov dx, 0x1f0
  .go_on_read:
      in ax,dx		
      mov [ebx], ax
      add ebx, 2
			
      loop .go_on_read
      ret

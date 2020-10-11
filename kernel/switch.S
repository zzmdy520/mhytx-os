[bits 32]
section .text
extern put_int
global switch_to
switch_to:
	;push eax
	;call put_int
	;add esp,4
	push esi
	push edi
	push ebx
	push ebp
	mov eax,[esp + 20]
	mov [eax],esp
	;以上为备份环境
	mov eax,[esp + 24]
	mov esp,[eax]
	pop ebp
	pop ebx
	pop edi
	pop esi 
	ret

;=======选择子属性======
TL_GDT equ 0
TI_LDT equ 100b
RPL0 equ 00b
RPL1 equ 01b
RPL2 equ 10b
RPL3 equ 11b

;=======选择子=========
SELECTOR_VIDEO equ (0x0003<<3) +TL_GDT + RPL0

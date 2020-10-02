BUILD_DIR = ./build
ENTRY_POINT = 0xc0015000
AS = nasm 
CC = gcc
LD = ld
LIB = -I lib/ -I lib/kernel/ -I lib/user/ -I kernel/ -I device/
ASFLAGS = -f elf
CFLAGS = -Wall $(LIB) -c -fno-builtin -W -Wstrict-prototypes -Wmissing-prototypes 
LDFLAGS = -no-pie -Ttext $(ENTRY_POINT) -e main -Map $(BUILD_DIR)/kernel.map
OBJS = $(BUILD_DIR)/main.o $(BUILD_DIR)/init.o $(BUILD_DIR)/interrupt.o $(BUILD_DIR)/timer.o  $(BUILD_DIR)/memory.o $(BUILD_DIR)/bitmap.o $(BUILD_DIR)/kernel.o $(BUILD_DIR)/print.o $(BUILD_DIR)/string.o


 #$(BUILD_DIR)/debug.o
.PHONY: mk_dir hd clean gccjob nasmjob ld


#c代码编译
$(BUILD_DIR)/main.o: kernel/main.c lib/kernel/print.h lib/stdint.h kernel/init.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/init.o: kernel/init.c kernel/init.h lib/kernel/print.h lib/stdint.h kernel/interrupt.h device/timer.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/interrupt.o: kernel/interrupt.c kernel/interrupt.h lib/stdint.h kernel/global.h kernel/io.hpp lib/kernel/print.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/timer.o: device/timer.c device/timer.h lib/stdint.h kernel/io.hpp lib/kernel/print.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/string.o:lib/string.c lib/string.h kernel/global.h lib/stdint.h
	$(CC) $(CFLAGS) $< -o $@
#$(BUILD_DIR)/debug.o: kernel/debug.c kernel/debug.h lib/kernel/print.h lib/stdint.h kern#el/interrupt

$(BUILD_DIR)/bitmap.o: lib/kernel/bitmap.c lib/kernel/bitmap.o lib/stdint.h kernel/global.h lib/string.h lib/kernel/print.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/memory.o: kernel/memory.c kernel/memory.h lib/kernel/print.h lib/stdint.h lib/kernel/bitmap.h
	$(CC) $(CFLAGS) $< -o $@
#	$(CC) $(CFLAGS) $< -o $@

# 编译loader和mbr
$(BUILD_DIR)/mbr.bin: mbr.S
	$(AS) $(ASIB) $< -o $@

$(BUILD_DIR)/loader.bin: loader.S
	$(AS) $(ASIB) $< -o $@

#nasm汇编
$(BUILD_DIR)/kernel.o: kernel/kernel.S
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/print.o: lib/kernel/print.S
	$(AS) $(ASFLAGS) $< -o $@

# 链接
$(BUILD_DIR)/kernel.bin: $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

mk_dir:
	if [ ! -d $(BUILD_DIR) ]; then mkdir $(BUILD_DIR); fi

hd:
	dd if=/Users/lonekriss/Documents/mhytx-os/kernel.bin of=/Users/lonekriss/hd60m.img bs=512 count=200 seek=9 conv=notrunc

clean:
	cd $(BUILD_DIR) && rm -f ./*


gccjob: $(BUILD_DIR)/main.o $(BUILD_DIR)/init.o $(BUILD_DIR)/interrupt.o $(BUILD_DIR)/timer.o $(BUILD_DIR)/string.o $(BUILD_DIR)/memory.o $(BUILD_DIR)/bitmap.o

nasmjob:$(BUILD_DIR)/kernel.o $(BUILD_DIR)/print.o

ld : $(BUILD_DIR)/kernel.bin 

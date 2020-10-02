#include "init.h"
#include "print.h"
#include "memory.h"
#include "timer.h"
extern void idt_init(void);

void init_all(){
    put_str("init_all start!\n");
    idt_init();
    timer_init();
    mem_init();
}

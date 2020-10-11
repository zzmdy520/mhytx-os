#include "init.h"
#include "print.h"
#include "memory.h"
#include "timer.h"
#include "thread.h"
#include "console.h"
extern void idt_init(void);

void init_all(){
    put_str("init_all start!\n");
    mem_init();
    idt_init();
    thread_init();
    timer_init();
    console_init();
   }

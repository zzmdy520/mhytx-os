#include "init.h"
#include "print.h"
extern void idt_init(void);

void init_all(){
    put_str("init_all start!\n");
    idt_init();
}

#include "print.h"
#include "init.h"
#include "memory.h"
#include "thread.h"

void k_thread_test(void *arg);

int main(void){
put_char('k');
put_char('e');
put_char('r');
put_char('n');
put_char('e');
put_char('l');
put_char('v');
put_char('1');
put_char('.');
put_char('0');
put_char('\n');
//put_str("put_str done v5!\n");
//put_char('\n');
//put_int(0xabcd1234);
//asm volatile("cli");
init_all();
put_char('\n');
//put_str("before!\n");
//asm volatile("sti");
//put_str("after!\n");

//void* addr = get_kernel_pages(3);
//put_str("\n get_kernel_pages vaddr is");
//put_int((uint32_t)addr);
//put_char('\n');

thread_start("k_thread_test", 31, k_thread_test, "thread_test");
asm volatile("hlt");
//while(1);
return 0;
}

void k_thread_test(void *arg){
    char* para = arg;
    put_str("hello\n");
    while(1){
        put_str(para);
    }
       }

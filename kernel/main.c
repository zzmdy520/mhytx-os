#include "print.h"
#include "init.h"
#include "memory.h"
#include "thread.h"
#include "interrupt.h"
# include "console.h"

void k_thread_test(void *arg);
void k_thread_test2(void *arg);

int main(void){
put_str("kernel v1.0 \n");
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

//thread_start("k_thread_test", 31, k_thread_test, "thread_test");
//thread_start("k_thread_test2", 8, k_thread_test2, "thread_test2");
intr_enable();
//asm volatile("hlt");
while(1){
    //console_put_str("main  ");
};

return 0;
}

void k_thread_test(void *arg){
    char* para = arg;
    while(1){
        console_put_str(para);
    }
       }

void k_thread_test2(void *arg){
    char* para = arg;
    while(1){
       console_put_str(para);
    }
       }

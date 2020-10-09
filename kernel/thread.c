# include "thread.h"
# include "stdint.h"
# include "string.h"
# include "global.h"
# include "memory.h"
# include "interrupt.h"
# include "print.h"

# define PAGE_SIZE 4096 


static void kernel_thread(thread_func* function, void* func_arg){
    function(func_arg);
}


void thread_create(struct task_struct* pthread, thread_func function, void* func_arg){
    pthread->self_kstack -= sizeof(struct intr_stack);
    pthread->self_kstack -= sizeof(struct thread_stack);
    struct thread_stack* kthread_stack = (struct thread_stack*) pthread->self_kstack;
    kthread_stack->eip = kernel_thread; //指向函数地址
    kthread_stack->function = function;
    kthread_stack->func_args = func_arg;
    kthread_stack->ebp = kthread_stack->ebx = kthread_stack->esi = kthread_stack ->edi = 0;//归主函数使用，先置0
}


void init_thread(struct task_struct* pthread, char* name, int prio){
    memset(pthread, 0, sizeof(*pthread));
    strcpy(pthread->name, name);//此函数出错导致无限循在在此
    //put_str("wtf!\n");排错

    pthread->status = TASK_RUNNING;
    pthread->priority = prio;
    pthread->self_kstack = (uint32_t*)((uint32_t)pthread + PAGE_SIZE);
    
    put_int((uint32_t)pthread->self_kstack);
    pthread->stack_magic = 0x19941219;
}


struct task_struct* thread_start(char* name, int prio, thread_func function, void* func_arg){
    //put_str("thread_start!\n");
    struct task_struct* thread = get_kernel_pages(1);
    //put_str("page_start!\n");
    init_thread(thread, name, prio);
    thread_create(thread, function, func_arg);
    
   asm volatile ("movl %0, %%esp; pop %%ebp; pop %%ebx; pop %%edi; pop %%esi; ret" : : "g" (thread->self_kstack) :    "memory");   
   return thread;
}

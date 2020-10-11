# include "thread.h"
# include "stdint.h"
# include "string.h"
# include "global.h"
# include "memory.h"
# include "interrupt.h"
# include "print.h"
# include "list.h"
# include "sync.h"
# define PAGE_SIZE 4096 

struct task_struct* main_thread;
struct list thread_ready_list;
struct list thread_all_list;
static struct list_elem* thread_tag;

extern void switch_to(struct task_struct* cur,struct task_struct* next);
void thread_create(struct task_struct* pthread, thread_func function, void* func_arg);
void thread_unblock(struct task_struct* pthread);
static void kernel_thread(thread_func* function, void* func_arg){
    intr_enable();
    function(func_arg);
}


struct task_struct* running_thread(){
    uint32_t esp;
    asm volatile("mov %%esp,%0":"=g" (esp));
    //put_int((uint32_t)(esp & 0xfffff000));
    return (struct task_struct*)(esp & 0xfffff000);
}



void thread_create(struct task_struct* pthread, thread_func function, void* func_arg){
    put_str("wtf_creat!\n");
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
    //put_str("wtf!\n");//排错
    if(pthread == main_thread){
        pthread->status = TASK_RUNNING;
    }else{
        pthread->status = TASK_READY;
    }
    pthread->priority = prio;
    pthread->ticks = prio;
    pthread->elapsed_ticks = 0;
    pthread->pgdir = NULL;
    pthread->self_kstack = (uint32_t*)((uint32_t)pthread + PAGE_SIZE);
    pthread->stack_magic = 0x19941219;
}


struct task_struct* thread_start(char* name, int prio, thread_func function, void* func_arg){
    //put_str("thread_start!\n");
    struct task_struct* thread = get_kernel_pages(1);
    //put_str("page_start!\n");
    init_thread(thread, name, prio);
     //put_str("init_thread_start!\n");
    thread_create(thread, function, func_arg);
     put_str("creat_thread_start!\n");

    //if(elem_find(&thread_ready_list, &thread->general_tag)) return NULL;
    list_append(&thread_ready_list, &thread->general_tag);
    put_str("list_done!\n");

    //if(elem_find(&thread_all_list, &thread->all_list_tag)) return NULL;
    list_append(&thread_all_list, &thread->all_list_tag);
   return thread;
}


static void make_main_thread(void){
    main_thread = running_thread();
    init_thread(main_thread, "main", 31);
    list_append(&thread_all_list,&main_thread->all_list_tag);

}


void schedule(void){
    struct task_struct* cur = running_thread();
    if(cur->status == TASK_RUNNING){
        list_append(&thread_ready_list,&cur->general_tag);
        cur->ticks = cur->priority;
        cur->status = TASK_READY;
    }else{
        //某些事件发生使其下处理器
    }
    thread_tag = NULL;
    thread_tag = list_pop(&thread_ready_list);
    //put_str("sche_run");
    struct task_struct* next = elem2entry(struct task_struct, general_tag, thread_tag);
    //put_str("sche_run2");

    next->status = TASK_RUNNING;
    switch_to(cur, next);
    }

    
void thread_init(void){
    put_str("thread_init start \n");
    list_init(&thread_ready_list);
    list_init(&thread_all_list);
    make_main_thread();
    put_str("thread_init done \n");
}


void thread_block(enum task_status stat){
    enum intr_status old_status = intr_disable();
    struct task_struct* cur_thread = running_thread();
    cur_thread->status = stat;
    schedule();
    intr_set_status(old_status);
} 

void thread_unblock(struct task_struct* pthread){
    enum intr_status old_status = intr_disable();
    if(pthread->status!= TASK_READY){
        if(elem_find(&thread_ready_list, &pthread->general_tag)){
            put_str("blocked thread in ready_list\n");
            return;
        }
        list_push(&thread_ready_list, &pthread->general_tag);
        pthread->status = TASK_READY;
    }
    intr_set_status(old_status);
}



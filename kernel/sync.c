
#include "sync.h"
#include "list.h"
#include "global.h"
#include "interrupt.h"
#include "thread.h"

void sema_init(struct semaphore* psema, uint8_t value){
    psema->value = value;
    list_init(&psema->waiters);
}

void lock_init(struct lock* plock){
    plock->holder = NULL;
    plock->holder_repeat_nr =0;
    sema_init(&plock->semaphore, 1);
}


void sema_down(struct semaphore* psema){
    enum intr_status old_status = intr_disable();
    while(psema->value == 0){
        list_append(&psema->waiters, &running_thread()->general_tag);
        thread_block(TASK_BLOCKED);
        }
    psema->value--;
    intr_set_status(old_status);
}


void sema_up(struct semaphore* psema){
    enum intr_status old_status = intr_disable();
    if(!list_empty(&psema->waiters)){
        struct task_struct* thread_blocked = elem2entry(struct task_struct, general_tag, \
        list_pop(&psema->waiters));
        thread_unblock(thread_blocked);
    }

    psema->value++;
    intr_set_status(old_status);
}

void lock_acquire(struct lock* plock){
       if (plock->holder != running_thread()) { 
      sema_down(&plock->semaphore);    // 对信号量P操作,原子操作
      plock->holder = running_thread();
      plock->holder_repeat_nr = 1;
   } else {
      plock->holder_repeat_nr++;
   }
}


/* 释放锁plock */
void lock_release(struct lock* plock) {
   if (plock->holder_repeat_nr > 1) {
      plock->holder_repeat_nr--;
      return;
   }

   plock->holder = NULL;	   // 把锁的持有者置空放在V操作之前
   plock->holder_repeat_nr = 0;
   sema_up(&plock->semaphore);	   // 信号量的V操作,也是原子操作
}

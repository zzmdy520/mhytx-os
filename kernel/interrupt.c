#include "stdint.h"
#include "global.h"
#include "print.h"
#include "io.hpp"
#include "interrupt.h"


#define IDT_DESC_CNT 0X30 //目前支持的中断数
#define PIC_M_CTRL 0X20
#define PIC_M_DATA 0X21
#define PIC_S_CTRL 0Xa0
#define PIC_S_DATA 0xa1
#define EFLAGS_IF 0X00000200


struct gate_desc{
uint16_t func_offset_low_word;
uint16_t selector;
uint8_t fixed;   //不会变化
uint8_t attribute;
uint16_t func_offset_high_word;
};

static struct gate_desc idt[IDT_DESC_CNT];
static void make_idt_desc(struct gate_desc* p_gdesc,uint8_t attr,void* function);
extern void* intr_entry_table[IDT_DESC_CNT];
void* idt_table[IDT_DESC_CNT];
char* intr_name[IDT_DESC_CNT];

//通用函数中断处理函数
static void general_init_handler(uint8_t vec_num){
    if(vec_num == 0x27 || vec_num == 0x2f) {return;}
    set_cursor(0);
    int cursor_pos = 0;
    while(cursor_pos < 320) {
        put_char(' ');
        cursor_pos++;
   }
   set_cursor(0);	 // 重置光标为屏幕左上角
   put_str("!!!!!!!      excetion message begin  !!!!!!!!\n");
   set_cursor(88);	// 从第2行第8个字符开始打印
   put_str(intr_name[vec_num]);
   if (vec_num == 14) {	  // 若为Pagefault,将缺失的地址打印出来并悬停
      int page_fault_vaddr = 0; 
      asm ("movl %%cr2, %0" : "=r" (page_fault_vaddr));	  // cr2是存放造成page_fault的地址
      put_str("\npage fault addr is ");put_int(page_fault_vaddr); 
   }
   put_str("\n!!!!!!!      excetion message end    !!!!!!!!\n");
  // 能进入中断处理程序就表示已经处在关中断情况下,
  // 不会出现调度进程的情况。故下面的死循环不会再被中断。
   while(1);
    }

//完成一般中断处理函数注册及异常名称注册
static void exception_init(void){
    int i ;
    for(i = 0;i < IDT_DESC_CNT;i++){
         idt_table[i] = general_init_handler;//先全部指向默认函数，因为其他的还没实现
         intr_name[i] = "unknow";
    }
    //0～19是处理器内部固定异常，20～31系统保留
    intr_name[0] = "#DE Divide Error";
    intr_name[1] = "#DB Debug Exception";
    intr_name[2] = "NMI Interrupt";
    intr_name[3] = "#BP Breakpoint Exception";
    intr_name[4] = "#OF Overflow Exception";
    intr_name[5] = "#BR BOUND Range Exceeded Exception";
    intr_name[6] = "#UD Invalid Opcode Exception";
    intr_name[7] = "#NM Device Not Available Exception";
    intr_name[8] = "#DF Double Fault Exception";
    intr_name[9] = "Coprocessor Segment Overrun";
    intr_name[10] = "#TS Invalid TSS Exception";
    intr_name[11] = "#NP Segment Not Present";
    intr_name[12] = "#SS Stack Fault Exception";
    intr_name[13] = "#GP General Protection Exception";
    intr_name[14] = "#PF Page-Fault Exception";
    intr_name[16] = "#MF 0x87 FPU Floating-Point Error";
    intr_name[17] = "#AC Alignment Check Exception";
    intr_name[18] = "#MC Machine-Check Exception";
    intr_name[19] = "#XF SIMD Floating-Point Exception";
    put_str(" exception_init done \n");
    
}
//写入中断调用门
static void make_idt_desc(struct gate_desc* p_gdesc,uint8_t attr,void* function){
    p_gdesc->func_offset_low_word = (uint32_t)function & 0x0000ffff;
    p_gdesc->selector = SELECTOR_K_CODE;
    p_gdesc->fixed = 0;
    p_gdesc->attribute = attr;
    p_gdesc->func_offset_high_word = ((uint32_t)function & 0xffff0000) >> 16;
}

//初始化中断门描述符表
static void idt_desc_init(void){
    int i;
    for(i  = 0; i < IDT_DESC_CNT;i++){
        
        make_idt_desc(&idt[i], IDT_DESC_ATTR_DPL0,intr_entry_table[i]);
    }
    put_str(" idt_desc_init done \n");
}

//初始化主从片
static void pic_init(void) {
    //初始化主片
    outb(PIC_M_CTRL,0X11);
    outb(PIC_M_DATA,0X20);
    outb(PIC_M_DATA,0X04);
    outb(PIC_M_DATA,0X01);
    //初始化从片
    outb(PIC_S_CTRL,0X11);
    outb(PIC_S_DATA,0X28);
    outb(PIC_S_DATA,0X02);
    outb(PIC_S_DATA,0X01);
    //只打开中钟同步中断
    //outb(PIC_M_DATA,0Xfe);
    //outb(PIC_S_DATA,0Xff);
    //只打开键盘中断
    outb(PIC_M_DATA,0xfd);
    outb(PIC_S_DATA,0xff);

    put_str("pic_init done!\n");


}

void idt_init(void){
    put_str("idt_init start \n");
    idt_desc_init();//中断门描述符表初始化
    exception_init();
    pic_init();

   //加载idt
    
uint64_t idt_operand =(sizeof(idt)-1) |( (uint64_t)(uint32_t)idt <<16);
    asm volatile("lidt %0" : :"m" (idt_operand));
    put_str("idt_init done");
}


/*
 输入：无
 函数功能：获得中断状态
 输出:返回中断状态
 */
enum intr_status intr_get_status(){
    uint32_t eflags;
    asm volatile("pushfl;popl %0":"=g" (eflags)) ;
    return (EFLAGS_IF & eflags)?INTR_ON:INTR_OFF;
}

/*
 输入：无
 函数功能：开中断并返回之前中断状态
 输出:返回之前中断状态
 */

enum intr_status intr_enable(){
    enum intr_status old_status;
    if(INTR_ON == intr_get_status()){
        old_status = INTR_ON;
        return old_status;
    }
    else{
        old_status  = INTR_OFF;
        asm volatile("sti");
        return old_status;
    }
}

enum intr_status intr_disable(){
    enum intr_status old_status;
    if(INTR_ON == intr_get_status()){
        asm volatile("cli");
        old_status = INTR_ON;
        return old_status;
    }
    else{
        old_status  = INTR_OFF;
        return old_status;
    }
}

//将中断设置为status
enum intr_status intr_set_status(enum intr_status status){
    return status & INTR_ON ? intr_enable():intr_disable();
}

void register_handler(uint8_t vec_num, void* function){
    
    idt_table[vec_num] = function;
}

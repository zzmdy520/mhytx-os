#include "memory.h"
#include "print.h"
#include "stdint.h"

#define PG_SIZE 4096 //4k

#define MEM_BITMAP_BASE 0xC009a000
#define  K_HEAP_START 0xc0100000 //跨过低端1m，使虚拟地址在逻辑上连续d dstatic void mem_pool_init(uint32_t all_mem);
struct pool{
    struct bitmap pool_bitmap;
    uint32_t phy_addr_start;
    uint32_t pool_size;
};

struct pool kernel_pool,usr_pool;

struct virtual_addr kernel_vaddr;//此结构用来给内核分配虚拟地址

static void mem_pool_init(uint32_t all_mem){
    put_str(" mem_pool_init_start\n");
    uint32_t page_table_size = PG_SIZE * 256 ;//共256个页框

    uint32_t used_mem = page_table_size + 0x100000;

    uint32_t free_mem = all_mem - used_mem;

    uint16_t all_free_pages = free_mem / PG_SIZE;
    uint16_t kernel_free_pages =all_free_pages / 2;
    uint16_t user_free_pages = all_free_pages - kernel_free_pages;

    uint32_t kbm_length = kernel_free_pages / 8;
    uint32_t ubm_length = user_free_pages / 8;

    uint32_t kp_start = used_mem; //kenel_map跳过低端1m使用了的部分
    uint32_t up_start = kp_start + kernel_free_pages * PG_SIZE;

    kernel_pool.phy_addr_start = kp_start;
    usr_pool.phy_addr_start = up_start;

    kernel_pool.pool_size = kernel_free_pages * PG_SIZE;
    usr_pool.pool_size = user_free_pages * PG_SIZE;

    kernel_pool.pool_bitmap.bitmap_bytes_len = kbm_length;
    usr_pool.pool_bitmap.bitmap_bytes_len = ubm_length;
 
    kernel_pool.pool_bitmap.bits = (void*) MEM_BITMAP_BASE; //0xc009a000
    usr_pool.pool_bitmap.bits = (void*) (MEM_BITMAP_BASE + kbm_length);
    
    put_str("Kernel pool bitmap address: ");
    put_int(kernel_pool.pool_bitmap.bits);
    put_str("; Kernel pool physical address: ");
    put_int(kernel_pool.phy_addr_start);
    put_char('\n');
    put_str("User pool bitmap address: ");
    put_int(usr_pool.pool_bitmap.bits);
    put_str("; User pool physical address: ");
    put_int(usr_pool.phy_addr_start);
    put_char('\n');

    bitmap_init(&kernel_pool.pool_bitmap);
    bitmap_init(&usr_pool.pool_bitmap);

    kernel_vaddr.vaddr_bitmap.bitmap_bytes_len = kbm_length;

    kernel_vaddr.vaddr_bitmap.bits = (void*) (MEM_BITMAP_BASE + kbm_length + ubm_length);

    kernel_vaddr.vaddr_start = K_HEAP_START;
    
    bitmap_init(&kernel_vaddr.vaddr_bitmap);
    put_str("mem_pool_init done \n");
}

void mem_init(){
    put_str("mem_init start \n");
    uint32_t mem_bytes_total = (*(uint32_t*) (0xb09));
    mem_pool_init(mem_bytes_total);
} 

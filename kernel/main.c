#include "print.h"
#include "init.h"
void main(void){
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
put_str("put_str done v5!\n");
put_char('\n');
put_int(0xabcd1234);
//asm volatile("cli");
init_all();
put_str("before!\n");
//asm volatile("sti");
put_str("after!\n");

while(1);
}

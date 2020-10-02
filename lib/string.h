#ifndef __LIB_STRING
#define __LIB_STRING

#include "stdint.h"
void memset(void *s , uint8_t value,uint32_t size );
void memcpy(void* dst, void* src,uint32_t size);
int memcmp(const void* a,const void*b,uint32_t size );
char* strcpy(char* dst,const char* src);
uint32_t strlen(const char* str);
int8_t strcmp(const char* a, const char* b);
char* strchr(const char* str, const char c);
char* strrchr(const char* str,const char c);
char* strcat(char* dst, const char* src);
uint32_t strchrs(const char* str, uint8_t ch);

#endif

#include "string.h"
#include "global.h"
#include "stdint.h"


void memset(void *s , uint8_t value,uint32_t size ){
    if(s != NULL){
        uint8_t* temp = (uint8_t*) s;
        while(size-- > 0){
            *temp++ = value;
        }
    }
}

void memcpy(void* dst, void* src,uint32_t size){
    if(dst!= NULL && src != NULL){
        uint8_t* temp_des = dst;
        const uint8_t* temp_src = src;
        while(size-- > 0){
            *temp_des++ = *temp_src++;
        }
    }
}
//相等返回0，a大于b返回+1
int memcmp(const void* a,const void*b,uint32_t size ){
    const uint8_t *temp_a = a;
    const uint8_t *temp_b = b;
    if(temp_a !=NULL || temp_b != NULL){
        while(size-- > 0){
            if(*temp_a != *temp_b){
                return *temp_a > *temp_b ? 1 : -1;
            }
            ++a;
            ++b;
        }
        return 0;
    }
}

char* strcpy(char* dst,const char* src){
    if(dst != NULL && src != NULL){
        char* tmp = dst;
        while ((*dst++ = *src++));
        return tmp;
    }
}

uint32_t strlen(const char* str){
    if(str!= NULL){
        const char* p = str;
        while(*p++);
        return (p-str-1);

    }
}

//a小于b返回-1，a大于b返回1
int8_t strcmp(const char* a, const char* b){
    while(*a != 0 && *b != 0){
        ++a;++b;
    }
    return *a < *b ? -1 : *a > *b;
}

char* strchr(const char* str, const char c){
    while(*str != 0){
        if(*str == c){
            return (char*)str;
        }
        str++;
    }
    return NULL;
}

char* strrchr(const char* str,const char c){
    const char* last_char = NULL;
    while(*str != 0){
        if(*str == c ){
            last_char = str;
        }
        str++;
    }
    return (char*) last_char;
}

char* strcat(char* dst, const char* src){
    char *str =dst;
    while(*str++);
    --str;
    while(*str++ = *src++);
    return dst;
}

uint32_t strchrs(const char* str, uint8_t ch){
    uint32_t ch_cnt = 0;
    const char *p = str;
    while(*p != 0){
        if(*p ==ch){
            ch_cnt++;            
        }
    p++;        
    }
    return ch_cnt;
}


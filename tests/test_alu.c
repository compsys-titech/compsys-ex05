#include "test_support.h"
#include <stdio.h>

void test_alu1(void)
{
    for (unsigned op = 0; op < 4; ++op)
        for (unsigned n = 0; n < 8; ++n) {
            char id[60]; snprintf(id,sizeof id,"B-ALU1-op%u-%u",op,n);
            case_alu1(id,op,(n & 4U) != 0,(n & 2U) != 0,(n & 1U) != 0);
        }
}

void test_alu32(void)
{
    const uint32_t pairs[][2] = {
        {5,3},{0,0},{0,1},{1,0},{UINT32_MAX,UINT32_MAX},{UINT32_MAX,1},
        {UINT32_C(0x7fffffff),1},{UINT32_C(0x80000000),1},
        {UINT32_C(0x80000000),UINT32_C(0x80000000)},
        {UINT32_C(0xaaaaaaaa),UINT32_C(0x55555555)},
        {UINT32_C(0x55555555),UINT32_C(0xaaaaaaaa)},{3,5},{5,5}
    };
    for (unsigned n = 0; n < sizeof pairs / sizeof pairs[0]; ++n)
        for (unsigned op = 0; op < 4; ++op) {
            char id[60]; snprintf(id,sizeof id,"B-ALU32-EDGE-%02u-op%u",n,op);
            case_alu32(id,op,pairs[n][0],pairs[n][1]);
        }
    for (unsigned i = 0; i < 32; ++i)
        for (unsigned op = 0; op < 4; ++op) {
            uint32_t bit = UINT32_C(1) << i;
            char id[60]; snprintf(id,sizeof id,"B-ALU32-BIT-%02u-op%u",i,op);
            case_alu32(id,op,bit,bit);
            snprintf(id,sizeof id,"B-ALU32-CHAIN-%02u-op%u",i,op);
            case_alu32(id,op,bit - UINT32_C(1),1);
        }
    uint32_t state = UINT32_C(0x202605b2);
    for (unsigned n = 0; n < 128; ++n) {
        uint32_t a = test_random(&state), b = test_random(&state);
        for (unsigned op = 0; op < 4; ++op) {
            char id[60]; snprintf(id,sizeof id,"B-ALU32-RANDOM-%03u-op%u",n,op);
            case_alu32(id,op,a,b);
        }
    }
}

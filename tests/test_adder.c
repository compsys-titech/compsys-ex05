#include "test_support.h"
#include <stdio.h>

void test_xor(void)
{
    for (unsigned n = 0; n < 4; ++n) {
        char id[40]; snprintf(id,sizeof id,"A-XOR-%u",n);
        case_xor(id,(n & 2U) != 0,(n & 1U) != 0);
    }
}

void test_fa(void)
{
    for (unsigned n = 0; n < 8; ++n) {
        char id[40]; snprintf(id,sizeof id,"A-FA-%u",n);
        case_fa(id,(n & 4U) != 0,(n & 2U) != 0,(n & 1U) != 0);
    }
}

void test_rca(void)
{
    const struct { uint32_t a,b; Signal cin; } slide[] = {
        {0,0,false},{0,0,true},{UINT32_MAX,1,false},
        {UINT32_C(0x7fffffff),1,false},
        {UINT32_C(0x80000000),UINT32_C(0x80000000),false},
        {UINT32_C(0xaaaaaaaa),UINT32_C(0x55555555),false}
    };
    for (unsigned i = 0; i < sizeof slide / sizeof slide[0]; ++i) {
        char id[60]; snprintf(id,sizeof id,"A-RCA-SLIDE-%u",i);
        case_rca(id,slide[i].a,slide[i].b,slide[i].cin);
        snprintf(id,sizeof id,"A-RCA-SWAP-%u",i);
        case_rca(id,slide[i].b,slide[i].a,slide[i].cin);
    }
    for (unsigned i = 0; i < 32; ++i) {
        uint32_t bit = UINT32_C(1) << i;
        for (unsigned c = 0; c < 2; ++c) {
            char id[60]; snprintf(id,sizeof id,"A-RCA-BIT-%02u-c%u",i,c);
            case_rca(id,bit,bit,c != 0);
            snprintf(id,sizeof id,"A-RCA-CHAIN-%02u-c%u",i,c);
            case_rca(id,bit - UINT32_C(1),UINT32_C(1),c != 0);
        }
    }
    uint32_t state = UINT32_C(0x202605a1);
    for (unsigned i = 0; i < 128; ++i) {
        uint32_t a = test_random(&state), b = test_random(&state);
        char id[60]; snprintf(id,sizeof id,"A-RCA-RANDOM-%03u",i);
        case_rca(id,a,b,(i & 1U) != 0);
    }
}

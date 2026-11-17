#include "test_support.h"
#include <inttypes.h>
#include <stdio.h>
#include <string.h>

static void gate_case(const char *name, unsigned n, unsigned p,
                      Signal expected, Signal actual)
{
    char id[80], detail[240], inputs[140];
    snprintf(id, sizeof id, "P-%s-%02u/s%u", name, n, p);
    if (!strcmp(name,"MUX4"))
        snprintf(inputs,sizeof inputs,"d0=%u d1=%u d2=%u d3=%u s1=%u s0=%u",
                 n&1U,(n>>1)&1U,(n>>2)&1U,(n>>3)&1U,(n>>5)&1U,(n>>4)&1U);
    else if (!strcmp(name,"MUX2"))
        snprintf(inputs,sizeof inputs,"d0=%u d1=%u select=%u",n&1U,(n>>1)&1U,(n>>2)&1U);
    else if (!strcmp(name,"NOT"))
        snprintf(inputs,sizeof inputs,"a=%u",n);
    else snprintf(inputs,sizeof inputs,"a=%u b=%u",(n>>1)&1U,n&1U);
    snprintf(detail, sizeof detail, "%s %s expected=%d actual=%d",name,inputs,expected,actual);
    test_assert(id, detail, expected == actual);
}

void test_parts(void)
{
    for (unsigned p = 0; p < 2; ++p) {
        for (unsigned n = 0; n < 4; ++n) {
            Signal a = (n & 2U) != 0, b = (n & 1U) != 0, s = p != 0;
            and_gate(a,b,&s); gate_case("AND",n,p,a && b,s);
            s = p != 0; or_gate(a,b,&s); gate_case("OR",n,p,a || b,s);
            s = p != 0; nand_example(a,b,&s); gate_case("NAND",n,p,!(a && b),s);
        }
        for (unsigned n = 0; n < 2; ++n) {
            Signal s = p != 0; not_gate(n != 0,&s); gate_case("NOT",n,p,n == 0,s);
        }
        for (unsigned n = 0; n < 8; ++n) {
            Signal d0 = (n & 1U) != 0, d1 = (n & 2U) != 0, sel = (n & 4U) != 0;
            Signal s = p != 0;
            mux2(d0,d1,sel,&s); gate_case("MUX2",n,p,sel ? d1 : d0,s);
        }
        for (unsigned n = 0; n < 64; ++n) {
            Signal d[4], s = p != 0;
            for (unsigned i = 0; i < 4; ++i) d[i] = ((n >> i) & 1U) != 0;
            unsigned select = n >> 4;
            mux4(d[0],d[1],d[2],d[3],(select & 2U) != 0,(select & 1U) != 0,&s);
            gate_case("MUX4",n,p,d[select],s);
        }
    }
    uint32_t values[38] = {0,UINT32_MAX,UINT32_C(0xaaaaaaaa),UINT32_C(0x55555555),
                          UINT32_C(1),UINT32_C(0x80000000)};
    for (unsigned i = 0; i < 32; ++i) values[i + 6] = UINT32_C(1) << i;
    for (unsigned n = 0; n < 38; ++n) {
        char id[80], detail[180];
        Word independent;
        for (unsigned i = 0; i < 32; ++i)
            independent.bit[i] = ((values[n] >> i) & UINT32_C(1)) != 0;
        uint32_t actual = word_get_value(independent);
        snprintf(id,sizeof id,"P-GET-%02u",n);
        snprintf(detail,sizeof detail,"expected=%08" PRIx32 " actual=%08" PRIx32,values[n],actual);
        test_assert(id,detail,actual == values[n]);
        for (unsigned p = 0; p < 2; ++p) {
            Word w;
            for (unsigned i = 0; i < 32; ++i) w.bit[i] = p != 0;
            word_set_value(&w,values[n]);
            bool ok = true;
            unsigned mismatch = 32;
            for (unsigned i = 0; i < 32; ++i)
                if (w.bit[i] != independent.bit[i]) { ok = false; mismatch = i; }
            snprintf(id,sizeof id,"P-SET-%02u/s%u",n,p);
            snprintf(detail,sizeof detail,"value=%08" PRIx32 " expected=all-32-bits actual=%s mismatch-bit=%u",
                     values[n],ok ? "equal" : "different",mismatch);
            test_assert(id,detail,ok);
            actual = word_get_value(w);
            snprintf(id,sizeof id,"P-ROUNDTRIP-%02u/s%u",n,p);
            snprintf(detail,sizeof detail,"expected=%08" PRIx32 " actual=%08" PRIx32,values[n],actual);
            test_assert(id,detail,actual == values[n]);
        }
    }
}

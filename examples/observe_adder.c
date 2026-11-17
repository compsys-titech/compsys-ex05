#include "test_support.h"
#include <stdio.h>

int main(void)
{
    test_begin("example-adder");
    puts("Example 2: actual student full_adder/rca; requires task A.");
    for (unsigned n = 0; n < 8; ++n) {
        char id[40]; snprintf(id,sizeof id,"OBS-FA-%u",n);
        case_fa(id,(n & 4U) != 0,(n & 2U) != 0,(n & 1U) != 0);
    }
    const uint32_t pairs[][2] = {
        {0,0},{0,0},{UINT32_MAX,1},{UINT32_C(0x7fffffff),1},
        {UINT32_C(0x80000000),UINT32_C(0x80000000)},
        {UINT32_C(0xaaaaaaaa),UINT32_C(0x55555555)}
    };
    for (unsigned n = 0; n < 6; ++n) {
        char id[40]; snprintf(id,sizeof id,"OBS-RCA-%u",n);
        case_rca(id,pairs[n][0],pairs[n][1],n == 1);
    }
    return test_end();
}

#include "test_support.h"
#include <stdio.h>

int main(void)
{
    test_begin("example-alu");
    puts("Example 3: actual student alu32; requires task B and its dependencies.");
    for (unsigned op = 0; op < 4; ++op) {
        char id[40]; snprintf(id,sizeof id,"OBS-ALU-5-3-op%u",op);
        case_alu32(id,op,5,3);
        snprintf(id,sizeof id,"OBS-ALU-0-1-op%u",op);
        case_alu32(id,op,0,1);
    }
    return test_end();
}

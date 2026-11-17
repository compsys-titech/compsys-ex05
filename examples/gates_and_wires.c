#include "test_support.h"
#include <stdio.h>

int main(void)
{
    puts("Example 1: supplied gates, NAND internal wire, MUX and Word.");
    test_begin("example-gates");
    test_parts();
    return test_end();
}

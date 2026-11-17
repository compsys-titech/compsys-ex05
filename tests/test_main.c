#include "test_support.h"
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv)
{
    if (argc != 2) return 2;
    test_begin(argv[1]);
    if (!strcmp(argv[1],"parts")) test_parts();
    else if (!strcmp(argv[1],"xor")) test_xor();
    else if (!strcmp(argv[1],"fa")) test_fa();
    else if (!strcmp(argv[1],"rca")) test_rca();
    else if (!strcmp(argv[1],"alu1")) test_alu1();
    else if (!strcmp(argv[1],"alu32")) test_alu32();
    else if (!strcmp(argv[1],"student-a")) student_a();
    else if (!strcmp(argv[1],"student-b")) student_b();
    else { fputs("Unknown test group\n",stderr); return 2; }
    return test_end();
}

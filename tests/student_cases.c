#include "test_support.h"
#include <stdio.h>

/* EDIT THIS FILE: add your own cases and explain each choice.
   These small examples alone do not complete the report. */
void student_a(void)
{
    puts("REASON S-A-001: distinguish carry_out from the highest sum bit");
    case_rca("S-A-001", UINT32_MAX, UINT32_C(1), false);
    puts("REASON S-A-002: isolate the effect of carry_in");
    case_rca("S-A-002", UINT32_C(0), UINT32_C(0), true);
}

void student_b(void)
{
    puts("REASON S-B-001: observe subtraction wrapping to a 32-bit pattern");
    /* control index: 0=AND, 1=OR, 2=ADD, 3=SUB; see test_ops. */
    case_alu32("S-B-001", 3, UINT32_C(0), UINT32_C(1));
}

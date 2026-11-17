#include "compsys.h"

void and_gate(Signal a, Signal b, Signal *out) { *out = a && b; }
void or_gate(Signal a, Signal b, Signal *out) { *out = a || b; }
void not_gate(Signal a, Signal *out) { *out = !a; }

/* Example: an internal wire connects AND to NOT (slide 19). */
void nand_example(Signal a, Signal b, Signal *out)
{
    Signal inner;
    and_gate(a, b, &inner);
    not_gate(inner, out);
}

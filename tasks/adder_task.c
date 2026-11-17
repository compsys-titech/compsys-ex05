#include "compsys.h"
#include <stdio.h>
#include <stdlib.h>

/* TODO-BEGIN A_HELPERS */
/* Optional gate-composition helper functions belong here. */
/* TODO-END A_HELPERS */

void xor_circuit(Signal a, Signal b, Signal *out)
{
    /* TODO-BEGIN XOR */
    (void)a; (void)b;
    *out = false;
    fputs("[UNFINISHED] xor_circuit\n", stderr);
    exit(3);
    /* TODO-END XOR */
}

void full_adder(Signal a, Signal b, Signal cin, Signal *sum, Signal *cout)
{
    /* TODO-BEGIN FA */
    (void)a; (void)b; (void)cin;
    *sum = false; *cout = false;
    fputs("[UNFINISHED] full_adder\n", stderr);
    exit(3);
    /* TODO-END FA */
}

void rca(Word a, Word b, Signal carry_in, Word *sum, Signal *carry_out)
{
    /* TODO-BEGIN RCA */
    (void)a; (void)b; (void)carry_in;
    for (unsigned i = 0; i < 32; ++i) sum->bit[i] = false;
    *carry_out = false;
    fputs("[UNFINISHED] rca\n", stderr);
    exit(3);
    /* TODO-END RCA */
}

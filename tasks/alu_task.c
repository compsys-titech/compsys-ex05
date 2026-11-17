#include "compsys.h"
#include <stdio.h>
#include <stdlib.h>

/* TODO-BEGIN B_HELPERS */
/* Optional gate-composition helper functions belong here. */
/* TODO-END B_HELPERS */

void alu1(const Signal op[3], Signal a, Signal b, Signal cin,
          Signal *s, Signal *cout)
{
    /* TODO-BEGIN ALU1 */
    (void)op; (void)a; (void)b; (void)cin;
    *s = false; *cout = false;
    fputs("[UNFINISHED] alu1\n", stderr);
    exit(3);
    /* TODO-END ALU1 */
}

void alu32(const Signal op[3], Word a, Word b, Word *s)
{
    /* TODO-BEGIN ALU32 */
    (void)op; (void)a; (void)b;
    for (unsigned i = 0; i < 32; ++i) s->bit[i] = false;
    fputs("[UNFINISHED] alu32\n", stderr);
    exit(3);
    /* TODO-END ALU32 */
}

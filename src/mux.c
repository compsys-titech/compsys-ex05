#include "compsys.h"

void mux2(Signal d0, Signal d1, Signal select, Signal *out)
{
    Signal inverted, left, right;
    not_gate(select, &inverted);
    and_gate(d0, inverted, &left);
    and_gate(d1, select, &right);
    or_gate(left, right, out);
}

void mux4(Signal d0, Signal d1, Signal d2, Signal d3,
          Signal s1, Signal s0, Signal *out)
{
    Signal low, high;
    mux2(d0, d1, s0, &low);
    mux2(d2, d3, s0, &high);
    mux2(low, high, s1, out);
}

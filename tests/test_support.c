#include "test_support.h"
#include <inttypes.h>
#include <stdio.h>

/* Numeric oracles are used only by test/observation callers. */
const Signal test_ops[4][3] = {
    {false, false, false}, {true, false, false},
    {false, true, false}, {false, true, true}
};
const char *const test_op_names[4] = {"AND/000", "OR/001", "ADD/010", "SUB/110"};
static const char *group;
static unsigned cases, failures;

void test_begin(const char *name)
{
    group = name;
    cases = failures = 0;
    setvbuf(stdout, NULL, _IOLBF, 0);
}

void test_assert(const char *id, const char *detail, bool ok)
{
    ++cases;
    if (!ok) ++failures;
    printf("[%s] %s %s\n", ok ? "PASS" : "FAIL", id, detail);
}

int test_end(void)
{
    if (cases == 0) ++failures;
    printf("RESULT %s %s cases=%u failures=%u\n",
           group, failures ? "FAIL" : "PASS", cases, failures);
    return failures ? 5 : 0;
}

uint32_t test_random(uint32_t *state)
{
    /* LCG modulo 2^32; fixed constants, no library rand(). */
    *state = (uint32_t)((uint64_t)*state * UINT64_C(1664525) + UINT64_C(1013904223));
    return *state;
}

static bool word_equals(Word w, uint32_t expected)
{
    bool ok = true;
    for (unsigned i = 0; i < 32; ++i)
        if (w.bit[i] != (((expected >> i) & UINT32_C(1)) != 0)) ok = false;
    return ok;
}

static Word sentinel(bool value)
{
    Word w;
    for (unsigned i = 0; i < 32; ++i) w.bit[i] = value;
    return w;
}

/* This display conversion is independent of word_get_value(). */
static uint32_t observed(Word w)
{
    uint32_t v = 0;
    for (unsigned i = 0; i < 32; ++i)
        if (w.bit[i]) v |= UINT32_C(1) << i;
    return v;
}

void case_xor(const char *id, Signal a, Signal b)
{
    char key[100], detail[200];
    Signal expected = a != b;
    for (unsigned p = 0; p < 2; ++p) {
        Signal out = p != 0, scratch = false;
        /* A different input is interleaved before the repeat. */
        if (p) xor_circuit(!a, b, &scratch);
        xor_circuit(a, b, &out);
        snprintf(key, sizeof key, "%s/s%u", id, p);
        snprintf(detail, sizeof detail, "XOR a=%d b=%d expected=%d actual=%d",
                 a, b, expected, out);
        test_assert(key, detail, out == expected);
    }
}

void case_fa(const char *id, Signal a, Signal b, Signal cin)
{
    char key[100], detail[200];
    unsigned expected = (unsigned)a + (unsigned)b + (unsigned)cin;
    for (unsigned p = 0; p < 2; ++p) {
        Signal s = p != 0, c = p == 0, unused_s = false, unused_c = false;
        if (p) full_adder(!a, !b, !cin, &unused_s, &unused_c);
        full_adder(a, b, cin, &s, &c);
        snprintf(key, sizeof key, "%s/s%u", id, p);
        snprintf(detail, sizeof detail,
                 "FA a=%d b=%d cin=%d expected=%u,%u actual=%d,%d (sum,cout)",
                 a, b, cin, expected & 1U, expected >> 1, s, c);
        test_assert(key, detail, s == ((expected & 1U) != 0) && c == (expected >= 2));
    }
}

void case_rca(const char *id, uint32_t a, uint32_t b, Signal cin)
{
    Word wa, wb;
    word_set_value(&wa, a); word_set_value(&wb, b);
    uint64_t wide = (uint64_t)a + (uint64_t)b + (uint64_t)cin;
    uint32_t expected = (uint32_t)wide;
    Signal carry = ((wide >> 32) & UINT64_C(1)) != 0;
    char key[100], detail[240];
    for (unsigned p = 0; p < 2; ++p) {
        Word s = sentinel(p != 0), other = sentinel(false), changed;
        Signal c = p == 0, unused_c = false;
        word_set_value(&changed, ~b);
        if (p) rca(wa, changed, !cin, &other, &unused_c);
        rca(wa, wb, cin, &s, &c);
        snprintf(key, sizeof key, "%s/s%u", id, p);
        snprintf(detail, sizeof detail,
                 "RCA a=%08" PRIx32 " b=%08" PRIx32 " cin=%d expected=%08" PRIx32
                 ",%d actual=%08" PRIx32 ",%d (sum,cout)", a,b,cin,expected,carry,observed(s),c);
        test_assert(key, detail, word_equals(s, expected) && c == carry);
    }
}

void case_alu1(const char *id, unsigned control, Signal a, Signal b, Signal cin)
{
    Signal effective = test_ops[control][2] ? !b : b;
    unsigned wide = (unsigned)a + (unsigned)effective + (unsigned)cin;
    Signal expected = control == 0 ? (a && effective) :
                      control == 1 ? (a || effective) : ((wide & 1U) != 0);
    Signal carry = wide >= 2;
    char key[100], detail[240];
    for (unsigned p = 0; p < 2; ++p) {
        Signal s = p != 0, c = p == 0, scratch_s = false, scratch_c = false;
        if (p) alu1(test_ops[(control + 1) % 4], !a, !b, !cin, &scratch_s, &scratch_c);
        alu1(test_ops[control], a, b, cin, &s, &c);
        snprintf(key, sizeof key, "%s/s%u", id, p);
        snprintf(detail, sizeof detail,
                 "ALU1 op=%s a=%d b=%d cin=%d expected=%d,%d actual=%d,%d (s,FA-cout)",
                 test_op_names[control],a,b,cin,expected,carry,s,c);
        test_assert(key, detail, s == expected && c == carry);
    }
}

void case_alu32(const char *id, unsigned control, uint32_t a, uint32_t b)
{
    uint32_t expected = control == 0 ? (a & b) : control == 1 ? (a | b) :
                        control == 2 ? (uint32_t)((uint64_t)a + b) :
                        (uint32_t)((uint64_t)a + UINT64_C(0x100000000) - b);
    Word wa, wb;
    word_set_value(&wa, a); word_set_value(&wb, b);
    char key[100], detail[240];
    for (unsigned p = 0; p < 2; ++p) {
        Word s = sentinel(p != 0), scratch = sentinel(false);
        if (p) alu32(test_ops[(control + 1) % 4], wb, wa, &scratch);
        alu32(test_ops[control], wa, wb, &s);
        snprintf(key, sizeof key, "%s/s%u", id, p);
        snprintf(detail, sizeof detail,
                 "ALU32 op=%s a=%08" PRIx32 " b=%08" PRIx32
                 " expected=%08" PRIx32 " actual=%08" PRIx32,
                 test_op_names[control], a,b,expected,observed(s));
        test_assert(key, detail, word_equals(s, expected));
    }
}

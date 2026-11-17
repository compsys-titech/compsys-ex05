#ifndef TEST_SUPPORT_H
#define TEST_SUPPORT_H
#include "compsys.h"
#include <stddef.h>

extern const Signal test_ops[4][3];
extern const char *const test_op_names[4];
void test_begin(const char *name);
int test_end(void);
void test_assert(const char *id, const char *detail, bool ok);
void case_xor(const char *id, Signal a, Signal b);
void case_fa(const char *id, Signal a, Signal b, Signal cin);
void case_rca(const char *id, uint32_t a, uint32_t b, Signal cin);
void case_alu1(const char *id, unsigned control, Signal a, Signal b, Signal cin);
void case_alu32(const char *id, unsigned control, uint32_t a, uint32_t b);
uint32_t test_random(uint32_t *state);
void test_parts(void);
void test_xor(void);
void test_fa(void);
void test_rca(void);
void test_alu1(void);
void test_alu32(void);
void student_a(void);
void student_b(void);
#endif

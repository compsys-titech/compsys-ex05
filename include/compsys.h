#ifndef COMPSYS_H
#define COMPSYS_H
#include <stdbool.h>
#include <stdint.h>

typedef bool Signal;
typedef struct { Signal bit[32]; } Word;

void word_set_value(Word *w, uint32_t value);
uint32_t word_get_value(Word w);
void and_gate(Signal a, Signal b, Signal *out);
void or_gate(Signal a, Signal b, Signal *out);
void not_gate(Signal a, Signal *out);
void nand_example(Signal a, Signal b, Signal *out);
void mux2(Signal d0, Signal d1, Signal select, Signal *out);
/* Control order follows the diagram: s1 is high, s0 is low. */
void mux4(Signal d0, Signal d1, Signal d2, Signal d3,
          Signal s1, Signal s0, Signal *out);

void xor_circuit(Signal a, Signal b, Signal *out);
void full_adder(Signal a, Signal b, Signal cin, Signal *sum, Signal *cout);
void rca(Word a, Word b, Signal carry_in, Word *sum, Signal *carry_out);
void alu1(const Signal op[3], Signal a, Signal b, Signal cin,
          Signal *s, Signal *cout);
void alu32(const Signal op[3], Word a, Word b, Word *s);
#endif

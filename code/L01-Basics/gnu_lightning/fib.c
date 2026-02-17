/*
 * fib.c — lazy-compiled Fibonacci example using GNU Lightning.
 * Builds a Fibonacci function at runtime and executes it.
 *
 * License: MIT — free to use, modify, and distribute. No warranty.
 */

#include <stdio.h>
#include <lightning.h>

static jit_state_t *_jit;

typedef int (*fib_fn_t)(int);

fib_fn_t build_fib(void) {
  jit_node_t *n_arg;
  /* Registers:
     R0 = n
     R1 = prev
     R2 = cur
     V0 = k
     V1 = next (temp)
  */

  /* int fib(int n) */
  jit_prolog();
  n_arg = jit_arg();
  jit_getarg(JIT_R0, n_arg);

  /* if (n == 0) return 0; */
  jit_node_t *br_n0 = jit_beqi(JIT_R0, 0);
  /* if (n == 1) return 1; */
  jit_node_t *br_n1 = jit_beqi(JIT_R0, 1);

  /* prev=0; cur=1; k=n-1; */
  jit_movi(JIT_R1, 0);
  jit_movi(JIT_R2, 1);
  jit_subi(JIT_V0, JIT_R0, 1);

  /* loop: while (k != 0) { next=prev+cur; prev=cur; cur=next; --k; } */
  jit_node_t *L = jit_label();
  jit_addr(JIT_V1, JIT_R1, JIT_R2);          /* next */
  jit_movr(JIT_R1, JIT_R2);                  /* prev = cur */
  jit_movr(JIT_R2, JIT_V1);                  /* cur  = next */
  jit_subi(JIT_V0, JIT_V0, 1);               /* --k */
  jit_node_t *back = jit_bnei(JIT_V0, 0);
  jit_patch_at(back, L);

  /* return cur */
  jit_retr(JIT_R2);

  /* Handle returns for specific cases */
  /* n==0 */
  jit_node_t *L0 = jit_label();
  jit_movi(JIT_R0, 0);
  jit_retr(JIT_R0);

  /* n==1 */
  jit_node_t *L1 = jit_label();
  jit_movi(JIT_R0, 1);
  jit_retr(JIT_R0);

  jit_patch_at(br_n0, L0);
  jit_patch_at(br_n1, L1);

  fib_fn_t fib = (fib_fn_t)jit_emit();
  jit_clear_state();
  return fib;
}

int main(int argc, char **argv) {
  init_jit(argv[0]);
  _jit = jit_new_state();

  fib_fn_t fib = build_fib();
#ifdef SHOW_ASM
  printf("Disassembly of function int fib(int):\n");
  jit_disassemble();
#endif
  printf("fib(12) = %d\n", fib(12));

  jit_destroy_state();
  finish_jit();
  return 0;
}

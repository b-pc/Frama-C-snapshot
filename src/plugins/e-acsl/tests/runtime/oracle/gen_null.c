/* Generated by Frama-C */
#include "stdio.h"
#include "stdlib.h"
int main(void)
{
  int __retres;
  __e_acsl_memory_init((int *)0,(char ***)0,(size_t)8);
  /*@ assert \null ≡ (void *)0; */
  __e_acsl_assert((void *)0 == (void *)0,(char *)"Assertion",(char *)"main",
                  (char *)"\\null == (void *)0",6);
  __retres = 0;
  return __retres;
}


/* Generated by Frama-C */
#include "stdio.h"
#include "stdlib.h"
extern int __e_acsl_sound_verdict;

int *X;
int Z;
/*@ requires \valid(x);
    ensures \valid(\result); */
int *__gen_e_acsl_f(int *x);

int *f(int *x)
{
  int *y;
  __e_acsl_store_block((void *)(& y),(size_t)8);
  /*@ assert ¬\valid(y); */
  {
    int __gen_e_acsl_initialized;
    int __gen_e_acsl_and;
    __e_acsl_store_block((void *)(& x),(size_t)8);
    __gen_e_acsl_initialized = __e_acsl_initialized((void *)(& y),
                                                    sizeof(int *));
    if (__gen_e_acsl_initialized) {
      int __gen_e_acsl_valid;
      __gen_e_acsl_valid = __e_acsl_valid((void *)y,sizeof(int),(void *)y,
                                          (void *)(& y));
      __gen_e_acsl_and = __gen_e_acsl_valid;
    }
    else __gen_e_acsl_and = 0;
    __e_acsl_assert(! __gen_e_acsl_and,(char *)"Assertion",(char *)"f",
                    (char *)"!\\valid(y)",17);
  }
  __e_acsl_full_init((void *)(& y));
  y = x;
  /*@ assert \valid(x); */
  {
    int __gen_e_acsl_valid_2;
    __gen_e_acsl_valid_2 = __e_acsl_valid((void *)x,sizeof(int),(void *)x,
                                          (void *)(& x));
    __e_acsl_assert(__gen_e_acsl_valid_2,(char *)"Assertion",(char *)"f",
                    (char *)"\\valid(x)",19);
  }
  __e_acsl_delete_block((void *)(& x));
  __e_acsl_delete_block((void *)(& y));
  return y;
}

void g(void)
{
  int m;
  int *u;
  int **p;
  __e_acsl_store_block((void *)(& p),(size_t)8);
  __e_acsl_store_block((void *)(& u),(size_t)8);
  __e_acsl_store_block((void *)(& m),(size_t)4);
  __e_acsl_full_init((void *)(& p));
  p = & u;
  __e_acsl_full_init((void *)(& u));
  u = & m;
  __e_acsl_full_init((void *)(& m));
  m = 123;
  /*@ assert \valid(*p); */
  {
    int __gen_e_acsl_initialized;
    int __gen_e_acsl_and_2;
    __gen_e_acsl_initialized = __e_acsl_initialized((void *)p,sizeof(int *));
    if (__gen_e_acsl_initialized) {
      int __gen_e_acsl_initialized_2;
      int __gen_e_acsl_and;
      int __gen_e_acsl_valid;
      __gen_e_acsl_initialized_2 = __e_acsl_initialized((void *)(& p),
                                                        sizeof(int **));
      if (__gen_e_acsl_initialized_2) {
        int __gen_e_acsl_valid_read;
        __gen_e_acsl_valid_read = __e_acsl_valid_read((void *)p,
                                                      sizeof(int *),
                                                      (void *)p,
                                                      (void *)(& p));
        __gen_e_acsl_and = __gen_e_acsl_valid_read;
      }
      else __gen_e_acsl_and = 0;
      __e_acsl_assert(__gen_e_acsl_and,(char *)"RTE",(char *)"g",
                      (char *)"mem_access: \\valid_read(p)",28);
      __gen_e_acsl_valid = __e_acsl_valid((void *)*p,sizeof(int),(void *)*p,
                                          (void *)p);
      __gen_e_acsl_and_2 = __gen_e_acsl_valid;
    }
    else __gen_e_acsl_and_2 = 0;
    __e_acsl_assert(__gen_e_acsl_and_2,(char *)"Assertion",(char *)"g",
                    (char *)"\\valid(*p)",28);
  }
  __e_acsl_delete_block((void *)(& p));
  __e_acsl_delete_block((void *)(& u));
  __e_acsl_delete_block((void *)(& m));
  return;
}

/*@ requires \valid(x);
    ensures \valid(\result); */
int *__gen_e_acsl_f(int *x)
{
  int *__retres;
  __e_acsl_store_block((void *)(& __retres),(size_t)8);
  {
    int __gen_e_acsl_valid;
    __e_acsl_store_block((void *)(& x),(size_t)8);
    __gen_e_acsl_valid = __e_acsl_valid((void *)x,sizeof(int),(void *)x,
                                        (void *)(& x));
    __e_acsl_assert(__gen_e_acsl_valid,(char *)"Precondition",(char *)"f",
                    (char *)"\\valid(x)",13);
  }
  __retres = f(x);
  {
    int __gen_e_acsl_valid_2;
    __gen_e_acsl_valid_2 = __e_acsl_valid((void *)__retres,sizeof(int),
                                          (void *)__retres,
                                          (void *)(& __retres));
    __e_acsl_assert(__gen_e_acsl_valid_2,(char *)"Postcondition",(char *)"f",
                    (char *)"\\valid(\\result)",14);
    __e_acsl_delete_block((void *)(& x));
    __e_acsl_delete_block((void *)(& __retres));
    return __retres;
  }
}

void __e_acsl_globals_init(void)
{
  static char __e_acsl_already_run = 0;
  if (! __e_acsl_already_run) {
    __e_acsl_already_run = 1;
    __e_acsl_store_block((void *)(& Z),(size_t)4);
    __e_acsl_full_init((void *)(& Z));
    __e_acsl_store_block((void *)(& X),(size_t)8);
    __e_acsl_full_init((void *)(& X));
  }
  return;
}

int main(void)
{
  int __retres;
  int *a;
  int *b;
  int **c;
  int ***d;
  __e_acsl_memory_init((int *)0,(char ***)0,(size_t)8);
  __e_acsl_globals_init();
  __e_acsl_store_block((void *)(& d),(size_t)8);
  __e_acsl_store_block((void *)(& c),(size_t)8);
  __e_acsl_store_block((void *)(& b),(size_t)8);
  __e_acsl_store_block((void *)(& a),(size_t)8);
  int n = 0;
  __e_acsl_store_block((void *)(& n),(size_t)4);
  __e_acsl_full_init((void *)(& n));
  /*@ assert ¬\valid(a) ∧ ¬\valid(b) ∧ ¬\valid(X); */
  {
    int __gen_e_acsl_initialized;
    int __gen_e_acsl_and;
    int __gen_e_acsl_and_3;
    int __gen_e_acsl_and_4;
    __gen_e_acsl_initialized = __e_acsl_initialized((void *)(& a),
                                                    sizeof(int *));
    if (__gen_e_acsl_initialized) {
      int __gen_e_acsl_valid;
      __gen_e_acsl_valid = __e_acsl_valid((void *)a,sizeof(int),(void *)a,
                                          (void *)(& a));
      __gen_e_acsl_and = __gen_e_acsl_valid;
    }
    else __gen_e_acsl_and = 0;
    if (! __gen_e_acsl_and) {
      int __gen_e_acsl_initialized_2;
      int __gen_e_acsl_and_2;
      __gen_e_acsl_initialized_2 = __e_acsl_initialized((void *)(& b),
                                                        sizeof(int *));
      if (__gen_e_acsl_initialized_2) {
        int __gen_e_acsl_valid_2;
        __gen_e_acsl_valid_2 = __e_acsl_valid((void *)b,sizeof(int),
                                              (void *)b,(void *)(& b));
        __gen_e_acsl_and_2 = __gen_e_acsl_valid_2;
      }
      else __gen_e_acsl_and_2 = 0;
      __gen_e_acsl_and_3 = ! __gen_e_acsl_and_2;
    }
    else __gen_e_acsl_and_3 = 0;
    if (__gen_e_acsl_and_3) {
      int __gen_e_acsl_valid_3;
      __gen_e_acsl_valid_3 = __e_acsl_valid((void *)X,sizeof(int),(void *)X,
                                            (void *)(& X));
      __gen_e_acsl_and_4 = ! __gen_e_acsl_valid_3;
    }
    else __gen_e_acsl_and_4 = 0;
    __e_acsl_assert(__gen_e_acsl_and_4,(char *)"Assertion",(char *)"main",
                    (char *)"!\\valid(a) && !\\valid(b) && !\\valid(X)",33);
  }
  __e_acsl_full_init((void *)(& a));
  a = (int *)malloc(sizeof(int));
  /*@ assert \valid(a) ∧ ¬\valid(b) ∧ ¬\valid(X); */
  {
    int __gen_e_acsl_initialized_3;
    int __gen_e_acsl_and_5;
    int __gen_e_acsl_and_7;
    int __gen_e_acsl_and_8;
    __gen_e_acsl_initialized_3 = __e_acsl_initialized((void *)(& a),
                                                      sizeof(int *));
    if (__gen_e_acsl_initialized_3) {
      int __gen_e_acsl_valid_4;
      __gen_e_acsl_valid_4 = __e_acsl_valid((void *)a,sizeof(int),(void *)a,
                                            (void *)(& a));
      __gen_e_acsl_and_5 = __gen_e_acsl_valid_4;
    }
    else __gen_e_acsl_and_5 = 0;
    if (__gen_e_acsl_and_5) {
      int __gen_e_acsl_initialized_4;
      int __gen_e_acsl_and_6;
      __gen_e_acsl_initialized_4 = __e_acsl_initialized((void *)(& b),
                                                        sizeof(int *));
      if (__gen_e_acsl_initialized_4) {
        int __gen_e_acsl_valid_5;
        __gen_e_acsl_valid_5 = __e_acsl_valid((void *)b,sizeof(int),
                                              (void *)b,(void *)(& b));
        __gen_e_acsl_and_6 = __gen_e_acsl_valid_5;
      }
      else __gen_e_acsl_and_6 = 0;
      __gen_e_acsl_and_7 = ! __gen_e_acsl_and_6;
    }
    else __gen_e_acsl_and_7 = 0;
    if (__gen_e_acsl_and_7) {
      int __gen_e_acsl_valid_6;
      __gen_e_acsl_valid_6 = __e_acsl_valid((void *)X,sizeof(int),(void *)X,
                                            (void *)(& X));
      __gen_e_acsl_and_8 = ! __gen_e_acsl_valid_6;
    }
    else __gen_e_acsl_and_8 = 0;
    __e_acsl_assert(__gen_e_acsl_and_8,(char *)"Assertion",(char *)"main",
                    (char *)"\\valid(a) && !\\valid(b) && !\\valid(X)",35);
  }
  X = a;
  /*@ assert \valid(a) ∧ ¬\valid(b) ∧ \valid(X); */
  {
    int __gen_e_acsl_initialized_5;
    int __gen_e_acsl_and_9;
    int __gen_e_acsl_and_11;
    int __gen_e_acsl_and_12;
    __gen_e_acsl_initialized_5 = __e_acsl_initialized((void *)(& a),
                                                      sizeof(int *));
    if (__gen_e_acsl_initialized_5) {
      int __gen_e_acsl_valid_7;
      __gen_e_acsl_valid_7 = __e_acsl_valid((void *)a,sizeof(int),(void *)a,
                                            (void *)(& a));
      __gen_e_acsl_and_9 = __gen_e_acsl_valid_7;
    }
    else __gen_e_acsl_and_9 = 0;
    if (__gen_e_acsl_and_9) {
      int __gen_e_acsl_initialized_6;
      int __gen_e_acsl_and_10;
      __gen_e_acsl_initialized_6 = __e_acsl_initialized((void *)(& b),
                                                        sizeof(int *));
      if (__gen_e_acsl_initialized_6) {
        int __gen_e_acsl_valid_8;
        __gen_e_acsl_valid_8 = __e_acsl_valid((void *)b,sizeof(int),
                                              (void *)b,(void *)(& b));
        __gen_e_acsl_and_10 = __gen_e_acsl_valid_8;
      }
      else __gen_e_acsl_and_10 = 0;
      __gen_e_acsl_and_11 = ! __gen_e_acsl_and_10;
    }
    else __gen_e_acsl_and_11 = 0;
    if (__gen_e_acsl_and_11) {
      int __gen_e_acsl_valid_9;
      __gen_e_acsl_valid_9 = __e_acsl_valid((void *)X,sizeof(int),(void *)X,
                                            (void *)(& X));
      __gen_e_acsl_and_12 = __gen_e_acsl_valid_9;
    }
    else __gen_e_acsl_and_12 = 0;
    __e_acsl_assert(__gen_e_acsl_and_12,(char *)"Assertion",(char *)"main",
                    (char *)"\\valid(a) && !\\valid(b) && \\valid(X)",37);
  }
  __e_acsl_full_init((void *)(& b));
  b = __gen_e_acsl_f(& n);
  /*@ assert \valid(a) ∧ \valid(b) ∧ \valid(X); */
  {
    int __gen_e_acsl_initialized_7;
    int __gen_e_acsl_and_13;
    int __gen_e_acsl_and_15;
    int __gen_e_acsl_and_16;
    __gen_e_acsl_initialized_7 = __e_acsl_initialized((void *)(& a),
                                                      sizeof(int *));
    if (__gen_e_acsl_initialized_7) {
      int __gen_e_acsl_valid_10;
      __gen_e_acsl_valid_10 = __e_acsl_valid((void *)a,sizeof(int),(void *)a,
                                             (void *)(& a));
      __gen_e_acsl_and_13 = __gen_e_acsl_valid_10;
    }
    else __gen_e_acsl_and_13 = 0;
    if (__gen_e_acsl_and_13) {
      int __gen_e_acsl_initialized_8;
      int __gen_e_acsl_and_14;
      __gen_e_acsl_initialized_8 = __e_acsl_initialized((void *)(& b),
                                                        sizeof(int *));
      if (__gen_e_acsl_initialized_8) {
        int __gen_e_acsl_valid_11;
        __gen_e_acsl_valid_11 = __e_acsl_valid((void *)b,sizeof(int),
                                               (void *)b,(void *)(& b));
        __gen_e_acsl_and_14 = __gen_e_acsl_valid_11;
      }
      else __gen_e_acsl_and_14 = 0;
      __gen_e_acsl_and_15 = __gen_e_acsl_and_14;
    }
    else __gen_e_acsl_and_15 = 0;
    if (__gen_e_acsl_and_15) {
      int __gen_e_acsl_valid_12;
      __gen_e_acsl_valid_12 = __e_acsl_valid((void *)X,sizeof(int),(void *)X,
                                             (void *)(& X));
      __gen_e_acsl_and_16 = __gen_e_acsl_valid_12;
    }
    else __gen_e_acsl_and_16 = 0;
    __e_acsl_assert(__gen_e_acsl_and_16,(char *)"Assertion",(char *)"main",
                    (char *)"\\valid(a) && \\valid(b) && \\valid(X)",39);
  }
  X = b;
  /*@ assert \valid(a) ∧ \valid(b) ∧ \valid(X); */
  {
    int __gen_e_acsl_initialized_9;
    int __gen_e_acsl_and_17;
    int __gen_e_acsl_and_19;
    int __gen_e_acsl_and_20;
    __gen_e_acsl_initialized_9 = __e_acsl_initialized((void *)(& a),
                                                      sizeof(int *));
    if (__gen_e_acsl_initialized_9) {
      int __gen_e_acsl_valid_13;
      __gen_e_acsl_valid_13 = __e_acsl_valid((void *)a,sizeof(int),(void *)a,
                                             (void *)(& a));
      __gen_e_acsl_and_17 = __gen_e_acsl_valid_13;
    }
    else __gen_e_acsl_and_17 = 0;
    if (__gen_e_acsl_and_17) {
      int __gen_e_acsl_initialized_10;
      int __gen_e_acsl_and_18;
      __gen_e_acsl_initialized_10 = __e_acsl_initialized((void *)(& b),
                                                         sizeof(int *));
      if (__gen_e_acsl_initialized_10) {
        int __gen_e_acsl_valid_14;
        __gen_e_acsl_valid_14 = __e_acsl_valid((void *)b,sizeof(int),
                                               (void *)b,(void *)(& b));
        __gen_e_acsl_and_18 = __gen_e_acsl_valid_14;
      }
      else __gen_e_acsl_and_18 = 0;
      __gen_e_acsl_and_19 = __gen_e_acsl_and_18;
    }
    else __gen_e_acsl_and_19 = 0;
    if (__gen_e_acsl_and_19) {
      int __gen_e_acsl_valid_15;
      __gen_e_acsl_valid_15 = __e_acsl_valid((void *)X,sizeof(int),(void *)X,
                                             (void *)(& X));
      __gen_e_acsl_and_20 = __gen_e_acsl_valid_15;
    }
    else __gen_e_acsl_and_20 = 0;
    __e_acsl_assert(__gen_e_acsl_and_20,(char *)"Assertion",(char *)"main",
                    (char *)"\\valid(a) && \\valid(b) && \\valid(X)",41);
  }
  __e_acsl_full_init((void *)(& c));
  c = & a;
  __e_acsl_full_init((void *)(& d));
  d = & c;
  /*@ assert \valid(*c); */
  {
    int __gen_e_acsl_initialized_11;
    int __gen_e_acsl_and_22;
    __gen_e_acsl_initialized_11 = __e_acsl_initialized((void *)c,
                                                       sizeof(int *));
    if (__gen_e_acsl_initialized_11) {
      int __gen_e_acsl_initialized_12;
      int __gen_e_acsl_and_21;
      int __gen_e_acsl_valid_16;
      __gen_e_acsl_initialized_12 = __e_acsl_initialized((void *)(& c),
                                                         sizeof(int **));
      if (__gen_e_acsl_initialized_12) {
        int __gen_e_acsl_valid_read;
        __gen_e_acsl_valid_read = __e_acsl_valid_read((void *)c,
                                                      sizeof(int *),
                                                      (void *)c,
                                                      (void *)(& c));
        __gen_e_acsl_and_21 = __gen_e_acsl_valid_read;
      }
      else __gen_e_acsl_and_21 = 0;
      __e_acsl_assert(__gen_e_acsl_and_21,(char *)"RTE",(char *)"main",
                      (char *)"mem_access: \\valid_read(c)",44);
      __gen_e_acsl_valid_16 = __e_acsl_valid((void *)*c,sizeof(int),
                                             (void *)*c,(void *)c);
      __gen_e_acsl_and_22 = __gen_e_acsl_valid_16;
    }
    else __gen_e_acsl_and_22 = 0;
    __e_acsl_assert(__gen_e_acsl_and_22,(char *)"Assertion",(char *)"main",
                    (char *)"\\valid(*c)",44);
  }
  /*@ assert \valid(*(*d)); */
  {
    int __gen_e_acsl_valid_read_2;
    int __gen_e_acsl_initialized_13;
    int __gen_e_acsl_and_26;
    __gen_e_acsl_valid_read_2 = __e_acsl_valid_read((void *)d,sizeof(int **),
                                                    (void *)d,(void *)(& d));
    __e_acsl_assert(__gen_e_acsl_valid_read_2,(char *)"RTE",(char *)"main",
                    (char *)"mem_access: \\valid_read(d)",45);
    __gen_e_acsl_initialized_13 = __e_acsl_initialized((void *)*d,
                                                       sizeof(int *));
    if (__gen_e_acsl_initialized_13) {
      int __gen_e_acsl_initialized_14;
      int __gen_e_acsl_and_24;
      int __gen_e_acsl_initialized_16;
      int __gen_e_acsl_and_25;
      int __gen_e_acsl_valid_17;
      __gen_e_acsl_initialized_14 = __e_acsl_initialized((void *)d,
                                                         sizeof(int **));
      if (__gen_e_acsl_initialized_14) {
        int __gen_e_acsl_initialized_15;
        int __gen_e_acsl_and_23;
        int __gen_e_acsl_valid_read_4;
        __gen_e_acsl_initialized_15 = __e_acsl_initialized((void *)(& d),
                                                           sizeof(int ***));
        if (__gen_e_acsl_initialized_15) {
          int __gen_e_acsl_valid_read_3;
          __gen_e_acsl_valid_read_3 = __e_acsl_valid_read((void *)d,
                                                          sizeof(int **),
                                                          (void *)d,
                                                          (void *)(& d));
          __gen_e_acsl_and_23 = __gen_e_acsl_valid_read_3;
        }
        else __gen_e_acsl_and_23 = 0;
        __e_acsl_assert(__gen_e_acsl_and_23,(char *)"RTE",(char *)"main",
                        (char *)"mem_access: \\valid_read(d)",45);
        __gen_e_acsl_valid_read_4 = __e_acsl_valid_read((void *)*d,
                                                        sizeof(int *),
                                                        (void *)*d,(void *)d);
        __gen_e_acsl_and_24 = __gen_e_acsl_valid_read_4;
      }
      else __gen_e_acsl_and_24 = 0;
      __e_acsl_assert(__gen_e_acsl_and_24,(char *)"RTE",(char *)"main",
                      (char *)"mem_access: \\valid_read(*d)",45);
      __gen_e_acsl_initialized_16 = __e_acsl_initialized((void *)(& d),
                                                         sizeof(int ***));
      if (__gen_e_acsl_initialized_16) {
        int __gen_e_acsl_valid_read_5;
        __gen_e_acsl_valid_read_5 = __e_acsl_valid_read((void *)d,
                                                        sizeof(int **),
                                                        (void *)d,
                                                        (void *)(& d));
        __gen_e_acsl_and_25 = __gen_e_acsl_valid_read_5;
      }
      else __gen_e_acsl_and_25 = 0;
      __e_acsl_assert(__gen_e_acsl_and_25,(char *)"RTE",(char *)"main",
                      (char *)"mem_access: \\valid_read(d)",45);
      __gen_e_acsl_valid_17 = __e_acsl_valid((void *)*(*d),sizeof(int),
                                             (void *)*(*d),(void *)*d);
      __gen_e_acsl_and_26 = __gen_e_acsl_valid_17;
    }
    else __gen_e_acsl_and_26 = 0;
    __e_acsl_assert(__gen_e_acsl_and_26,(char *)"Assertion",(char *)"main",
                    (char *)"\\valid(*(*d))",45);
  }
  free((void *)a);
  /*@ assert ¬\valid(a) ∧ \valid(b) ∧ \valid(X); */
  {
    int __gen_e_acsl_initialized_17;
    int __gen_e_acsl_and_27;
    int __gen_e_acsl_and_29;
    int __gen_e_acsl_and_30;
    __gen_e_acsl_initialized_17 = __e_acsl_initialized((void *)(& a),
                                                       sizeof(int *));
    if (__gen_e_acsl_initialized_17) {
      int __gen_e_acsl_valid_18;
      /*@ assert Eva: dangling_pointer: ¬\dangling(&a); */
      __gen_e_acsl_valid_18 = __e_acsl_valid((void *)a,sizeof(int),(void *)a,
                                             (void *)(& a));
      __gen_e_acsl_and_27 = __gen_e_acsl_valid_18;
    }
    else __gen_e_acsl_and_27 = 0;
    if (! __gen_e_acsl_and_27) {
      int __gen_e_acsl_initialized_18;
      int __gen_e_acsl_and_28;
      __gen_e_acsl_initialized_18 = __e_acsl_initialized((void *)(& b),
                                                         sizeof(int *));
      if (__gen_e_acsl_initialized_18) {
        int __gen_e_acsl_valid_19;
        __gen_e_acsl_valid_19 = __e_acsl_valid((void *)b,sizeof(int),
                                               (void *)b,(void *)(& b));
        __gen_e_acsl_and_28 = __gen_e_acsl_valid_19;
      }
      else __gen_e_acsl_and_28 = 0;
      __gen_e_acsl_and_29 = __gen_e_acsl_and_28;
    }
    else __gen_e_acsl_and_29 = 0;
    if (__gen_e_acsl_and_29) {
      int __gen_e_acsl_valid_20;
      __gen_e_acsl_valid_20 = __e_acsl_valid((void *)X,sizeof(int),(void *)X,
                                             (void *)(& X));
      __gen_e_acsl_and_30 = __gen_e_acsl_valid_20;
    }
    else __gen_e_acsl_and_30 = 0;
    __e_acsl_assert(__gen_e_acsl_and_30,(char *)"Assertion",(char *)"main",
                    (char *)"!\\valid(a) && \\valid(b) && \\valid(X)",47);
  }
  /*@ assert \valid(&Z); */
  {
    int __gen_e_acsl_valid_21;
    __gen_e_acsl_valid_21 = __e_acsl_valid((void *)(& Z),sizeof(int),
                                           (void *)(& Z),(void *)0);
    __e_acsl_assert(__gen_e_acsl_valid_21,(char *)"Assertion",(char *)"main",
                    (char *)"\\valid(&Z)",48);
  }
  g();
  __retres = 0;
  __e_acsl_delete_block((void *)(& Z));
  __e_acsl_delete_block((void *)(& X));
  __e_acsl_delete_block((void *)(& n));
  __e_acsl_delete_block((void *)(& d));
  __e_acsl_delete_block((void *)(& c));
  __e_acsl_delete_block((void *)(& b));
  __e_acsl_delete_block((void *)(& a));
  __e_acsl_memory_clean();
  return __retres;
}


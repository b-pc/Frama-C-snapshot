/* run.config
   EXECNOW: make -s tests/slicing/min_call.opt
   CMD: tests/slicing/min_call.opt
   OPT: -deps -lib-entry -main g -journal-disable
*/

/* dummy source file in order to test minimal calls feature
 * on select_return.c  */

#include "tests/slicing/select_return.c"
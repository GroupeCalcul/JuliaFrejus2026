#include <inttypes.h>
#include <stdlib.h>
#include <stdio.h>
double* my_alloc(int64_t size, void *fp) {
  double * p = (double*) calloc(size, sizeof(double));
  //fprintf((FILE*)fp, "alloc %d at adress %p\n", size, p);
  return p;
}

void my_free(double * p) {
    free(p);
}

#include <stdio.h>
void truc(int * x, FILE * fp) { *x += 2; fprintf(fp, "%d\n", *x); fflush(fp); }

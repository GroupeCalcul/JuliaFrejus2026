#include <inttypes.h>
#include <string.h>
#include <stdlib.h>

#define ALLOC_MAX 4

extern double *table[ALLOC_MAX];
extern int64_t compteur = 0;

int64_t my_alloc(int64_t size);
void my_free(int64_t num) ;
int64_t set_values(int64_t size, int64_t num, double * val) ;
int64_t get_values(int64_t size, int64_t num, double * val) ;

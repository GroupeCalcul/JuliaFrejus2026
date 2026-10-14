#include <stdio.h>
void truc(int * x) {
  *x += 2;
  printf("%d", x);
}

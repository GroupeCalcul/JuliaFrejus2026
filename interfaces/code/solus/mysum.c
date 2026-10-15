#include <inttypes.h>
double mysum(int64_t m, int64_t n, double *x) {
  double s = 0.;
  for(int64_t i = 0; i < m; ++i)
    for(int64_t j = 0; j < n; ++j) s += x[i * n + j];
  return s;
}

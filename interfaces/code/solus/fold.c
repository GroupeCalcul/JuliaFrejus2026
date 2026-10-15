#include <inttypes.h>
double fold(double (*op)(double, double), double (*f)(double),int64_t n , double *v, double c0) {
  double s = c0;
  for(int64_t i = 0; i < n; ++i)
      s = op(s, f(v[i]));
  return s;
}

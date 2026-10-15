subroutine mysum(m,n,x,s)
 use iso_c_binding
 integer(c_int64_t), intent(in), value :: m,n
 real(c_double)    , intent(in) :: x(m,n)
 !real(c_double)    , intent(in) :: x(:,:)
 real(c_double)    , intent(out):: s
 s = sum(x)
end subroutine

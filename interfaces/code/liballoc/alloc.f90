module alloc
   use iso_c_binding
   implicit none 
   integer, parameter :: ALLOC_MAX = 4
   integer(c_int64_t) :: compteur = 0

type :: array_1d
  real(c_double), pointer :: arr(:)
end type
  
   type(array_1d)  :: table(ALLOC_MAX)
contains

subroutine my_alloc(size, ret) bind(C, name="my_alloc")
  integer(c_int64_t), intent(in) :: size
  integer(c_int64_t), intent(out) :: ret
  integer(c_int64_t) :: alloc_stat
  if (compteur <  ALLOC_MAX ) then
    compteur = compteur + 1
    allocate(table(compteur)%arr(size), stat=alloc_stat)
    ret = compteur
    if (alloc_stat > 0) ret = -1
  else
    ret = -2
  end if
end subroutine my_alloc

subroutine my_free(num) bind(C, name="my_free")
  integer(c_int64_t), intent(in) :: num
  if (associated(table(num)%arr)) then 
    deallocate(table(num)%arr)
  end if
end subroutine my_free

subroutine set_values(size, ind, val_ptr, ierr) bind(C, name="set_values")
  integer(c_int64_t), intent(in) :: size
  type(c_ptr), intent(in), value :: val_ptr
  integer(c_int64_t), intent(in) :: ind
  integer(c_int64_t), intent(out) :: ierr
  real(c_double), pointer :: values(:)
  call c_f_pointer(val_ptr, values, [size])
  if (associated(table(ind)%arr)) then
    table(ind)%arr(1:size) = values(1:size)
  else
    ierr = -1
  end if
end subroutine set_values

subroutine get_values(size, num, val_ptr, ierr) bind(C, name="get_values")
  integer(c_int64_t), intent(in) :: size
  integer(c_int64_t), intent(in) :: num
  type(c_ptr), value :: val_ptr
  integer(c_int64_t), intent(out) :: ierr
  real(c_double), pointer :: values(:)
  ierr = 0
  call c_f_pointer(val_ptr, values, [size])
  if (associated(table(num)%arr)) then
    values(1:size)= table(num)%arr(1:size)
  else
    ierr = -1
  end if
end subroutine get_values

end module alloc

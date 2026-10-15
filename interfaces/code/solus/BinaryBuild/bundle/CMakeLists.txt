cmake_minimum_required(VERSION 3.17)
project(libAlloc
  DESCRIPTION "Toy allocation library"
  LANGUAGES Fortran C
)
add_library(alloc SHARED alloc.c)
add_library(alloc_f SHARED alloc.f90)
install(TARGETS alloc_f alloc)

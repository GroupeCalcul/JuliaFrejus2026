.SUFFIXES:

CC=gcc
FC=gfortran
CFLAGS=--shared -fPIC

all: liballoc.so liballoc_f.so

liballoc.so: alloc.c
	$(CC) $(CFLAGS) -o $@ $< 
liballoc_f.so: alloc.f90
	$(FC) $(CFLAGS) -o $@ $< 
clean: 
	@echo cleaning...
	@rm -fr *.so *.mod

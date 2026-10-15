# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Alloc"
version = v"0.1"

# Collection of sources required to complete build
sources = [ DirectorySource("./bundle")]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} \
               -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
               -DCMAKE_BUILD_TYPE=Release
cmake --build build 
cmake --install build
install_license ${WORKSPACE}/srcdir/LICENSE
"""

# Only linux because lacking of storage on my harddisk
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),  
]
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("liballoc", :liballoc)
    LibraryProduct("liballoc_f", :liballoc_f)
]
dependencies = [
  Dependency(PackageSpec(name="CompilerSupportLibraries_jll", 
                         uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]
# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")

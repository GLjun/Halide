#!/bin/bash -x
set -e
set -o pipefail

# Note this script assumes that the current working directory
# is the root of the repository
if [ ! -f ./.travis.yml ]; then
  echo "This script must be run from the root of the repository"
  exit 1
fi

: ${LLVM_VERSION:?"LLVM_VERSION must be specified"}
: ${BUILD_SYSTEM:?"BUILD_SYSTEM must be specified"}
: ${CXX:?"CXX must be specified"}

if [ ${BUILD_SYSTEM} = 'CMAKE' ]; then
  : ${HALIDE_SHARED_LIBRARY:?"HALIDE_SHARED_LIBRARY must be set"}
  LLVM_VERSION_NO_DOT="$( echo ${LLVM_VERSION} | sed 's/\.//' | cut -b1,2 )"
  mkdir -p build/ && cd build/
  # Require a specific version of LLVM, just in case the Travis instance has
  # an older clang/llvm version present
  cmake -DHALIDE_REQUIRE_LLVM_VERSION="${LLVM_VERSION_NO_DOT}" \
        -DLLVM_DIR="/usr/local/llvm/lib/cmake/llvm/" \
        -DHALIDE_SHARED_LIBRARY="${HALIDE_SHARED_LIBRARY}" \
        -DWITH_APPS=OFF \
        -DWITH_TESTS=ON \
        -DWITH_TEST_OPENGL=OFF \
        -DWITH_TUTORIALS=OFF \
        -DWITH_DOCS=ON \
        -DCMAKE_BUILD_TYPE=Debug \
        -G "Unix Makefiles" \
        ../

  # Build and run internal tests
  make ${MAKEFLAGS} run_correctness_cross_compilation

elif [ ${BUILD_SYSTEM} = 'MAKE' ]; then
  export LLVM_CONFIG=/usr/local/llvm/bin/llvm-config
  export CLANG=/usr/local/llvm/bin/clang
  ${LLVM_CONFIG} --cxxflags --libdir --bindir

  OPTIMIZE=-g make ${MAKEFLAGS} correctness_cross_compilation

  # Build and run internal tests
  # make ${MAKEFLAGS}

  # Build the docs and run the tests

else
  echo "Unexpected BUILD_SYSTEM: \"${BUILD_SYSTEM}\""
  exit 1
fi

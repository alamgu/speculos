cmake_minimum_required(VERSION 3.10)

project(Speculos C)

include(CTest)
include(ExternalProject)

if (CMAKE_TOOLCHAIN_FILE)
  message(STATUS "Using toolchain ${CMAKE_TOOLCHAIN_FILE}")
else ()
  # # By default, use gcc cross-compiler for ARM-Thumb
  # set(CMAKE_C_COMPILER arm-linux-gnueabihf-gcc)
  # add_compile_options(-mthumb)
  # message(STATUS "Using default compiler ${CMAKE_C_COMPILER}")
endif ()
# add_link_options(-static)

enable_testing()

# option(WITH_VNC "Support for VNC" OFF)

add_compile_options(-W -Wall -fPIC)
add_definitions(-DOS_LITTLE_ENDIAN -DNATIVE_64BITS -DGIT_REVISION=\"${GIT_REVISION}\")

option(
  CODE_COVERAGE
  "Builds targets with code coverage instrumentation. (Requires GCC or Clang)"
  OFF
)
if (CODE_COVERAGE)
  # Always disable optimisations and build with debug symbols, when building for code coverage
  add_compile_options(-O0 -g)
  add_link_options(-g)
  if (CMAKE_C_COMPILER_ID MATCHES "(Apple)?[Cc]lang")
    # Options for clang
    message(STATUS "Building with clang code coverage...")
    add_compile_options(-fprofile-instr-generate -fcoverage-mapping)
    add_link_options(-fprofile-instr-generate -fcoverage-mapping)
  elseif(CMAKE_C_COMPILER_ID MATCHES "GNU")
    # Options for gcc
    message(STATUS "Building with gcc code coverage...")
    add_compile_options(--coverage -fprofile-arcs -ftest-coverage)
    add_link_options(--coverage -fprofile-arcs -ftest-coverage)
  else()
    message(FATAL_ERROR "Unable to identify the compiler! Aborting...")
  endif()
endif()

include_directories(sdk src)

add_library(openssl UNKNOWN IMPORTED)

if (BUILD_TESTING)
  add_library(cmocka UNKNOWN IMPORTED)
endif()

include_directories(${INSTALL_DIR}/include)
link_directories(${INSTALL_DIR}/lib)

link_libraries(ssl crypto dl pthread)

add_subdirectory(src)

if (BUILD_TESTING)
  add_subdirectory(tests/syscalls)
endif()

# if (WITH_VNC)
# endif()

cmake_minimum_required(VERSION 3.16)
project(fib_jit C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

find_package(PkgConfig REQUIRED)
pkg_check_modules(LIGHTNING REQUIRED lightning)

add_executable(fib_jit fib.c)
target_include_directories(fib_jit PRIVATE ${LIGHTNING_INCLUDE_DIRS})
target_link_libraries(fib_jit PRIVATE ${LIGHTNING_LIBRARIES})

install(TARGETS fib_jit RUNTIME DESTINATION bin)

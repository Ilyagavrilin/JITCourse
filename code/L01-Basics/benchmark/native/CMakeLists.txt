cmake_minimum_required(VERSION 3.16)
project(nativebench)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

find_package(JNI REQUIRED)

add_library(nativebench SHARED
    native_bench.cpp
)

target_include_directories(nativebench PRIVATE
    ${JNI_INCLUDE_DIRS}
)

target_link_libraries(nativebench
    ${JNI_LIBRARIES}
)

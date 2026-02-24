cmake_minimum_required(VERSION 3.16)
project(MacPadPlusPlus VERSION 1.0.0 LANGUAGES C CXX OBJC OBJCXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_OBJCXX_STANDARD 17)

set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0" CACHE STRING "Minimum macOS version")

if(NOT APPLE)
    message(FATAL_ERROR "This project is macOS only. For Windows, use PowerEditor/src/CMakeLists.txt")
endif()

add_subdirectory(MacPadPlusPlus)

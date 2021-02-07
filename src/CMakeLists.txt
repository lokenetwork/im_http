# Copyright (c) Facebook, Inc. and its affiliates.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

cmake_minimum_required(VERSION 3.10)
include(CheckCXXCompilerFlag)

project(
        proxygen_echo
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(PROXYGEN_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../proxygen)

#设置 module 文件搜索路径
set(CMAKE_MODULE_PATH
        "${PROXYGEN_PATH}/cmake"
        # For shipit-transformed builds
        "${PROXYGEN_PATH}/build/fbcode_builder/CMake"
        ${CMAKE_MODULE_PATH})
#设置 config 文件搜索路径
set(CMAKE_PREFIX_PATH
        "${PROXYGEN_PATH}/proxygen/_build/deps/lib/cmake"
        "${PROXYGEN_PATH}/proxygen/_build/lib/cmake"
        ${CMAKE_PREFIX_PATH})

MESSAGE("CMAKE_MODULE_PATH = ${CMAKE_MODULE_PATH}, CMAKE_PREFIX_PATH = ${CMAKE_PREFIX_PATH}")


# Dependencies
#
# IMPORTANT: If you change this, make the analogous update in:
#   cmake/proxygen-config.cmake.in
find_package(fmt REQUIRED)
find_package(folly REQUIRED)
find_package(wangle REQUIRED)
find_package(Fizz REQUIRED)
find_package(Zstd REQUIRED)
find_package(ZLIB REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(Threads)
find_package(Boost 1.58 REQUIRED
        COMPONENTS
        iostreams
        context
        date_time
        filesystem
        program_options
        regex
        system
        thread
        )
find_package(proxygen REQUIRED)


SET(GFLAG_DEPENDENCIES "")
SET(PROXYGEN_EXTRA_LINK_LIBRARIES "")
SET(PROXYGEN_EXTRA_INCLUDE_DIRECTORIES "")

find_package(gflags CONFIG QUIET)
if (gflags_FOUND)
    message(STATUS "Found gflags from package config")
    if (TARGET gflags-shared)
        list(APPEND GFLAG_DEPENDENCIES gflags-shared)
    elseif (TARGET gflags)
        list(APPEND GFLAG_DEPENDENCIES gflags)
    else()
        message(FATAL_ERROR
                "Unable to determine the target name for the GFlags package.")
    endif()
    list(APPEND CMAKE_REQUIRED_LIBRARIES ${GFLAGS_LIBRARIES})
    list(APPEND CMAKE_REQUIRED_INCLUDES ${GFLAGS_INCLUDE_DIR})
else()
    find_package(Gflags REQUIRED MODULE)
    list(APPEND PROXYGEN_EXTRA_LINK_LIBRARIES ${LIBGFLAGS_LIBRARY})
    list(APPEND PROXYGEN_EXTRA_INCLUDE_DIRECTORIES ${LIBGFLAGS_INCLUDE_DIR})
    list(APPEND CMAKE_REQUIRED_LIBRARIES ${LIBGFLAGS_LIBRARY})
    list(APPEND CMAKE_REQUIRED_INCLUDES ${LIBGFLAGS_INCLUDE_DIR})
endif()

list(APPEND
        _PROXYGEN_COMMON_COMPILE_OPTIONS
        -Wall
        -Wextra
        )

CHECK_CXX_COMPILER_FLAG(-Wnoexcept-type COMPILER_HAS_W_NOEXCEPT_TYPE)
if (COMPILER_HAS_W_NOEXCEPT_TYPE)
    list(APPEND _PROXYGEN_COMMON_COMPILE_OPTIONS -Wno-noexcept-type)
endif()
CHECK_CXX_COMPILER_FLAG(-Wunused-parameter COMPILER_HAS_W_UNUSED_PARAMETER)
if (COMPILER_HAS_W_UNUSED_PARAMETER)
    list(APPEND _PROXYGEN_COMMON_COMPILE_OPTIONS -Wno-unused-parameter)
endif()
CHECK_CXX_COMPILER_FLAG(-Wmissing-field-initializers COMPILER_HAS_W_MISSING_FIELD_INITIALIZERS)
if (COMPILER_HAS_W_MISSING_FIELD_INITIALIZERS)
    list(APPEND _PROXYGEN_COMMON_COMPILE_OPTIONS -Wno-missing-field-initializers)
endif()
CHECK_CXX_COMPILER_FLAG(-Wnullability-completeness COMPILER_HAS_W_NULLABILITY_COMPLETENESS)
if (COMPILER_HAS_W_NULLABILITY_COMPLETENESS)
    list(APPEND _PROXYGEN_COMMON_COMPILE_OPTIONS -Wno-nullability-completeness)
endif()
CHECK_CXX_COMPILER_FLAG(-Wdeprecated-register COMPILER_HAS_W_DEPRECATED_REGISTER)
if (COMPILER_HAS_W_DEPRECATED_REGISTER)
    list(APPEND _PROXYGEN_COMMON_COMPILE_OPTIONS -Wno-deprecated-register)
endif()
CHECK_CXX_COMPILER_FLAG(-Wunused-value COMPILER_HAS_W_UNUSED_VALUE)
if (COMPILER_HAS_W_UNUSED_VALUE)
    list(APPEND _PROXYGEN_COMMON_COMPILE_OPTIONS -Wno-unused-value)
endif()

link_directories("${PROXYGEN_PATH}/proxygen/_build/lib")
include_directories("${PROXYGEN_PATH}/proxygen/_build/include")

add_library(
        proxygenhttpserver
        http_server/RequestHandlerAdaptor.cpp
        http_server/SignalHandler.cpp
        http_server/HTTPServerAcceptor.cpp
        http_server/HTTPServer.cpp
)
target_compile_options(
        proxygenhttpserver
        PRIVATE
        ${_PROXYGEN_COMMON_COMPILE_OPTIONS}
)
if (BUILD_SHARED_LIBS)
    set_property(TARGET proxygenhttpserver PROPERTY POSITION_INDEPENDENT_CODE ON)
endif()

target_link_libraries(
        proxygenhttpserver
        PUBLIC
        proxygen
        Folly::folly
        fizz::fizz
        wangle::wangle
        zstd
        Boost::boost
        Boost::iostreams
        -lz
)

MESSAGE("CMAKE_MODULE_PATH = ${CMAKE_MODULE_PATH}")

add_executable(im_http
        EchoServer.cpp
        EchoHandler.cpp
)
target_compile_options(
        im_http
        PRIVATE
        ${_PROXYGEN_COMMON_COMPILE_OPTIONS}
)
target_link_libraries(
        im_http
        PUBLIC
        proxygen
        proxygenhttpserver
)


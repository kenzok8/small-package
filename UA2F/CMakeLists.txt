cmake_minimum_required(VERSION 3.16)
project(UA2F LANGUAGES C CXX)

set(CMAKE_C_STANDARD 17)

OPTION(UA2F_BUILD_TESTS "Build tests" OFF)
OPTION(UA2F_ENABLE_UCI "Enable UCI support" ON)

find_package(Git)
if(GIT_FOUND)
    execute_process(
            COMMAND ${GIT_EXECUTABLE} describe --tags --abbrev=0
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            OUTPUT_VARIABLE GIT_TAG
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    execute_process(
            COMMAND ${GIT_EXECUTABLE} branch --show-current
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            OUTPUT_VARIABLE GIT_BRANCH
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    execute_process(
            COMMAND ${GIT_EXECUTABLE} rev-parse HEAD
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            OUTPUT_VARIABLE GIT_COMMIT
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )
else()
    set(GIT_COMMIT "unknown")
    set(GIT_BRANCH "unknown")
    set(GIT_TAG "unknown")
endif()

if(UA2F_VERSION_STR)
    message(STATUS "Using version string: ${UA2F_VERSION_STR}")
else ()
    set(UA2F_VERSION_STR "unknown")
    message(STATUS "Using version string: unknown")
endif()

# Define macros
add_compile_definitions(UA2F_GIT_COMMIT="${GIT_COMMIT}")
add_compile_definitions(UA2F_GIT_BRANCH="${GIT_BRANCH}")
add_compile_definitions(UA2F_GIT_TAG="${GIT_TAG}")
add_compile_definitions(UA2F_VERSION="${UA2F_VERSION_STR}")

include(CheckSymbolExists)
check_symbol_exists(__malloc_hook "malloc.h" IS_LIBC_GLIBC)

if (IS_LIBC_GLIBC)
    add_compile_options(-fsanitize=address)
    add_link_options(-fsanitize=address)
else ()
    message(STATUS "AddressSanitizer is disabled.")
endif ()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ffunction-sections -fdata-sections")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-gc-sections")

if(UA2F_CUSTOM_USER_AGENT)
    if(NOT UA2F_USER_AGENT_STRING)
        message(FATAL_ERROR "UA2F_USER_AGENT_STRING is not set")
    endif()
    message(STATUS "Using custom user agent string: ${UA2F_USER_AGENT_STRING}")
    add_compile_definitions(UA2F_USE_CUSTOM_UA=1)
endif()

# Configure the header file
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/custom.h.in ${CMAKE_CURRENT_BINARY_DIR}/custom.h)

# Include the binary directory to find the generated header file
include_directories(${CMAKE_CURRENT_BINARY_DIR})

add_executable(ua2f
        src/ua2f.c
        src/statistics.c
        src/util.c
        src/cache.c
        src/handler.c
        src/cli.c
        src/config.c
        src/third/nfqueue-mnl.c)

target_link_libraries(ua2f mnl netfilter_queue pthread nfnetlink)

if (UA2F_ENABLE_UCI)
    add_compile_definitions(UA2F_ENABLE_UCI=1)
    target_link_libraries(ua2f uci)
else ()
    message(STATUS "UCI support is disabled.")
endif ()

install(TARGETS ua2f RUNTIME DESTINATION bin)

if (UA2F_BUILD_TESTS)
    set(CMAKE_CXX_STANDARD 14)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)

    cmake_policy(SET CMP0135 NEW)
    include(FetchContent)
    FetchContent_Declare(
            googletest
            URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip
    )

    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(googletest)

    enable_testing()
    add_executable(
            ua2f_test
            test/util_test.cc
            src/util.c
            src/cache.c
            src/cli.c
    )
    target_link_libraries(
            ua2f_test
            GTest::gtest_main
    )
    target_include_directories(ua2f_test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

    include(GoogleTest)
    gtest_discover_tests(ua2f_test)
else ()
    message(STATUS "Tests are disabled.")
endif ()
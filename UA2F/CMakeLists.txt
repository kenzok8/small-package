cmake_minimum_required(VERSION 3.16)
project(UA2F LANGUAGES C CXX)

set(CMAKE_C_STANDARD 17)

OPTION(UA2F_BUILD_TESTS "Build tests" OFF)
OPTION(UA2F_ENABLE_UCI "Enable UCI support" ON)
OPTION(UA2F_NO_CACHE "Disable cache" OFF)

find_package(Git)
if (GIT_FOUND)
    execute_process(
            COMMAND ${GIT_EXECUTABLE} describe --tags --abbrev=0
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            OUTPUT_VARIABLE GIT_TAG
            OUTPUT_STRIP_TRAILING_WHITESPACE
            RESULT_VARIABLE GIT_TAG_RESULT
    )
    if ((NOT GIT_TAG_RESULT EQUAL 0) OR (GIT_TAG STREQUAL ""))
        set(GIT_TAG "unknown")
    endif ()

    execute_process(
            COMMAND ${GIT_EXECUTABLE} branch --show-current
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            OUTPUT_VARIABLE GIT_BRANCH
            OUTPUT_STRIP_TRAILING_WHITESPACE
            RESULT_VARIABLE GIT_BRANCH_RESULT
    )
    if ((NOT GIT_BRANCH_RESULT EQUAL 0) OR (GIT_BRANCH STREQUAL ""))
        set(GIT_BRANCH "unknown")
    endif ()

    execute_process(
            COMMAND ${GIT_EXECUTABLE} rev-parse HEAD
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            OUTPUT_VARIABLE GIT_COMMIT
            OUTPUT_STRIP_TRAILING_WHITESPACE
            RESULT_VARIABLE GIT_COMMIT_RESULT
    )
    if ((NOT GIT_COMMIT_RESULT EQUAL 0) OR (GIT_COMMIT STREQUAL ""))
        set(GIT_COMMIT "unknown")
    endif ()

    execute_process(
            COMMAND ${GIT_EXECUTABLE} status --porcelain
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            OUTPUT_VARIABLE GIT_DIRTY_OUTPUT
            OUTPUT_STRIP_TRAILING_WHITESPACE
            RESULT_VARIABLE GIT_DIRTY_RESULT
    )
    if ((NOT GIT_DIRTY_RESULT EQUAL 0))
        set(GIT_DIRTY "unknown")
    elseif (GIT_DIRTY_OUTPUT STREQUAL "")
        set(GIT_DIRTY "clean")
    else ()
        set(GIT_DIRTY "dirty")
    endif ()
else ()
    set(GIT_COMMIT "unknown")
    set(GIT_BRANCH "unknown")
    set(GIT_TAG "unknown")
    set(GIT_DIRTY "unknown")
endif ()

if (UA2F_VERSION_STR)
    message(STATUS "Using version string: ${UA2F_VERSION_STR}")
else ()
    set(UA2F_VERSION_STR "unknown")
    message(STATUS "Using version string: unknown")
endif ()

add_compile_definitions(UA2F_GIT_COMMIT="${GIT_COMMIT}")
add_compile_definitions(UA2F_GIT_BRANCH="${GIT_BRANCH}")
add_compile_definitions(UA2F_GIT_TAG="${GIT_TAG}")
add_compile_definitions(UA2F_GIT_DIRTY="${GIT_DIRTY}")
add_compile_definitions(UA2F_VERSION="${UA2F_VERSION_STR}")

if (DEFINED ENV{UA2F_ENABLE_ASAN})
    set(UA2F_ENABLE_ASAN $ENV{UA2F_ENABLE_ASAN})
    message(STATUS "UA2F_ENABLE_ASAN set from environment: ${UA2F_ENABLE_ASAN}")
else ()
    message(STATUS "UA2F_ENABLE_ASAN not set in environment")
endif ()

if (UA2F_ENABLE_ASAN)
    add_compile_options(-fsanitize=address)
    add_link_options(-fsanitize=address)
    message(STATUS "AddressSanitizer is enabled.")
else ()
    message(STATUS "AddressSanitizer is disabled.")
endif ()

if (UA2F_CUSTOM_USER_AGENT)
    if (NOT UA2F_USER_AGENT_STRING)
        message(FATAL_ERROR "UA2F_USER_AGENT_STRING is not set")
    endif ()
    message(STATUS "Using custom user agent string: ${UA2F_USER_AGENT_STRING}")
    add_compile_definitions(UA2F_USE_CUSTOM_UA=1)
endif ()

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/custom.h.in ${CMAKE_CURRENT_BINARY_DIR}/custom.h)

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

if (UA2F_NO_CACHE)
    add_compile_definitions(UA2F_NO_CACHE=1)
    message(STATUS "Cache is disabled.")
else ()
    message(STATUS "Cache is auto.")
endif ()

install(TARGETS ua2f RUNTIME DESTINATION bin)

if (UA2F_BUILD_TESTS)
    set(CMAKE_CXX_STANDARD 14)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)

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
            test/cache_test.cc
            src/util.c
            src/cache.c
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
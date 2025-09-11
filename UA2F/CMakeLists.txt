cmake_minimum_required(VERSION 3.16)
project(UA2F LANGUAGES C CXX)

set(CMAKE_C_STANDARD 17)

cmake_policy(SET CMP0135 NEW)

OPTION(UA2F_BUILD_TESTS "Build tests" OFF)

if(DEFINED ENV{CI})
    # In CI, always enable coverage for all builds
    set(UA2F_ENABLE_COVERAGE ON CACHE BOOL "Enable code coverage (auto-enabled in CI)" FORCE)
    message(STATUS "Auto-enabling coverage in CI environment")
else()
    OPTION(UA2F_ENABLE_COVERAGE "Enable code coverage" OFF)
endif()

OPTION(UA2F_ENABLE_UCI "Enable UCI support" ON)
OPTION(UA2F_NO_CACHE "Disable cache" OFF)
OPTION(UA2F_ENABLE_BACKTRACE "Enable libbacktrace support" ON)

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

add_compile_options(-fno-omit-frame-pointer -fno-strict-aliasing)

# Coverage configuration
if (UA2F_ENABLE_COVERAGE)
    if (CMAKE_C_COMPILER_ID STREQUAL "GNU" OR CMAKE_C_COMPILER_ID STREQUAL "Clang")
        add_compile_options(--coverage -O0 -g)
        add_link_options(--coverage)
        message(STATUS "Code coverage is enabled.")
    else()
        message(WARNING "Code coverage is only supported with GCC or Clang.")
    endif()
else()
    message(STATUS "Code coverage is disabled.")
endif()

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
        src/third/nfqueue-mnl/nfqueue-mnl.c)

target_link_libraries(ua2f mnl netfilter_queue pthread nfnetlink)

if (UA2F_ENABLE_BACKTRACE)
    set(LIBBACKTRACE_BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/libbacktrace)
    
    execute_process(
        COMMAND ${CMAKE_C_COMPILER} -dumpmachine
        OUTPUT_VARIABLE LIBBACKTRACE_HOST
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE DUMPMACHINE_RESULT
    )
    if(NOT DUMPMACHINE_RESULT EQUAL 0)
        set(LIBBACKTRACE_HOST "")
    endif()
    message(STATUS "LIBBACKTRACE_HOST: ${LIBBACKTRACE_HOST}")
    
    add_custom_target(libbacktrace
        COMMAND cd ${CMAKE_CURRENT_SOURCE_DIR}/src/third/libbacktrace && 
                autoreconf -i && 
                ./configure --prefix=${LIBBACKTRACE_BUILD_DIR} --host=${LIBBACKTRACE_HOST} && 
                make && 
                make install
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src/third/libbacktrace
    )
    
    target_include_directories(ua2f PRIVATE ${LIBBACKTRACE_BUILD_DIR}/include)
    
    target_link_directories(ua2f PRIVATE ${LIBBACKTRACE_BUILD_DIR}/lib)
    
    target_link_libraries(ua2f backtrace)
    
    add_dependencies(ua2f libbacktrace)
    
    add_compile_definitions(UA2F_ENABLE_BACKTRACE=1)
    message(STATUS "libbacktrace support is enabled.")
else()
    message(STATUS "libbacktrace support is disabled.")
endif()

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

    # Add coverage target
    if (UA2F_ENABLE_COVERAGE)
        add_custom_target(coverage
            COMMAND echo "Running unit tests to generate coverage data"
            COMMAND ${CMAKE_CURRENT_BINARY_DIR}/ua2f_test
            COMMENT "Generating code coverage data"
            DEPENDS ua2f_test
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        )
        
        # Add lcov target for preprocessed coverage data
        add_custom_target(coverage-lcov
            COMMAND echo "Running unit tests and generating lcov report"
            COMMAND ${CMAKE_CURRENT_BINARY_DIR}/ua2f_test
            COMMAND lcov --capture --directory . --output-file coverage.info --ignore-errors mismatch --branch-coverage
            COMMAND lcov --remove coverage.info '*/test/*' '*/build*/_deps/*' '/usr/*' '*/googletest/*' '*_deps/*' --output-file coverage.info --ignore-errors unused --branch-coverage
            COMMAND lcov --list coverage.info --branch-coverage
            COMMENT "Generating lcov coverage report"
            DEPENDS ua2f_test
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        )
    endif()

    include(GoogleTest)
    gtest_discover_tests(ua2f_test)
else ()
    message(STATUS "Tests are disabled.")
endif ()

# Coverage targets for integration testing (independent of unit tests)
if (UA2F_ENABLE_COVERAGE)
    add_custom_target(coverage-integration-reset
        COMMAND find . -name "*.gcda" -delete
        COMMENT "Reset coverage counters for integration tests"
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
    
    add_custom_target(coverage-integration-process
        COMMAND lcov --capture --directory . --output-file coverage-integration.info --ignore-errors mismatch --branch-coverage
        COMMAND lcov --remove coverage-integration.info '*/test/*' '*/build*/_deps/*' '/usr/*' '*/googletest/*' '*_deps/*' --output-file coverage-integration.info --ignore-errors unused --branch-coverage
        COMMAND lcov --list coverage-integration.info --branch-coverage
        COMMENT "Process integration test coverage data with lcov"
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
    
    add_custom_target(coverage-clean
        COMMAND find . -name "*.gcda" -delete
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Cleaning coverage data"
    )
endif()

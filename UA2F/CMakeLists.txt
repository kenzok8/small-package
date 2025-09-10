cmake_minimum_required(VERSION 3.16)
project(UA2F LANGUAGES C CXX)

set(CMAKE_C_STANDARD 17)

cmake_policy(SET CMP0135 NEW)

OPTION(UA2F_BUILD_TESTS "Build tests" OFF)
OPTION(UA2F_ENABLE_COVERAGE "Enable code coverage" OFF)
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
        find_program(LCOV_PATH lcov)
        find_program(GENHTML_PATH genhtml)
        
        if(LCOV_PATH AND GENHTML_PATH)
            add_custom_target(coverage
                COMMAND ${LCOV_PATH} --directory . --zerocounters
                COMMAND ${CMAKE_CURRENT_BINARY_DIR}/ua2f_test
                COMMAND ${LCOV_PATH} --directory . --capture --output-file coverage.info --ignore-errors mismatch
                COMMAND ${LCOV_PATH} --remove coverage.info '/usr/*' '${CMAKE_CURRENT_BINARY_DIR}/_deps/*' '*/test/*' --output-file coverage_filtered.info --ignore-errors mismatch
                COMMAND ${GENHTML_PATH} coverage_filtered.info --output-directory coverage_html --ignore-errors mismatch
                COMMAND echo "Coverage report generated in coverage_html/index.html"
                WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                COMMENT "Generating code coverage report"
                DEPENDS ua2f_test
            )
            
            add_custom_target(coverage-integration
                COMMAND ${LCOV_PATH} --directory . --zerocounters
                COMMAND echo "Run integration tests manually, then use 'make coverage-collect'"
                WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                COMMENT "Preparing for integration test coverage"
            )
            
            add_custom_target(coverage-collect
                COMMAND ${LCOV_PATH} --directory . --capture --output-file coverage_integration.info --ignore-errors mismatch
                COMMAND ${LCOV_PATH} --remove coverage_integration.info '/usr/*' '*/test/*' --output-file coverage_integration_filtered.info --ignore-errors mismatch,unused
                COMMAND ${GENHTML_PATH} coverage_integration_filtered.info --output-directory coverage_integration_html --ignore-errors mismatch
                COMMAND echo "Integration test coverage report generated in coverage_integration_html/index.html"
                WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                COMMENT "Collecting integration test coverage data"
            )
            
            add_custom_target(coverage-combined
                COMMAND ${LCOV_PATH} --directory . --zerocounters
                COMMAND ${CMAKE_CURRENT_BINARY_DIR}/ua2f_test
                COMMAND ${LCOV_PATH} --directory . --capture --output-file coverage_unit.info --ignore-errors mismatch
                COMMAND echo "Unit tests coverage collected. Run integration tests now..."
                COMMAND echo "After integration tests, coverage data will be merged automatically"
                WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                COMMENT "Generating combined coverage report (unit + integration)"
                DEPENDS ua2f_test
            )
            
            add_custom_target(coverage-merge
                COMMAND ${LCOV_PATH} --directory . --capture --output-file coverage_after_integration.info --ignore-errors mismatch
                COMMAND ${LCOV_PATH} --add-tracefile coverage_unit.info --add-tracefile coverage_after_integration.info --output-file coverage_combined.info --ignore-errors mismatch || ${LCOV_PATH} --directory . --capture --output-file coverage_combined.info --ignore-errors mismatch
                COMMAND ${LCOV_PATH} --remove coverage_combined.info '/usr/*' '*/test/*' --output-file coverage_combined_filtered.info --ignore-errors mismatch,unused
                COMMAND ${GENHTML_PATH} coverage_combined_filtered.info --output-directory coverage_combined_html --ignore-errors mismatch
                COMMAND echo "Combined coverage report generated in coverage_combined_html/index.html"
                WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                COMMENT "Merging unit and integration test coverage"
            )
            
            add_custom_target(coverage-clean
                COMMAND ${LCOV_PATH} --directory . --zerocounters
                COMMAND find . -name "*.gcda" -delete
                WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                COMMENT "Cleaning coverage data"
            )
        else()
            message(WARNING "lcov and genhtml are required for coverage reports")
        endif()
    endif()

    include(GoogleTest)
    gtest_discover_tests(ua2f_test)
else ()
    message(STATUS "Tests are disabled.")
endif ()

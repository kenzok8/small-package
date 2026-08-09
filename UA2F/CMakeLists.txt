cmake_minimum_required(VERSION 3.16)
project(UA2F LANGUAGES C CXX)

set(CMAKE_C_STANDARD 17)

cmake_policy(SET CMP0135 NEW)

OPTION(UA2F_BUILD_TESTS "Build tests" OFF)
OPTION(UA2F_ENABLE_COVERAGE "Enable code coverage" OFF)

OPTION(UA2F_ENABLE_UCI "Enable UCI support" ON)
OPTION(UA2F_NO_CACHE "Disable cache" OFF)
OPTION(UA2F_ENABLE_BACKTRACE "Enable libbacktrace support" ON)

set(UA2F_MAX_HTTP_SESSIONS 0 CACHE STRING "Default max HTTP sessions (0 = unlimited)")
add_compile_definitions(UA2F_DEFAULT_MAX_HTTP_SESSIONS=${UA2F_MAX_HTTP_SESSIONS})

include(CheckCSourceCompiles)

set(UA2F_64BIT_ATOMIC_TEST_SOURCE
        "#include <stdatomic.h>
int main(void) {
    atomic_llong value = ATOMIC_VAR_INIT(0);
    long long expected = 1;
    atomic_fetch_add_explicit(&value, 1, memory_order_relaxed);
    atomic_compare_exchange_strong_explicit(&value, &expected, 2, memory_order_relaxed, memory_order_relaxed);
    return (int)atomic_load_explicit(&value, memory_order_relaxed);
}")

check_c_source_compiles("${UA2F_64BIT_ATOMIC_TEST_SOURCE}" UA2F_64BIT_ATOMICS_WITHOUT_LIBATOMIC)
if (NOT UA2F_64BIT_ATOMICS_WITHOUT_LIBATOMIC)
    set(UA2F_PREVIOUS_REQUIRED_LIBRARIES "${CMAKE_REQUIRED_LIBRARIES}")
    set(CMAKE_REQUIRED_LIBRARIES atomic)
    check_c_source_compiles("${UA2F_64BIT_ATOMIC_TEST_SOURCE}" UA2F_64BIT_ATOMICS_WITH_LIBATOMIC)
    set(CMAKE_REQUIRED_LIBRARIES "${UA2F_PREVIOUS_REQUIRED_LIBRARIES}")

    if (UA2F_64BIT_ATOMICS_WITH_LIBATOMIC)
        set(UA2F_ATOMIC_LIBRARIES atomic)
        message(STATUS "64-bit atomics require libatomic.")
    else ()
        message(FATAL_ERROR "64-bit C atomics are unavailable with or without libatomic")
    endif ()
else ()
    message(STATUS "64-bit atomics do not require libatomic.")
endif ()

function(ua2f_link_atomic_if_needed target)
    if (UA2F_ATOMIC_LIBRARIES)
        target_link_libraries(${target} ${UA2F_ATOMIC_LIBRARIES})
    endif ()
endfunction()

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
        add_compile_options(--coverage -O0 -g -fno-lto)
        add_link_options(--coverage -fno-lto)
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
        src/handler_io.c
        src/proxy.c
        src/cli.c
        src/config.c
        src/http_session.c
        src/http_parser_ua.c
        src/session_cleaner.c
        src/third/nfqueue-mnl/nfqueue-mnl.c
        src/third/llhttp/llhttp.c
        src/third/llhttp/api.c
        src/third/llhttp/http.c)

target_include_directories(ua2f PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src/third/llhttp)

target_link_libraries(ua2f mnl netfilter_queue pthread nfnetlink)
ua2f_link_atomic_if_needed(ua2f)

find_library(NFCONNTRACK netfilter_conntrack)
if(NFCONNTRACK)
    target_sources(ua2f PRIVATE src/conntrack_listener.c)
    target_link_libraries(ua2f netfilter_conntrack)
    target_compile_definitions(ua2f PRIVATE UA2F_HAS_CONNTRACK_LISTENER=1)
    message(STATUS "Conntrack listener enabled.")
else()
    message(STATUS "libnetfilter_conntrack not found, conntrack listener disabled.")
endif()

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
            test/statistics_test.cc
            test/cli_test.cc
            test/http_session_test.cc
            test/http_parser_ua_test.cc
            src/util.c
            src/cache.c
            src/http_session.c
            src/http_parser_ua.c
            src/statistics.c
            src/cli.c
            src/third/llhttp/llhttp.c
            src/third/llhttp/api.c
            src/third/llhttp/http.c
    )
    target_link_libraries(
            ua2f_test
            GTest::gtest_main
            pthread
    )
    ua2f_link_atomic_if_needed(ua2f_test)
    target_include_directories(ua2f_test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
    target_include_directories(ua2f_test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src/third/llhttp)
    if (UA2F_ENABLE_UCI)
        target_sources(ua2f_test PRIVATE test/config_test.cc)
        target_sources(ua2f_test PRIVATE src/config.c)
        target_link_libraries(ua2f_test uci)
    endif ()

    # Add coverage target
    if (UA2F_ENABLE_COVERAGE)
        add_custom_target(coverage
            COMMAND echo "Running unit tests to generate coverage data"
            COMMAND ${CMAKE_CURRENT_BINARY_DIR}/ua2f_test
            COMMAND ${CMAKE_CURRENT_BINARY_DIR}/ua2f_handler_test
            COMMAND ${CMAKE_CURRENT_BINARY_DIR}/ua2f_proxy_test
            COMMAND ${CMAKE_CURRENT_BINARY_DIR}/ua2f_listener_test
            COMMAND ${CMAKE_CURRENT_BINARY_DIR}/ua2f_runtime_test
            COMMENT "Generating code coverage data"
            DEPENDS ua2f_test ua2f_handler_test ua2f_proxy_test ua2f_listener_test ua2f_runtime_test
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        )

        # Upload conventional line coverage to Codecov. Keep a second report
        # with branch data so branch gaps remain visible in the CI log without
        # making partially covered branches look like completely missed lines.
        # Note: delete ua2f.dir gcda first — the production binary is never executed,
        # so its empty coverage data would override test coverage for shared sources.
        add_custom_target(coverage-lcov
            COMMAND find ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/ua2f.dir -name "*.gcda" -delete
            COMMAND find ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/ua2f_proxy_test.dir -name "*.gcda" -delete
            COMMAND ${CMAKE_CURRENT_BINARY_DIR}/ua2f_test
            COMMAND ${CMAKE_CURRENT_BINARY_DIR}/ua2f_handler_test
            COMMAND ${CMAKE_CURRENT_BINARY_DIR}/ua2f_listener_test
            COMMAND ${CMAKE_CURRENT_BINARY_DIR}/ua2f_runtime_test
            COMMAND lcov --capture --directory . --output-file coverage.info --ignore-errors mismatch,inconsistent
            COMMAND lcov --remove coverage.info '*/test/*' '*/build*/_deps/*' '/usr/*' '*/googletest/*' '*_deps/*' '*/third/*' --output-file coverage.info --ignore-errors unused,inconsistent
            COMMAND lcov --list coverage.info
            COMMAND lcov --capture --directory . --output-file coverage-branches.info --ignore-errors mismatch,inconsistent --branch-coverage
            COMMAND lcov --remove coverage-branches.info '*/test/*' '*/build*/_deps/*' '/usr/*' '*/googletest/*' '*_deps/*' '*/third/*' --output-file coverage-branches.info --ignore-errors unused,inconsistent --branch-coverage
            COMMAND lcov --list coverage-branches.info --branch-coverage
            COMMENT "Generating lcov coverage report"
            DEPENDS ua2f_test ua2f_handler_test ua2f_proxy_test ua2f_listener_test ua2f_runtime_test
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        )
    endif()

    # Handler tests - tests handler.c with mock I/O (no libmnl dependency)
    add_executable(
            ua2f_handler_test
            test/handler_test.cc
            test/handler_pcap_test.cc
            test/packet_builder.cc
            test/pcap_helpers.cc
            src/handler.c
            src/util.c
            src/cache.c
            src/http_session.c
            src/http_parser_ua.c
            src/statistics.c
            src/cli.c
            src/third/llhttp/llhttp.c
            src/third/llhttp/api.c
            src/third/llhttp/http.c
    )
    target_link_libraries(
            ua2f_handler_test
            GTest::gtest_main
            pthread
            netfilter_queue
            nfnetlink
    )
    ua2f_link_atomic_if_needed(ua2f_handler_test)
    target_compile_options(ua2f_handler_test PRIVATE
            $<$<COMPILE_LANGUAGE:C>:-iquote${CMAKE_CURRENT_SOURCE_DIR}/src>
            $<$<COMPILE_LANGUAGE:CXX>:-iquote${CMAKE_CURRENT_SOURCE_DIR}/src>
    )
    target_include_directories(ua2f_handler_test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src/third/llhttp)
    target_compile_definitions(ua2f_handler_test PRIVATE
            PCAP_DATA_DIR="${CMAKE_CURRENT_SOURCE_DIR}/test/data"
    )
    if (UA2F_ENABLE_UCI)
        target_sources(ua2f_handler_test PRIVATE src/config.c)
        target_link_libraries(ua2f_handler_test uci)
    endif ()

    # Proxy lifecycle tests exercise listener setup, worker selection, and
    # startup failure paths without requiring transparent-routing privileges.
    add_executable(
            ua2f_proxy_test
            test/proxy_test.cc
            src/proxy.c
            src/handler.c
            src/util.c
            src/cache.c
            src/http_session.c
            src/http_parser_ua.c
            src/statistics.c
            src/cli.c
            src/third/llhttp/llhttp.c
            src/third/llhttp/api.c
            src/third/llhttp/http.c
    )
    target_link_libraries(
            ua2f_proxy_test
            GTest::gtest_main
            pthread
            netfilter_queue
            nfnetlink
    )
    ua2f_link_atomic_if_needed(ua2f_proxy_test)
    target_compile_options(ua2f_proxy_test PRIVATE
            $<$<COMPILE_LANGUAGE:C>:-iquote${CMAKE_CURRENT_SOURCE_DIR}/src>
            $<$<COMPILE_LANGUAGE:CXX>:-iquote${CMAKE_CURRENT_SOURCE_DIR}/src>
    )
    target_include_directories(ua2f_proxy_test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src/third/llhttp)
    if (UA2F_ENABLE_UCI)
        target_sources(ua2f_proxy_test PRIVATE src/config.c)
        target_link_libraries(ua2f_proxy_test uci)
    endif ()

    # Listener tests run thread entry points synchronously and replace kernel,
    # sleep, and pthread creation calls with deterministic in-process fakes.
    add_executable(
            ua2f_listener_test
            test/listener_test.cc
            src/conntrack_listener.c
            src/session_cleaner.c
            src/http_session.c
    )
    target_link_libraries(
            ua2f_listener_test
            GTest::gtest_main
            pthread
    )
    target_compile_options(ua2f_listener_test PRIVATE
            $<$<COMPILE_LANGUAGE:C>:-iquote${CMAKE_CURRENT_SOURCE_DIR}/src>
            $<$<COMPILE_LANGUAGE:CXX>:-iquote${CMAKE_CURRENT_SOURCE_DIR}/src>
    )
    target_compile_definitions(ua2f_listener_test PRIVATE
            pthread_create=ua2f_test_pthread_create
            pthread_detach=ua2f_test_pthread_detach
            sleep=ua2f_test_sleep
            nfct_open=ua2f_test_nfct_open
            nfct_close=ua2f_test_nfct_close
            nfct_callback_register=ua2f_test_nfct_callback_register
            nfct_catch=ua2f_test_nfct_catch
            nfct_get_attr_u32=ua2f_test_nfct_get_attr_u32
    )

    # Runtime tests cover main-loop orchestration and error recovery without
    # opening real netlink queues or transparent proxy listeners.
    add_executable(
            ua2f_runtime_test
            test/runtime_test.cc
            src/ua2f.c
    )
    target_link_libraries(
            ua2f_runtime_test
            GTest::gtest_main
            pthread
    )
    target_compile_options(ua2f_runtime_test PRIVATE
            $<$<COMPILE_LANGUAGE:C>:-iquote${CMAKE_CURRENT_SOURCE_DIR}/src>
            $<$<COMPILE_LANGUAGE:CXX>:-iquote${CMAKE_CURRENT_SOURCE_DIR}/src>
            $<$<COMPILE_LANGUAGE:C>:-UUA2F_ENABLE_BACKTRACE>
    )
    target_compile_definitions(ua2f_runtime_test PRIVATE
            main=ua2f_entrypoint
            nfqueue_open=ua2f_test_nfqueue_open
            nfqueue_close=ua2f_test_nfqueue_close
            nfqueue_receive=ua2f_test_nfqueue_receive
            nfqueue_next=ua2f_test_nfqueue_next
            handle_packet=ua2f_test_handle_packet
            pthread_create=ua2f_test_pthread_create
            pthread_join=ua2f_test_pthread_join
            try_print_info=ua2f_test_try_print_info
            require_root=ua2f_test_require_root
            init_statistics=ua2f_test_init_statistics
            init_handler=ua2f_test_init_handler
            init_http_sessions=ua2f_test_init_http_sessions
            init_session_cleaner=ua2f_test_init_session_cleaner
            run_proxy=ua2f_test_run_proxy
            load_config=ua2f_test_load_config
    )

    if (UA2F_ENABLE_COVERAGE)
        # Keep this report in a separate Codecov flag. Adding proxy.c to the
        # established unit-test flag would create an artificial flag-level
        # regression even though the combined project coverage increases.
        add_custom_target(coverage-proxy-lcov
            COMMAND find ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/ua2f_proxy_test.dir -name "*.gcda" -delete
            COMMAND ${CMAKE_CURRENT_BINARY_DIR}/ua2f_proxy_test
            COMMAND lcov --capture --directory ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/ua2f_proxy_test.dir --output-file coverage-proxy.info --ignore-errors mismatch,inconsistent
            COMMAND lcov --extract coverage-proxy.info '*/src/proxy.c' '*/src/mode.h' --output-file coverage-proxy.info --ignore-errors unused,inconsistent
            COMMAND lcov --list coverage-proxy.info
            COMMAND lcov --capture --directory ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/ua2f_proxy_test.dir --output-file coverage-proxy-branches.info --ignore-errors mismatch,inconsistent --branch-coverage
            COMMAND lcov --extract coverage-proxy-branches.info '*/src/proxy.c' '*/src/mode.h' --output-file coverage-proxy-branches.info --ignore-errors unused,inconsistent --branch-coverage
            COMMAND lcov --list coverage-proxy-branches.info --branch-coverage
            COMMENT "Generating proxy lifecycle coverage report"
            DEPENDS ua2f_proxy_test
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        )
    endif()

    # Conditionally link libpcap for pcap-based tests
    find_library(PCAP_LIB pcap)
    if(PCAP_LIB)
        target_link_libraries(ua2f_handler_test ${PCAP_LIB})
        target_compile_definitions(ua2f_handler_test PRIVATE UA2F_HAS_PCAP=1)
        message(STATUS "libpcap found, pcap-based handler tests enabled.")
    else()
        message(STATUS "libpcap not found, pcap-based handler tests disabled.")
    endif()

    include(GoogleTest)
    gtest_discover_tests(ua2f_test)
    gtest_discover_tests(ua2f_handler_test)
    gtest_discover_tests(ua2f_proxy_test)
    gtest_discover_tests(ua2f_listener_test)
    gtest_discover_tests(ua2f_runtime_test)
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
        COMMAND lcov --capture --directory . --output-file coverage-integration.info --ignore-errors mismatch,inconsistent
        COMMAND lcov --remove coverage-integration.info '*/test/*' '*/build*/_deps/*' '/usr/*' '*/googletest/*' '*_deps/*' '*/third/*' --output-file coverage-integration.info --ignore-errors unused,inconsistent
        COMMAND lcov --list coverage-integration.info
        COMMAND lcov --capture --directory . --output-file coverage-integration-branches.info --ignore-errors mismatch,inconsistent --branch-coverage
        COMMAND lcov --remove coverage-integration-branches.info '*/test/*' '*/build*/_deps/*' '/usr/*' '*/googletest/*' '*_deps/*' '*/third/*' --output-file coverage-integration-branches.info --ignore-errors unused,inconsistent --branch-coverage
        COMMAND lcov --list coverage-integration-branches.info --branch-coverage
        COMMENT "Process integration test coverage data with lcov"
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
    
    add_custom_target(coverage-clean
        COMMAND find . -name "*.gcda" -delete
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Cleaning coverage data"
    )
endif()

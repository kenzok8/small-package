#ifdef pthread_create
#undef pthread_create
#endif
#ifdef pthread_join
#undef pthread_join
#endif

#include <gtest/gtest.h>

#include <cerrno>
#include <csignal>
#include <cstdint>
#include <cstdlib>
#include <deque>
#include <string>
#include <vector>

extern "C" {
#include <pthread.h>

#include "cli.h"
#ifdef UA2F_ENABLE_UCI
#include "config.h"
#endif
#include "handler.h"
#include "http_session.h"
#include "proxy.h"
#include "session_cleaner.h"
#include "statistics.h"
#include "util.h"
}

extern "C" {
extern volatile sig_atomic_t should_exit;

void signal_handler(int sig);
int parse_packet(const struct nf_queue *queue, struct nf_buffer *buf);
int read_buffer(struct nf_queue *queue, struct nf_buffer *buf);
bool retry_without_conntrack(struct nf_queue *queue);
void main_loop(struct nf_queue *queue);
int ua2f_entrypoint(int argc, char *argv[]);

bool cli_mode_set = false;
enum ua2f_mode cli_mode = UA2F_MODE_NFQUEUE;
bool cli_listen_port_set = false;
uint16_t cli_listen_port = UA2F_DEFAULT_PROXY_PORT;

extern const struct packet_io nfqueue_packet_io = {nullptr};

#ifdef UA2F_ENABLE_UCI
struct ua2f_config config;
#endif
}

namespace {

    std::deque<bool> queue_open_results;
    std::deque<int> receive_results;
    std::deque<int> next_results;
    int queue_open_calls;
    int queue_close_calls;
    int receive_calls;
    int next_calls;
    int handle_packet_calls;
    bool last_skip_conntrack;
    bool request_exit_on_receive;

    int pthread_create_calls;
    int pthread_join_calls;
    int pthread_failure_call;
    bool run_threads_inline;

    int try_print_info_calls;
    int require_root_calls;
    int init_statistics_calls;
    int init_handler_calls;
    int init_sessions_calls;
    int init_cleaner_calls;
    int proxy_calls;
    int proxy_result;
    enum ua2f_mode last_proxy_mode;
    uint16_t last_proxy_port;

#ifdef UA2F_ENABLE_UCI
    int load_config_calls;
#endif

    void reset_runtime_mocks() {
        queue_open_results.clear();
        receive_results.clear();
        next_results.clear();
        queue_open_calls = 0;
        queue_close_calls = 0;
        receive_calls = 0;
        next_calls = 0;
        handle_packet_calls = 0;
        last_skip_conntrack = false;
        request_exit_on_receive = false;

        pthread_create_calls = 0;
        pthread_join_calls = 0;
        pthread_failure_call = 0;
        run_threads_inline = false;

        try_print_info_calls = 0;
        require_root_calls = 0;
        init_statistics_calls = 0;
        init_handler_calls = 0;
        init_sessions_calls = 0;
        init_cleaner_calls = 0;
        proxy_calls = 0;
        proxy_result = 0;
        last_proxy_mode = UA2F_MODE_NFQUEUE;
        last_proxy_port = 0;

#ifdef UA2F_ENABLE_UCI
        load_config_calls = 0;
        config = {};
        config.mode = UA2F_MODE_NFQUEUE;
        config.listen_port = UA2F_DEFAULT_PROXY_PORT;
        config.nfqueue_workers = 1;
        config.max_http_sessions = 0;
        config.session_ttl = 300;
#endif

        should_exit = 0;
        cli_mode_set = false;
        cli_mode = UA2F_MODE_NFQUEUE;
        cli_listen_port_set = false;
        cli_listen_port = UA2F_DEFAULT_PROXY_PORT;
        unsetenv("UA2F_NFQUEUE_WORKERS");
    }

    int run_entrypoint() {
        char executable[] = "ua2f";
        char *argv[] = {executable, nullptr};
        return ua2f_entrypoint(1, argv);
    }

    class RuntimeTest : public ::testing::Test {
    protected:
        void SetUp() override { reset_runtime_mocks(); }
        void TearDown() override { unsetenv("UA2F_NFQUEUE_WORKERS"); }
    };

    TEST_F(RuntimeTest, SignalHandlerRequestsExit) {
        signal_handler(SIGTERM);
        EXPECT_EQ(should_exit, 1);
    }

    TEST_F(RuntimeTest, ParsePacketDispatchesReadyPackets) {
        struct nf_queue queue{};
        struct nf_buffer buffer{};
        next_results = {IO_READY, IO_NOTREADY};

        EXPECT_EQ(parse_packet(&queue, &buffer), IO_NOTREADY);
        EXPECT_EQ(next_calls, 2);
        EXPECT_EQ(handle_packet_calls, 1);
    }

    TEST_F(RuntimeTest, ParsePacketStopsAfterSignal) {
        struct nf_queue queue{};
        struct nf_buffer buffer{};
        should_exit = 1;

        EXPECT_EQ(parse_packet(&queue, &buffer), IO_ERROR);
        EXPECT_EQ(next_calls, 0);
    }

    TEST_F(RuntimeTest, ReadBufferPropagatesNonReadyStatus) {
        struct nf_queue queue{};
        struct nf_buffer buffer{};
        receive_results = {IO_NOTREADY};

        EXPECT_EQ(read_buffer(&queue, &buffer), IO_NOTREADY);
        EXPECT_EQ(next_calls, 0);
    }

    TEST_F(RuntimeTest, ReadBufferParsesReadyData) {
        struct nf_queue queue{};
        struct nf_buffer buffer{};
        receive_results = {IO_READY};
        next_results = {IO_ERROR};

        EXPECT_EQ(read_buffer(&queue, &buffer), IO_ERROR);
        EXPECT_EQ(receive_calls, 1);
        EXPECT_EQ(next_calls, 1);
    }

    TEST_F(RuntimeTest, RetryReopensQueueWithoutConntrack) {
        struct nf_queue queue{};
        queue.queue_num = 10012;
        queue.nl_socket = reinterpret_cast<struct mnl_socket *>(0x1000);
        queue_open_results = {true};

        EXPECT_TRUE(retry_without_conntrack(&queue));
        EXPECT_EQ(queue_close_calls, 1);
        EXPECT_EQ(queue_open_calls, 1);
        EXPECT_TRUE(last_skip_conntrack);
        EXPECT_EQ(queue.queue_num, 10012);
    }

    TEST_F(RuntimeTest, RetryReportsQueueReopenFailure) {
        struct nf_queue queue{};
        queue.queue_num = 10012;
        queue.nl_socket = reinterpret_cast<struct mnl_socket *>(0x1000);
        queue_open_results = {false};

        EXPECT_FALSE(retry_without_conntrack(&queue));
        EXPECT_EQ(queue_close_calls, 1);
    }

    TEST_F(RuntimeTest, MainLoopRetriesOnceThenStopsOnSecondError) {
        struct nf_queue queue{};
        queue.queue_num = QUEUE_NUM;
        queue.nl_socket = reinterpret_cast<struct mnl_socket *>(0x1000);
        receive_results = {IO_ERROR, IO_ERROR};
        queue_open_results = {true};

        main_loop(&queue);

        EXPECT_EQ(receive_calls, 2);
        EXPECT_EQ(queue_open_calls, 1);
        EXPECT_EQ(should_exit, 1);
    }

    TEST_F(RuntimeTest, MainLoopStopsWhenRetryFails) {
        struct nf_queue queue{};
        queue.queue_num = QUEUE_NUM;
        queue.nl_socket = reinterpret_cast<struct mnl_socket *>(0x1000);
        receive_results = {IO_ERROR};
        queue_open_results = {false};

        main_loop(&queue);

        EXPECT_EQ(receive_calls, 1);
        EXPECT_EQ(queue_open_calls, 1);
        EXPECT_EQ(should_exit, 0);
    }

    TEST_F(RuntimeTest, MainLoopStopsWithoutRetryAfterSignal) {
        struct nf_queue queue{};
        queue.queue_num = QUEUE_NUM;
        queue.nl_socket = reinterpret_cast<struct mnl_socket *>(0x1000);
        receive_results = {IO_ERROR};
        request_exit_on_receive = true;

        main_loop(&queue);

        EXPECT_EQ(receive_calls, 1);
        EXPECT_EQ(queue_open_calls, 0);
        EXPECT_EQ(should_exit, 1);
    }

    TEST_F(RuntimeTest, ProxyModeReturnsSuccess) {
        cli_mode_set = true;
        cli_mode = UA2F_MODE_REDIRECT;
        cli_listen_port_set = true;
        cli_listen_port = 12345;

        EXPECT_EQ(run_entrypoint(), EXIT_SUCCESS);
        EXPECT_EQ(proxy_calls, 1);
        EXPECT_EQ(last_proxy_mode, UA2F_MODE_REDIRECT);
        EXPECT_EQ(last_proxy_port, 12345);
    }

    TEST_F(RuntimeTest, ProxyModePropagatesFailure) {
        cli_mode_set = true;
        cli_mode = UA2F_MODE_TPROXY;
        proxy_result = -1;

        EXPECT_EQ(run_entrypoint(), EXIT_FAILURE);
        EXPECT_EQ(proxy_calls, 1);
    }

    TEST_F(RuntimeTest, RunsSingleNfqueueWorker) {
        setenv("UA2F_NFQUEUE_WORKERS", "1", 1);
        queue_open_results = {true};
        should_exit = 1;

        EXPECT_EQ(run_entrypoint(), EXIT_SUCCESS);
        EXPECT_EQ(queue_open_calls, 1);
        EXPECT_EQ(queue_close_calls, 1);
        EXPECT_EQ(pthread_create_calls, 0);
    }

    TEST_F(RuntimeTest, UsesDefaultWorkerCountWhenEnvironmentIsUnset) {
        queue_open_results = {true};
        should_exit = 1;

        EXPECT_EQ(run_entrypoint(), EXIT_SUCCESS);
        EXPECT_EQ(queue_open_calls, 1);
        EXPECT_EQ(pthread_create_calls, 0);
    }

    TEST_F(RuntimeTest, FallsBackForInvalidWorkerCount) {
        setenv("UA2F_NFQUEUE_WORKERS", "invalid", 1);
        queue_open_results = {true};
        should_exit = 1;

        EXPECT_EQ(run_entrypoint(), EXIT_SUCCESS);
        EXPECT_EQ(queue_open_calls, 1);
    }

    TEST_F(RuntimeTest, FallsBackForOverflowingWorkerCount) {
        setenv("UA2F_NFQUEUE_WORKERS", "999999999999999999999999999999", 1);
        queue_open_results = {true};
        should_exit = 1;

        EXPECT_EQ(run_entrypoint(), EXIT_SUCCESS);
        EXPECT_EQ(queue_open_calls, 1);
    }

    TEST_F(RuntimeTest, ClampsWorkerCountAndRunsWorkers) {
        setenv("UA2F_NFQUEUE_WORKERS", "999", 1);
        should_exit = 1;
        run_threads_inline = true;

        EXPECT_EQ(run_entrypoint(), EXIT_SUCCESS);
        EXPECT_EQ(queue_open_calls, 16);
        EXPECT_EQ(pthread_create_calls, 16);
        EXPECT_EQ(pthread_join_calls, 16);
        EXPECT_EQ(queue_close_calls, 16);
    }

    TEST_F(RuntimeTest, ClosesOpenedQueuesAfterPartialOpenFailure) {
        setenv("UA2F_NFQUEUE_WORKERS", "2", 1);
        queue_open_results = {true, false};

        EXPECT_EQ(run_entrypoint(), EXIT_FAILURE);
        EXPECT_EQ(queue_open_calls, 2);
        EXPECT_EQ(queue_close_calls, 1);
        EXPECT_EQ(pthread_create_calls, 0);
    }

    TEST_F(RuntimeTest, JoinsCreatedWorkersAfterThreadFailure) {
        setenv("UA2F_NFQUEUE_WORKERS", "2", 1);
        queue_open_results = {true, true};
        pthread_failure_call = 2;

        EXPECT_EQ(run_entrypoint(), EXIT_FAILURE);
        EXPECT_EQ(pthread_create_calls, 2);
        EXPECT_EQ(pthread_join_calls, 1);
        EXPECT_EQ(queue_close_calls, 2);
        EXPECT_EQ(should_exit, 1);
    }

    TEST_F(RuntimeTest, InitializesRuntimeServices) {
        cli_mode_set = true;
        cli_mode = UA2F_MODE_REDIRECT;

        EXPECT_EQ(run_entrypoint(), EXIT_SUCCESS);
        EXPECT_EQ(try_print_info_calls, 1);
        EXPECT_EQ(require_root_calls, 1);
        EXPECT_EQ(init_statistics_calls, 1);
        EXPECT_EQ(init_handler_calls, 1);
        EXPECT_EQ(init_sessions_calls, 1);
        EXPECT_EQ(init_cleaner_calls, 1);
#ifdef UA2F_ENABLE_UCI
        EXPECT_EQ(load_config_calls, 1);
#endif
    }

} // namespace

extern "C" bool ua2f_test_nfqueue_open(struct nf_queue *queue, int queue_num, uint32_t, bool skip_conntrack) {
    ++queue_open_calls;
    last_skip_conntrack = skip_conntrack;
    const bool result = queue_open_results.empty() ? true : queue_open_results.front();
    if (!queue_open_results.empty()) {
        queue_open_results.pop_front();
    }
    queue->queue_num = queue_num;
    queue->nl_socket = result ? reinterpret_cast<struct mnl_socket *>(0x1000) : nullptr;
    return result;
}

extern "C" void ua2f_test_nfqueue_close(struct nf_queue *queue) {
    ++queue_close_calls;
    queue->nl_socket = nullptr;
}

extern "C" int ua2f_test_nfqueue_receive(struct nf_queue *, struct nf_buffer *, int64_t) {
    ++receive_calls;
    if (request_exit_on_receive) {
        should_exit = 1;
    }
    if (receive_results.empty()) {
        return IO_ERROR;
    }
    const int result = receive_results.front();
    receive_results.pop_front();
    return result;
}

extern "C" int ua2f_test_nfqueue_next(struct nf_buffer *, struct nf_packet *) {
    ++next_calls;
    if (next_results.empty()) {
        return IO_NOTREADY;
    }
    const int result = next_results.front();
    next_results.pop_front();
    return result;
}

extern "C" void ua2f_test_handle_packet(const struct packet_io *, void *, const struct nf_packet *) {
    ++handle_packet_calls;
}

extern "C" int ua2f_test_pthread_create(pthread_t *thread, const pthread_attr_t *, void *(*start_routine)(void *),
                                        void *arg) {
    ++pthread_create_calls;
    if (pthread_failure_call == pthread_create_calls) {
        return EAGAIN;
    }
    *thread = pthread_self();
    if (run_threads_inline) {
        start_routine(arg);
    }
    return 0;
}

extern "C" int ua2f_test_pthread_join(pthread_t, void **) {
    ++pthread_join_calls;
    return 0;
}

extern "C" void ua2f_test_try_print_info(int, char **) { ++try_print_info_calls; }
extern "C" void ua2f_test_require_root() { ++require_root_calls; }
extern "C" void ua2f_test_init_statistics() { ++init_statistics_calls; }
extern "C" void ua2f_test_init_handler() { ++init_handler_calls; }
extern "C" void ua2f_test_init_http_sessions(int) { ++init_sessions_calls; }
extern "C" void ua2f_test_init_session_cleaner(int, int) { ++init_cleaner_calls; }

extern "C" int ua2f_test_run_proxy(enum ua2f_mode mode, uint16_t port, volatile sig_atomic_t *) {
    ++proxy_calls;
    last_proxy_mode = mode;
    last_proxy_port = port;
    return proxy_result;
}

#ifdef UA2F_ENABLE_UCI
extern "C" void ua2f_test_load_config() { ++load_config_calls; }
#endif

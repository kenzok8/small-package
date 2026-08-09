#ifdef pthread_create
#undef pthread_create
#endif
#ifdef pthread_detach
#undef pthread_detach
#endif
#ifdef sleep
#undef sleep
#endif

#include <gtest/gtest.h>

#include <cerrno>
#include <cstdint>
#include <ctime>
#include <deque>
#include <vector>

extern "C" {
#include <libnetfilter_conntrack/libnetfilter_conntrack.h>
#include <pthread.h>

#include "conntrack_listener.h"
#include "http_session.h"
#include "session_cleaner.h"
}

namespace {

    using ThreadRoutine = void *(*)(void *);
    using ConntrackCallback = int (*)(enum nf_conntrack_msg_type, struct nf_conntrack *, void *);

    int pthread_create_result;
    int pthread_create_calls;
    int pthread_detach_calls;
    ThreadRoutine captured_thread;
    void *captured_thread_arg;

    std::deque<struct nfct_handle *> open_results;
    std::deque<int> catch_results;
    int open_calls;
    int close_calls;
    int callback_register_calls;
    int catch_calls;
    int sleep_calls;
    uint32_t conntrack_id;
    ConntrackCallback captured_callback;

    struct nfct_handle *fake_handle(const uintptr_t value) { return reinterpret_cast<struct nfct_handle *>(value); }

    void reset_mocks() {
        pthread_create_result = 0;
        pthread_create_calls = 0;
        pthread_detach_calls = 0;
        captured_thread = nullptr;
        captured_thread_arg = nullptr;

        open_results.clear();
        catch_results.clear();
        open_calls = 0;
        close_calls = 0;
        callback_register_calls = 0;
        catch_calls = 0;
        sleep_calls = 0;
        conntrack_id = 0;
        captured_callback = nullptr;
    }

    class ListenerTest : public ::testing::Test {
    protected:
        void SetUp() override {
            reset_mocks();
            init_http_sessions(0);
        }

        void TearDown() override {
            session_wrlock();
            session_cleanup_expired(-1);
            session_wrunlock();
        }
    };

    TEST_F(ListenerTest, ReportsConntrackThreadCreationFailure) {
        pthread_create_result = EAGAIN;

        init_conntrack_listener();

        EXPECT_EQ(pthread_create_calls, 1);
        EXPECT_EQ(pthread_detach_calls, 0);
        EXPECT_EQ(captured_thread, nullptr);
    }

    TEST_F(ListenerTest, ExitsWhenConntrackCannotBeOpened) {
        open_results.push_back(nullptr);

        init_conntrack_listener();
        ASSERT_NE(captured_thread, nullptr);
        EXPECT_EQ(pthread_detach_calls, 1);

        EXPECT_EQ(captured_thread(captured_thread_arg), nullptr);
        EXPECT_EQ(open_calls, 1);
        EXPECT_EQ(callback_register_calls, 0);
        EXPECT_EQ(catch_calls, 0);
    }

    TEST_F(ListenerTest, ReopensAfterErrorsAndDeletesDestroyedSession) {
        open_results = {fake_handle(0x1000), fake_handle(0x2000), nullptr};
        for (int i = 0; i < 9; ++i) {
            catch_results.push_back(-1);
        }
        catch_results.push_back(0);
        for (int i = 0; i < 20; ++i) {
            catch_results.push_back(-1);
        }

        session_wrlock();
        const struct session_key key = session_key_from_connid(42);
        ASSERT_NE(session_create(&key), nullptr);
        session_wrunlock();

        init_conntrack_listener();
        ASSERT_NE(captured_thread, nullptr);
        EXPECT_EQ(captured_thread(captured_thread_arg), nullptr);

        EXPECT_EQ(open_calls, 3);
        EXPECT_EQ(close_calls, 2);
        EXPECT_EQ(callback_register_calls, 2);
        EXPECT_EQ(catch_calls, 30);
        EXPECT_EQ(sleep_calls, 28);
        ASSERT_NE(captured_callback, nullptr);

        conntrack_id = 42;
        EXPECT_EQ(captured_callback(NFCT_T_DESTROY, reinterpret_cast<struct nf_conntrack *>(0x3000), nullptr),
                  NFCT_CB_CONTINUE);
        EXPECT_EQ(session_count(), 0);
    }

    TEST_F(ListenerTest, DestroyCallbackIgnoresUnknownSession) {
        open_results = {fake_handle(0x1000), nullptr};
        for (int i = 0; i < 10; ++i) {
            catch_results.push_back(-1);
        }

        init_conntrack_listener();
        ASSERT_NE(captured_thread, nullptr);
        EXPECT_EQ(captured_thread(captured_thread_arg), nullptr);
        ASSERT_NE(captured_callback, nullptr);

        conntrack_id = 999;
        EXPECT_EQ(captured_callback(NFCT_T_DESTROY, reinterpret_cast<struct nf_conntrack *>(0x3000), nullptr),
                  NFCT_CB_CONTINUE);
        EXPECT_EQ(session_count(), 0);
    }

    TEST_F(ListenerTest, RunsSessionCleanupPass) {
        session_wrlock();
        const struct session_key expired_key = session_key_from_connid(7);
        const struct session_key active_key = session_key_from_connid(8);
        struct http_session *expired = session_create(&expired_key);
        struct http_session *active = session_create(&active_key);
        ASSERT_NE(expired, nullptr);
        ASSERT_NE(active, nullptr);
        expired->last_active = time(nullptr) - 100;
        session_wrunlock();

        EXPECT_EQ(session_cleaner_run_once(10), 1);
        EXPECT_EQ(session_cleaner_run_once(10), 0);
        EXPECT_EQ(session_count(), 1);
    }

    TEST_F(ListenerTest, ReportsCleanerThreadCreationFailure) {
        pthread_create_result = EAGAIN;

        init_session_cleaner(300, 60);

        EXPECT_EQ(pthread_create_calls, 1);
        EXPECT_EQ(pthread_detach_calls, 0);
    }

    TEST_F(ListenerTest, StartsCleanerThread) {
        init_session_cleaner(300, 60);

        EXPECT_EQ(pthread_create_calls, 1);
        EXPECT_EQ(pthread_detach_calls, 1);
        EXPECT_NE(captured_thread, nullptr);
    }

} // namespace

extern "C" int ua2f_test_pthread_create(pthread_t *thread, const pthread_attr_t *, void *(*start_routine)(void *),
                                        void *arg) {
    ++pthread_create_calls;
    if (pthread_create_result != 0) {
        return pthread_create_result;
    }
    *thread = pthread_self();
    captured_thread = start_routine;
    captured_thread_arg = arg;
    return 0;
}

extern "C" int ua2f_test_pthread_detach(pthread_t) {
    ++pthread_detach_calls;
    return 0;
}

extern "C" unsigned int ua2f_test_sleep(unsigned int) {
    ++sleep_calls;
    return 0;
}

extern "C" struct nfct_handle *ua2f_test_nfct_open(uint8_t, unsigned int) {
    ++open_calls;
    if (open_results.empty()) {
        return nullptr;
    }
    struct nfct_handle *result = open_results.front();
    open_results.pop_front();
    return result;
}

extern "C" int ua2f_test_nfct_close(struct nfct_handle *) {
    ++close_calls;
    return 0;
}

extern "C" int
ua2f_test_nfct_callback_register(struct nfct_handle *, enum nf_conntrack_msg_type,
                                 int (*callback)(enum nf_conntrack_msg_type, struct nf_conntrack *, void *), void *) {
    ++callback_register_calls;
    captured_callback = callback;
    return 0;
}

extern "C" int ua2f_test_nfct_catch(struct nfct_handle *) {
    ++catch_calls;
    if (catch_results.empty()) {
        return -1;
    }
    const int result = catch_results.front();
    catch_results.pop_front();
    return result;
}

extern "C" uint32_t ua2f_test_nfct_get_attr_u32(const struct nf_conntrack *, enum nf_conntrack_attr) {
    return conntrack_id;
}

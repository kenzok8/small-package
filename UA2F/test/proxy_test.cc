#include <gtest/gtest.h>

#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>

#include <cstdlib>
#include <string>
#include <utility>

extern "C" {
#include "proxy.h"
}

namespace {

    class ScopedProxyWorkers final {
    public:
        explicit ScopedProxyWorkers(const char *value) {
            const char *current = std::getenv("UA2F_PROXY_WORKERS");
            if (current != nullptr) {
                previous_ = current;
                had_previous_ = true;
            }
            if (value == nullptr) {
                unsetenv("UA2F_PROXY_WORKERS");
            } else {
                setenv("UA2F_PROXY_WORKERS", value, 1);
            }
        }

        ~ScopedProxyWorkers() {
            if (had_previous_) {
                setenv("UA2F_PROXY_WORKERS", previous_.c_str(), 1);
            } else {
                unsetenv("UA2F_PROXY_WORKERS");
            }
        }

        ScopedProxyWorkers(const ScopedProxyWorkers &) = delete;
        ScopedProxyWorkers &operator=(const ScopedProxyWorkers &) = delete;

    private:
        std::string previous_;
        bool had_previous_ = false;
    };

    class Socket final {
    public:
        explicit Socket(int fd = -1) : fd_(fd) {}
        ~Socket() {
            if (fd_ >= 0) {
                close(fd_);
            }
        }

        Socket(const Socket &) = delete;
        Socket &operator=(const Socket &) = delete;

        Socket(Socket &&other) noexcept : fd_(other.fd_) { other.fd_ = -1; }
        Socket &operator=(Socket &&other) noexcept {
            if (this != &other) {
                if (fd_ >= 0) {
                    close(fd_);
                }
                fd_ = other.fd_;
                other.fd_ = -1;
            }
            return *this;
        }

        int get() const { return fd_; }

    private:
        int fd_;
    };

    uint16_t occupy_dual_stack_port(Socket *ipv4, Socket *ipv6) {
        Socket v6(socket(AF_INET6, SOCK_STREAM, 0));
        if (v6.get() < 0) {
            return 0;
        }

        const int one = 1;
        if (setsockopt(v6.get(), IPPROTO_IPV6, IPV6_V6ONLY, &one, sizeof(one)) != 0) {
            return 0;
        }

        sockaddr_in6 address6{};
        address6.sin6_family = AF_INET6;
        address6.sin6_addr = in6addr_any;
        address6.sin6_port = 0;
        if (bind(v6.get(), reinterpret_cast<sockaddr *>(&address6), sizeof(address6)) != 0 ||
            listen(v6.get(), 1) != 0) {
            return 0;
        }

        socklen_t address6_len = sizeof(address6);
        if (getsockname(v6.get(), reinterpret_cast<sockaddr *>(&address6), &address6_len) != 0) {
            return 0;
        }

        Socket v4(socket(AF_INET, SOCK_STREAM, 0));
        if (v4.get() < 0) {
            return 0;
        }
        sockaddr_in address4{};
        address4.sin_family = AF_INET;
        address4.sin_addr.s_addr = htonl(INADDR_ANY);
        address4.sin_port = address6.sin6_port;
        if (bind(v4.get(), reinterpret_cast<sockaddr *>(&address4), sizeof(address4)) != 0 ||
            listen(v4.get(), 1) != 0) {
            return 0;
        }

        *ipv4 = std::move(v4);
        *ipv6 = std::move(v6);
        return ntohs(address6.sin6_port);
    }

    TEST(ProxyLifecycleTest, StartsAndStopsSingleWorker) {
        ScopedProxyWorkers workers("1");
        volatile sig_atomic_t should_exit = 1;

        EXPECT_EQ(run_proxy(UA2F_MODE_REDIRECT, 0, &should_exit), 0);
    }

    TEST(ProxyLifecycleTest, StartsAndStopsMultipleWorkers) {
        ScopedProxyWorkers workers("2");
        volatile sig_atomic_t should_exit = 1;

        EXPECT_EQ(run_proxy(UA2F_MODE_REDIRECT, 0, &should_exit), 0);
    }

    TEST(ProxyLifecycleTest, FallsBackForInvalidWorkerCount) {
        ScopedProxyWorkers workers("invalid");
        volatile sig_atomic_t should_exit = 1;

        EXPECT_EQ(run_proxy(UA2F_MODE_REDIRECT, 0, &should_exit), 0);
    }

    TEST(ProxyLifecycleTest, ClampsExcessiveWorkerCount) {
        ScopedProxyWorkers workers("999");
        volatile sig_atomic_t should_exit = 1;

        EXPECT_EQ(run_proxy(UA2F_MODE_REDIRECT, 0, &should_exit), 0);
    }

    TEST(ProxyLifecycleTest, FailsWhenBothListenerAddressesAreOccupied) {
        ScopedProxyWorkers workers("1");
        Socket ipv4;
        Socket ipv6;
        const uint16_t port = occupy_dual_stack_port(&ipv4, &ipv6);
        if (port == 0) {
            GTEST_SKIP() << "dual-stack loopback listeners are unavailable";
        }

        volatile sig_atomic_t should_exit = 1;
        EXPECT_EQ(run_proxy(UA2F_MODE_REDIRECT, port, &should_exit), -1);
    }

} // namespace

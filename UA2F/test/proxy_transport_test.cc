#include <gtest/gtest.h>

#include <arpa/inet.h>
#include <fcntl.h>
#include <netinet/tcp.h>
#include <sys/epoll.h>
#include <sys/socket.h>
#include <unistd.h>

#include <array>
#include <cerrno>
#include <chrono>
#include <cstdint>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

extern "C" {
#include "proxy_transport.h"
}

namespace {

struct Transport {
    bool tcp;
    bool splice;
};

class Socket {
public:
    ~Socket() { if (fd >= 0) close(fd); }
    int Release() { const int result = fd; fd = -1; return result; }
    int fd = -1;
};

using Clock = std::chrono::steady_clock;
using Bytes = std::vector<uint8_t>;

Bytes Payload(size_t size, uint32_t seed) {
    Bytes result(size);
    for (auto &byte : result) {
        seed = seed * 1664525U + 1013904223U;
        byte = static_cast<uint8_t>(seed >> 24);
    }
    return result;
}

uint64_t Checksum(const Bytes &bytes) {
    uint64_t result = UINT64_C(14695981039346656037);
    for (uint8_t byte : bytes) result = (result ^ byte) * UINT64_C(1099511628211);
    return result;
}

class ProxyTransportTest : public testing::TestWithParam<Transport> {
protected:
    void Pair(Socket *peer, Socket *proxy) {
        if (!GetParam().tcp) {
            int pair[2];
            ASSERT_EQ(socketpair(AF_UNIX, SOCK_STREAM, 0, pair), 0);
            peer->fd = pair[0]; proxy->fd = pair[1];
        } else {
            Socket listener;
            listener.fd = socket(AF_INET, SOCK_STREAM, 0);
            ASSERT_GE(listener.fd, 0);
            sockaddr_in address{};
            address.sin_family = AF_INET;
            address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
            ASSERT_EQ(bind(listener.fd, reinterpret_cast<sockaddr *>(&address), sizeof(address)), 0);
            ASSERT_EQ(listen(listener.fd, 1), 0);
            socklen_t length = sizeof(address);
            ASSERT_EQ(getsockname(listener.fd, reinterpret_cast<sockaddr *>(&address), &length), 0);
            peer->fd = socket(AF_INET, SOCK_STREAM, 0);
            ASSERT_GE(peer->fd, 0);
            ASSERT_EQ(connect(peer->fd, reinterpret_cast<sockaddr *>(&address), length), 0);
            proxy->fd = accept(listener.fd, nullptr, nullptr);
            ASSERT_GE(proxy->fd, 0);
            const int one = 1;
            ASSERT_EQ(setsockopt(peer->fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof(one)), 0);
            ASSERT_EQ(setsockopt(proxy->fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof(one)), 0);
        }
        for (int fd : {peer->fd, proxy->fd}) {
            const int flags = fcntl(fd, F_GETFL);
            ASSERT_GE(flags, 0);
            ASSERT_EQ(fcntl(fd, F_SETFL, flags | O_NONBLOCK), 0);
        }
    }

    void Start(bool small_outputs = false, bool target_in_progress = false) {
        Socket client_proxy, target_proxy;
        ASSERT_NO_FATAL_FAILURE(Pair(&client_, &client_proxy));
        ASSERT_NO_FATAL_FAILURE(Pair(&target_, &target_proxy));
        if (small_outputs) {
            const int small = 4096;
            for (int fd : {client_proxy.fd, target_proxy.fd}) {
                ASSERT_EQ(setsockopt(fd, SOL_SOCKET, SO_SNDBUF, &small, sizeof(small)), 0);
            }
        }
        test_.reset(proxy_test_create(client_proxy.Release(), target_proxy.Release(),
                                      GetParam().splice, target_in_progress));
        ASSERT_NE(test_, nullptr);
        ASSERT_EQ(State().splice_enabled, GetParam().splice);
    }

    proxy_test_state State() const { return proxy_test_snapshot(test_.get()); }
    int Pump(int timeout = 1) {
        const int events = proxy_test_step(test_.get(), timeout);
        EXPECT_GE(events, 0);
        return events;
    }
    void Write(int fd, const Bytes &bytes, size_t *offset) {
        if (*offset == bytes.size()) return;
        const ssize_t n = send(fd, bytes.data() + *offset, bytes.size() - *offset, MSG_NOSIGNAL);
        if (n < 0) ASSERT_TRUE(errno == EAGAIN || errno == EWOULDBLOCK) << strerror(errno);
        else { ASSERT_GT(n, 0); *offset += static_cast<size_t>(n); }
    }
    void Read(int fd, Bytes *bytes, bool *eof) {
        std::array<uint8_t, 65536> buffer{};
        for (;;) {
            const ssize_t n = recv(fd, buffer.data(), buffer.size(), 0);
            if (n < 0) {
                ASSERT_TRUE(errno == EAGAIN || errno == EWOULDBLOCK) << strerror(errno);
                return;
            }
            if (n == 0) { *eof = true; return; }
            bytes->insert(bytes->end(), buffer.begin(), buffer.begin() + n);
        }
    }
    void EqualPayload(const Bytes &expected, const Bytes &received) {
        ASSERT_EQ(received.size(), expected.size());
        EXPECT_EQ(Checksum(received), Checksum(expected));
        EXPECT_EQ(memcmp(received.data(), expected.data(), expected.size()), 0);
    }
    void Drain(int peer, const Bytes &expected) {
        Bytes received;
        bool eof = false;
        const auto deadline = Clock::now() + std::chrono::seconds(10);
        while (!eof) {
            ASSERT_LT(Clock::now(), deadline) << "timeout before EOF";
            Pump();
            ASSERT_NO_FATAL_FAILURE(Read(peer, &received, &eof));
        }
        ASSERT_NO_FATAL_FAILURE(EqualPayload(expected, received));
    }

    Socket client_, target_;
    std::unique_ptr<proxy_test_connection, decltype(&proxy_test_destroy)> test_{nullptr, proxy_test_destroy};
};

TEST_P(ProxyTransportTest, DrainsClientBytesAfterTargetHalfClose) {
    ASSERT_NO_FATAL_FAILURE(Start());
    ASSERT_EQ(shutdown(target_.fd, SHUT_WR), 0);
    const auto deadline = Clock::now() + std::chrono::seconds(10);
    while (!State().target_eof) { ASSERT_LT(Clock::now(), deadline); Pump(); }
    ASSERT_TRUE(State().client_write_shutdown);
    ASSERT_FALSE(State().client_eof);
    EXPECT_EQ(Pump(0), 0) << "a drained read side must not spin while the other side remains open";
    // Regression: master delivered only 16,384 of these 65,536 accepted bytes.
    const Bytes request = Payload(65536, 17);
    ASSERT_EQ(send(client_.fd, request.data(), request.size(), MSG_NOSIGNAL), static_cast<ssize_t>(request.size()));
    ASSERT_EQ(shutdown(client_.fd, SHUT_WR), 0);
    ASSERT_NO_FATAL_FAILURE(Drain(target_.fd, request));
    EXPECT_TRUE(State().closing);
    EXPECT_TRUE(State().client_eof);
}

TEST_P(ProxyTransportTest, DrainsTargetBytesAfterClientHalfClose) {
    ASSERT_NO_FATAL_FAILURE(Start());
    ASSERT_EQ(shutdown(client_.fd, SHUT_WR), 0);
    const auto deadline = Clock::now() + std::chrono::seconds(10);
    while (!State().client_eof) { ASSERT_LT(Clock::now(), deadline); Pump(); }
    ASSERT_TRUE(State().target_write_shutdown);
    EXPECT_EQ(Pump(0), 0) << "a drained read side must not spin while the other side remains open";
    const Bytes response = Payload(65536, 71);
    ASSERT_EQ(send(target_.fd, response.data(), response.size(), MSG_NOSIGNAL), static_cast<ssize_t>(response.size()));
    ASSERT_EQ(shutdown(target_.fd, SHUT_WR), 0);
    ASSERT_NO_FATAL_FAILURE(Drain(client_.fd, response));
    EXPECT_TRUE(State().closing);
    EXPECT_TRUE(State().target_eof);
}

TEST_P(ProxyTransportTest, RegistersClientAfterTargetConnectThenDrainsHalfClosedInput) {
    // An already-connected TCP/socketpair endpoint makes connect completion
    // deterministic while exercising the production deferred-registration path.
    ASSERT_NO_FATAL_FAILURE(Start(false, true));
    ASSERT_FALSE(State().target_connected);
    ASSERT_FALSE(State().client_registered);
    ASSERT_TRUE(State().target_registered);
    ASSERT_EQ(State().target_events, static_cast<uint32_t>(EPOLLOUT));
    const Bytes request = Payload(65536, 101);
    ASSERT_EQ(send(client_.fd, request.data(), request.size(), MSG_NOSIGNAL), static_cast<ssize_t>(request.size()));
    ASSERT_EQ(shutdown(client_.fd, SHUT_WR), 0);
    ASSERT_EQ(shutdown(target_.fd, SHUT_WR), 0);
    ASSERT_NO_FATAL_FAILURE(Drain(target_.fd, request));
    EXPECT_TRUE(State().target_connected);
    EXPECT_TRUE(State().closing);
}

TEST_P(ProxyTransportTest, DrainsPayloadsWhenBothPeersHalfCloseBeforeAnyDispatch) {
    ASSERT_NO_FATAL_FAILURE(Start(true));
    const Bytes request = Payload(65536, 113), response = Payload(65536, 127);
    ASSERT_EQ(send(client_.fd, request.data(), request.size(), MSG_NOSIGNAL), static_cast<ssize_t>(request.size()));
    ASSERT_EQ(send(target_.fd, response.data(), response.size(), MSG_NOSIGNAL), static_cast<ssize_t>(response.size()));
    // Both FINs are queued before the proxy processes either direction.
    ASSERT_EQ(shutdown(client_.fd, SHUT_WR), 0);
    ASSERT_EQ(shutdown(target_.fd, SHUT_WR), 0);
    Bytes received_request, received_response;
    bool request_eof = false, response_eof = false;
    const auto deadline = Clock::now() + std::chrono::seconds(10);
    while (!request_eof || !response_eof) {
        ASSERT_LT(Clock::now(), deadline);
        Pump();
        ASSERT_NO_FATAL_FAILURE(Read(target_.fd, &received_request, &request_eof));
        ASSERT_NO_FATAL_FAILURE(Read(client_.fd, &received_response, &response_eof));
    }
    ASSERT_NO_FATAL_FAILURE(EqualPayload(request, received_request));
    ASSERT_NO_FATAL_FAILURE(EqualPayload(response, received_response));
    EXPECT_TRUE(State().closing);
}

TEST_P(ProxyTransportTest, DrainsBothDirectionsAfterSimultaneousHalfCloseWithBackpressure) {
    ASSERT_NO_FATAL_FAILURE(Start(true));
    const Bytes request = Payload(1048613, 131), response = Payload(1048627, 197);
    Bytes received_request, received_response;
    size_t request_sent = 0, response_sent = 0;
    bool request_shutdown = false, response_shutdown = false;
    bool request_eof = false, response_eof = false;
    bool request_blocked = false, response_blocked = false;
    const auto deadline = Clock::now() + std::chrono::seconds(15);
    while (!request_eof || !response_eof) {
        ASSERT_LT(Clock::now(), deadline) << "duplex transfer stalled";
        ASSERT_NO_FATAL_FAILURE(Write(client_.fd, request, &request_sent));
        ASSERT_NO_FATAL_FAILURE(Write(target_.fd, response, &response_sent));
        if (request_sent == request.size() && !request_shutdown) {
            ASSERT_EQ(shutdown(client_.fd, SHUT_WR), 0); request_shutdown = true;
        }
        if (response_sent == response.size() && !response_shutdown) {
            ASSERT_EQ(shutdown(target_.fd, SHUT_WR), 0); response_shutdown = true;
        }
        Pump();
        const auto state = State();
        request_blocked |= state.request_pending > 0;
        response_blocked |= state.response_pending > 0 || state.splice_pending > 0;
        if (state.request_pending > 0) EXPECT_FALSE(state.target_write_shutdown);
        if (state.response_pending > 0 || state.splice_pending > 0) EXPECT_FALSE(state.client_write_shutdown);
        // Pause both applications until both forwarding directions are blocked.
        if (request_blocked && response_blocked) {
            ASSERT_NO_FATAL_FAILURE(Read(target_.fd, &received_request, &request_eof));
            ASSERT_NO_FATAL_FAILURE(Read(client_.fd, &received_response, &response_eof));
        }
    }
    EXPECT_TRUE(request_blocked);
    EXPECT_TRUE(response_blocked);
    ASSERT_NO_FATAL_FAILURE(EqualPayload(request, received_request));
    ASSERT_NO_FATAL_FAILURE(EqualPayload(response, received_response));
    EXPECT_TRUE(State().closing);
    EXPECT_EQ(State().request_pending, 0U);
    EXPECT_EQ(State().response_pending, 0U);
    EXPECT_EQ(State().splice_pending, 0U);
}

// UNIX sockets make send-buffer backpressure deterministic, without relying on
// TCP delayed ACK timing. The TCP variants above exercise the real HUP flags.
TEST_P(ProxyTransportTest, PausesHungUpBlockedInputAndReaddsItAfterOutputProgress) {
    if (GetParam().tcp) GTEST_SKIP() << "deterministic socket-buffer pressure uses UNIX sockets";
    ASSERT_NO_FATAL_FAILURE(Start(true));
    ASSERT_EQ(shutdown(target_.fd, SHUT_WR), 0);
    const auto deadline = Clock::now() + std::chrono::seconds(10);
    while (!State().target_eof) { ASSERT_LT(Clock::now(), deadline); Pump(); }
    const Bytes request = Payload(65536, 263);
    ASSERT_EQ(send(client_.fd, request.data(), request.size(), MSG_NOSIGNAL), static_cast<ssize_t>(request.size()));
    ASSERT_EQ(shutdown(client_.fd, SHUT_WR), 0);
    for (int i = 0; i < 100 && State().client_registered; i++) Pump();
    ASSERT_GT(State().request_pending, 0U);
    ASSERT_FALSE(State().client_eof);
    ASSERT_FALSE(State().client_registered);
    ASSERT_FALSE(State().target_write_shutdown);
    EXPECT_EQ(Pump(0), 0) << "HUP must not repeatedly wake a blocked source";
    ASSERT_NO_FATAL_FAILURE(Drain(target_.fd, request));
    EXPECT_TRUE(State().closing);
}

TEST_P(ProxyTransportTest, DoesNotPollReadHalfCloseWhileResponseOutputIsBlocked) {
    if (GetParam().tcp) GTEST_SKIP() << "deterministic socket-buffer pressure uses UNIX sockets";
    ASSERT_NO_FATAL_FAILURE(Start(true));
    ASSERT_EQ(shutdown(client_.fd, SHUT_WR), 0);
    const auto deadline = Clock::now() + std::chrono::seconds(10);
    while (!State().client_eof) { ASSERT_LT(Clock::now(), deadline); Pump(); }
    const Bytes response = Payload(65536, 331);
    ASSERT_EQ(send(target_.fd, response.data(), response.size(), MSG_NOSIGNAL), static_cast<ssize_t>(response.size()));
    ASSERT_EQ(shutdown(target_.fd, SHUT_WR), 0);
    for (int i = 0; i < 100; i++) { if (Pump(0) == 0) break; }
    const auto state = State();
    ASSERT_GT(state.response_pending + state.splice_pending, 0U);
    ASSERT_FALSE(state.client_write_shutdown);
    ASSERT_TRUE(state.client_registered);
    EXPECT_EQ(state.client_events, static_cast<uint32_t>(EPOLLOUT));
    EXPECT_EQ(Pump(0), 0) << "RDHUP must not wake a read-complete socket waiting to write";
    ASSERT_NO_FATAL_FAILURE(Drain(client_.fd, response));
    EXPECT_TRUE(State().closing);
}

TEST_P(ProxyTransportTest, ClosesCleanlyOnTargetReset) {
    if (!GetParam().tcp) GTEST_SKIP() << "TCP reset semantics require TCP sockets";
    ASSERT_NO_FATAL_FAILURE(Start(true));
    const linger reset{1, 0};
    ASSERT_EQ(setsockopt(target_.fd, SOL_SOCKET, SO_LINGER, &reset, sizeof(reset)), 0);
    ASSERT_EQ(close(target_.Release()), 0);
    const auto deadline = Clock::now() + std::chrono::seconds(10);
    while (!State().closing) { ASSERT_LT(Clock::now(), deadline); Pump(); }
    EXPECT_EQ(Pump(0), 0);
}

INSTANTIATE_TEST_SUITE_P(BufferedAndSplice, ProxyTransportTest,
                        testing::Values(Transport{true, false}, Transport{true, true},
                                        Transport{false, false}, Transport{false, true}),
                        [](const testing::TestParamInfo<Transport> &info) {
                            return std::string(info.param.tcp ? "Tcp" : "Unix") +
                                   (info.param.splice ? "Splice" : "Buffered");
                        });

} // namespace

#include <gtest/gtest.h>
#include <cstring>
#include <string>

extern "C" {
#include "handler.h"
#include "cache.h"
#include "http_session.h"
#include "http_parser_ua.h"
#include "statistics.h"
}

#include "mock_packet_io.h"
#include "packet_builder.h"

class HandlerTest : public ::testing::Test {
protected:
    mock_io_context mock_ctx;

    void SetUp() override {
        init_not_http_cache(60);
        init_handler();
        init_http_sessions(0);
        init_statistics();
        use_conntrack = false;
    }

    void TearDown() override {
        // Clean up sessions
        session_wrlock();
        session_cleanup_expired(-1);
        session_wrunlock();
    }

    // Helper: build an IPv4 HTTP packet with given payload
    struct nf_packet make_http_packet(const char *http_data, uint32_t pkt_id = 1) {
        auto raw = build_ipv4_tcp_packet(
            htonl(0x0a000001), htonl(0x0a000002),
            12345, 80,
            http_data, strlen(http_data));
        return make_nf_packet(raw, pkt_id, IPV4);
    }

    // Helper: build an IPv4 HTTP packet with conntrack
    struct nf_packet make_http_packet_ct(const char *http_data, uint32_t pkt_id = 1,
                                          uint32_t conn_id = 100) {
        auto raw = build_ipv4_tcp_packet(
            htonl(0x0a000001), htonl(0x0a000002),
            12345, 80,
            http_data, strlen(http_data));
        return make_nf_packet_with_conntrack(raw, pkt_id, IPV4, conn_id,
                                              htonl(0x0a000001), htonl(0x0a000002), 12345, 80);
    }
};

// 1. HTTP GET with User-Agent → NF_ACCEPT, UA replaced
TEST_F(HandlerTest, HttpGetWithUserAgent) {
    const char *req = "GET / HTTP/1.1\r\nHost: example.com\r\nUser-Agent: Mozilla/5.0\r\n\r\n";
    auto pkt = make_http_packet(req);

    handle_packet(&mock_packet_io, &mock_ctx, &pkt);

    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    EXPECT_EQ(mock_ctx.verdicts[0].verdict, NF_ACCEPT);
    EXPECT_FALSE(mock_ctx.verdicts[0].mangled_data.empty());

    // Extract TCP payload from mangled data and verify UA was replaced
    auto payload = extract_tcp_payload(mock_ctx.verdicts[0].mangled_data, IPV4);
    ASSERT_FALSE(payload.empty());
    std::string payload_str(payload.begin(), payload.end());

    // The original "Mozilla/5.0" (11 chars) should be replaced with "FFFFFFFFFFF"
    EXPECT_NE(payload_str.find("FFFFFFFFFFF"), std::string::npos);
    EXPECT_EQ(payload_str.find("Mozilla/5.0"), std::string::npos);
}

// 2. HTTP GET without User-Agent → NF_ACCEPT, mangled data present (packet still sent back)
TEST_F(HandlerTest, HttpGetWithoutUserAgent) {
    const char *req = "GET / HTTP/1.1\r\nHost: example.com\r\n\r\n";
    auto pkt = make_http_packet(req);

    handle_packet(&mock_packet_io, &mock_ctx, &pkt);

    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    EXPECT_EQ(mock_ctx.verdicts[0].verdict, NF_ACCEPT);
}

// 3. Non-HTTP traffic → NF_ACCEPT, no mangling
TEST_F(HandlerTest, NonHttpTraffic) {
    const char *data = "\x16\x03\x01\x02\x00\x01\x00"; // TLS ClientHello-like
    auto raw = build_ipv4_tcp_packet(
        htonl(0x0a000001), htonl(0x0a000002),
        12345, 443,
        data, 7);
    auto pkt = make_nf_packet(raw, 1, IPV4);

    handle_packet(&mock_packet_io, &mock_ctx, &pkt);

    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    EXPECT_EQ(mock_ctx.verdicts[0].verdict, NF_ACCEPT);
    EXPECT_FALSE(mock_ctx.verdicts[0].mark.should_set);
}

// 4. Empty TCP payload (ACK) → NF_ACCEPT
TEST_F(HandlerTest, EmptyTcpPayload) {
    auto raw = build_ipv4_tcp_packet(
        htonl(0x0a000001), htonl(0x0a000002),
        12345, 80,
        nullptr, 0);
    auto pkt = make_nf_packet(raw, 1, IPV4);

    handle_packet(&mock_packet_io, &mock_ctx, &pkt);

    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    EXPECT_EQ(mock_ctx.verdicts[0].verdict, NF_ACCEPT);
}

// 5. IPv6 HTTP with User-Agent → NF_ACCEPT, mangled
TEST_F(HandlerTest, Ipv6HttpWithUserAgent) {
    const char *req = "GET / HTTP/1.1\r\nHost: example.com\r\nUser-Agent: TestBrowser\r\n\r\n";

    struct in6_addr src = IN6ADDR_LOOPBACK_INIT;
    struct in6_addr dst = IN6ADDR_LOOPBACK_INIT;
    // Make them different
    dst.s6_addr[15] = 2;

    auto raw = build_ipv6_tcp_packet(src, dst, 12345, 80, req, strlen(req));
    auto pkt = make_nf_packet(raw, 1, IPV6);

    handle_packet(&mock_packet_io, &mock_ctx, &pkt);

    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    EXPECT_EQ(mock_ctx.verdicts[0].verdict, NF_ACCEPT);
    EXPECT_FALSE(mock_ctx.verdicts[0].mangled_data.empty());

    auto payload = extract_tcp_payload(mock_ctx.verdicts[0].mangled_data, IPV6);
    std::string payload_str(payload.begin(), payload.end());
    EXPECT_EQ(payload_str.find("TestBrowser"), std::string::npos);
}

// 6. UA replacement preserves payload length
TEST_F(HandlerTest, UaReplacementPreservesLength) {
    const char *req = "GET / HTTP/1.1\r\nHost: example.com\r\nUser-Agent: MyCustomAgent/1.0\r\n\r\n";
    auto raw_original = build_ipv4_tcp_packet(
        htonl(0x0a000001), htonl(0x0a000002),
        12345, 80,
        req, strlen(req));
    auto pkt = make_nf_packet(raw_original, 1, IPV4);

    handle_packet(&mock_packet_io, &mock_ctx, &pkt);

    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    EXPECT_EQ(mock_ctx.verdicts[0].mangled_data.size(), raw_original.size());
}

// 7. Pipelined requests → both UAs mangled
TEST_F(HandlerTest, PipelinedRequests) {
    std::string req =
        "GET /page1 HTTP/1.1\r\nHost: example.com\r\nUser-Agent: Agent1\r\n\r\n"
        "GET /page2 HTTP/1.1\r\nHost: example.com\r\nUser-Agent: Agent2\r\n\r\n";
    auto pkt = make_http_packet(req.c_str());

    handle_packet(&mock_packet_io, &mock_ctx, &pkt);

    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    EXPECT_EQ(mock_ctx.verdicts[0].verdict, NF_ACCEPT);
    EXPECT_FALSE(mock_ctx.verdicts[0].mangled_data.empty());

    auto payload = extract_tcp_payload(mock_ctx.verdicts[0].mangled_data, IPV4);
    std::string payload_str(payload.begin(), payload.end());
    EXPECT_EQ(payload_str.find("Agent1"), std::string::npos);
    EXPECT_EQ(payload_str.find("Agent2"), std::string::npos);
}

// 8. Conntrack: cached destination → CONNMARK_NOT_HTTP, skip processing
TEST_F(HandlerTest, ConntrackCachedDestination) {
    use_conntrack = true;

    // First, send a non-HTTP packet to cache the destination
    const char *data = "\x16\x03\x01\x02\x00\x01\x00";
    auto raw = build_ipv4_tcp_packet(
        htonl(0x0a000001), htonl(0x0a000002),
        12345, 443,
        data, 7);
    auto pkt1 = make_nf_packet_with_conntrack(raw, 1, IPV4, 100,
                                               htonl(0x0a000001), htonl(0x0a000002), 12345, 443);
    handle_packet(&mock_packet_io, &mock_ctx, &pkt1);

    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    EXPECT_EQ(mock_ctx.verdicts[0].mark.should_set, true);
    EXPECT_EQ(mock_ctx.verdicts[0].mark.mark, (uint32_t)CONNMARK_NOT_HTTP);

    // Second packet to same destination should hit cache
    mock_ctx.verdicts.clear();
    auto raw2 = build_ipv4_tcp_packet(
        htonl(0x0a000001), htonl(0x0a000002),
        12346, 443,
        data, 7);
    auto pkt2 = make_nf_packet_with_conntrack(raw2, 2, IPV4, 101,
                                               htonl(0x0a000001), htonl(0x0a000002), 12346, 443);
    handle_packet(&mock_packet_io, &mock_ctx, &pkt2);

    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    EXPECT_TRUE(mock_ctx.verdicts[0].mark.should_set);
    EXPECT_EQ(mock_ctx.verdicts[0].mark.mark, (uint32_t)CONNMARK_NOT_HTTP);

    use_conntrack = false;
}

// 9. Conntrack: new HTTP → CONNMARK_HTTP
TEST_F(HandlerTest, ConntrackNewHttp) {
    use_conntrack = true;

    const char *req = "GET / HTTP/1.1\r\nHost: example.com\r\nUser-Agent: TestAgent\r\n\r\n";
    auto pkt = make_http_packet_ct(req, 1, 200);

    handle_packet(&mock_packet_io, &mock_ctx, &pkt);

    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    EXPECT_EQ(mock_ctx.verdicts[0].verdict, NF_ACCEPT);
    EXPECT_TRUE(mock_ctx.verdicts[0].mark.should_set);
    EXPECT_EQ(mock_ctx.verdicts[0].mark.mark, (uint32_t)CONNMARK_HTTP);

    use_conntrack = false;
}

// 10. Conntrack: non-HTTP → CONNMARK_NOT_HTTP, added to cache
TEST_F(HandlerTest, ConntrackNonHttp) {
    use_conntrack = true;

    const char *data = "\x16\x03\x01\x02\x00\x01\x00";
    auto raw = build_ipv4_tcp_packet(
        htonl(0x0a000001), htonl(0x0a000003),
        12345, 8443,
        data, 7);
    auto pkt = make_nf_packet_with_conntrack(raw, 1, IPV4, 300,
                                              htonl(0x0a000001), htonl(0x0a000003), 12345, 8443);
    handle_packet(&mock_packet_io, &mock_ctx, &pkt);

    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    EXPECT_TRUE(mock_ctx.verdicts[0].mark.should_set);
    EXPECT_EQ(mock_ctx.verdicts[0].mark.mark, (uint32_t)CONNMARK_NOT_HTTP);

    use_conntrack = false;
}

// 11. Session limit → NF_DROP
TEST_F(HandlerTest, SessionLimitDrop) {
    // Reinit with limit of 1 session
    init_http_sessions(1);

    const char *req1 = "GET /1 HTTP/1.1\r\nHost: a.com\r\nUser-Agent: A\r\n\r\n";
    auto raw1 = build_ipv4_tcp_packet(
        htonl(0x0a000001), htonl(0x0a000002),
        10001, 80,
        req1, strlen(req1));
    auto pkt1 = make_nf_packet(raw1, 1, IPV4);
    handle_packet(&mock_packet_io, &mock_ctx, &pkt1);
    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    EXPECT_EQ(mock_ctx.verdicts[0].verdict, NF_ACCEPT);

    // Second session from different source should be dropped
    const char *req2 = "GET /2 HTTP/1.1\r\nHost: b.com\r\nUser-Agent: B\r\n\r\n";
    auto raw2 = build_ipv4_tcp_packet(
        htonl(0x0a000003), htonl(0x0a000004),
        10002, 80,
        req2, strlen(req2));
    auto pkt2 = make_nf_packet(raw2, 2, IPV4);
    handle_packet(&mock_packet_io, &mock_ctx, &pkt2);

    ASSERT_EQ(mock_ctx.verdicts.size(), 2u);
    EXPECT_EQ(mock_ctx.verdicts[1].verdict, NF_DROP);

    // Reset to unlimited
    init_http_sessions(0);
}

// 12. Parse error mid-session → session deleted, NF_ACCEPT
TEST_F(HandlerTest, ParseErrorMidSession) {
    // Send valid HTTP first to create a session
    const char *req = "GET / HTTP/1.1\r\nHost: example.com\r\nUser-Agent: Test\r\n\r\n";
    auto pkt1 = make_http_packet(req, 1);
    handle_packet(&mock_packet_io, &mock_ctx, &pkt1);
    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    EXPECT_EQ(mock_ctx.verdicts[0].verdict, NF_ACCEPT);

    // Send garbage on same connection to trigger parse error
    // Use same src/dst so it maps to the same session
    const char *garbage = "INVALID GARBAGE DATA\r\n\r\n";
    auto raw2 = build_ipv4_tcp_packet(
        htonl(0x0a000001), htonl(0x0a000002),
        12345, 80,
        garbage, strlen(garbage));
    auto pkt2 = make_nf_packet(raw2, 2, IPV4);
    handle_packet(&mock_packet_io, &mock_ctx, &pkt2);

    ASSERT_EQ(mock_ctx.verdicts.size(), 2u);
    EXPECT_EQ(mock_ctx.verdicts[1].verdict, NF_ACCEPT);
}

// 13. HTTP POST with User-Agent
TEST_F(HandlerTest, HttpPostWithUserAgent) {
    const char *req = "POST /api HTTP/1.1\r\nHost: example.com\r\nUser-Agent: curl/7.68.0\r\nContent-Length: 0\r\n\r\n";
    auto pkt = make_http_packet(req);

    handle_packet(&mock_packet_io, &mock_ctx, &pkt);

    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    EXPECT_EQ(mock_ctx.verdicts[0].verdict, NF_ACCEPT);
    EXPECT_FALSE(mock_ctx.verdicts[0].mangled_data.empty());

    auto payload = extract_tcp_payload(mock_ctx.verdicts[0].mangled_data, IPV4);
    std::string payload_str(payload.begin(), payload.end());
    EXPECT_EQ(payload_str.find("curl/7.68.0"), std::string::npos);
}

// 14. Unknown hw_protocol → NF_ACCEPT, no mark
TEST_F(HandlerTest, UnknownHwProtocol) {
    const char *data = "some payload data";
    auto raw = build_ipv4_tcp_packet(
        htonl(0x0a000001), htonl(0x0a000002),
        12345, 80,
        data, strlen(data));
    auto pkt = make_nf_packet(raw, 1, IPV4);
    // Set hw_protocol to something unknown (not ETH_P_IP or ETH_P_IPV6)
    pkt.hw_protocol = 0x9999;

    handle_packet(&mock_packet_io, &mock_ctx, &pkt);

    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    EXPECT_EQ(mock_ctx.verdicts[0].verdict, NF_ACCEPT);
    EXPECT_FALSE(mock_ctx.verdicts[0].mark.should_set);
}

// 15. Conntrack parse error → cache + CONNMARK_NOT_HTTP
TEST_F(HandlerTest, ConntrackParseError) {
    use_conntrack = true;

    // First packet: valid HTTP to create a session
    const char *req = "GET / HTTP/1.1\r\nHost: example.com\r\nUser-Agent: Test\r\n\r\n";
    auto pkt1 = make_http_packet_ct(req, 1, 500);
    handle_packet(&mock_packet_io, &mock_ctx, &pkt1);
    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    EXPECT_EQ(mock_ctx.verdicts[0].verdict, NF_ACCEPT);

    // Second packet: garbage on same conntrack session → parse error
    const char *garbage = "INVALID GARBAGE DATA\r\n\r\n";
    auto raw2 = build_ipv4_tcp_packet(
        htonl(0x0a000001), htonl(0x0a000002),
        12345, 80,
        garbage, strlen(garbage));
    auto pkt2 = make_nf_packet_with_conntrack(raw2, 2, IPV4, 500,
                                               htonl(0x0a000001), htonl(0x0a000002), 12345, 80);
    handle_packet(&mock_packet_io, &mock_ctx, &pkt2);

    ASSERT_EQ(mock_ctx.verdicts.size(), 2u);
    EXPECT_EQ(mock_ctx.verdicts[1].verdict, NF_ACCEPT);
    EXPECT_TRUE(mock_ctx.verdicts[1].mark.should_set);
    EXPECT_EQ(mock_ctx.verdicts[1].mark.mark, (uint32_t)CONNMARK_NOT_HTTP);

    use_conntrack = false;
}

// 16. Conntrack non-HTTP first packet → cache + CONNMARK_NOT_HTTP
TEST_F(HandlerTest, ConntrackNonHttpFirstPacket) {
    use_conntrack = true;

    // Non-HTTP binary data on a new connection with conntrack
    const char *binary = "\x00\x01\x02\x03\x04\x05\x06\x07";
    auto raw = build_ipv4_tcp_packet(
        htonl(0x0a000001), htonl(0x0a000005),
        50000, 9999,
        binary, 8);
    auto pkt = make_nf_packet_with_conntrack(raw, 1, IPV4, 600,
                                              htonl(0x0a000001), htonl(0x0a000005), 50000, 9999);
    handle_packet(&mock_packet_io, &mock_ctx, &pkt);

    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    EXPECT_EQ(mock_ctx.verdicts[0].verdict, NF_ACCEPT);
    EXPECT_TRUE(mock_ctx.verdicts[0].mark.should_set);
    EXPECT_EQ(mock_ctx.verdicts[0].mark.mark, (uint32_t)CONNMARK_NOT_HTTP);

    use_conntrack = false;
}

// 17. Existing session second packet → no CONNMARK_HTTP (not new)
TEST_F(HandlerTest, ConntrackExistingSessionNoMark) {
    use_conntrack = true;

    // Use unique IPs/ports to avoid collisions with other tests
    uint32_t src = htonl(0x0a0a0001);
    uint32_t dst = htonl(0x0a0a0002);

    // First packet creates session → CONNMARK_HTTP
    const char *req1 = "GET /1 HTTP/1.1\r\nHost: x.com\r\nUser-Agent: A\r\n\r\n";
    auto raw1 = build_ipv4_tcp_packet(src, dst, 60001, 80, req1, strlen(req1));
    auto pkt1 = make_nf_packet_with_conntrack(raw1, 1, IPV4, 700, src, dst, 60001, 80);
    handle_packet(&mock_packet_io, &mock_ctx, &pkt1);
    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    EXPECT_TRUE(mock_ctx.verdicts[0].mark.should_set);
    EXPECT_EQ(mock_ctx.verdicts[0].mark.mark, (uint32_t)CONNMARK_HTTP);

    // Second packet on same conntrack session → no mark (not new)
    const char *req2 = "GET /2 HTTP/1.1\r\nHost: x.com\r\nUser-Agent: B\r\n\r\n";
    auto raw2 = build_ipv4_tcp_packet(src, dst, 60001, 80, req2, strlen(req2));
    auto pkt2 = make_nf_packet_with_conntrack(raw2, 2, IPV4, 700, src, dst, 60001, 80);
    handle_packet(&mock_packet_io, &mock_ctx, &pkt2);

    ASSERT_EQ(mock_ctx.verdicts.size(), 2u);
    EXPECT_FALSE(mock_ctx.verdicts[1].mark.should_set);

    use_conntrack = false;
}

TEST_F(HandlerTest, CrossPacketUserAgentUsesReplacementOffset) {
    char *replacement = const_cast<char *>(get_replacement_user_agent_string());
    ASSERT_NE(replacement, nullptr);
    for (size_t i = 0; i < 64; i++) {
        replacement[i] = static_cast<char>('A' + (i % 26));
    }

    const char *pkt1_data = "GET / HTTP/1.1\r\nUser-Agent: Mozilla/5.";
    auto pkt1 = make_http_packet(pkt1_data, 1);
    handle_packet(&mock_packet_io, &mock_ctx, &pkt1);

    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    auto payload1 = extract_tcp_payload(mock_ctx.verdicts[0].mangled_data, IPV4);
    std::string payload1_str(payload1.begin(), payload1.end());
    EXPECT_NE(payload1_str.find("ABCDEFGHIJ"), std::string::npos);
    EXPECT_EQ(payload1_str.find("Mozilla/5."), std::string::npos);

    const char *pkt2_data = "0 (Windows)\r\n\r\n";
    auto pkt2 = make_http_packet(pkt2_data, 2);
    handle_packet(&mock_packet_io, &mock_ctx, &pkt2);

    ASSERT_EQ(mock_ctx.verdicts.size(), 2u);
    auto payload2 = extract_tcp_payload(mock_ctx.verdicts[1].mangled_data, IPV4);
    std::string payload2_str(payload2.begin(), payload2.end());
    EXPECT_NE(payload2_str.find("KLMNOPQRSTU"), std::string::npos);
    EXPECT_EQ(payload2_str.find("0 (Windows)"), std::string::npos);
}

TEST_F(HandlerTest, MalformedIpv4StillSendsVerdict) {
    std::vector<uint8_t> raw = {0x45};
    auto pkt = make_nf_packet(raw, 99, IPV4);

    handle_packet(&mock_packet_io, &mock_ctx, &pkt);

    ASSERT_EQ(mock_ctx.verdicts.size(), 1u);
    EXPECT_EQ(mock_ctx.verdicts[0].verdict, NF_ACCEPT);
    EXPECT_TRUE(mock_ctx.verdicts[0].mangled_data.empty());
}

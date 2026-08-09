#include <gtest/gtest.h>

#include <fstream>
#include <string>

#include <stdlib.h>
#include <string.h>
#include <unistd.h>

extern "C" {
#include <config.h>
}

class ConfigTest : public ::testing::Test {
protected:
    void SetUp() override {
        char path[] = "/tmp/ua2f-config-test-XXXXXX";
        const char *created = mkdtemp(path);
        ASSERT_NE(created, nullptr);
        config_dir = created;
        config_path = config_dir + "/ua2f";
        free_config();
    }

    void TearDown() override {
        free_config();
        unlink(config_path.c_str());
        rmdir(config_dir.c_str());
    }

    void WriteConfig(const std::string &contents) const {
        std::ofstream output(config_path);
        ASSERT_TRUE(output.is_open());
        output << contents;
        output.close();
        ASSERT_TRUE(output.good());
    }

    std::string config_dir;
    std::string config_path;
};

TEST_F(ConfigTest, LoadsEverySupportedMainOption) {
    WriteConfig(R"(
config ua2f 'main'
    option custom_ua 'Test UA/1.0'
    option disable_connmark '1'
    option max_http_sessions '42'
    option session_ttl '15'
    option mode 'TPROXY'
    option listen_port '12345'
    option nfqueue_workers '4'
    option proxy_workers '3'
)");

    ASSERT_TRUE(load_config_from_dir(config_dir.c_str()));
    EXPECT_TRUE(config.use_custom_ua);
    ASSERT_NE(config.custom_ua, nullptr);
    EXPECT_STREQ(config.custom_ua, "Test UA/1.0");
    EXPECT_TRUE(config.disable_connmark);
    EXPECT_EQ(config.max_http_sessions, 42);
    EXPECT_EQ(config.session_ttl, 15);
    EXPECT_EQ(config.mode, UA2F_MODE_TPROXY);
    EXPECT_EQ(config.listen_port, 12345);
    EXPECT_EQ(config.nfqueue_workers, 4);
    EXPECT_EQ(config.proxy_workers, 3);
}

TEST_F(ConfigTest, InvalidValuesKeepDefaults) {
    WriteConfig(R"(
config ua2f 'main'
    option max_http_sessions '-1'
    option session_ttl '0'
    option mode 'invalid'
    option listen_port '70000'
    option nfqueue_workers '17'
    option proxy_workers '-1'
)");

    ASSERT_TRUE(load_config_from_dir(config_dir.c_str()));
    EXPECT_FALSE(config.use_custom_ua);
    EXPECT_EQ(config.custom_ua, nullptr);
    EXPECT_FALSE(config.disable_connmark);
    EXPECT_EQ(config.max_http_sessions, 0);
    EXPECT_EQ(config.session_ttl, 300);
    EXPECT_EQ(config.mode, UA2F_MODE_NFQUEUE);
    EXPECT_EQ(config.listen_port, UA2F_DEFAULT_PROXY_PORT);
    EXPECT_EQ(config.nfqueue_workers, 1);
    EXPECT_EQ(config.proxy_workers, 0);
}

TEST_F(ConfigTest, MissingPackageRestoresDefaults) {
    config.use_custom_ua = true;
    config.custom_ua = strdup("stale");
    config.mode = UA2F_MODE_REDIRECT;

    EXPECT_FALSE(load_config_from_dir(config_dir.c_str()));
    EXPECT_FALSE(config.use_custom_ua);
    EXPECT_EQ(config.custom_ua, nullptr);
    EXPECT_EQ(config.mode, UA2F_MODE_NFQUEUE);
    EXPECT_EQ(config.listen_port, UA2F_DEFAULT_PROXY_PORT);
}

TEST_F(ConfigTest, ReloadClearsOptionsRemovedFromTheFile) {
    WriteConfig(R"(
config ua2f 'main'
    option custom_ua 'first'
    option mode 'REDIRECT'
)");
    ASSERT_TRUE(load_config_from_dir(config_dir.c_str()));
    ASSERT_TRUE(config.use_custom_ua);
    ASSERT_EQ(config.mode, UA2F_MODE_REDIRECT);

    WriteConfig(R"(
config ua2f 'main'
    option session_ttl '60'
)");
    ASSERT_TRUE(load_config_from_dir(config_dir.c_str()));
    EXPECT_FALSE(config.use_custom_ua);
    EXPECT_EQ(config.custom_ua, nullptr);
    EXPECT_EQ(config.mode, UA2F_MODE_NFQUEUE);
    EXPECT_EQ(config.session_ttl, 60);
}

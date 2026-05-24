#include <gtest/gtest.h>
#include <cstdlib>
#include <unistd.h>

extern "C" {
#include <cli.h>
}

class CLIDeathTest : public ::testing::Test {
protected:
    void SetUp() override {
        GTEST_FLAG_SET(death_test_style, "threadsafe");
        // Capture original uid for cleanup
        original_uid = geteuid();
    }
    
    void TearDown() override {
        // Reset to original state if needed
    }
    
    uid_t original_uid;
};

// Keep these in a *DeathTest suite so GoogleTest runs EXPECT_EXIT tests before
// cache tests start detached cleanup threads.
TEST_F(CLIDeathTest, TryPrintInfoNoArgs) {
    char *argv[] = {(char*)"ua2f"};
    int argc = 1;
    
    // Should not crash with no arguments
    EXPECT_NO_THROW(try_print_info(argc, argv));
}

TEST_F(CLIDeathTest, TryPrintInfoVersion) {
    char *argv[] = {(char*)"ua2f", (char*)"--version"};
    int argc = 2;
    
    // --version should exit, but we can't easily test exit behavior in unit tests
    // Just make sure the function exists and can be called without segfault
    EXPECT_EXIT(try_print_info(argc, argv), ::testing::ExitedWithCode(EXIT_SUCCESS), ".*");
}

TEST_F(CLIDeathTest, TryPrintInfoHelp) {
    char *argv[] = {(char*)"ua2f", (char*)"--help"};
    int argc = 2;
    
    // --help should exit with success
    EXPECT_EXIT(try_print_info(argc, argv), ::testing::ExitedWithCode(EXIT_SUCCESS), ".*");
}

TEST_F(CLIDeathTest, TryPrintInfoUnknownOption) {
    char *argv[] = {(char*)"ua2f", (char*)"--unknown"};
    int argc = 2;
    
    // Unknown option should exit with failure
    EXPECT_EXIT(try_print_info(argc, argv), ::testing::ExitedWithCode(EXIT_FAILURE), ".*");
}

TEST_F(CLIDeathTest, RequireRootWhenRoot) {
    if (geteuid() == 0) {
        // If we're actually root, this should not exit
        EXPECT_NO_THROW(require_root());
    } else {
        // If we're not root, this should exit with failure
        EXPECT_EXIT(require_root(), ::testing::ExitedWithCode(EXIT_FAILURE), ".*");
    }
}

TEST(CLIOptionsTest, ModeAndListenPortAreAvailableWithoutUci) {
    cli_mode_set = false;
    cli_mode = UA2F_MODE_NFQUEUE;
    cli_listen_port_set = false;
    cli_listen_port = UA2F_DEFAULT_PROXY_PORT;

    char *argv[] = {(char *)"ua2f", (char *)"--mode", (char *)"TPROXY", (char *)"--listen-port", (char *)"12345"};
    int argc = 5;

    EXPECT_NO_THROW(try_print_info(argc, argv));
    EXPECT_TRUE(cli_mode_set);
    EXPECT_EQ(cli_mode, UA2F_MODE_TPROXY);
    EXPECT_TRUE(cli_listen_port_set);
    EXPECT_EQ(cli_listen_port, 12345);
}

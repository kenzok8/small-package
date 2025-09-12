#include <gtest/gtest.h>
#include <cstdlib>
#include <unistd.h>

extern "C" {
#include <cli.h>
}

class CLITest : public ::testing::Test {
protected:
    void SetUp() override {
        // Capture original uid for cleanup
        original_uid = geteuid();
    }
    
    void TearDown() override {
        // Reset to original state if needed
    }
    
    uid_t original_uid;
};

TEST_F(CLITest, TryPrintInfoNoArgs) {
    char *argv[] = {(char*)"ua2f"};
    int argc = 1;
    
    // Should not crash with no arguments
    EXPECT_NO_THROW(try_print_info(argc, argv));
}

TEST_F(CLITest, TryPrintInfoVersion) {
    char *argv[] = {(char*)"ua2f", (char*)"--version"};
    int argc = 2;
    
    // --version should exit, but we can't easily test exit behavior in unit tests
    // Just make sure the function exists and can be called without segfault
    EXPECT_EXIT(try_print_info(argc, argv), ::testing::ExitedWithCode(EXIT_SUCCESS), ".*");
}

TEST_F(CLITest, TryPrintInfoHelp) {
    char *argv[] = {(char*)"ua2f", (char*)"--help"};
    int argc = 2;
    
    // --help should exit with success
    EXPECT_EXIT(try_print_info(argc, argv), ::testing::ExitedWithCode(EXIT_SUCCESS), ".*");
}

TEST_F(CLITest, TryPrintInfoUnknownOption) {
    char *argv[] = {(char*)"ua2f", (char*)"--unknown"};
    int argc = 2;
    
    // Unknown option should exit with failure
    EXPECT_EXIT(try_print_info(argc, argv), ::testing::ExitedWithCode(EXIT_FAILURE), ".*");
}

TEST_F(CLITest, RequireRootWhenRoot) {
    if (geteuid() == 0) {
        // If we're actually root, this should not exit
        EXPECT_NO_THROW(require_root());
    } else {
        // If we're not root, this should exit with failure
        EXPECT_EXIT(require_root(), ::testing::ExitedWithCode(EXIT_FAILURE), ".*");
    }
}
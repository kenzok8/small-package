package service

import (
	"context"
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func assertDAEValidationFiles(t *testing.T, args []string, content string) string {
	t.Helper()
	if len(args) != 3 || args[0] != "validate" || args[1] != "-c" {
		t.Errorf("validation argv does not use validate -c <config>")
		return ""
	}
	configPath := args[2]
	if filepath.Base(configPath) != "config.dae" {
		t.Errorf("temporary config filename = %q, want config.dae", filepath.Base(configPath))
	}
	dir := filepath.Dir(configPath)
	dirInfo, err := os.Stat(dir)
	if err != nil {
		t.Errorf("temporary directory is not accessible: %v", err)
		return dir
	}
	if mode := dirInfo.Mode().Perm(); mode != 0o700 {
		t.Errorf("temporary directory mode = %#o, want 0700", mode)
	}
	fileInfo, err := os.Stat(configPath)
	if err != nil {
		t.Errorf("temporary config is not accessible: %v", err)
		return dir
	}
	if mode := fileInfo.Mode().Perm(); mode != 0o600 {
		t.Errorf("temporary config mode = %#o, want 0600", mode)
	}
	actual, err := os.ReadFile(configPath)
	if err != nil {
		t.Errorf("temporary config could not be read: %v", err)
	} else if string(actual) != content {
		t.Errorf("temporary config content differs from the supplied config")
	}
	return dir
}

func assertDAEValidationCleaned(t *testing.T, dir string) {
	t.Helper()
	if dir == "" {
		t.Fatal("validation runner did not receive a temporary directory")
	}
	if _, err := os.Stat(dir); !errors.Is(err, os.ErrNotExist) {
		t.Errorf("temporary directory cleanup error = %v, want not-exist", err)
	}
}

func TestValidateDAEConfigWithUsesSecureFilesAndFixedCommand(t *testing.T) {
	const content = "routing { fallback: direct }\n"
	t.Setenv("DAE_LOCATION_ASSET", "/tmp/unexpected")
	var dir string
	run := func(ctx context.Context, executable string, args, env []string) error {
		if executable != "/usr/bin/dae" {
			t.Errorf("validator path = %q, want /usr/bin/dae", executable)
		}
		dir = assertDAEValidationFiles(t, args, content)
		var assetEnv []string
		for _, value := range env {
			if strings.HasPrefix(value, "DAE_LOCATION_ASSET=") {
				assetEnv = append(assetEnv, value)
			}
		}
		if len(assetEnv) != 1 || assetEnv[0] != "DAE_LOCATION_ASSET=/usr/share/v2ray" {
			t.Errorf("DAE_LOCATION_ASSET environment is not fixed to the bundled asset directory")
		}
		deadline, ok := ctx.Deadline()
		if !ok || time.Until(deadline) <= 0 || time.Until(deadline) > 2*time.Second {
			t.Errorf("validator context has no short deadline")
		}
		return nil
	}

	err := validateDAEConfigWith(context.Background(), content, "/usr/bin/dae", time.Second, run)
	if err != nil {
		t.Fatalf("validation returned an error: %v", err)
	}
	assertDAEValidationCleaned(t, dir)
}

func TestValidateDAEConfigWithRedactsFailureAndCleansUp(t *testing.T) {
	const content = "outbounds { password: \"test\" }\n"
	const secret = "https://private-user:private-pass@example.invalid/path"
	var dir string
	run := func(_ context.Context, _ string, args, _ []string) error {
		dir = assertDAEValidationFiles(t, args, content)
		return errors.New("validator output: " + secret)
	}

	err := validateDAEConfigWith(context.Background(), content, "/usr/bin/dae", time.Second, run)
	if err == nil {
		t.Fatal("validation accepted a rejected config")
	}
	if strings.Contains(err.Error(), secret) {
		t.Fatal("validation error exposed validator output")
	}
	assertDAEValidationCleaned(t, dir)
}

func TestValidateDAEConfigWithTimeoutCleansUp(t *testing.T) {
	var dir string
	run := func(ctx context.Context, _ string, args, _ []string) error {
		dir = assertDAEValidationFiles(t, args, "timeout fixture")
		<-ctx.Done()
		return ctx.Err()
	}

	err := validateDAEConfigWith(context.Background(), "timeout fixture", "/usr/bin/dae", 20*time.Millisecond, run)
	if err == nil || !strings.Contains(strings.ToLower(err.Error()), "timed out") {
		t.Fatal("validation did not report the short timeout")
	}
	assertDAEValidationCleaned(t, dir)
}

func TestValidateDAEConfigWithMissingValidatorFailsClosed(t *testing.T) {
	var dir string
	run := func(_ context.Context, _ string, args, _ []string) error {
		dir = assertDAEValidationFiles(t, args, "config-secret-sentinel")
		return exec.ErrNotFound
	}
	err := validateDAEConfigWith(context.Background(), "config-secret-sentinel", "/usr/bin/dae", time.Second, run)
	if err == nil {
		t.Fatal("validation succeeded without a validator binary")
	}
	if strings.Contains(err.Error(), "config-secret-sentinel") {
		t.Fatal("missing-validator error exposed the config content")
	}
	assertDAEValidationCleaned(t, dir)
}

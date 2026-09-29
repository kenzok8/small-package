package store

import (
	"os"
	"path/filepath"
	"testing"
)

func TestLoadSecuresExistingState(t *testing.T) {
	dir := filepath.Join(t.TempDir(), "tower")
	if err := os.Mkdir(dir, 0o755); err != nil {
		t.Fatal(err)
	}
	path := filepath.Join(dir, stateFile)
	if err := os.WriteFile(path, []byte(`{"subscriptions":[],"nodes":[],"schemes":[]}`), 0o644); err != nil {
		t.Fatal(err)
	}
	if _, err := New(dir).Load(); err != nil {
		t.Fatal(err)
	}
	checkMode(t, dir, 0o700)
	checkMode(t, path, 0o600)
}

func TestSaveUsesPrivateAtomicFile(t *testing.T) {
	dir := filepath.Join(t.TempDir(), "tower")
	st := New(dir)
	if err := st.Save(emptyState()); err != nil {
		t.Fatal(err)
	}
	checkMode(t, dir, 0o700)
	checkMode(t, filepath.Join(dir, stateFile), 0o600)
	if err := st.Save(emptyState()); err != nil {
		t.Fatal(err)
	}
	entries, err := os.ReadDir(dir)
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) != 1 || entries[0].Name() != stateFile {
		t.Fatalf("unexpected state files: %v", entries)
	}
}

func TestRejectsSymlinkedState(t *testing.T) {
	dir := filepath.Join(t.TempDir(), "tower")
	if err := os.Mkdir(dir, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(filepath.Join(t.TempDir(), "target"), filepath.Join(dir, stateFile)); err != nil {
		t.Fatal(err)
	}
	if _, err := New(dir).Load(); err == nil {
		t.Fatal("expected symlinked state to be rejected")
	}
}

func checkMode(t *testing.T, path string, want os.FileMode) {
	t.Helper()
	info, err := os.Stat(path)
	if err != nil {
		t.Fatal(err)
	}
	if got := info.Mode().Perm(); got != want {
		t.Errorf("%s mode = %#o, want %#o", path, got, want)
	}
}

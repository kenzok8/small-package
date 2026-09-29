package service

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/kenzok8/tower/internal/model"
	"github.com/kenzok8/tower/internal/store"
)

func TestLocalShareRotatesAndRevokes(t *testing.T) {
	dir := t.TempDir()
	svc := New(store.New(dir))
	if _, err := svc.Store.Update(func(state *store.State) error {
		state.Nodes = []model.ProxyNode{
			{ID: "ss", Name: "test", Kind: model.KindShadowsocks, Server: "example.com", Port: 443, Cipher: "aes-128-gcm", Password: "secret"},
			{ID: "ssr", Name: "old", Kind: model.KindShadowsocksR, Server: "example.org", Port: 443, Cipher: "aes-128-cfb", Password: "secret", ProtocolName: "origin", Obfs: "plain"},
		}
		return nil
	}); err != nil {
		t.Fatal(err)
	}

	first, err := svc.CreateLocalShare("daede", []string{"ss", "ssr"}, "", true)
	if err != nil {
		t.Fatal(err)
	}
	if first.Included != 1 || first.Skipped != 1 {
		t.Fatalf("counts = %+v", first)
	}
	content, _, ok := svc.LocalShare(first.Token)
	if !ok {
		t.Fatal("new token could not read the snapshot")
	}
	if !strings.HasPrefix(content, "ss://") {
		t.Fatal("invalid daede subscription")
	}
	info, err := os.Stat(filepath.Join(dir, shareFile))
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm() != 0o600 {
		t.Fatalf("snapshot permissions = %v", info.Mode().Perm())
	}
	if _, _, ok := svc.LocalShare(strings.Repeat("0", 64)); ok {
		t.Fatal("incorrect token was accepted")
	}

	second, err := svc.CreateLocalShare("momo", []string{"ss"}, "", true)
	if err != nil {
		t.Fatal(err)
	}
	if _, _, ok := svc.LocalShare(first.Token); ok {
		t.Fatal("rotated token is still valid")
	}
	content, contentType, ok := svc.LocalShare(second.Token)
	if !ok || !strings.Contains(contentType, "application/json") || !strings.Contains(content, `"outbounds"`) {
		t.Fatal("Momo sing-box JSON subscription is unavailable")
	}
	if err := svc.RevokeLocalShare(); err != nil {
		t.Fatal(err)
	}
	if _, _, ok := svc.LocalShare(second.Token); ok {
		t.Fatal("revoked token is still valid")
	}

}

func TestLocalShareRejectsRulesForNodeSubscriptions(t *testing.T) {
	svc := New(store.New(t.TempDir()))
	if _, err := svc.CreateLocalShare("daede", nil, "kenzok8-rules", true); err == nil {
		t.Fatal("daede accepted a rule scheme")
	}
	if _, err := svc.CreateLocalShare("homeproxy", nil, "", true); err == nil {
		t.Fatal("removed HomeProxy destination was accepted")
	}
	if _, err := svc.CreateLocalShare("not-a-client", nil, "", true); err == nil {
		t.Fatal("unknown destination was accepted")
	}
}

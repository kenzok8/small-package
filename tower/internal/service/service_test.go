package service

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/kenzok8/tower/internal/model"
	"github.com/kenzok8/tower/internal/store"
)

func TestFetchSubscriptionReadsUserinfoHeader(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Subscription-Userinfo", "upload=1024;download=2048;total=8192;expire=2000000000")
		_, _ = w.Write([]byte("ss://example"))
	}))
	defer server.Close()

	body, usage, err := FetchSubscription(server.URL, "test-agent")
	if err != nil {
		t.Fatalf("FetchSubscription() error = %v", err)
	}
	if string(body) != "ss://example" {
		t.Fatalf("body = %q, want fixture body", body)
	}
	if usage == nil {
		t.Fatal("usage is nil")
	}
	if usage.UploadBytes != 1024 || usage.DownloadBytes != 2048 || usage.TotalBytes != 8192 {
		t.Fatalf("usage bytes = %+v", usage)
	}
	if usage.ExpiresAt == nil || usage.ExpiresAt.Unix() != 2000000000 {
		t.Fatalf("expiry = %v, want Unix timestamp 2000000000", usage.ExpiresAt)
	}
}

func TestParseSubscriptionUserinfoToleratesSpacingAndInvalidFields(t *testing.T) {
	usage := parseSubscriptionUserinfo(" upload = 12 ; download=bad; total=40; expire=-1 ")
	if usage == nil || usage.UploadBytes != 12 || usage.TotalBytes != 40 || usage.DownloadBytes != 0 || usage.ExpiresAt != nil {
		t.Fatalf("parsed usage = %+v", usage)
	}
}

func TestAddSchemeRequiresName(t *testing.T) {
	svc := New(store.New(t.TempDir()))
	if _, err := svc.AddScheme("  ", "proxies: []", ""); err == nil {
		t.Fatal("AddScheme() accepted an empty name")
	}
}

func TestImportedSchemeCanBeRenamedAndNamesStayDistinct(t *testing.T) {
	svc := New(store.New(t.TempDir()))
	config := "proxy-groups:\n  - name: 节点选择\n    type: select\n    proxies: [DIRECT]\nrules:\n  - MATCH,节点选择\n"
	first, err := svc.AddScheme("个人方案", config, "")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := svc.AddScheme("个人方案", config, ""); err == nil {
		t.Fatal("AddScheme() accepted a duplicate name")
	}
	if err := svc.RenameScheme(first.ID, "旅行方案"); err != nil {
		t.Fatal(err)
	}
	state, err := svc.Store.Load()
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, scheme := range state.Schemes {
		if scheme.ID == first.ID {
			found = scheme.Name == "旅行方案"
		}
	}
	if !found {
		t.Fatal("renamed scheme was not persisted")
	}
}

func TestAddSchemeDoesNotRequireRemoteRuleAccess(t *testing.T) {
	svc := New(store.New(t.TempDir()))
	config := `rule-providers:
  offline:
    type: http
    behavior: classical
    format: text
    url: https://127.0.0.1:1/rules.list
proxy-groups:
  - name: 节点选择
    type: select
    proxies: [DIRECT]
rules:
  - RULE-SET,offline,节点选择
  - MATCH,节点选择
`
	scheme, err := svc.AddScheme("离线导入", config, "")
	if err != nil {
		t.Fatal(err)
	}
	if scheme.ID == "" || len(scheme.Rules) != 2 {
		t.Fatalf("scheme not persisted: %+v", scheme)
	}
	state, err := svc.Store.Load()
	if err != nil {
		t.Fatal(err)
	}
	if len(state.Schemes) != 1 || state.Schemes[0].ID != scheme.ID {
		t.Fatal("imported scheme missing from state")
	}
	if svc.ruleCache.Has("https://127.0.0.1:1/rules.list") {
		t.Fatal("remote rule was unexpectedly cached")
	}
}

func TestUpdateAndRemoveOwnedNode(t *testing.T) {
	svc := New(store.New(t.TempDir()))
	local := model.ProxyNode{ID: "local-1", Kind: model.KindVLESS, Name: "old", Server: "old.example", Port: 443}
	subscription := model.ProxyNode{ID: "sub-1", SourceID: "sub", Kind: model.KindVMess, Name: "subscribed", Server: "sub.example", Port: 443}
	if _, err := svc.Store.Update(func(state *store.State) error {
		state.Nodes = append(state.Nodes, local, subscription)
		return nil
	}); err != nil {
		t.Fatal(err)
	}

	local.Name = "new"
	local.Server = "new.example"
	if err := svc.UpdateOwnedNode(local); err != nil {
		t.Fatalf("UpdateOwnedNode() error = %v", err)
	}
	if err := svc.UpdateOwnedNode(subscription); err == nil {
		t.Fatal("UpdateOwnedNode() accepted a subscription node")
	}
	if err := svc.RemoveOwnedNode("sub-1"); err == nil {
		t.Fatal("RemoveOwnedNode() accepted a subscription node")
	}
	if err := svc.RemoveOwnedNode("local-1"); err != nil {
		t.Fatalf("RemoveOwnedNode() error = %v", err)
	}

	state, err := svc.Store.Load()
	if err != nil {
		t.Fatal(err)
	}
	if len(state.Nodes) != 1 || state.Nodes[0].ID != "sub-1" || state.Nodes[0].Name != "subscribed" {
		t.Fatalf("unexpected remaining nodes: %+v", state.Nodes)
	}
}

func TestUpdateOwnedNodeValidatesRequiredFields(t *testing.T) {
	svc := New(store.New(t.TempDir()))
	if err := svc.UpdateOwnedNode(model.ProxyNode{ID: "node-1", Name: "node", Server: "example.com", Port: 0}); err == nil {
		t.Fatal("UpdateOwnedNode() accepted an invalid port")
	}
	if err := svc.RemoveOwnedNode(" "); err == nil {
		t.Fatal("RemoveOwnedNode() accepted an empty id")
	}
}

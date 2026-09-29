package api

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/kenzok8/tower/internal/model"
	"github.com/kenzok8/tower/internal/service"
	"github.com/kenzok8/tower/internal/store"
)

func TestLocalShareHandler(t *testing.T) {
	svc := service.New(store.New(t.TempDir()))
	if _, err := svc.Store.Update(func(state *store.State) error {
		state.Nodes = []model.ProxyNode{{ID: "node", Name: "test", Kind: model.KindShadowsocks, Server: "example.com", Port: 443, Cipher: "aes-128-gcm", Password: "secret"}}
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	share, err := svc.CreateLocalShare("daede", []string{"node"}, "", true)
	if err != nil {
		t.Fatal(err)
	}
	handler := New(svc).Handler()
	path := "/share/v1/" + share.Token
	for _, test := range []struct {
		method string
		path   string
		want   int
	}{
		{http.MethodGet, path, http.StatusOK},
		{http.MethodHead, path, http.StatusOK},
		{http.MethodGet, "/share/v1/invalid", http.StatusNotFound},
		{http.MethodPost, path, http.StatusMethodNotAllowed},
		{http.MethodGet, "/api/state", http.StatusNotFound},
		{http.MethodGet, "/api/nodes", http.StatusNotFound},
		{http.MethodGet, "/api/export", http.StatusNotFound},
		{http.MethodPost, "/api/subscriptions", http.StatusNotFound},
	} {
		recorder := httptest.NewRecorder()
		handler.ServeHTTP(recorder, httptest.NewRequest(test.method, test.path, nil))
		if recorder.Code != test.want {
			t.Errorf("%s %s = %d, want %d", test.method, test.path, recorder.Code, test.want)
		}
	}
}

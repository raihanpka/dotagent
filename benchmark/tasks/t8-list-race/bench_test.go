package app

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func bxDo(h http.Handler, method, path, token, body string) *httptest.ResponseRecorder {
	w := httptest.NewRecorder()
	r := httptest.NewRequest(method, path, strings.NewReader(body))
	r.Header.Set("Content-Type", "application/json")
	if token != "" {
		r.Header.Set("Authorization", "Bearer "+token)
	}
	h.ServeHTTP(w, r)
	return w
}

func bxSignup(h http.Handler, email string) string {
	w := bxDo(h, "POST", "/api/v1/signup", "", `{"email":"`+email+`","password":"password1"}`)
	var s struct{ Token string }
	_ = json.Unmarshal(w.Body.Bytes(), &s)
	return s.Token
}

func bxField(w *httptest.ResponseRecorder, key string) string {
	var m map[string]any
	_ = json.Unmarshal(w.Body.Bytes(), &m)
	v, _ := m[key].(string)
	return v
}

func TestBenchListWhileEditing(t *testing.T) {
	h := New()
	tok := bxSignup(h, "a@x.io")
	board := bxField(bxDo(h, "POST", "/api/v1/boards", tok, `{"name":"B"}`), "id")
	var ids []string
	for i := 0; i < 5; i++ {
		ids = append(ids, bxField(bxDo(h, "POST", "/api/v1/boards/"+board+"/tasks", tok, `{"title":"t"}`), "id"))
	}
	done := make(chan struct{})
	go func() {
		defer close(done)
		for i := 0; i < 300; i++ {
			bxDo(h, "PATCH", "/api/v1/tasks/"+ids[i%5], tok, `{"title":"edited","done":true}`)
		}
	}()
	for i := 0; i < 300; i++ {
		if w := bxDo(h, "GET", "/api/v1/boards/"+board+"/tasks", tok, ""); w.Code != 200 {
			t.Fatalf("list: %d", w.Code)
		}
	}
	<-done
}

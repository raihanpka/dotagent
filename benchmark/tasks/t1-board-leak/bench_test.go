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

func bxSignup(t *testing.T, h http.Handler, email string) string {
	t.Helper()
	w := bxDo(h, "POST", "/api/v1/signup", "", `{"email":"`+email+`","password":"password1"}`)
	var out struct{ Token string }
	_ = json.Unmarshal(w.Body.Bytes(), &out)
	if out.Token == "" {
		t.Fatalf("signup: %d %s", w.Code, w.Body)
	}
	return out.Token
}

func TestBenchBoardsListIsPerUser(t *testing.T) {
	h := New()
	a := bxSignup(t, h, "a@x.io")
	b := bxSignup(t, h, "b@x.io")
	bxDo(h, "POST", "/api/v1/boards", a, `{"name":"A1"}`)
	bxDo(h, "POST", "/api/v1/boards", a, `{"name":"A2"}`)
	bxDo(h, "POST", "/api/v1/boards", b, `{"name":"B1"}`)

	var got []struct{ Name string }
	w := bxDo(h, "GET", "/api/v1/boards", b, "")
	_ = json.Unmarshal(w.Body.Bytes(), &got)
	if len(got) != 1 || got[0].Name != "B1" {
		t.Fatalf("user b sees %s", w.Body)
	}
	w = bxDo(h, "GET", "/api/v1/boards", a, "")
	_ = json.Unmarshal(w.Body.Bytes(), &got)
	if len(got) != 2 {
		t.Fatalf("user a sees %s", w.Body)
	}
}

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

func TestBenchArchive(t *testing.T) {
	h := New()
	tok := bxSignup(h, "a@x.io")
	other := bxSignup(h, "b@x.io")
	var b struct{ ID string }
	_ = json.Unmarshal(bxDo(h, "POST", "/api/v1/boards", tok, `{"name":"Old"}`).Body.Bytes(), &b)
	bxDo(h, "POST", "/api/v1/boards", tok, `{"name":"Live"}`)
	var task struct{ ID string }
	_ = json.Unmarshal(bxDo(h, "POST", "/api/v1/boards/"+b.ID+"/tasks", tok, `{"title":"x"}`).Body.Bytes(), &task)

	if w := bxDo(h, "POST", "/api/v1/boards/"+b.ID+"/archive", other, ""); w.Code != 404 {
		t.Fatalf("archive by non owner: %d", w.Code)
	}
	w := bxDo(h, "POST", "/api/v1/boards/"+b.ID+"/archive", tok, "")
	var got map[string]any
	_ = json.Unmarshal(w.Body.Bytes(), &got)
	if w.Code != 200 || got["archived"] != true {
		t.Fatalf("archive: %d %s", w.Code, w.Body)
	}

	names := func(q string) []string {
		var list []struct{ Name string }
		_ = json.Unmarshal(bxDo(h, "GET", "/api/v1/boards"+q, tok, "").Body.Bytes(), &list)
		var out []string
		for _, x := range list {
			if x.Name == "Old" || x.Name == "Live" {
				out = append(out, x.Name)
			}
		}
		return out
	}
	if n := names(""); len(n) != 1 || n[0] != "Live" {
		t.Fatalf("default list: %v", n)
	}
	if n := names("?archived=true"); len(n) != 1 || n[0] != "Old" {
		t.Fatalf("archived list: %v", n)
	}

	if w := bxDo(h, "POST", "/api/v1/boards/"+b.ID+"/tasks", tok, `{"title":"y"}`); w.Code != 409 {
		t.Fatalf("create on archived: %d", w.Code)
	}
	if w := bxDo(h, "PATCH", "/api/v1/tasks/"+task.ID, tok, `{"done":true}`); w.Code != 409 {
		t.Fatalf("update on archived: %d", w.Code)
	}
	if w := bxDo(h, "DELETE", "/api/v1/tasks/"+task.ID, tok, ""); w.Code != 409 {
		t.Fatalf("delete on archived: %d", w.Code)
	}
	if w := bxDo(h, "GET", "/api/v1/boards/"+b.ID+"/tasks", tok, ""); w.Code != 200 {
		t.Fatalf("read on archived: %d", w.Code)
	}

	if w := bxDo(h, "POST", "/api/v1/boards/"+b.ID+"/unarchive", tok, ""); w.Code != 200 {
		t.Fatalf("unarchive: %d", w.Code)
	}
	if w := bxDo(h, "POST", "/api/v1/boards/"+b.ID+"/tasks", tok, `{"title":"z"}`); w.Code != 201 {
		t.Fatalf("create after unarchive: %d", w.Code)
	}
}

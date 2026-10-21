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

func TestBenchComments(t *testing.T) {
	h := New()
	tok := bxSignup(h, "a@x.io")
	other := bxSignup(h, "b@x.io")
	var b struct{ ID string }
	_ = json.Unmarshal(bxDo(h, "POST", "/api/v1/boards", tok, `{"name":"B"}`).Body.Bytes(), &b)
	var task struct{ ID string }
	_ = json.Unmarshal(bxDo(h, "POST", "/api/v1/boards/"+b.ID+"/tasks", tok, `{"title":"t"}`).Body.Bytes(), &task)
	path := "/api/v1/tasks/" + task.ID + "/comments"

	w := bxDo(h, "POST", path, tok, `{"body":"first"}`)
	if w.Code != 201 {
		t.Fatalf("create: %d %s", w.Code, w.Body)
	}
	var c map[string]any
	_ = json.Unmarshal(w.Body.Bytes(), &c)
	for _, k := range []string{"id", "task_id", "author_id", "body", "created_at"} {
		if _, ok := c[k]; !ok {
			t.Fatalf("comment misses %q: %v", k, c)
		}
	}
	bxDo(h, "POST", path, tok, `{"body":"second"}`)

	if w := bxDo(h, "POST", path, tok, `{"body":""}`); w.Code != 400 {
		t.Fatalf("empty body: %d", w.Code)
	}
	if w := bxDo(h, "GET", path, other, ""); w.Code != 404 {
		t.Fatalf("other user read: %d", w.Code)
	}
	if w := bxDo(h, "POST", path, other, `{"body":"x"}`); w.Code != 404 {
		t.Fatalf("other user write: %d", w.Code)
	}

	var list []map[string]any
	_ = json.Unmarshal(bxDo(h, "GET", path, tok, "").Body.Bytes(), &list)
	if len(list) != 2 || list[0]["body"] != "first" || list[1]["body"] != "second" {
		t.Fatalf("list: %v", list)
	}

	bxDo(h, "DELETE", "/api/v1/tasks/"+task.ID, tok, "")
	if w := bxDo(h, "GET", path, tok, ""); w.Code != 404 {
		t.Fatalf("comments of a deleted task: %d", w.Code)
	}
}

package app

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func do(h http.Handler, method, path, token, body string) *httptest.ResponseRecorder {
	w := httptest.NewRecorder()
	r := httptest.NewRequest(method, path, strings.NewReader(body))
	r.Header.Set("Content-Type", "application/json")
	if token != "" {
		r.Header.Set("Authorization", "Bearer "+token)
	}
	h.ServeHTTP(w, r)
	return w
}

func signup(t *testing.T, h http.Handler, email string) string {
	t.Helper()
	w := do(h, "POST", "/api/v1/signup", "", `{"email":"`+email+`","password":"password1"}`)
	var out struct{ Token string }
	_ = json.Unmarshal(w.Body.Bytes(), &out)
	if out.Token == "" {
		t.Fatalf("signup: %d %s", w.Code, w.Body)
	}
	return out.Token
}

func TestBoardAndTaskFlow(t *testing.T) {
	h := New()
	tok := signup(t, h, "a@b.c")

	w := do(h, "POST", "/api/v1/boards", tok, `{"name":"Launch"}`)
	if w.Code != 201 {
		t.Fatalf("create board: %d %s", w.Code, w.Body)
	}
	var b struct{ ID string }
	_ = json.Unmarshal(w.Body.Bytes(), &b)

	if w := do(h, "POST", "/api/v1/boards/"+b.ID+"/tasks", tok, `{"title":"write docs"}`); w.Code != 201 {
		t.Fatalf("create task: %d %s", w.Code, w.Body)
	}
	w = do(h, "GET", "/api/v1/boards/"+b.ID+"/tasks", tok, "")
	var list []struct{ ID, Title string }
	_ = json.Unmarshal(w.Body.Bytes(), &list)
	if len(list) != 1 || list[0].Title != "write docs" {
		t.Fatalf("list: %s", w.Body)
	}
	if w := do(h, "PATCH", "/api/v1/tasks/"+list[0].ID, tok, `{"done":true}`); w.Code != 200 {
		t.Fatalf("update: %d", w.Code)
	}
}

func TestRoutesNeedAToken(t *testing.T) {
	if w := do(New(), "GET", "/api/v1/boards", "", ""); w.Code != 401 {
		t.Fatalf("got %d", w.Code)
	}
}

func TestAnotherUserCannotReadATaskBoard(t *testing.T) {
	h := New()
	a := signup(t, h, "a@b.c")
	b := signup(t, h, "d@e.f")
	w := do(h, "POST", "/api/v1/boards", a, `{"name":"Private"}`)
	var bd struct{ ID string }
	_ = json.Unmarshal(w.Body.Bytes(), &bd)
	if w := do(h, "GET", "/api/v1/boards/"+bd.ID+"/tasks", b, ""); w.Code != 404 {
		t.Fatalf("got %d", w.Code)
	}
}

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

func TestBenchMembersAndRoles(t *testing.T) {
	h := New()
	owner := bxSignup(h, "o@x.io")
	editor := bxSignup(h, "e@x.io")
	viewer := bxSignup(h, "v@x.io")
	stranger := bxSignup(h, "s@x.io")
	id := func(tok string) string { return bxField(bxDo(h, "GET", "/api/v1/me", tok, ""), "user_id") }

	board := bxField(bxDo(h, "POST", "/api/v1/boards", owner, `{"name":"Team"}`), "id")
	task := bxField(bxDo(h, "POST", "/api/v1/boards/"+board+"/tasks", owner, `{"title":"first"}`), "id")
	m := "/api/v1/boards/" + board + "/members"

	if w := bxDo(h, "POST", m, owner, `{"user_id":"`+id(editor)+`","role":"boss"}`); w.Code != 400 {
		t.Fatalf("bad role: %d", w.Code)
	}
	if w := bxDo(h, "POST", m, editor, `{"user_id":"`+id(viewer)+`","role":"viewer"}`); w.Code != 404 {
		t.Fatalf("non member adds: %d", w.Code)
	}
	if w := bxDo(h, "POST", m, owner, `{"user_id":"`+id(editor)+`","role":"editor"}`); w.Code != 200 && w.Code != 201 {
		t.Fatalf("add editor: %d %s", w.Code, w.Body)
	}
	bxDo(h, "POST", m, owner, `{"user_id":"`+id(viewer)+`","role":"editor"}`)
	if w := bxDo(h, "POST", m, owner, `{"user_id":"`+id(viewer)+`","role":"viewer"}`); w.Code != 200 && w.Code != 201 {
		t.Fatalf("update role: %d", w.Code)
	}

	var members []map[string]any
	_ = json.Unmarshal(bxDo(h, "GET", m, viewer, "").Body.Bytes(), &members)
	if len(members) != 2 {
		t.Fatalf("members: %v", members)
	}
	if w := bxDo(h, "GET", m, stranger, ""); w.Code != 404 {
		t.Fatalf("stranger lists members: %d", w.Code)
	}

	if w := bxDo(h, "GET", "/api/v1/boards/"+board+"/tasks", viewer, ""); w.Code != 200 {
		t.Fatalf("viewer reads tasks: %d", w.Code)
	}
	if w := bxDo(h, "POST", "/api/v1/boards/"+board+"/tasks", viewer, `{"title":"nope"}`); w.Code != 403 && w.Code != 404 {
		t.Fatalf("viewer writes: %d", w.Code)
	}
	if w := bxDo(h, "POST", "/api/v1/boards/"+board+"/tasks", editor, `{"title":"ok"}`); w.Code != 201 {
		t.Fatalf("editor writes: %d", w.Code)
	}
	if w := bxDo(h, "PATCH", "/api/v1/tasks/"+task, editor, `{"done":true}`); w.Code != 200 {
		t.Fatalf("editor updates: %d", w.Code)
	}
	if w := bxDo(h, "PATCH", "/api/v1/tasks/"+task, viewer, `{"done":false}`); w.Code != 403 && w.Code != 404 {
		t.Fatalf("viewer updates: %d", w.Code)
	}
	if w := bxDo(h, "GET", "/api/v1/boards/"+board+"/tasks", stranger, ""); w.Code != 404 {
		t.Fatalf("stranger reads: %d", w.Code)
	}
	if w := bxDo(h, "DELETE", "/api/v1/boards/"+board, editor, ""); w.Code != 403 && w.Code != 404 {
		t.Fatalf("editor deletes board: %d", w.Code)
	}

	names := func(tok string) int {
		var list []map[string]any
		_ = json.Unmarshal(bxDo(h, "GET", "/api/v1/boards", tok, "").Body.Bytes(), &list)
		return len(list)
	}
	if names(viewer) != 1 || names(owner) != 1 || names(stranger) != 0 {
		t.Fatalf("board lists: viewer %d owner %d stranger %d", names(viewer), names(owner), names(stranger))
	}

	if w := bxDo(h, "DELETE", m+"/"+id(viewer), owner, ""); w.Code != 204 {
		t.Fatalf("remove member: %d", w.Code)
	}
	if w := bxDo(h, "GET", "/api/v1/boards/"+board+"/tasks", viewer, ""); w.Code != 404 {
		t.Fatalf("removed member still reads: %d", w.Code)
	}
}

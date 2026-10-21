package app

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
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

func bxBoard(t *testing.T, h http.Handler) (string, string) {
	t.Helper()
	w := bxDo(h, "POST", "/api/v1/signup", "", `{"email":"a@x.io","password":"password1"}`)
	var s struct{ Token string }
	_ = json.Unmarshal(w.Body.Bytes(), &s)
	w = bxDo(h, "POST", "/api/v1/boards", s.Token, `{"name":"B"}`)
	var b struct{ ID string }
	_ = json.Unmarshal(w.Body.Bytes(), &b)
	if s.Token == "" || b.ID == "" {
		t.Fatalf("setup failed")
	}
	return s.Token, b.ID
}

func TestBenchDueDates(t *testing.T) {
	h := New()
	tok, board := bxBoard(t, h)
	base := "/api/v1/boards/" + board + "/tasks"
	past := time.Now().Add(-48 * time.Hour).UTC().Format(time.RFC3339)
	future := time.Now().Add(48 * time.Hour).UTC().Format(time.RFC3339)

	if w := bxDo(h, "POST", base, tok, `{"title":"late","due":"`+past+`"}`); w.Code != 201 {
		t.Fatalf("create late: %d %s", w.Code, w.Body)
	}
	bxDo(h, "POST", base, tok, `{"title":"soon","due":"`+future+`"}`)
	bxDo(h, "POST", base, tok, `{"title":"nodue"}`)
	w := bxDo(h, "POST", base, tok, `{"title":"done-late","due":"`+past+`"}`)
	var done struct{ ID string }
	_ = json.Unmarshal(w.Body.Bytes(), &done)
	bxDo(h, "PATCH", "/api/v1/tasks/"+done.ID, tok, `{"done":true}`)

	if w := bxDo(h, "POST", base, tok, `{"title":"bad","due":"tomorrow"}`); w.Code != 400 {
		t.Fatalf("bad due should be 400, got %d", w.Code)
	}

	var all []map[string]any
	_ = json.Unmarshal(bxDo(h, "GET", base, tok, "").Body.Bytes(), &all)
	if len(all) != 4 {
		t.Fatalf("unfiltered list has %d tasks", len(all))
	}
	for _, task := range all {
		if _, ok := task["due"]; !ok {
			t.Fatalf("task without a due key: %v", task)
		}
	}

	var over []map[string]any
	_ = json.Unmarshal(bxDo(h, "GET", base+"?overdue=true", tok, "").Body.Bytes(), &over)
	if len(over) != 1 || over[0]["title"] != "late" {
		t.Fatalf("overdue list: %v", over)
	}

	id := over[0]["id"].(string)
	w = bxDo(h, "PATCH", "/api/v1/tasks/"+id, tok, `{"due":null}`)
	if w.Code != 200 {
		t.Fatalf("clear due: %d %s", w.Code, w.Body)
	}
	var cleared map[string]any
	_ = json.Unmarshal(w.Body.Bytes(), &cleared)
	if cleared["due"] != nil {
		t.Fatalf("due not cleared: %v", cleared["due"])
	}
	if w := bxDo(h, "PATCH", "/api/v1/tasks/"+id, tok, `{"due":"nope"}`); w.Code != 400 {
		t.Fatalf("bad patch due: %d", w.Code)
	}
}

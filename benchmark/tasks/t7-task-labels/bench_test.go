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

func TestBenchTaskLabels(t *testing.T) {
	h := New()
	tok := bxSignup(h, "a@x.io")
	b1 := bxField(bxDo(h, "POST", "/api/v1/boards", tok, `{"name":"One"}`), "id")
	b2 := bxField(bxDo(h, "POST", "/api/v1/boards", tok, `{"name":"Two"}`), "id")
	t1 := bxField(bxDo(h, "POST", "/api/v1/boards/"+b1+"/tasks", tok, `{"title":"a"}`), "id")
	t2 := bxField(bxDo(h, "POST", "/api/v1/boards/"+b1+"/tasks", tok, `{"title":"b"}`), "id")
	bug := bxField(bxDo(h, "POST", "/api/v1/boards/"+b1+"/labels", tok, `{"name":"bug","color":"#ff0000"}`), "id")
	other := bxField(bxDo(h, "POST", "/api/v1/boards/"+b2+"/labels", tok, `{"name":"x","color":"#00ff00"}`), "id")

	if w := bxDo(h, "PUT", "/api/v1/tasks/"+t1+"/labels/"+bug, tok, ""); w.Code != 204 {
		t.Fatalf("attach: %d %s", w.Code, w.Body)
	}
	if w := bxDo(h, "PUT", "/api/v1/tasks/"+t1+"/labels/"+bug, tok, ""); w.Code != 204 {
		t.Fatalf("attach twice: %d", w.Code)
	}
	if w := bxDo(h, "PUT", "/api/v1/tasks/"+t1+"/labels/"+other, tok, ""); w.Code != 404 {
		t.Fatalf("label of another board: %d", w.Code)
	}

	var all []struct {
		ID     string
		Labels []string
	}
	w := bxDo(h, "GET", "/api/v1/boards/"+b1+"/tasks", tok, "")
	if strings.Contains(w.Body.String(), `"labels":null`) {
		t.Fatalf("labels must be an array, never null: %s", w.Body)
	}
	_ = json.Unmarshal(w.Body.Bytes(), &all)
	if len(all) != 2 || len(all[0].Labels) != 1 || all[0].Labels[0] != bug || all[1].Labels == nil || len(all[1].Labels) != 0 {
		t.Fatalf("task labels: %s", w.Body)
	}

	var filtered []struct{ ID string }
	_ = json.Unmarshal(bxDo(h, "GET", "/api/v1/boards/"+b1+"/tasks?label="+bug, tok, "").Body.Bytes(), &filtered)
	if len(filtered) != 1 || filtered[0].ID != t1 {
		t.Fatalf("filter: %v", filtered)
	}

	bxDo(h, "PUT", "/api/v1/tasks/"+t2+"/labels/"+bug, tok, "")
	if w := bxDo(h, "DELETE", "/api/v1/tasks/"+t2+"/labels/"+bug, tok, ""); w.Code != 204 {
		t.Fatalf("detach: %d", w.Code)
	}
	if w := bxDo(h, "DELETE", "/api/v1/labels/"+bug, tok, ""); w.Code != 204 {
		t.Fatalf("delete label: %d", w.Code)
	}
	w = bxDo(h, "GET", "/api/v1/boards/"+b1+"/tasks", tok, "")
	if strings.Contains(w.Body.String(), bug) {
		t.Fatalf("deleted label still on a task: %s", w.Body)
	}
}

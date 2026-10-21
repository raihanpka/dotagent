package app

import (
	"encoding/json"
	"fmt"
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

func TestBenchPagination(t *testing.T) {
	h := New()
	w := bxDo(h, "POST", "/api/v1/signup", "", `{"email":"a@x.io","password":"password1"}`)
	var s struct{ Token string }
	_ = json.Unmarshal(w.Body.Bytes(), &s)
	w = bxDo(h, "POST", "/api/v1/boards", s.Token, `{"name":"B"}`)
	var b struct{ ID string }
	_ = json.Unmarshal(w.Body.Bytes(), &b)
	base := "/api/v1/boards/" + b.ID + "/tasks"
	for i := 1; i <= 120; i++ {
		bxDo(h, "POST", base, s.Token, fmt.Sprintf(`{"title":"task %03d"}`, i))
	}

	page := func(q string) (int, int, string, string) {
		w := bxDo(h, "GET", base+q, s.Token, "")
		var out []struct{ Title string }
		_ = json.Unmarshal(w.Body.Bytes(), &out)
		first := ""
		if len(out) > 0 {
			first = out[0].Title
		}
		return w.Code, len(out), first, w.Header().Get("X-Total-Count")
	}

	if code, n, first, total := page(""); code != 200 || n != 50 || first != "task 001" || total != "120" {
		t.Fatalf("default page: %d %d %q %q", code, n, first, total)
	}
	if code, n, first, total := page("?limit=10&offset=115"); code != 200 || n != 5 || first != "task 116" || total != "120" {
		t.Fatalf("tail page: %d %d %q %q", code, n, first, total)
	}
	if code, n, _, _ := page("?offset=500"); code != 200 || n != 0 {
		t.Fatalf("offset past the end: %d %d", code, n)
	}
	for _, q := range []string{"?limit=0", "?limit=101", "?limit=abc", "?offset=-1", "?offset=x"} {
		if code, _, _, _ := page(q); code != 400 {
			t.Fatalf("%s should be 400, got %d", q, code)
		}
	}
}

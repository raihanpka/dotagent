package profile

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/raihanpka/taskboard/internal/httpx"
)

func router(user string) http.Handler {
	m := New()
	e := httpx.NewEngine()
	g := e.Group("", func(c *gin.Context) { c.Set("auth.user", user) })
	m.Register(g)
	return e
}

func call(h http.Handler, method, body string) *httptest.ResponseRecorder {
	w := httptest.NewRecorder()
	r := httptest.NewRequest(method, "/me", strings.NewReader(body))
	r.Header.Set("Content-Type", "application/json")
	h.ServeHTTP(w, r)
	return w
}

func TestUpdateAndRead(t *testing.T) {
	h := router("u1")
	if w := call(h, "PATCH", `{"display_name":"  Ana "}`); w.Code != 200 || !strings.Contains(w.Body.String(), `"Ana"`) {
		t.Fatalf("patch: %d %s", w.Code, w.Body)
	}
	if w := call(h, "GET", ""); !strings.Contains(w.Body.String(), `"user_id":"u1"`) {
		t.Fatalf("get: %s", w.Body)
	}
}

func TestRejectsEmptyName(t *testing.T) {
	if w := call(router("u1"), "PATCH", `{"display_name":"  "}`); w.Code != 400 {
		t.Fatalf("got %d", w.Code)
	}
}

package webhooks

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/raihanpka/taskboard/internal/httpx"
)

func router(m *Module, user string) http.Handler {
	e := httpx.NewEngine()
	m.Register(e.Group("", func(c *gin.Context) { c.Set("auth.user", user) }))
	return e
}

func call(h http.Handler, method, path, body string) *httptest.ResponseRecorder {
	w := httptest.NewRecorder()
	r := httptest.NewRequest(method, path, strings.NewReader(body))
	r.Header.Set("Content-Type", "application/json")
	h.ServeHTTP(w, r)
	return w
}

func TestCreateValidatesUrlAndEvent(t *testing.T) {
	h := router(New(), "u1")
	if w := call(h, "POST", "/webhooks", `{"url":"https://x.io/h","event":"task.created"}`); w.Code != 201 {
		t.Fatalf("create: %d %s", w.Code, w.Body)
	}
	for _, body := range []string{`{"url":"ftp://x.io","event":"task.created"}`, `{"url":"https://x.io","event":"nope"}`, `{"url":"","event":"task.created"}`} {
		if w := call(h, "POST", "/webhooks", body); w.Code != 400 {
			t.Fatalf("%s: %d", body, w.Code)
		}
	}
}

func TestHooksArePerUser(t *testing.T) {
	m := New()
	call(router(m, "u1"), "POST", "/webhooks", `{"url":"https://x.io/h","event":"task.created"}`)
	if w := call(router(m, "u2"), "GET", "/webhooks", ""); strings.Contains(w.Body.String(), "x.io") {
		t.Fatalf("u2 sees %s", w.Body)
	}
	if w := call(router(m, "u2"), "DELETE", "/webhooks/w1", ""); w.Code != 404 {
		t.Fatalf("u2 delete: %d", w.Code)
	}
}

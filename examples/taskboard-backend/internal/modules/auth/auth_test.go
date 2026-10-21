package auth

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"

	"github.com/raihanpka/taskboard/internal/httpx"
)

func newRouter() (*Module, http.Handler) {
	m := New()
	e := httpx.NewEngine()
	m.Register(e)
	e.GET("/me", m.Middleware(), func(c *gin.Context) { c.String(200, UserID(c)) })
	return m, e
}

func post(h http.Handler, path, body string) *httptest.ResponseRecorder {
	w := httptest.NewRecorder()
	r := httptest.NewRequest("POST", path, strings.NewReader(body))
	r.Header.Set("Content-Type", "application/json")
	h.ServeHTTP(w, r)
	return w
}

func TestSignupThenLogin(t *testing.T) {
	_, h := newRouter()
	if w := post(h, "/signup", `{"email":"a@b.c","password":"password1"}`); w.Code != 201 {
		t.Fatalf("signup: %d %s", w.Code, w.Body)
	}
	if w := post(h, "/signup", `{"email":"a@b.c","password":"password1"}`); w.Code != 409 {
		t.Fatalf("duplicate signup: %d", w.Code)
	}
	if w := post(h, "/login", `{"email":"a@b.c","password":"wrong"}`); w.Code != 401 {
		t.Fatalf("bad login: %d", w.Code)
	}
	if w := post(h, "/login", `{"email":"a@b.c","password":"password1"}`); w.Code != 200 {
		t.Fatalf("login: %d", w.Code)
	}
}

func TestMiddlewareRejectsMissingToken(t *testing.T) {
	_, h := newRouter()
	w := httptest.NewRecorder()
	h.ServeHTTP(w, httptest.NewRequest("GET", "/me", nil))
	if w.Code != 401 {
		t.Fatalf("got %d", w.Code)
	}
}

package labels

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/raihanpka/taskboard/internal/httpx"
)

type fakeBoards struct{ owner string }

func (f fakeBoards) Owns(board, user string) bool { return board == "b1" && user == f.owner }

func router(user string) http.Handler {
	m := New(fakeBoards{owner: "u1"})
	e := httpx.NewEngine()
	g := e.Group("", func(c *gin.Context) { c.Set("auth.user", user) })
	m.Register(g)
	return e
}

func call(h http.Handler, method, path, body string) *httptest.ResponseRecorder {
	w := httptest.NewRecorder()
	r := httptest.NewRequest(method, path, strings.NewReader(body))
	r.Header.Set("Content-Type", "application/json")
	h.ServeHTTP(w, r)
	return w
}

func TestCreateListDelete(t *testing.T) {
	h := router("u1")
	if w := call(h, "POST", "/boards/b1/labels", `{"name":"bug","color":"#ff0000"}`); w.Code != 201 {
		t.Fatalf("create: %d %s", w.Code, w.Body)
	}
	if w := call(h, "GET", "/boards/b1/labels", ""); !strings.Contains(w.Body.String(), `"bug"`) {
		t.Fatalf("list: %s", w.Body)
	}
	if w := call(h, "DELETE", "/labels/l1", ""); w.Code != 204 {
		t.Fatalf("delete: %d", w.Code)
	}
}

func TestValidationAndOwnership(t *testing.T) {
	if w := call(router("u1"), "POST", "/boards/b1/labels", `{"name":"bug","color":"red"}`); w.Code != 400 {
		t.Fatalf("bad color: %d", w.Code)
	}
	if w := call(router("u2"), "POST", "/boards/b1/labels", `{"name":"bug","color":"#ff0000"}`); w.Code != 404 {
		t.Fatalf("not owner: %d", w.Code)
	}
}

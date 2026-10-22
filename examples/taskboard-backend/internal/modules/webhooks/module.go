// Package webhooks keeps the callback URLs a user registered. It only stores them, nothing is delivered yet.
package webhooks

import (
	"net/http"
	"net/url"
	"sort"
	"sync"

	"github.com/gin-gonic/gin"
	"github.com/raihanpka/taskboard/internal/httpx"
	"github.com/raihanpka/taskboard/internal/modules/auth"
)

type Hook struct {
	ID      string `json:"id"`
	OwnerID string `json:"owner_id"`
	URL     string `json:"url"`
	Event   string `json:"event"`
}

var events = map[string]bool{"task.created": true, "task.updated": true, "task.deleted": true}

type Module struct {
	mu    sync.Mutex
	hooks map[string]*Hook
	seq   int
}

func New() *Module { return &Module{hooks: map[string]*Hook{}} }

// Register mounts the webhook routes on a group that already requires a signed in user.
func (m *Module) Register(r gin.IRoutes) {
	r.POST("/webhooks", m.create)
	r.GET("/webhooks", m.list)
	r.DELETE("/webhooks/:id", m.remove)
}

func (m *Module) create(c *gin.Context) {
	var in struct{ URL, Event string }
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid body")
		return
	}
	u, err := url.Parse(in.URL)
	if err != nil || (u.Scheme != "http" && u.Scheme != "https") || u.Host == "" || !events[in.Event] {
		httpx.Error(c, http.StatusBadRequest, "an http(s) url and a known event are required")
		return
	}
	m.mu.Lock()
	m.seq++
	h := &Hook{ID: "w" + itoa(m.seq), OwnerID: auth.UserID(c), URL: in.URL, Event: in.Event}
	m.hooks[h.ID] = h
	out := *h
	m.mu.Unlock()
	c.JSON(http.StatusCreated, out)
}

func (m *Module) list(c *gin.Context) {
	me := auth.UserID(c)
	m.mu.Lock()
	out := []Hook{}
	for _, h := range m.hooks {
		if h.OwnerID == me {
			out = append(out, *h)
		}
	}
	m.mu.Unlock()
	sort.Slice(out, func(i, j int) bool { return out[i].ID < out[j].ID })
	c.JSON(http.StatusOK, out)
}

func (m *Module) remove(c *gin.Context) {
	id := c.Param("id")
	m.mu.Lock()
	h, ok := m.hooks[id]
	if ok && h.OwnerID == auth.UserID(c) {
		delete(m.hooks, id)
		m.mu.Unlock()
		c.Status(http.StatusNoContent)
		return
	}
	m.mu.Unlock()
	httpx.Error(c, http.StatusNotFound, "webhook not found")
}

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	var d []byte
	for ; n > 0; n /= 10 {
		d = append([]byte{byte('0' + n%10)}, d...)
	}
	return string(d)
}

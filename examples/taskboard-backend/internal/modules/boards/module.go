// Package boards owns boards. Its public interface is Module and Owns.
package boards

import (
	"net/http"
	"sort"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/raihanpka/taskboard/internal/httpx"
	"github.com/raihanpka/taskboard/internal/modules/auth"
)

type Board struct {
	ID        string    `json:"id"`
	OwnerID   string    `json:"owner_id"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
}

type Module struct {
	mu     sync.Mutex
	boards map[string]*Board
	seq    int
}

func New() *Module { return &Module{boards: map[string]*Board{}} }

// Register mounts the board routes on a group that already requires a signed in user.
func (m *Module) Register(r gin.IRoutes) {
	r.POST("/boards", m.create)
	r.GET("/boards", m.list)
	r.GET("/boards/:id", m.get)
	r.DELETE("/boards/:id", m.remove)
}

// Owns reports whether the board exists and belongs to the user.
func (m *Module) Owns(boardID, userID string) bool {
	m.mu.Lock()
	defer m.mu.Unlock()
	b, ok := m.boards[boardID]
	return ok && b.OwnerID == userID
}

func (m *Module) create(c *gin.Context) {
	var in struct {
		Name string `json:"name"`
	}
	if err := c.ShouldBindJSON(&in); err != nil || in.Name == "" {
		httpx.Error(c, http.StatusBadRequest, "name is required")
		return
	}
	m.mu.Lock()
	m.seq++
	b := &Board{ID: "b" + itoa(m.seq), OwnerID: auth.UserID(c), Name: in.Name, CreatedAt: time.Now().UTC()}
	m.boards[b.ID] = b
	m.mu.Unlock()
	c.JSON(http.StatusCreated, b)
}

func (m *Module) list(c *gin.Context) {
	m.mu.Lock()
	out := make([]*Board, 0, len(m.boards))
	for _, b := range m.boards {
		out = append(out, b)
	}
	m.mu.Unlock()
	sort.Slice(out, func(i, j int) bool { return out[i].ID < out[j].ID })
	c.JSON(http.StatusOK, out)
}

func (m *Module) get(c *gin.Context) {
	id := c.Param("id")
	if !m.Owns(id, auth.UserID(c)) {
		httpx.Error(c, http.StatusNotFound, "board not found")
		return
	}
	m.mu.Lock()
	b := *m.boards[id]
	m.mu.Unlock()
	c.JSON(http.StatusOK, b)
}

func (m *Module) remove(c *gin.Context) {
	id := c.Param("id")
	if !m.Owns(id, auth.UserID(c)) {
		httpx.Error(c, http.StatusNotFound, "board not found")
		return
	}
	m.mu.Lock()
	delete(m.boards, id)
	m.mu.Unlock()
	c.Status(http.StatusNoContent)
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

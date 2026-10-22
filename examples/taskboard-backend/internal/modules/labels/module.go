// Package labels owns the labels of a board. It asks boards who owns a board through the Boards interface.
package labels

import (
	"net/http"
	"regexp"
	"sort"
	"sync"

	"github.com/gin-gonic/gin"
	"github.com/raihanpka/taskboard/internal/httpx"
	"github.com/raihanpka/taskboard/internal/modules/auth"
)

// Boards is the part of the boards module that labels needs.
type Boards interface {
	Owns(boardID, userID string) bool
}

type Label struct {
	ID      string `json:"id"`
	BoardID string `json:"board_id"`
	Name    string `json:"name"`
	Color   string `json:"color"`
}

var hexColor = regexp.MustCompile(`^#[0-9a-fA-F]{6}$`)

type Module struct {
	boards Boards
	mu     sync.Mutex
	labels map[string]*Label
	seq    int
}

func New(b Boards) *Module { return &Module{boards: b, labels: map[string]*Label{}} }

// Register mounts the label routes on a group that already requires a signed in user.
func (m *Module) Register(r gin.IRoutes) {
	r.POST("/boards/:id/labels", m.create)
	r.GET("/boards/:id/labels", m.list)
	r.DELETE("/labels/:id", m.remove)
}

func (m *Module) create(c *gin.Context) {
	board := c.Param("id")
	if !m.boards.Owns(board, auth.UserID(c)) {
		httpx.Error(c, http.StatusNotFound, "board not found")
		return
	}
	var in struct{ Name, Color string }
	if err := c.ShouldBindJSON(&in); err != nil || in.Name == "" || !hexColor.MatchString(in.Color) {
		httpx.Error(c, http.StatusBadRequest, "name and a #rrggbb color are required")
		return
	}
	m.mu.Lock()
	m.seq++
	l := &Label{ID: "l" + itoa(m.seq), BoardID: board, Name: in.Name, Color: in.Color}
	m.labels[l.ID] = l
	out := *l
	m.mu.Unlock()
	c.JSON(http.StatusCreated, out)
}

func (m *Module) list(c *gin.Context) {
	board := c.Param("id")
	if !m.boards.Owns(board, auth.UserID(c)) {
		httpx.Error(c, http.StatusNotFound, "board not found")
		return
	}
	m.mu.Lock()
	out := []Label{}
	for _, l := range m.labels {
		if l.BoardID == board {
			out = append(out, *l)
		}
	}
	m.mu.Unlock()
	sort.Slice(out, func(i, j int) bool { return out[i].ID < out[j].ID })
	c.JSON(http.StatusOK, out)
}

func (m *Module) remove(c *gin.Context) {
	id := c.Param("id")
	m.mu.Lock()
	l, ok := m.labels[id]
	m.mu.Unlock()
	if !ok || !m.boards.Owns(l.BoardID, auth.UserID(c)) {
		httpx.Error(c, http.StatusNotFound, "label not found")
		return
	}
	m.mu.Lock()
	delete(m.labels, id)
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

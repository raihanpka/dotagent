// Package tasks owns the tasks on a board. It asks the boards module who owns a board
// through the Boards interface and never imports its internals.
package tasks

import (
	"net/http"
	"sort"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/raihanpka/taskboard/internal/httpx"
	"github.com/raihanpka/taskboard/internal/modules/auth"
)

// Boards is the part of the boards module that tasks needs.
type Boards interface {
	Owns(boardID, userID string) bool
}

type Task struct {
	ID        string    `json:"id"`
	BoardID   string    `json:"board_id"`
	Title     string    `json:"title"`
	Done      bool      `json:"done"`
	CreatedAt time.Time `json:"created_at"`
}

type Module struct {
	boards Boards
	mu     sync.Mutex
	tasks  map[string]*Task
	seq    int
}

func New(b Boards) *Module { return &Module{boards: b, tasks: map[string]*Task{}} }

// Register mounts the task routes on a group that already requires a signed in user.
func (m *Module) Register(r gin.IRoutes) {
	r.POST("/boards/:id/tasks", m.create)
	r.GET("/boards/:id/tasks", m.list)
	r.PATCH("/tasks/:id", m.update)
	r.DELETE("/tasks/:id", m.remove)
}

func (m *Module) create(c *gin.Context) {
	board := c.Param("id")
	if !m.boards.Owns(board, auth.UserID(c)) {
		httpx.Error(c, http.StatusNotFound, "board not found")
		return
	}
	var in struct {
		Title string `json:"title"`
	}
	if err := c.ShouldBindJSON(&in); err != nil || in.Title == "" {
		httpx.Error(c, http.StatusBadRequest, "title is required")
		return
	}
	m.mu.Lock()
	m.seq++
	t := &Task{ID: "t" + itoa(m.seq), BoardID: board, Title: in.Title, CreatedAt: time.Now().UTC()}
	m.tasks[t.ID] = t
	m.mu.Unlock()
	c.JSON(http.StatusCreated, t)
}

func (m *Module) list(c *gin.Context) {
	board := c.Param("id")
	if !m.boards.Owns(board, auth.UserID(c)) {
		httpx.Error(c, http.StatusNotFound, "board not found")
		return
	}
	m.mu.Lock()
	out := []*Task{}
	for _, t := range m.tasks {
		if t.BoardID == board {
			out = append(out, t)
		}
	}
	m.mu.Unlock()
	sort.Slice(out, func(i, j int) bool {
		return out[i].CreatedAt.Before(out[j].CreatedAt) || (out[i].CreatedAt.Equal(out[j].CreatedAt) && out[i].ID < out[j].ID)
	})
	c.JSON(http.StatusOK, out)
}

// owned returns the task when the caller owns its board.
func (m *Module) owned(c *gin.Context) (*Task, bool) {
	m.mu.Lock()
	t, ok := m.tasks[c.Param("id")]
	m.mu.Unlock()
	if !ok || !m.boards.Owns(t.BoardID, auth.UserID(c)) {
		httpx.Error(c, http.StatusNotFound, "task not found")
		return nil, false
	}
	return t, true
}

func (m *Module) update(c *gin.Context) {
	t, ok := m.owned(c)
	if !ok {
		return
	}
	var in struct {
		Title *string `json:"title"`
		Done  *bool   `json:"done"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid body")
		return
	}
	m.mu.Lock()
	if in.Title != nil && *in.Title != "" {
		t.Title = *in.Title
	}
	if in.Done != nil {
		t.Done = *in.Done
	}
	out := *t
	m.mu.Unlock()
	c.JSON(http.StatusOK, out)
}

func (m *Module) remove(c *gin.Context) {
	t, ok := m.owned(c)
	if !ok {
		return
	}
	m.mu.Lock()
	delete(m.tasks, t.ID)
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

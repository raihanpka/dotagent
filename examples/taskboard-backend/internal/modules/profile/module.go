// Package profile owns the display name of a user. Its public interface is Module.
package profile

import (
	"net/http"
	"strings"
	"sync"

	"github.com/gin-gonic/gin"
	"github.com/raihanpka/taskboard/internal/httpx"
	"github.com/raihanpka/taskboard/internal/modules/auth"
)

type Module struct {
	mu    sync.Mutex
	names map[string]string // user id -> display name
}

func New() *Module { return &Module{names: map[string]string{}} }

// Register mounts GET /me and PATCH /me on a group that already requires a signed in user.
func (m *Module) Register(r gin.IRoutes) {
	r.GET("/me", m.get)
	r.PATCH("/me", m.update)
}

func (m *Module) view(id string) gin.H {
	m.mu.Lock()
	defer m.mu.Unlock()
	return gin.H{"user_id": id, "display_name": m.names[id]}
}

func (m *Module) get(c *gin.Context) { c.JSON(http.StatusOK, m.view(auth.UserID(c))) }

func (m *Module) update(c *gin.Context) {
	var in struct {
		DisplayName *string `json:"display_name"`
	}
	if err := c.ShouldBindJSON(&in); err != nil || in.DisplayName == nil || len(strings.TrimSpace(*in.DisplayName)) == 0 || len(*in.DisplayName) > 60 {
		httpx.Error(c, http.StatusBadRequest, "display_name must be 1 to 60 characters")
		return
	}
	id := auth.UserID(c)
	m.mu.Lock()
	m.names[id] = strings.TrimSpace(*in.DisplayName)
	m.mu.Unlock()
	c.JSON(http.StatusOK, m.view(id))
}

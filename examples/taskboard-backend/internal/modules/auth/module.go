// Package auth signs users up and in and guards routes with a bearer token.
// Its public interface is Module, Middleware, and UserID.
package auth

import (
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/raihanpka/taskboard/internal/httpx"
)

const userKey = "auth.user"

type Module struct {
	svc *service
}

func New() *Module { return &Module{svc: newService()} }

// Register mounts the public routes: POST /signup and POST /login.
func (m *Module) Register(r gin.IRoutes) {
	r.POST("/signup", m.signup)
	r.POST("/login", m.login)
}

// Middleware rejects a request without a valid bearer token and stores the user id.
func (m *Module) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")
		id, ok := m.svc.userForToken(token)
		if !ok {
			httpx.Error(c, 401, "unauthorized")
			return
		}
		c.Set(userKey, id)
		c.Next()
	}
}

// UserID returns the signed in user id set by Middleware.
func UserID(c *gin.Context) string { return c.GetString(userKey) }

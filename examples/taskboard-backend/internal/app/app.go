// Package app is the composition root: the only place that wires every module together.
package app

import (
	"github.com/gin-gonic/gin"
	"github.com/raihanpka/taskboard/internal/httpx"
	"github.com/raihanpka/taskboard/internal/modules/auth"
	"github.com/raihanpka/taskboard/internal/modules/boards"
	"github.com/raihanpka/taskboard/internal/modules/labels"
	"github.com/raihanpka/taskboard/internal/modules/profile"
	"github.com/raihanpka/taskboard/internal/modules/tasks"
	"github.com/raihanpka/taskboard/internal/modules/webhooks"
)

// New builds the router with every module mounted under /api/v1.
func New() *gin.Engine {
	a := auth.New()
	b := boards.New()
	t := tasks.New(b)
	l := labels.New(b)
	p := profile.New()
	w := webhooks.New()

	e := httpx.NewEngine()
	e.GET("/healthz", func(c *gin.Context) { c.JSON(200, gin.H{"status": "ok"}) })

	v1 := e.Group("/api/v1")
	a.Register(v1)
	guarded := v1.Group("", a.Middleware())
	b.Register(guarded)
	t.Register(guarded)
	l.Register(guarded)
	p.Register(guarded)
	w.Register(guarded)
	return e
}

// Package httpx holds the small helpers every module shares.
package httpx

import (
	"github.com/gin-gonic/gin"
)

// Error writes the one error shape the API uses: {"error": "..."}.
func Error(c *gin.Context, status int, msg string) {
	c.AbortWithStatusJSON(status, gin.H{"error": msg})
}

// NewEngine returns a gin engine without the default logger, so tests stay quiet.
func NewEngine() *gin.Engine {
	gin.SetMode(gin.ReleaseMode)
	e := gin.New()
	e.Use(gin.Recovery())
	return e
}

package auth

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/raihanpka/taskboard/internal/httpx"
)

type credentials struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (m *Module) signup(c *gin.Context) {
	var in credentials
	if err := c.ShouldBindJSON(&in); err != nil || !strings.Contains(in.Email, "@") || len(in.Password) < 8 {
		httpx.Error(c, http.StatusBadRequest, "email and a password of 8 or more characters are required")
		return
	}
	token, err := m.svc.signup(in.Email, in.Password)
	if err != nil {
		httpx.Error(c, http.StatusConflict, err.Error())
		return
	}
	c.JSON(http.StatusCreated, gin.H{"token": token})
}

func (m *Module) login(c *gin.Context) {
	var in credentials
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid body")
		return
	}
	token, err := m.svc.login(in.Email, in.Password)
	if err != nil {
		httpx.Error(c, http.StatusUnauthorized, err.Error())
		return
	}
	c.JSON(http.StatusOK, gin.H{"token": token})
}

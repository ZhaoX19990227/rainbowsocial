package api

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"rainbow-social-backend/internal/service"
)

type AuthHandler struct {
	authService *service.AuthService
}

func NewAuthHandler(authService *service.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

type registerRequest struct {
	Account  string `json:"account" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type loginRequest struct {
	Account  string `json:"account" binding:"required"`
	Password string `json:"password" binding:"required"`
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req registerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		failure(c, http.StatusBadRequest, "账号和密码不能为空")
		return
	}

	user, err := h.authService.Register(req.Account, req.Password)
	if err != nil {
		failure(c, http.StatusBadRequest, err.Error())
		return
	}

	success(c, gin.H{
		"message": "register success",
		"user":    user,
	})
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req loginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		failure(c, http.StatusBadRequest, "账号和密码不能为空")
		return
	}

	token, user, err := h.authService.Login(req.Account, req.Password)
	if err != nil {
		failure(c, http.StatusBadRequest, err.Error())
		return
	}

	success(c, gin.H{
		"token": token,
		"user":  user,
	})
}

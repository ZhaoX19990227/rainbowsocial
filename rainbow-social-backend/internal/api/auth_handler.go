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

type sendCodeRequest struct {
	Email string `json:"email" binding:"required"`
}

type loginRequest struct {
	Email string `json:"email" binding:"required"`
	Code  string `json:"code" binding:"required"`
}

func (h *AuthHandler) SendCode(c *gin.Context) {
	var req sendCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		failure(c, http.StatusBadRequest, "email is required")
		return
	}

	if err := h.authService.SendCode(req.Email); err != nil {
		failure(c, http.StatusBadRequest, err.Error())
		return
	}

	success(c, gin.H{"message": "verification code sent"})
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req loginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		failure(c, http.StatusBadRequest, "email and code are required")
		return
	}

	token, user, err := h.authService.Login(req.Email, req.Code)
	if err != nil {
		failure(c, http.StatusBadRequest, err.Error())
		return
	}

	success(c, gin.H{
		"token": token,
		"user":  user,
	})
}

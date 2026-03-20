package api

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"rainbow-social-backend/internal/middleware"
	"rainbow-social-backend/internal/model"
	"rainbow-social-backend/internal/service"
)

type UserHandler struct {
	userService *service.UserService
}

func NewUserHandler(userService *service.UserService) *UserHandler {
	return &UserHandler{userService: userService}
}

func (h *UserHandler) GetProfile(c *gin.Context) {
	user, err := h.userService.GetProfile(middleware.GetUserID(c))
	if err != nil {
		failure(c, http.StatusNotFound, "user not found")
		return
	}
	success(c, user)
}

func (h *UserHandler) UpdateProfile(c *gin.Context) {
	var req model.User
	if err := c.ShouldBindJSON(&req); err != nil {
		failure(c, http.StatusBadRequest, "invalid profile payload")
		return
	}

	user, err := h.userService.UpdateProfile(middleware.GetUserID(c), req)
	if err != nil {
		failure(c, http.StatusBadRequest, err.Error())
		return
	}
	success(c, user)
}

func (h *UserHandler) ListUsers(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	users, err := h.userService.ListUsers(limit)
	if err != nil {
		failure(c, http.StatusInternalServerError, err.Error())
		return
	}
	success(c, users)
}

func (h *UserHandler) Nearby(c *gin.Context) {
	lat, err := strconv.ParseFloat(c.Query("lat"), 64)
	if err != nil {
		failure(c, http.StatusBadRequest, "lat must be a valid number")
		return
	}
	lng, err := strconv.ParseFloat(c.Query("lng"), 64)
	if err != nil {
		failure(c, http.StatusBadRequest, "lng must be a valid number")
		return
	}

	users, err := h.userService.Nearby(middleware.GetUserID(c), lat, lng)
	if err != nil {
		failure(c, http.StatusInternalServerError, err.Error())
		return
	}
	success(c, users)
}

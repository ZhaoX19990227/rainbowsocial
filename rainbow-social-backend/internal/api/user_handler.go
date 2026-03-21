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

type deviceTokenRequest struct {
	Token    string `json:"token" binding:"required"`
	Platform string `json:"platform"`
}

type updateLocationRequest struct {
	Lat           float64 `json:"lat" binding:"required"`
	Lng           float64 `json:"lng" binding:"required"`
	LocationLabel string  `json:"location_label"`
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

func (h *UserHandler) UpdateLocation(c *gin.Context) {
	var req updateLocationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		failure(c, http.StatusBadRequest, "invalid location payload")
		return
	}

	user, err := h.userService.UpdateLocation(
		middleware.GetUserID(c),
		req.Lat,
		req.Lng,
		req.LocationLabel,
	)
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
	minAge, _ := strconv.Atoi(c.DefaultQuery("min_age", "0"))
	maxAge, _ := strconv.Atoi(c.DefaultQuery("max_age", "0"))
	onlineOnly := c.DefaultQuery("online_only", "false") == "true"
	tag := c.Query("tag")

	users, err := h.userService.Nearby(middleware.GetUserID(c), lat, lng, minAge, maxAge, onlineOnly, tag)
	if err != nil {
		failure(c, http.StatusInternalServerError, err.Error())
		return
	}
	success(c, users)
}

func (h *UserHandler) SaveDeviceToken(c *gin.Context) {
	var req deviceTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		failure(c, http.StatusBadRequest, "token is required")
		return
	}

	if err := h.userService.SaveDeviceToken(middleware.GetUserID(c), req.Token, req.Platform); err != nil {
		failure(c, http.StatusBadRequest, err.Error())
		return
	}
	success(c, gin.H{"message": "device token saved"})
}

func (h *UserHandler) DeleteDeviceToken(c *gin.Context) {
	var req deviceTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		failure(c, http.StatusBadRequest, "token is required")
		return
	}

	if err := h.userService.DeleteDeviceToken(middleware.GetUserID(c), req.Token); err != nil {
		failure(c, http.StatusBadRequest, err.Error())
		return
	}
	success(c, gin.H{"message": "device token deleted"})
}

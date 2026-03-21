package api

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"rainbow-social-backend/internal/middleware"
	"rainbow-social-backend/internal/service"
)

type HoroscopeHandler struct {
	horoscopeService *service.HoroscopeService
	userService      *service.UserService
}

func NewHoroscopeHandler(horoscopeService *service.HoroscopeService, userService *service.UserService) *HoroscopeHandler {
	return &HoroscopeHandler{
		horoscopeService: horoscopeService,
		userService:      userService,
	}
}

func (h *HoroscopeHandler) Today(c *gin.Context) {
	profile, err := h.userService.GetProfile(middleware.GetUserID(c))
	if err != nil {
		failure(c, http.StatusNotFound, "user not found")
		return
	}
	if profile.ZodiacSign == "" {
		failure(c, http.StatusBadRequest, "zodiac_sign is required")
		return
	}

	date := time.Now()
	if raw := c.Query("date"); raw != "" {
		parsed, err := time.Parse("2006-01-02", raw)
		if err != nil {
			failure(c, http.StatusBadRequest, "date must be in YYYY-MM-DD format")
			return
		}
		date = parsed
	}

	data, err := h.horoscopeService.BuildDaily(c.Request.Context(), profile.ZodiacSign, date)
	if err != nil {
		failure(c, http.StatusBadGateway, err.Error())
		return
	}
	success(c, data)
}

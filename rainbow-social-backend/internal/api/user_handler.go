package api

import (
	"net/http"
	"strconv"
	"strings"
	"time"

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

type updateMomentRequest struct {
	ImageURL      string   `json:"image_url"`
	ImageURLs     []string `json:"image_urls"`
	Caption       string   `json:"caption"`
	LocationLabel string   `json:"location_label"`
	CreatedAt     *string  `json:"created_at"`
}

type updateProfileRequest struct {
	Nickname        string                `json:"nickname"`
	Avatar          string                `json:"avatar"`
	Photos          []string              `json:"photos"`
	Moments         []updateMomentRequest `json:"moments"`
	Age             int                   `json:"age"`
	HeightCM        int                   `json:"height_cm"`
	WeightKG        int                   `json:"weight_kg"`
	Birthday        string                `json:"birthday"`
	ZodiacSign      string                `json:"zodiac_sign"`
	MBTIType        string                `json:"mbti_type"`
	Bio             string                `json:"bio"`
	Tags            []string              `json:"tags"`
	PositionRole    string                `json:"position_role"`
	StatusID        string                `json:"status_id"`
	StatusLabel     string                `json:"status_label"`
	StatusExpiresAt string                `json:"status_expires_at"`
	Lat             float64               `json:"lat"`
	Lng             float64               `json:"lng"`
	LocationLabel   string                `json:"location_label"`
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

func (h *UserHandler) GetUser(c *gin.Context) {
	userID, err := strconv.ParseInt(c.Param("userID"), 10, 64)
	if err != nil || userID <= 0 {
		failure(c, http.StatusBadRequest, "invalid user id")
		return
	}

	user, err := h.userService.GetUser(middleware.GetUserID(c), userID)
	if err != nil {
		failure(c, http.StatusNotFound, "user not found")
		return
	}
	success(c, user)
}

func (h *UserHandler) UpdateProfile(c *gin.Context) {
	var req updateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		failure(c, http.StatusBadRequest, "invalid profile payload")
		return
	}

	user, err := h.userService.UpdateProfile(
		middleware.GetUserID(c),
		model.User{
			Nickname:        req.Nickname,
			Avatar:          req.Avatar,
			Photos:          req.Photos,
			Moments:         mapUpdateMoments(req.Moments),
			Age:             req.Age,
			HeightCM:        req.HeightCM,
			WeightKG:        req.WeightKG,
			Birthday:        req.Birthday,
			ZodiacSign:      req.ZodiacSign,
			MBTIType:        req.MBTIType,
			Bio:             req.Bio,
			Tags:            req.Tags,
			PositionRole:    req.PositionRole,
			StatusID:        req.StatusID,
			StatusLabel:     req.StatusLabel,
			StatusExpiresAt: req.StatusExpiresAt,
			Lat:             req.Lat,
			Lng:             req.Lng,
			LocationLabel:   req.LocationLabel,
		},
	)
	if err != nil {
		failure(c, http.StatusBadRequest, err.Error())
		return
	}
	success(c, user)
}

func mapUpdateMoments(items []updateMomentRequest) []model.Moment {
	result := make([]model.Moment, 0, len(items))
	for _, item := range items {
		moment := model.Moment{
			ImageURL:      item.ImageURL,
			ImageURLs:     item.ImageURLs,
			Caption:       item.Caption,
			LocationLabel: item.LocationLabel,
		}
		if item.CreatedAt != nil {
			if parsed, ok := parseMomentTime(*item.CreatedAt); ok {
				moment.CreatedAt = parsed
			}
		}
		result = append(result, moment)
	}
	return result
}

func parseMomentTime(raw string) (time.Time, bool) {
	raw = strings.TrimSpace(raw)
	if raw == "" || raw == "null" {
		return time.Time{}, false
	}
	parsed, err := time.Parse(time.RFC3339Nano, raw)
	if err != nil {
		return time.Time{}, false
	}
	return parsed, true
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
	mbtiType := c.Query("mbti_type")
	zodiacSign := c.Query("zodiac_sign")

	users, err := h.userService.Nearby(middleware.GetUserID(c), lat, lng, minAge, maxAge, onlineOnly, tag, mbtiType, zodiacSign)
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

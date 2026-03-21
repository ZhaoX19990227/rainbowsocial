package api

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"rainbow-social-backend/internal/middleware"
	"rainbow-social-backend/internal/service"
)

type SwipeHandler struct {
	swipeService *service.SwipeService
}

func NewSwipeHandler(swipeService *service.SwipeService) *SwipeHandler {
	return &SwipeHandler{swipeService: swipeService}
}

type swipeRequest struct {
	TargetUserID int64 `json:"target_user_id" binding:"required"`
}

func (h *SwipeHandler) Like(c *gin.Context) {
	h.handleSwipe(c, "like")
}

func (h *SwipeHandler) Pass(c *gin.Context) {
	h.handleSwipe(c, "pass")
}

func (h *SwipeHandler) Undo(c *gin.Context) {
	var req swipeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		failure(c, http.StatusBadRequest, "target_user_id is required")
		return
	}

	if err := h.swipeService.UndoSwipe(middleware.GetUserID(c), req.TargetUserID); err != nil {
		failure(c, http.StatusBadRequest, err.Error())
		return
	}

	success(c, gin.H{
		"action": "undo",
	})
}

func (h *SwipeHandler) Recommendations(c *gin.Context) {
	users, err := h.swipeService.Recommendations(middleware.GetUserID(c))
	if err != nil {
		failure(c, http.StatusInternalServerError, err.Error())
		return
	}
	success(c, users)
}

func (h *SwipeHandler) handleSwipe(c *gin.Context, action string) {
	var req swipeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		failure(c, http.StatusBadRequest, "target_user_id is required")
		return
	}

	matched, err := h.swipeService.Swipe(middleware.GetUserID(c), req.TargetUserID, action)
	if err != nil {
		failure(c, http.StatusBadRequest, err.Error())
		return
	}

	success(c, gin.H{
		"action":  action,
		"matched": matched,
	})
}

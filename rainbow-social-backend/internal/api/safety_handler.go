package api

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"rainbow-social-backend/internal/middleware"
	"rainbow-social-backend/internal/service"
)

type SafetyHandler struct {
	safetyService *service.SafetyService
}

func NewSafetyHandler(safetyService *service.SafetyService) *SafetyHandler {
	return &SafetyHandler{safetyService: safetyService}
}

type reportRequest struct {
	ReportedUserID int64  `json:"reported_user_id" binding:"required"`
	Reason         string `json:"reason" binding:"required"`
	Details        string `json:"details"`
}

type blockRequest struct {
	BlockedUserID int64  `json:"blocked_user_id" binding:"required"`
	Reason        string `json:"reason"`
}

func (h *SafetyHandler) Report(c *gin.Context) {
	var req reportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		failure(c, http.StatusBadRequest, "reported_user_id and reason are required")
		return
	}

	if err := h.safetyService.Report(middleware.GetUserID(c), req.ReportedUserID, req.Reason, req.Details); err != nil {
		failure(c, http.StatusBadRequest, err.Error())
		return
	}
	success(c, gin.H{"message": "report submitted"})
}

func (h *SafetyHandler) Block(c *gin.Context) {
	var req blockRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		failure(c, http.StatusBadRequest, "blocked_user_id is required")
		return
	}

	if err := h.safetyService.Block(middleware.GetUserID(c), req.BlockedUserID, req.Reason); err != nil {
		failure(c, http.StatusBadRequest, err.Error())
		return
	}
	success(c, gin.H{"message": "user blocked"})
}

func (h *SafetyHandler) Unblock(c *gin.Context) {
	var req blockRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		failure(c, http.StatusBadRequest, "blocked_user_id is required")
		return
	}

	if err := h.safetyService.Unblock(middleware.GetUserID(c), req.BlockedUserID); err != nil {
		failure(c, http.StatusBadRequest, err.Error())
		return
	}
	success(c, gin.H{"message": "user unblocked"})
}

func (h *SafetyHandler) BlockStatus(c *gin.Context) {
	targetUserID, err := strconv.ParseInt(c.Param("targetUserID"), 10, 64)
	if err != nil {
		failure(c, http.StatusBadRequest, "invalid target user id")
		return
	}

	status, err := h.safetyService.BlockStatus(middleware.GetUserID(c), targetUserID)
	if err != nil {
		failure(c, http.StatusBadRequest, err.Error())
		return
	}
	success(c, status)
}

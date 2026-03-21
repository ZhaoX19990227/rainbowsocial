package api

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"rainbow-social-backend/internal/middleware"
	"rainbow-social-backend/internal/service"
)

type ChatHandler struct {
	chatService *service.ChatService
}

type pinConversationRequest struct {
	IsPinned bool `json:"is_pinned"`
}

func NewChatHandler(chatService *service.ChatService) *ChatHandler {
	return &ChatHandler{chatService: chatService}
}

func (h *ChatHandler) ListConversations(c *gin.Context) {
	items, err := h.chatService.ListConversationSummaries(middleware.GetUserID(c))
	if err != nil {
		failure(c, http.StatusInternalServerError, err.Error())
		return
	}
	success(c, items)
}

func (h *ChatHandler) MarkRead(c *gin.Context) {
	peerUserID, err := strconv.ParseInt(c.Param("peerUserID"), 10, 64)
	if err != nil {
		failure(c, http.StatusBadRequest, "invalid peer user id")
		return
	}

	if err := h.chatService.MarkConversationRead(middleware.GetUserID(c), peerUserID); err != nil {
		failure(c, http.StatusBadRequest, err.Error())
		return
	}
	success(c, gin.H{"message": "conversation marked as read"})
}

func (h *ChatHandler) SetPinned(c *gin.Context) {
	peerUserID, err := strconv.ParseInt(c.Param("peerUserID"), 10, 64)
	if err != nil {
		failure(c, http.StatusBadRequest, "invalid peer user id")
		return
	}

	var req pinConversationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		failure(c, http.StatusBadRequest, "is_pinned is required")
		return
	}

	if err := h.chatService.SetConversationPinned(middleware.GetUserID(c), peerUserID, req.IsPinned); err != nil {
		failure(c, http.StatusBadRequest, err.Error())
		return
	}
	success(c, gin.H{"message": "conversation updated"})
}

func (h *ChatHandler) ListMessages(c *gin.Context) {
	peerUserID, err := strconv.ParseInt(c.Param("peerUserID"), 10, 64)
	if err != nil {
		failure(c, http.StatusBadRequest, "invalid peer user id")
		return
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "30"))
	beforeID, _ := strconv.ParseInt(c.DefaultQuery("before_id", "0"), 10, 64)
	items, err := h.chatService.ListMessages(middleware.GetUserID(c), peerUserID, limit, beforeID)
	if err != nil {
		failure(c, http.StatusBadRequest, err.Error())
		return
	}
	success(c, items)
}

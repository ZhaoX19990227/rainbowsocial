package api

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"

	"rainbow-social-backend/internal/service"
	"rainbow-social-backend/internal/ws"
	"rainbow-social-backend/pkg/utils"
)

type WSHandler struct {
	jwtManager  *utils.JWTManager
	chatService *service.ChatService
	hub         *ws.Hub
	upgrader    websocket.Upgrader
}

func NewWSHandler(jwtManager *utils.JWTManager, chatService *service.ChatService, hub *ws.Hub) *WSHandler {
	return &WSHandler{
		jwtManager:  jwtManager,
		chatService: chatService,
		hub:         hub,
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool { return true },
		},
	}
}

func (h *WSHandler) Connect(c *gin.Context) {
	token := strings.TrimSpace(c.Query("token"))
	if token == "" {
		authHeader := strings.TrimSpace(c.GetHeader("Authorization"))
		if strings.HasPrefix(authHeader, "Bearer ") {
			token = strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer "))
		}
	}
	if token == "" {
		failure(c, http.StatusUnauthorized, "missing websocket token")
		return
	}

	claims, err := h.jwtManager.ParseToken(token)
	if err != nil {
		failure(c, http.StatusUnauthorized, "invalid websocket token")
		return
	}

	if rawUserID := strings.TrimSpace(c.Query("user_id")); rawUserID != "" {
		queryUserID, err := strconv.ParseInt(rawUserID, 10, 64)
		if err != nil || queryUserID != claims.UserID {
			failure(c, http.StatusUnauthorized, "user_id does not match token")
			return
		}
	}

	conn, err := h.upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		return
	}

	client := ws.NewClient(h.hub, conn, claims.UserID, h.chatService)
	h.hub.RegisterClient(client)
	go client.WritePump()
	go client.ReadPump()
}

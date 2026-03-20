package api

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"rainbow-social-backend/internal/middleware"
	"rainbow-social-backend/internal/service"
)

type MatchHandler struct {
	matchService *service.MatchService
}

func NewMatchHandler(matchService *service.MatchService) *MatchHandler {
	return &MatchHandler{matchService: matchService}
}

func (h *MatchHandler) ListMatches(c *gin.Context) {
	matches, err := h.matchService.ListMatches(middleware.GetUserID(c))
	if err != nil {
		failure(c, http.StatusInternalServerError, err.Error())
		return
	}
	success(c, matches)
}

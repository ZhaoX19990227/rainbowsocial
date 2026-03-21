package api

import (
	"net/http"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"

	"rainbow-social-backend/internal/config"
	"rainbow-social-backend/internal/middleware"
	"rainbow-social-backend/internal/service"
	"rainbow-social-backend/internal/ws"
	"rainbow-social-backend/pkg/utils"
)

type Dependencies struct {
	JWTManager       *utils.JWTManager
	AuthService      *service.AuthService
	UserService      *service.UserService
	HoroscopeService *service.HoroscopeService
	SwipeService     *service.SwipeService
	MatchService     *service.MatchService
	SafetyService    *service.SafetyService
	ChatService      *service.ChatService
	Hub              *ws.Hub
}

func NewRouter(cfg *config.Config, deps Dependencies) *gin.Engine {
	router := gin.New()
	router.Use(gin.Recovery())
	router.Use(middleware.Logging())

	corsConfig := cors.Config{
		AllowOrigins:     cfg.AllowedOrigins,
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		AllowWebSockets:  true,
		MaxAge:           12 * time.Hour,
	}
	if len(cfg.AllowedOrigins) == 1 && cfg.AllowedOrigins[0] == "*" {
		corsConfig.AllowAllOrigins = true
		corsConfig.AllowCredentials = false
		corsConfig.AllowOrigins = nil
	}
	router.Use(cors.New(corsConfig))

	authHandler := NewAuthHandler(deps.AuthService)
	userHandler := NewUserHandler(deps.UserService)
	horoscopeHandler := NewHoroscopeHandler(deps.HoroscopeService, deps.UserService)
	swipeHandler := NewSwipeHandler(deps.SwipeService)
	matchHandler := NewMatchHandler(deps.MatchService)
	safetyHandler := NewSafetyHandler(deps.SafetyService)
	chatHandler := NewChatHandler(deps.ChatService, deps.Hub)
	wsHandler := NewWSHandler(deps.JWTManager, deps.ChatService, deps.Hub)
	uploadHandler := NewUploadHandler(cfg)

	router.Static("/uploads", cfg.UploadDir)

	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	auth := router.Group("/auth")
	{
		auth.POST("/register", authHandler.Register)
		auth.POST("/login", authHandler.Login)
	}

	protected := router.Group("/")
	protected.Use(middleware.Auth(deps.JWTManager))
	{
		protected.GET("/user/profile", userHandler.GetProfile)
		protected.PUT("/user/profile", userHandler.UpdateProfile)
		protected.POST("/user/location", userHandler.UpdateLocation)
		protected.GET("/users/list", userHandler.ListUsers)
		protected.GET("/users/nearby", userHandler.Nearby)
		protected.GET("/horoscope/today", horoscopeHandler.Today)
		protected.POST("/uploads/image", uploadHandler.UploadImage)
		protected.POST("/uploads/audio", uploadHandler.UploadAudio)
		protected.POST("/user/device-token", userHandler.SaveDeviceToken)
		protected.DELETE("/user/device-token", userHandler.DeleteDeviceToken)
		protected.POST("/swipe/like", swipeHandler.Like)
		protected.POST("/swipe/pass", swipeHandler.Pass)
		protected.POST("/swipe/undo", swipeHandler.Undo)
		protected.GET("/recommendations", swipeHandler.Recommendations)
		protected.GET("/matches", matchHandler.ListMatches)
		protected.GET("/matches/summary", matchHandler.Summary)
		protected.GET("/conversations", chatHandler.ListConversations)
		protected.GET("/conversations/:peerUserID/messages", chatHandler.ListMessages)
		protected.POST("/conversations/:peerUserID/read", chatHandler.MarkRead)
		protected.PUT("/conversations/:peerUserID/pin", chatHandler.SetPinned)
		protected.POST("/report", safetyHandler.Report)
		protected.POST("/block", safetyHandler.Block)
		protected.DELETE("/block", safetyHandler.Unblock)
		protected.GET("/block/:targetUserID/status", safetyHandler.BlockStatus)
	}

	router.GET("/ws", wsHandler.Connect)

	return router
}

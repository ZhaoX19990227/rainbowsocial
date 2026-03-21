package cmd

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"rainbow-social-backend/internal/api"
	"rainbow-social-backend/internal/config"
	"rainbow-social-backend/internal/repository"
	"rainbow-social-backend/internal/service"
	"rainbow-social-backend/internal/ws"
	"rainbow-social-backend/pkg/email"
	"rainbow-social-backend/pkg/utils"
)

func Run() error {
	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("load config: %w", err)
	}

	db, err := repository.NewDatabase(cfg)
	if err != nil {
		return fmt.Errorf("init database: %w", err)
	}
	defer db.Close()

	jwtManager := utils.NewJWTManager(cfg.JWTSecret, cfg.JWTExpiryHours)
	emailSender := email.NewSMTPEmailSender(cfg)

	authRepo := repository.NewAuthRepository(db)
	userRepo := repository.NewUserRepository(db)
	horoscopeRepo := repository.NewHoroscopeRepository(db)
	swipeRepo := repository.NewSwipeRepository(db)
	matchRepo := repository.NewMatchRepository(db)
	safetyRepo := repository.NewSafetyRepository(db)
	chatRepo := repository.NewChatRepository(db)

	authService := service.NewAuthService(authRepo, userRepo, emailSender, jwtManager, time.Duration(cfg.OTPExpiryMinutes)*time.Minute)
	userService := service.NewUserService(userRepo)
	horoscopeService := service.NewHoroscopeService(cfg, horoscopeRepo)
	swipeService := service.NewSwipeService(userRepo, swipeRepo, matchRepo, safetyRepo)
	matchService := service.NewMatchService(matchRepo)
	safetyService := service.NewSafetyService(safetyRepo, matchRepo)
	chatService := service.NewChatService(chatRepo, userRepo, matchRepo, safetyRepo)

	hub := ws.NewHub(userService)
	go hub.Run()

	router := api.NewRouter(cfg, api.Dependencies{
		JWTManager:       jwtManager,
		AuthService:      authService,
		UserService:      userService,
		HoroscopeService: horoscopeService,
		SwipeService:     swipeService,
		MatchService:     matchService,
		SafetyService:    safetyService,
		ChatService:      chatService,
		Hub:              hub,
	})

	server := &http.Server{
		Addr:              ":" + cfg.ServerPort,
		Handler:           router,
		ReadHeaderTimeout: 5 * time.Second,
	}

	errCh := make(chan error, 1)
	go func() {
		errCh <- server.ListenAndServe()
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)

	select {
	case err := <-errCh:
		if err != nil && err != http.ErrServerClosed {
			return fmt.Errorf("listen server: %w", err)
		}
	case <-stop:
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	return server.Shutdown(ctx)
}

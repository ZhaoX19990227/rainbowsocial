package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/joho/godotenv"
)

type Config struct {
	AppEnv           string
	ServerPort       string
	DatabasePath     string
	UploadDir        string
	JWTSecret        string
	JWTExpiryHours   int
	OTPExpiryMinutes int
	AllowedOrigins   []string
	SMTPHost         string
	SMTPPort         int
	SMTPUsername     string
	SMTPPassword     string
	SMTPFrom         string
	SMTPEnabled      bool
}

func Load() (*Config, error) {
	_ = godotenv.Load()

	cfg := &Config{
		AppEnv:           getEnv("APP_ENV", "development"),
		ServerPort:       getEnv("SERVER_PORT", "8088"),
		DatabasePath:     getEnv("DATABASE_PATH", "./social_app.db"),
		UploadDir:        getEnv("UPLOAD_DIR", "./uploads"),
		JWTSecret:        getEnv("JWT_SECRET", "change-me-in-production"),
		JWTExpiryHours:   getEnvAsInt("JWT_EXPIRY_HOURS", 72),
		OTPExpiryMinutes: getEnvAsInt("OTP_EXPIRY_MINUTES", 5),
		AllowedOrigins:   getEnvAsList("ALLOWED_ORIGINS", []string{"*"}),
		SMTPHost:         getEnv("SMTP_HOST", "smtp.qq.com"),
		SMTPPort:         getEnvAsInt("SMTP_PORT", 465),
		SMTPUsername:     getEnv("SMTP_USERNAME", ""),
		SMTPPassword:     getEnv("SMTP_PASSWORD", ""),
		SMTPFrom:         getEnv("SMTP_FROM", ""),
		SMTPEnabled:      getEnvAsBool("SMTP_ENABLED", false),
	}

	if cfg.JWTSecret == "" {
		return nil, fmt.Errorf("JWT_SECRET is required")
	}

	if cfg.SMTPFrom == "" {
		cfg.SMTPFrom = cfg.SMTPUsername
	}

	return cfg, nil
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}

func getEnvAsInt(key string, fallback int) int {
	value, exists := os.LookupEnv(key)
	if !exists || strings.TrimSpace(value) == "" {
		return fallback
	}

	parsed, err := strconv.Atoi(value)
	if err != nil {
		return fallback
	}
	return parsed
}

func getEnvAsBool(key string, fallback bool) bool {
	value, exists := os.LookupEnv(key)
	if !exists || strings.TrimSpace(value) == "" {
		return fallback
	}

	parsed, err := strconv.ParseBool(value)
	if err != nil {
		return fallback
	}
	return parsed
}

func getEnvAsList(key string, fallback []string) []string {
	value, exists := os.LookupEnv(key)
	if !exists || strings.TrimSpace(value) == "" {
		return fallback
	}

	parts := strings.Split(value, ",")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		trimmed := strings.TrimSpace(part)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}
	if len(result) == 0 {
		return fallback
	}
	return result
}

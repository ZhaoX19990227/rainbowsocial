package service

import (
	"database/sql"
	"errors"
	"fmt"
	"net/mail"
	"strings"
	"time"

	"rainbow-social-backend/internal/model"
	"rainbow-social-backend/internal/repository"
	"rainbow-social-backend/pkg/email"
	"rainbow-social-backend/pkg/utils"
)

type AuthService struct {
	authRepo   *repository.AuthRepository
	userRepo   *repository.UserRepository
	sender     email.Sender
	jwtManager *utils.JWTManager
	otpTTL     time.Duration
}

func NewAuthService(
	authRepo *repository.AuthRepository,
	userRepo *repository.UserRepository,
	sender email.Sender,
	jwtManager *utils.JWTManager,
	otpTTL time.Duration,
) *AuthService {
	return &AuthService{
		authRepo:   authRepo,
		userRepo:   userRepo,
		sender:     sender,
		jwtManager: jwtManager,
		otpTTL:     otpTTL,
	}
}

func (s *AuthService) SendCode(emailAddr string) error {
	emailAddr = strings.TrimSpace(strings.ToLower(emailAddr))
	if _, err := mail.ParseAddress(emailAddr); err != nil {
		return fmt.Errorf("invalid email address")
	}

	code, err := utils.GenerateOTP()
	if err != nil {
		return err
	}

	if err := s.authRepo.SaveCode(emailAddr, code, time.Now().UTC().Add(s.otpTTL)); err != nil {
		return err
	}

	return s.sender.SendOTP(emailAddr, code)
}

func (s *AuthService) Login(emailAddr, code string) (string, *model.User, error) {
	emailAddr = strings.TrimSpace(strings.ToLower(emailAddr))
	code = strings.TrimSpace(code)

	if _, err := mail.ParseAddress(emailAddr); err != nil {
		return "", nil, fmt.Errorf("invalid email address")
	}
	if len(code) != 6 {
		return "", nil, fmt.Errorf("verification code must be 6 digits")
	}

	otp, err := s.authRepo.GetCode(emailAddr)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return "", nil, fmt.Errorf("verification code not found")
		}
		return "", nil, err
	}

	if otp.ExpiresAt.Before(time.Now().UTC()) {
		_ = s.authRepo.DeleteCode(emailAddr)
		return "", nil, fmt.Errorf("verification code expired")
	}
	if otp.Code != code {
		return "", nil, fmt.Errorf("invalid verification code")
	}

	user, err := s.userRepo.GetByEmail(emailAddr)
	if err != nil {
		if !errors.Is(err, sql.ErrNoRows) {
			return "", nil, err
		}
		nickname := strings.Split(emailAddr, "@")[0]
		user, err = s.userRepo.Create(emailAddr, nickname)
		if err != nil {
			return "", nil, err
		}
	}

	_ = s.authRepo.DeleteCode(emailAddr)

	token, err := s.jwtManager.GenerateToken(user.ID, user.Email)
	if err != nil {
		return "", nil, err
	}

	return token, user, nil
}

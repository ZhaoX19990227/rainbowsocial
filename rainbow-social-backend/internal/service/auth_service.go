package service

import (
	"database/sql"
	"errors"
	"fmt"
	"strings"

	"golang.org/x/crypto/bcrypt"

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
}

func NewAuthService(
	authRepo *repository.AuthRepository,
	userRepo *repository.UserRepository,
	sender email.Sender,
	jwtManager *utils.JWTManager,
	_ any,
) *AuthService {
	return &AuthService{
		authRepo:   authRepo,
		userRepo:   userRepo,
		sender:     sender,
		jwtManager: jwtManager,
	}
}

func (s *AuthService) Register(account, password string) (*model.User, error) {
	account = normalizeAccount(account)
	password = strings.TrimSpace(password)

	if err := validateAccount(account); err != nil {
		return nil, err
	}
	if err := validatePassword(password); err != nil {
		return nil, err
	}

	if _, err := s.userRepo.GetByAccount(account); err == nil {
		return nil, fmt.Errorf("账号已存在")
	} else if !errors.Is(err, sql.ErrNoRows) {
		return nil, err
	}

	passwordHash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("password hash failed")
	}

	nickname := account
	user, err := s.userRepo.Create(
		account,
		account,
		nickname,
		string(passwordHash),
	)
	if err != nil {
		return nil, err
	}
	return user, nil
}

func (s *AuthService) Login(account, password string) (string, *model.User, error) {
	account = normalizeAccount(account)
	password = strings.TrimSpace(password)

	if err := validateAccount(account); err != nil {
		return "", nil, err
	}
	if password == "" {
		return "", nil, fmt.Errorf("密码不能为空")
	}

	passwordHash, err := s.userRepo.GetPasswordHashByAccount(account)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return "", nil, fmt.Errorf("账号或密码错误")
		}
		return "", nil, err
	}

	if passwordHash == "" {
		return "", nil, fmt.Errorf("该账号暂不支持密码登录")
	}
	if err := bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(password)); err != nil {
		return "", nil, fmt.Errorf("账号或密码错误")
	}

	user, err := s.userRepo.GetByAccount(account)
	if err != nil {
		return "", nil, err
	}

	token, err := s.jwtManager.GenerateToken(user.ID, user.Email)
	if err != nil {
		return "", nil, err
	}

	return token, user, nil
}

func normalizeAccount(account string) string {
	return strings.ToLower(strings.TrimSpace(account))
}

func validateAccount(account string) error {
	if len(account) < 4 || len(account) > 24 {
		return fmt.Errorf("账号长度需为 4 到 24 位")
	}
	for _, char := range account {
		if (char >= 'a' && char <= 'z') ||
			(char >= '0' && char <= '9') ||
			char == '_' {
			continue
		}
		return fmt.Errorf("账号仅支持小写字母、数字和下划线")
	}
	return nil
}

func validatePassword(password string) error {
	if len(password) < 6 || len(password) > 32 {
		return fmt.Errorf("密码长度需为 6 到 32 位")
	}
	return nil
}

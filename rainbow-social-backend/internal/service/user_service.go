package service

import (
	"database/sql"
	"fmt"
	"sort"
	"strings"

	"rainbow-social-backend/internal/model"
	"rainbow-social-backend/internal/repository"
	"rainbow-social-backend/pkg/utils"
)

type UserService struct {
	userRepo *repository.UserRepository
}

func NewUserService(userRepo *repository.UserRepository) *UserService {
	return &UserService{userRepo: userRepo}
}

func (s *UserService) GetProfile(userID int64) (*model.User, error) {
	return s.userRepo.GetByID(userID)
}

func (s *UserService) UpdateProfile(userID int64, input model.User) (*model.User, error) {
	existing, err := s.userRepo.GetByID(userID)
	if err != nil {
		return nil, err
	}

	existing.Nickname = strings.TrimSpace(input.Nickname)
	existing.Avatar = strings.TrimSpace(input.Avatar)
	existing.Age = input.Age
	existing.Bio = strings.TrimSpace(input.Bio)
	existing.Tags = sanitizeTags(input.Tags)
	existing.Lat = input.Lat
	existing.Lng = input.Lng

	if existing.Nickname == "" {
		return nil, fmt.Errorf("nickname is required")
	}
	if existing.Age < 18 || existing.Age > 99 {
		return nil, fmt.Errorf("age must be between 18 and 99")
	}

	return s.userRepo.UpdateProfile(existing)
}

func (s *UserService) ListUsers(limit int) ([]model.User, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	return s.userRepo.ListUsers(limit)
}

func (s *UserService) Nearby(userID int64, lat, lng float64) ([]model.User, error) {
	users, err := s.userRepo.ListOtherUsers(userID)
	if err != nil {
		return nil, err
	}

	for i := range users {
		users[i].DistanceKM = utils.DistanceKM(lat, lng, users[i].Lat, users[i].Lng)
	}

	sort.Slice(users, func(i, j int) bool {
		if users[i].DistanceKM == users[j].DistanceKM {
			return users[i].OnlineStatus && !users[j].OnlineStatus
		}
		return users[i].DistanceKM < users[j].DistanceKM
	})

	return users, nil
}

func (s *UserService) SetOnlineStatus(userID int64, online bool) error {
	return s.userRepo.SetOnlineStatus(userID, online)
}

func sanitizeTags(tags []string) []string {
	result := make([]string, 0, len(tags))
	for _, tag := range tags {
		tag = strings.TrimSpace(tag)
		if tag != "" {
			result = append(result, tag)
		}
	}
	return result
}

func IsNotFound(err error) bool {
	return err == sql.ErrNoRows
}

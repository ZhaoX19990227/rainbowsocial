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
	existing.Photos = sanitizePhotos(input.Photos)
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

func (s *UserService) Nearby(userID int64, lat, lng float64, minAge, maxAge int, onlineOnly bool, tag string) ([]model.User, error) {
	users, err := s.userRepo.ListOtherUsers(userID)
	if err != nil {
		return nil, err
	}

	tag = strings.ToLower(strings.TrimSpace(tag))
	for i := range users {
		if minAge > 0 && users[i].Age < minAge {
			users[i].DistanceKM = -1
			continue
		}
		if maxAge > 0 && users[i].Age > maxAge {
			users[i].DistanceKM = -1
			continue
		}
		if onlineOnly && !users[i].OnlineStatus {
			users[i].DistanceKM = -1
			continue
		}
		if tag != "" && !containsTag(users[i].Tags, tag) {
			users[i].DistanceKM = -1
			continue
		}
		users[i].DistanceKM = utils.DistanceKM(lat, lng, users[i].Lat, users[i].Lng)
	}

	filtered := users[:0]
	for _, user := range users {
		if user.DistanceKM >= 0 {
			filtered = append(filtered, user)
		}
	}

	sort.Slice(filtered, func(i, j int) bool {
		if filtered[i].DistanceKM == filtered[j].DistanceKM {
			return filtered[i].OnlineStatus && !filtered[j].OnlineStatus
		}
		return filtered[i].DistanceKM < filtered[j].DistanceKM
	})

	return filtered, nil
}

func (s *UserService) SetOnlineStatus(userID int64, online bool) error {
	return s.userRepo.SetOnlineStatus(userID, online)
}

func sanitizeTags(tags []string) []string {
	result := make([]string, 0, len(tags))
	seen := make(map[string]struct{}, len(tags))
	for _, tag := range tags {
		tag = strings.TrimSpace(tag)
		if tag == "" {
			continue
		}
		if _, ok := seen[tag]; ok {
			continue
		}
		seen[tag] = struct{}{}
		result = append(result, tag)
		if len(result) >= 5 {
			break
		}
	}
	return result
}

func sanitizePhotos(photos []string) []string {
	result := make([]string, 0, len(photos))
	seen := make(map[string]struct{}, len(photos))
	for _, photo := range photos {
		photo = strings.TrimSpace(photo)
		if photo == "" {
			continue
		}
		if _, ok := seen[photo]; ok {
			continue
		}
		seen[photo] = struct{}{}
		result = append(result, photo)
		if len(result) >= 6 {
			break
		}
	}
	return result
}

func containsTag(tags []string, target string) bool {
	for _, tag := range tags {
		if strings.Contains(strings.ToLower(tag), target) {
			return true
		}
	}
	return false
}

func (s *UserService) SaveDeviceToken(userID int64, token, platform string) error {
	token = strings.TrimSpace(token)
	platform = strings.TrimSpace(platform)
	if token == "" {
		return fmt.Errorf("device token is required")
	}
	return s.userRepo.SaveDeviceToken(userID, token, platform)
}

func (s *UserService) DeleteDeviceToken(userID int64, token string) error {
	token = strings.TrimSpace(token)
	if token == "" {
		return fmt.Errorf("device token is required")
	}
	return s.userRepo.DeleteDeviceToken(userID, token)
}

func IsNotFound(err error) bool {
	return err == sql.ErrNoRows
}

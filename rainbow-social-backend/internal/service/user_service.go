package service

import (
	"database/sql"
	"fmt"
	"sort"
	"strings"
	"time"

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
	_ = s.userRepo.TouchActive(userID)
	return s.userRepo.GetByID(userID)
}

func (s *UserService) GetUser(requesterUserID, targetUserID int64) (*model.User, error) {
	_ = s.userRepo.TouchActive(requesterUserID)
	return s.userRepo.GetByID(targetUserID)
}

func (s *UserService) UpdateProfile(userID int64, input model.User) (*model.User, error) {
	existing, err := s.userRepo.GetByID(userID)
	if err != nil {
		return nil, err
	}

	existing.Nickname = strings.TrimSpace(input.Nickname)
	existing.Avatar = strings.TrimSpace(input.Avatar)
	existing.Age = input.Age
	existing.HeightCM = input.HeightCM
	existing.WeightKG = input.WeightKG
	existing.Birthday = strings.TrimSpace(input.Birthday)
	existing.ZodiacSign = sanitizeZodiacSign(input.ZodiacSign)
	existing.MBTIType = sanitizeMBTIType(input.MBTIType)
	existing.Bio = strings.TrimSpace(input.Bio)
	existing.Tags = sanitizeTags(input.Tags)
	existing.PositionRole = strings.TrimSpace(input.PositionRole)
	existing.StatusID = strings.TrimSpace(input.StatusID)
	existing.StatusLabel = strings.TrimSpace(input.StatusLabel)
	existing.StatusExpiresAt = strings.TrimSpace(input.StatusExpiresAt)
	existing.Photos = sanitizePhotos(input.Photos)
	existing.Moments = sanitizeMoments(input.Moments)
	existing.Lat = input.Lat
	existing.Lng = input.Lng
	existing.LocationLabel = strings.TrimSpace(input.LocationLabel)
	_ = s.userRepo.TouchActive(userID)

	if existing.Nickname == "" {
		return nil, fmt.Errorf("nickname is required")
	}
	if existing.Age < 18 || existing.Age > 99 {
		return nil, fmt.Errorf("age must be between 18 and 99")
	}
	if existing.HeightCM < 120 || existing.HeightCM > 230 {
		return nil, fmt.Errorf("height_cm must be between 120 and 230")
	}
	if existing.WeightKG < 30 || existing.WeightKG > 200 {
		return nil, fmt.Errorf("weight_kg must be between 30 and 200")
	}
	if existing.MBTIType != "" && !isValidMBTIType(existing.MBTIType) {
		return nil, fmt.Errorf("mbti_type is invalid")
	}
	if existing.Birthday == "" && existing.ZodiacSign != "" {
		return nil, fmt.Errorf("birthday is required when zodiac_sign is set")
	}
	if existing.ZodiacSign != "" && !isValidZodiacSign(existing.ZodiacSign) {
		return nil, fmt.Errorf("zodiac_sign is invalid")
	}

	return s.userRepo.UpdateProfile(existing)
}

func (s *UserService) ListUsers(limit int) ([]model.User, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	return s.userRepo.ListUsers(limit)
}

func (s *UserService) Nearby(userID int64, lat, lng float64, minAge, maxAge int, onlineOnly bool, tag, mbtiType, zodiacSign string) ([]model.User, error) {
	tag = strings.ToLower(strings.TrimSpace(tag))
	mbtiType = sanitizeMBTIType(mbtiType)
	zodiacSign = sanitizeZodiacSign(zodiacSign)

	users, err := s.userRepo.ListNearbyCandidates(
		userID,
		minAge,
		maxAge,
		onlineOnly,
		tag,
		mbtiType,
		zodiacSign,
		120,
	)
	if err != nil {
		return nil, err
	}
	_ = s.userRepo.TouchActive(userID)

	for i := range users {
		if tag != "" && !containsTag(users[i].Tags, tag) {
			users[i].DistanceKM = -1
			continue
		}
		if mbtiType != "" && users[i].MBTIType != mbtiType {
			users[i].DistanceKM = -1
			continue
		}
		if zodiacSign != "" && users[i].ZodiacSign != zodiacSign {
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

func (s *UserService) UpdateLocation(userID int64, lat, lng float64, locationLabel string) (*model.User, error) {
	locationLabel = strings.TrimSpace(locationLabel)
	if lat == 0 || lng == 0 {
		return nil, fmt.Errorf("location coordinates are required")
	}
	if err := s.userRepo.UpdateLocation(userID, lat, lng, locationLabel); err != nil {
		return nil, err
	}
	return s.userRepo.GetByID(userID)
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

func sanitizeMoments(moments []model.Moment) []model.Moment {
	result := make([]model.Moment, 0, len(moments))
	seen := make(map[string]struct{}, len(moments))
	for _, moment := range moments {
		moment.ImageURL = strings.TrimSpace(moment.ImageURL)
		moment.ImageURLs = sanitizeMomentImages(moment.ImageURLs, moment.ImageURL)
		if len(moment.ImageURLs) > 0 {
			moment.ImageURL = moment.ImageURLs[0]
		}
		moment.Caption = strings.TrimSpace(moment.Caption)
		moment.LocationLabel = strings.TrimSpace(moment.LocationLabel)
		if moment.ImageURL == "" {
			continue
		}
		identity := strings.Join(moment.ImageURLs, "|")
		if _, ok := seen[identity]; ok {
			continue
		}
		seen[identity] = struct{}{}
		if moment.CreatedAt.IsZero() {
			moment.CreatedAt = time.Now().UTC()
		} else {
			moment.CreatedAt = moment.CreatedAt.UTC()
		}
		result = append(result, moment)
		if len(result) >= 20 {
			break
		}
	}

	sort.Slice(result, func(i, j int) bool {
		return result[i].CreatedAt.Before(result[j].CreatedAt)
	})
	return result
}

func sanitizeMomentImages(imageURLs []string, fallback string) []string {
	result := make([]string, 0, len(imageURLs)+1)
	seen := make(map[string]struct{}, len(imageURLs)+1)
	for _, candidate := range append(imageURLs, fallback) {
		candidate = strings.TrimSpace(candidate)
		if candidate == "" {
			continue
		}
		if _, ok := seen[candidate]; ok {
			continue
		}
		seen[candidate] = struct{}{}
		result = append(result, candidate)
		if len(result) >= 9 {
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

func sanitizeMBTIType(value string) string {
	return strings.ToUpper(strings.TrimSpace(value))
}

func isValidMBTIType(value string) bool {
	switch value {
	case "INTJ", "INTP", "ENTJ", "ENTP",
		"INFJ", "INFP", "ENFJ", "ENFP",
		"ISTJ", "ISFJ", "ESTJ", "ESFJ",
		"ISTP", "ISFP", "ESTP", "ESFP":
		return true
	default:
		return false
	}
}

func sanitizeZodiacSign(value string) string {
	value = strings.TrimSpace(value)
	switch strings.ToLower(value) {
	case "aries":
		return "Aries"
	case "taurus":
		return "Taurus"
	case "gemini":
		return "Gemini"
	case "cancer":
		return "Cancer"
	case "leo":
		return "Leo"
	case "virgo":
		return "Virgo"
	case "libra":
		return "Libra"
	case "scorpio":
		return "Scorpio"
	case "sagittarius":
		return "Sagittarius"
	case "capricorn":
		return "Capricorn"
	case "aquarius":
		return "Aquarius"
	case "pisces":
		return "Pisces"
	default:
		return value
	}
}

func isValidZodiacSign(value string) bool {
	switch value {
	case "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces":
		return true
	default:
		return false
	}
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

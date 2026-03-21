package service

import (
	"database/sql"
	"fmt"
	"sort"

	"rainbow-social-backend/internal/model"
	"rainbow-social-backend/internal/repository"
	"rainbow-social-backend/pkg/utils"
)

type SwipeService struct {
	userRepo   *repository.UserRepository
	swipeRepo  *repository.SwipeRepository
	matchRepo  *repository.MatchRepository
	safetyRepo *repository.SafetyRepository
}

func NewSwipeService(
	userRepo *repository.UserRepository,
	swipeRepo *repository.SwipeRepository,
	matchRepo *repository.MatchRepository,
	safetyRepo *repository.SafetyRepository,
) *SwipeService {
	return &SwipeService{
		userRepo:   userRepo,
		swipeRepo:  swipeRepo,
		matchRepo:  matchRepo,
		safetyRepo: safetyRepo,
	}
}

func (s *SwipeService) Swipe(userID, targetUserID int64, action string) (bool, error) {
	if userID == targetUserID {
		return false, fmt.Errorf("cannot swipe yourself")
	}
	if action != "like" && action != "pass" {
		return false, fmt.Errorf("invalid swipe action")
	}
	if _, err := s.userRepo.GetByID(targetUserID); err != nil {
		return false, fmt.Errorf("target user not found")
	}

	blocked, err := s.safetyRepo.AreUsersBlocked(userID, targetUserID)
	if err != nil {
		return false, err
	}
	if blocked {
		return false, fmt.Errorf("你们暂时无法建立关系")
	}

	if err := s.swipeRepo.SaveSwipe(userID, targetUserID, action); err != nil {
		return false, err
	}

	if action != "like" {
		return false, nil
	}

	mutual, err := s.swipeRepo.HasMutualLike(userID, targetUserID)
	if err != nil {
		return false, err
	}
	if mutual {
		if err := s.matchRepo.CreateIfNotExists(userID, targetUserID); err != nil {
			return false, err
		}
	}
	return mutual, nil
}

func (s *SwipeService) Recommendations(userID int64) ([]model.User, error) {
	currentUser, err := s.userRepo.GetByID(userID)
	if err != nil {
		return nil, err
	}

	candidates, err := s.userRepo.ListOtherUsers(userID)
	if err != nil {
		return nil, err
	}

	blockedUserIDs, err := s.safetyRepo.GetBlockedUserIDs(userID)
	if err != nil {
		return nil, err
	}

	swipedUserIDs, err := s.swipeRepo.GetSwipedTargetIDs(userID)
	if err != nil {
		return nil, err
	}

	filtered := make([]model.User, 0)
	for _, candidate := range candidates {
		if _, blocked := blockedUserIDs[candidate.ID]; blocked {
			continue
		}
		if _, swiped := swipedUserIDs[candidate.ID]; swiped {
			continue
		}
		candidate.DistanceKM = utils.DistanceKM(currentUser.Lat, currentUser.Lng, candidate.Lat, candidate.Lng)
		filtered = append(filtered, candidate)
	}

	sort.Slice(filtered, func(i, j int) bool {
		if filtered[i].OnlineStatus != filtered[j].OnlineStatus {
			return filtered[i].OnlineStatus
		}
		return filtered[i].DistanceKM < filtered[j].DistanceKM
	})

	if len(filtered) > 20 {
		filtered = filtered[:20]
	}
	return filtered, nil
}

func (s *SwipeService) UndoSwipe(userID, targetUserID int64) error {
	if userID == targetUserID {
		return fmt.Errorf("cannot undo swipe yourself")
	}
	if _, err := s.userRepo.GetByID(targetUserID); err != nil {
		return fmt.Errorf("target user not found")
	}

	action, err := s.swipeRepo.GetSwipeAction(userID, targetUserID)
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("no swipe found")
		}
		return err
	}
	if err := s.swipeRepo.DeleteSwipe(userID, targetUserID); err != nil {
		return err
	}
	if action == "like" {
		if err := s.matchRepo.DeleteBetweenUsers(userID, targetUserID); err != nil {
			return err
		}
	}
	return nil
}

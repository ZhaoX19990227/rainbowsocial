package service

import (
	"fmt"
	"strings"

	"rainbow-social-backend/internal/model"
	"rainbow-social-backend/internal/repository"
)

type SafetyService struct {
	safetyRepo *repository.SafetyRepository
	matchRepo  *repository.MatchRepository
}

func NewSafetyService(safetyRepo *repository.SafetyRepository, matchRepo *repository.MatchRepository) *SafetyService {
	return &SafetyService{
		safetyRepo: safetyRepo,
		matchRepo:  matchRepo,
	}
}

func (s *SafetyService) Report(reporterID, reportedUserID int64, reason, details string) error {
	if reporterID == reportedUserID {
		return fmt.Errorf("cannot report yourself")
	}
	reason = strings.TrimSpace(reason)
	if reason == "" {
		return fmt.Errorf("reason is required")
	}
	return s.safetyRepo.CreateReport(reporterID, reportedUserID, reason, strings.TrimSpace(details))
}

func (s *SafetyService) Block(blockerUserID, blockedUserID int64, reason string) error {
	if blockerUserID == blockedUserID {
		return fmt.Errorf("cannot block yourself")
	}
	if err := s.safetyRepo.BlockUser(blockerUserID, blockedUserID, strings.TrimSpace(reason)); err != nil {
		return err
	}
	return s.matchRepo.DeleteBetweenUsers(blockerUserID, blockedUserID)
}

func (s *SafetyService) Unblock(blockerUserID, blockedUserID int64) error {
	if blockerUserID == blockedUserID {
		return fmt.Errorf("不能取消屏蔽自己")
	}
	return s.safetyRepo.UnblockUser(blockerUserID, blockedUserID)
}

func (s *SafetyService) BlockStatus(userID, targetUserID int64) (*model.BlockStatus, error) {
	if userID == targetUserID {
		return &model.BlockStatus{}, nil
	}

	blockedByMe, reason, err := s.safetyRepo.GetBlockStatus(userID, targetUserID)
	if err != nil {
		return nil, err
	}
	if blockedByMe == nil {
		return &model.BlockStatus{}, nil
	}
	if *blockedByMe {
		return &model.BlockStatus{
			IsBlocked:       true,
			BlockedByMe:     true,
			BlockedByTarget: false,
			Reason:          reason,
		}, nil
	}
	return &model.BlockStatus{
		IsBlocked:       true,
		BlockedByMe:     false,
		BlockedByTarget: true,
		Reason:          reason,
	}, nil
}

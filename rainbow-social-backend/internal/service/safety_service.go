package service

import (
	"fmt"
	"strings"

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

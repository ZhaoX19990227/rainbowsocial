package service

import (
	"rainbow-social-backend/internal/model"
	"rainbow-social-backend/internal/repository"
)

type MatchService struct {
	matchRepo *repository.MatchRepository
}

func NewMatchService(matchRepo *repository.MatchRepository) *MatchService {
	return &MatchService{matchRepo: matchRepo}
}

func (s *MatchService) ListMatches(userID int64) ([]model.MatchUser, error) {
	return s.matchRepo.ListByUser(userID)
}

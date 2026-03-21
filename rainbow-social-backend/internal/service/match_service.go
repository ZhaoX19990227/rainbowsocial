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

func (s *MatchService) Summary(userID int64) (*model.MatchSummary, error) {
	sent, err := s.matchRepo.ListSentLikes(userID)
	if err != nil {
		return nil, err
	}
	received, err := s.matchRepo.ListReceivedLikes(userID)
	if err != nil {
		return nil, err
	}
	mutual, err := s.matchRepo.ListByUser(userID)
	if err != nil {
		return nil, err
	}
	return &model.MatchSummary{
		Sent:     sent,
		Received: received,
		Mutual:   mutual,
	}, nil
}

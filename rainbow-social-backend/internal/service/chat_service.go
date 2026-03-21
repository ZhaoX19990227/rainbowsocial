package service

import (
	"fmt"
	"strings"
	"time"

	"rainbow-social-backend/internal/model"
	"rainbow-social-backend/internal/repository"
)

type ChatService struct {
	chatRepo   *repository.ChatRepository
	userRepo   *repository.UserRepository
	matchRepo  *repository.MatchRepository
	safetyRepo *repository.SafetyRepository
}

func NewChatService(
	chatRepo *repository.ChatRepository,
	userRepo *repository.UserRepository,
	matchRepo *repository.MatchRepository,
	safetyRepo *repository.SafetyRepository,
) *ChatService {
	return &ChatService{
		chatRepo:   chatRepo,
		userRepo:   userRepo,
		matchRepo:  matchRepo,
		safetyRepo: safetyRepo,
	}
}

func (s *ChatService) SaveMessage(fromUserID, toUserID int64, content, messageType, clientMessageID, mediaURL string, durationSeconds int) (*model.ChatMessage, error) {
	content = strings.TrimSpace(content)
	mediaURL = strings.TrimSpace(mediaURL)
	if content == "" && mediaURL == "" {
		return nil, fmt.Errorf("content is required")
	}
	if messageType == "" {
		messageType = "text"
	}
	if messageType == "audio" {
		if mediaURL == "" {
			return nil, fmt.Errorf("audio media_url is required")
		}
		if durationSeconds <= 0 {
			return nil, fmt.Errorf("audio duration is required")
		}
		if content == "" {
			content = "语音消息"
		}
	}

	if _, err := s.userRepo.GetByID(fromUserID); err != nil {
		return nil, fmt.Errorf("sender not found")
	}
	if _, err := s.userRepo.GetByID(toUserID); err != nil {
		return nil, fmt.Errorf("recipient not found")
	}
	matched, err := s.matchRepo.ExistsBetweenUsers(fromUserID, toUserID)
	if err != nil {
		return nil, err
	}
	if !matched {
		return nil, fmt.Errorf("can only message matched users")
	}
	blocked, err := s.safetyRepo.AreUsersBlocked(fromUserID, toUserID)
	if err != nil {
		return nil, err
	}
	if blocked {
		return nil, fmt.Errorf("cannot message a blocked user")
	}

	message := model.ChatMessage{
		ClientMessageID: clientMessageID,
		FromUser:        fromUserID,
		ToUser:          toUserID,
		Content:         content,
		Type:            messageType,
		MediaURL:        mediaURL,
		DurationSeconds: durationSeconds,
	}
	return s.chatRepo.SaveMessage(message)
}

func (s *ChatService) ListConversationSummaries(userID int64) ([]model.ConversationSummary, error) {
	if _, err := s.userRepo.GetByID(userID); err != nil {
		return nil, fmt.Errorf("user not found")
	}
	return s.chatRepo.ListConversationSummaries(userID)
}

func (s *ChatService) ListMessages(userID, peerUserID int64, limit int, beforeID int64) ([]model.ChatMessage, error) {
	if err := s.validateConversationAccess(userID, peerUserID); err != nil {
		return nil, err
	}

	messages, err := s.chatRepo.ListMessagesBetweenUsers(userID, peerUserID, limit, beforeID)
	if err != nil {
		return nil, err
	}
	if beforeID == 0 {
		if err := s.chatRepo.MarkConversationRead(userID, peerUserID, time.Now().UTC()); err != nil {
			return nil, err
		}
	}
	return messages, nil
}

func (s *ChatService) MarkConversationRead(userID, peerUserID int64) error {
	if err := s.validateConversationAccess(userID, peerUserID); err != nil {
		return err
	}
	return s.chatRepo.MarkConversationRead(userID, peerUserID, time.Now().UTC())
}

func (s *ChatService) SetConversationPinned(userID, peerUserID int64, pinned bool) error {
	if err := s.validateConversationAccess(userID, peerUserID); err != nil {
		return err
	}
	return s.chatRepo.SetConversationPinned(userID, peerUserID, pinned, time.Now().UTC())
}

func (s *ChatService) validateConversationAccess(userID, peerUserID int64) error {
	if _, err := s.userRepo.GetByID(userID); err != nil {
		return fmt.Errorf("user not found")
	}
	if _, err := s.userRepo.GetByID(peerUserID); err != nil {
		return fmt.Errorf("peer user not found")
	}

	matched, err := s.matchRepo.ExistsBetweenUsers(userID, peerUserID)
	if err != nil {
		return err
	}
	if !matched {
		return fmt.Errorf("conversation is only available for matched users")
	}

	blocked, err := s.safetyRepo.AreUsersBlocked(userID, peerUserID)
	if err != nil {
		return err
	}
	if blocked {
		return fmt.Errorf("cannot access messages for a blocked user")
	}

	return nil
}

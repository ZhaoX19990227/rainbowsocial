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

func (s *ChatService) SaveMessage(
	fromUserID, toUserID int64,
	content, messageType, clientMessageID, mediaURL string,
	durationSeconds int,
	replyToMessageID int64,
) (*model.ChatMessage, error) {
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
		return nil, fmt.Errorf("互相关注后才能聊天")
	}
	blocked, err := s.safetyRepo.AreUsersBlocked(fromUserID, toUserID)
	if err != nil {
		return nil, err
	}
	if blocked {
		return nil, fmt.Errorf("对方当前不可见，暂时无法聊天")
	}

	var replyPreview *model.ChatReplyPreview
	if replyToMessageID > 0 {
		target, err := s.chatRepo.GetMessageByID(replyToMessageID)
		if err != nil {
			return nil, fmt.Errorf("引用的消息不存在")
		}
		if !belongsToConversation(target, fromUserID, toUserID) {
			return nil, fmt.Errorf("只能引用当前聊天中的消息")
		}
		replyPreview = &model.ChatReplyPreview{
			MessageID:       target.ID,
			ClientMessageID: target.ClientMessageID,
			FromUser:        target.FromUser,
			Type:            target.Type,
			Content:         quotedPreviewContent(target),
			MediaURL:        target.MediaURL,
		}
	}

	message := model.ChatMessage{
		ClientMessageID:  clientMessageID,
		FromUser:         fromUserID,
		ToUser:           toUserID,
		Content:          content,
		Type:             messageType,
		MediaURL:         mediaURL,
		DurationSeconds:  durationSeconds,
		ReplyToMessageID: replyToMessageID,
		ReplyPreview:     replyPreview,
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

func (s *ChatService) MarkConversationRead(userID, peerUserID int64) (time.Time, error) {
	if err := s.validateConversationAccess(userID, peerUserID); err != nil {
		return time.Time{}, err
	}
	readAt := time.Now().UTC()
	return readAt, s.chatRepo.MarkConversationRead(userID, peerUserID, readAt)
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
		return fmt.Errorf("互相关注后才能聊天")
	}

	blocked, err := s.safetyRepo.AreUsersBlocked(userID, peerUserID)
	if err != nil {
		return err
	}
	if blocked {
		return fmt.Errorf("对方当前不可见，暂时无法查看聊天")
	}

	return nil
}

func belongsToConversation(message *model.ChatMessage, userID, peerUserID int64) bool {
	return (message.FromUser == userID && message.ToUser == peerUserID) ||
		(message.FromUser == peerUserID && message.ToUser == userID)
}

func quotedPreviewContent(message *model.ChatMessage) string {
	switch message.Type {
	case "image":
		if strings.TrimSpace(message.Content) != "" {
			return strings.TrimSpace(message.Content)
		}
		return "[图片]"
	case "flash_image":
		return "[闪照]"
	case "audio":
		return "[语音]"
	case "video":
		return "[视频]"
	case "flirt":
		if strings.TrimSpace(message.Content) != "" {
			return strings.TrimSpace(message.Content)
		}
		return "[心动动作]"
	default:
		return strings.TrimSpace(message.Content)
	}
}

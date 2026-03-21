package model

import "time"

type User struct {
	ID            int64     `json:"id"`
	Account       string    `json:"account,omitempty"`
	Email         string    `json:"email"`
	Nickname      string    `json:"nickname"`
	Avatar        string    `json:"avatar"`
	Photos        []string  `json:"photos"`
	Age           int       `json:"age"`
	Bio           string    `json:"bio"`
	Tags          []string  `json:"tags"`
	Lat           float64   `json:"lat"`
	Lng           float64   `json:"lng"`
	LocationLabel string    `json:"location_label,omitempty"`
	OnlineStatus  bool      `json:"online_status"`
	DistanceKM    float64   `json:"distance_km,omitempty"`
	CreatedAt     time.Time `json:"created_at"`
	LastActiveAt  time.Time `json:"last_active_at"`
}

type OTPCode struct {
	Email     string
	Code      string
	ExpiresAt time.Time
}

type Swipe struct {
	ID         int64     `json:"id"`
	FromUserID int64     `json:"from_user_id"`
	ToUserID   int64     `json:"to_user_id"`
	Action     string    `json:"action"`
	CreatedAt  time.Time `json:"created_at"`
}

type Match struct {
	ID        int64     `json:"id"`
	User1ID   int64     `json:"user1_id"`
	User2ID   int64     `json:"user2_id"`
	CreatedAt time.Time `json:"created_at"`
}

type MatchUser struct {
	User      User      `json:"user"`
	MatchedAt time.Time `json:"matched_at"`
}

type LikeUser struct {
	User      User      `json:"user"`
	LikedAt   time.Time `json:"liked_at"`
	IsMutual  bool      `json:"is_mutual"`
	MatchedAt time.Time `json:"matched_at,omitempty"`
}

type MatchSummary struct {
	Sent     []LikeUser  `json:"sent"`
	Received []LikeUser  `json:"received"`
	Mutual   []MatchUser `json:"mutual"`
}

type Report struct {
	ID             int64     `json:"id"`
	ReporterUserID int64     `json:"reporter_user_id"`
	ReportedUserID int64     `json:"reported_user_id"`
	Reason         string    `json:"reason"`
	Details        string    `json:"details"`
	CreatedAt      time.Time `json:"created_at"`
}

type Block struct {
	ID            int64     `json:"id"`
	BlockerUserID int64     `json:"blocker_user_id"`
	BlockedUserID int64     `json:"blocked_user_id"`
	Reason        string    `json:"reason"`
	CreatedAt     time.Time `json:"created_at"`
}

type BlockStatus struct {
	IsBlocked       bool   `json:"is_blocked"`
	BlockedByMe     bool   `json:"blocked_by_me"`
	BlockedByTarget bool   `json:"blocked_by_target"`
	Reason          string `json:"reason,omitempty"`
}

type ChatMessage struct {
	ID              int64     `json:"id"`
	ClientMessageID string    `json:"client_message_id,omitempty"`
	FromUser        int64     `json:"from_user"`
	ToUser          int64     `json:"to_user"`
	Content         string    `json:"content"`
	Type            string    `json:"type"`
	MediaURL        string    `json:"media_url,omitempty"`
	DurationSeconds int       `json:"duration_seconds,omitempty"`
	DeliveryStatus  string    `json:"delivery_status,omitempty"`
	Timestamp       time.Time `json:"timestamp"`
}

type ConversationState struct {
	UserID     int64      `json:"user_id"`
	PeerUserID int64      `json:"peer_user_id"`
	LastReadAt *time.Time `json:"last_read_at,omitempty"`
	IsPinned   bool       `json:"is_pinned"`
	PinnedAt   *time.Time `json:"pinned_at,omitempty"`
	CreatedAt  time.Time  `json:"created_at"`
	UpdatedAt  time.Time  `json:"updated_at"`
}

type ConversationReadEvent struct {
	UserID     int64     `json:"user_id"`
	PeerUserID int64     `json:"peer_user_id"`
	ReadAt     time.Time `json:"read_at"`
}

type ConversationSummary struct {
	PeerUser       User      `json:"peer_user"`
	LastMessage    string    `json:"last_message"`
	LastMessageAt  time.Time `json:"last_message_at"`
	LastType       string    `json:"last_type"`
	LastFromUser   int64     `json:"last_from_user"`
	LastToUser     int64     `json:"last_to_user"`
	DeliveryStatus string    `json:"delivery_status,omitempty"`
	UnreadCount    int       `json:"unread_count"`
	IsPinned       bool      `json:"is_pinned"`
	MatchedAt      time.Time `json:"matched_at,omitempty"`
}

type DeviceToken struct {
	ID        int64     `json:"id"`
	UserID    int64     `json:"user_id"`
	Token     string    `json:"token"`
	Platform  string    `json:"platform"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

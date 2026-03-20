package model

import "time"

type User struct {
	ID           int64     `json:"id"`
	Email        string    `json:"email"`
	Nickname     string    `json:"nickname"`
	Avatar       string    `json:"avatar"`
	Age          int       `json:"age"`
	Bio          string    `json:"bio"`
	Tags         []string  `json:"tags"`
	Lat          float64   `json:"lat"`
	Lng          float64   `json:"lng"`
	OnlineStatus bool      `json:"online_status"`
	DistanceKM   float64   `json:"distance_km,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
	LastActiveAt time.Time `json:"last_active_at"`
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

type ChatMessage struct {
	ID              int64     `json:"id"`
	ClientMessageID string    `json:"client_message_id,omitempty"`
	FromUser        int64     `json:"from_user"`
	ToUser          int64     `json:"to_user"`
	Content         string    `json:"content"`
	Type            string    `json:"type"`
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

type ConversationSummary struct {
	PeerUser      User      `json:"peer_user"`
	LastMessage   string    `json:"last_message"`
	LastMessageAt time.Time `json:"last_message_at"`
	LastType      string    `json:"last_type"`
	UnreadCount   int       `json:"unread_count"`
	IsPinned      bool      `json:"is_pinned"`
	MatchedAt     time.Time `json:"matched_at,omitempty"`
}

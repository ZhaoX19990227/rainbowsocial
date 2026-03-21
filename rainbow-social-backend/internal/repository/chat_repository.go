package repository

import (
	"database/sql"
	"fmt"
	"time"

	"rainbow-social-backend/internal/model"
)

type ChatRepository struct {
	db *sql.DB
}

func NewChatRepository(db *sql.DB) *ChatRepository {
	return &ChatRepository{db: db}
}

func (r *ChatRepository) SaveMessage(message model.ChatMessage) (*model.ChatMessage, error) {
	message.Timestamp = time.Now().UTC()
	message.DeliveryStatus = "delivered"
	result, err := r.db.Exec(`
		INSERT INTO messages (client_message_id, from_user_id, to_user_id, content, type, media_url, duration_seconds, timestamp)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)
	`, message.ClientMessageID, message.FromUser, message.ToUser, message.Content, message.Type, message.MediaURL, message.DurationSeconds, message.Timestamp)
	if err != nil {
		return nil, err
	}

	message.ID, err = result.LastInsertId()
	if err != nil {
		return nil, err
	}
	return &message, nil
}

func (r *ChatRepository) ListConversationSummaries(userID int64) ([]model.ConversationSummary, error) {
	rows, err := r.db.Query(`
		SELECT
			u.id, u.email, u.nickname, u.avatar, u.age, u.bio, u.tags, u.lat, u.lng,
			u.online_status, u.created_at, u.last_active_at,
			COALESCE(CASE
				WHEN msg.type = 'audio' THEN '发来一条语音'
				ELSE msg.content
			END, '') AS last_message,
			COALESCE(msg.type, 'text') AS last_type,
			COALESCE(msg.timestamp, m.created_at) AS last_message_at,
			m.created_at AS matched_at,
			COALESCE(unread.unread_count, 0) AS unread_count,
			COALESCE(cs.is_pinned, 0) AS is_pinned
		FROM matches m
		JOIN users u ON u.id = CASE WHEN m.user1_id = ? THEN m.user2_id ELSE m.user1_id END
		LEFT JOIN conversation_states cs ON cs.user_id = ? AND cs.peer_user_id = u.id
		LEFT JOIN messages msg ON msg.id = (
			SELECT id
			FROM messages
			WHERE
				(from_user_id = ? AND to_user_id = u.id)
				OR
				(from_user_id = u.id AND to_user_id = ?)
			ORDER BY timestamp DESC
			LIMIT 1
		)
		LEFT JOIN (
			SELECT
				msg.from_user_id AS peer_user_id,
				COUNT(1) AS unread_count
			FROM messages msg
			WHERE msg.to_user_id = ?
				AND unixepoch(msg.timestamp) > unixepoch(COALESCE((
					SELECT state.last_read_at
					FROM conversation_states state
					WHERE state.user_id = ? AND state.peer_user_id = msg.from_user_id
				), '1970-01-01T00:00:00Z'))
			GROUP BY msg.from_user_id
		) unread ON unread.peer_user_id = u.id
		WHERE m.user1_id = ? OR m.user2_id = ?
		ORDER BY COALESCE(cs.is_pinned, 0) DESC, unixepoch(COALESCE(msg.timestamp, m.created_at)) DESC, unixepoch(m.created_at) DESC
	`, userID, userID, userID, userID, userID, userID, userID, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	summaries := make([]model.ConversationSummary, 0)
	for rows.Next() {
		var item model.ConversationSummary
		var tagsJSON string
		var online int
		var lastMessageAt string
		var matchedAt string
		var unreadCount int
		var isPinned int
		if err := rows.Scan(
			&item.PeerUser.ID,
			&item.PeerUser.Email,
			&item.PeerUser.Nickname,
			&item.PeerUser.Avatar,
			&item.PeerUser.Age,
			&item.PeerUser.Bio,
			&tagsJSON,
			&item.PeerUser.Lat,
			&item.PeerUser.Lng,
			&online,
			&item.PeerUser.CreatedAt,
			&item.PeerUser.LastActiveAt,
			&item.LastMessage,
			&item.LastType,
			&lastMessageAt,
			&matchedAt,
			&unreadCount,
			&isPinned,
		); err != nil {
			return nil, err
		}
		item.LastMessageAt, err = parseSQLiteTime(lastMessageAt)
		if err != nil {
			return nil, err
		}
		item.MatchedAt, err = parseSQLiteTime(matchedAt)
		if err != nil {
			return nil, err
		}
		item.PeerUser.Tags = decodeTags(tagsJSON)
		item.PeerUser.OnlineStatus = online == 1
		item.UnreadCount = unreadCount
		item.IsPinned = isPinned == 1
		summaries = append(summaries, item)
	}
	return summaries, rows.Err()
}

func (r *ChatRepository) ListMessagesBetweenUsers(userID, peerUserID int64, limit int, beforeID int64) ([]model.ChatMessage, error) {
	if limit <= 0 || limit > 200 {
		limit = 30
	}

	query := `
		SELECT
			id,
			client_message_id,
			from_user_id,
			to_user_id,
			content,
			type,
			media_url,
			duration_seconds,
			CASE
				WHEN from_user_id = ? AND unixepoch(timestamp) <= unixepoch(COALESCE((
					SELECT state.last_read_at
					FROM conversation_states state
					WHERE state.user_id = ? AND state.peer_user_id = ?
				), '1970-01-01T00:00:00Z')) THEN 'read'
				WHEN from_user_id = ? THEN 'delivered'
				ELSE ''
			END AS delivery_status,
			timestamp
		FROM messages
		WHERE (
			(from_user_id = ? AND to_user_id = ?)
			OR
			(from_user_id = ? AND to_user_id = ?)
		)
	`
	args := []any{
		userID,
		peerUserID,
		userID,
		userID,
		userID,
		peerUserID,
		peerUserID,
		userID,
	}
	if beforeID > 0 {
		query += ` AND id < ?`
		args = append(args, beforeID)
	}
	query += ` ORDER BY timestamp DESC, id DESC LIMIT ?`
	args = append(args, limit)

	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	messages := make([]model.ChatMessage, 0)
	for rows.Next() {
		var message model.ChatMessage
		if err := rows.Scan(
			&message.ID,
			&message.ClientMessageID,
			&message.FromUser,
			&message.ToUser,
			&message.Content,
			&message.Type,
			&message.MediaURL,
			&message.DurationSeconds,
			&message.DeliveryStatus,
			&message.Timestamp,
		); err != nil {
			return nil, err
		}
		messages = append(messages, message)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	for left, right := 0, len(messages)-1; left < right; left, right = left+1, right-1 {
		messages[left], messages[right] = messages[right], messages[left]
	}
	return messages, nil
}

func (r *ChatRepository) MarkConversationRead(userID, peerUserID int64, readAt time.Time) error {
	_, err := r.db.Exec(`
		INSERT INTO conversation_states (
			user_id, peer_user_id, last_read_at, is_pinned, pinned_at, created_at, updated_at
		) VALUES (?, ?, ?, 0, NULL, ?, ?)
		ON CONFLICT(user_id, peer_user_id) DO UPDATE SET
			last_read_at = excluded.last_read_at,
			updated_at = excluded.updated_at
	`, userID, peerUserID, readAt.UTC(), readAt.UTC(), readAt.UTC())
	return err
}

func (r *ChatRepository) SetConversationPinned(userID, peerUserID int64, pinned bool, changedAt time.Time) error {
	pinnedValue := 0
	var pinnedAt any
	if pinned {
		pinnedValue = 1
		pinnedAt = changedAt.UTC()
	}

	_, err := r.db.Exec(`
		INSERT INTO conversation_states (
			user_id, peer_user_id, last_read_at, is_pinned, pinned_at, created_at, updated_at
		) VALUES (?, ?, NULL, ?, ?, ?, ?)
		ON CONFLICT(user_id, peer_user_id) DO UPDATE SET
			is_pinned = excluded.is_pinned,
			pinned_at = excluded.pinned_at,
			updated_at = excluded.updated_at
	`, userID, peerUserID, pinnedValue, pinnedAt, changedAt.UTC(), changedAt.UTC())
	return err
}

func parseSQLiteTime(value string) (time.Time, error) {
	layouts := []string{
		time.RFC3339Nano,
		"2006-01-02 15:04:05.999999999 -0700 MST",
		"2006-01-02 15:04:05",
	}

	for _, layout := range layouts {
		if parsed, err := time.Parse(layout, value); err == nil {
			return parsed.UTC(), nil
		}
	}

	return time.Time{}, fmt.Errorf("invalid sqlite time value: %s", value)
}

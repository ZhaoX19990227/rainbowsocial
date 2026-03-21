package repository

import (
	"database/sql"
	"time"

	"rainbow-social-backend/internal/model"
)

type MatchRepository struct {
	db *sql.DB
}

func NewMatchRepository(db *sql.DB) *MatchRepository {
	return &MatchRepository{db: db}
}

func (r *MatchRepository) CreateIfNotExists(userA, userB int64) error {
	user1ID, user2ID := userA, userB
	if user1ID > user2ID {
		user1ID, user2ID = user2ID, user1ID
	}

	_, err := r.db.Exec(`
		INSERT INTO matches (user1_id, user2_id, created_at)
		VALUES (?, ?, ?)
		ON CONFLICT(user1_id, user2_id) DO NOTHING
	`, user1ID, user2ID, time.Now().UTC())
	return err
}

func (r *MatchRepository) ListByUser(userID int64) ([]model.MatchUser, error) {
	rows, err := r.db.Query(`
		SELECT
			u.id, u.email, u.nickname, u.avatar, u.age, u.bio, u.tags, u.lat, u.lng,
			u.online_status, u.created_at, u.last_active_at, m.created_at
		FROM matches m
		JOIN users u ON u.id = CASE WHEN m.user1_id = ? THEN m.user2_id ELSE m.user1_id END
		WHERE m.user1_id = ? OR m.user2_id = ?
		ORDER BY m.created_at DESC
	`, userID, userID, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make([]model.MatchUser, 0)
	for rows.Next() {
		var item model.MatchUser
		var tagsJSON string
		var online int
		if err := rows.Scan(
			&item.User.ID,
			&item.User.Email,
			&item.User.Nickname,
			&item.User.Avatar,
			&item.User.Age,
			&item.User.Bio,
			&tagsJSON,
			&item.User.Lat,
			&item.User.Lng,
			&online,
			&item.User.CreatedAt,
			&item.User.LastActiveAt,
			&item.MatchedAt,
		); err != nil {
			return nil, err
		}
		item.User.Tags = decodeTags(tagsJSON)
		item.User.OnlineStatus = online == 1
		result = append(result, item)
	}
	return result, rows.Err()
}

func (r *MatchRepository) ExistsBetweenUsers(userA, userB int64) (bool, error) {
	var count int
	err := r.db.QueryRow(`
		SELECT COUNT(1)
		FROM matches
		WHERE (user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)
	`, userA, userB, userB, userA).Scan(&count)
	return count > 0, err
}

func (r *MatchRepository) DeleteBetweenUsers(userA, userB int64) error {
	_, err := r.db.Exec(`
		DELETE FROM matches
		WHERE (user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)
	`, userA, userB, userB, userA)
	return err
}

func (r *MatchRepository) ListSentLikes(userID int64) ([]model.LikeUser, error) {
	return r.listLikes(userID, true)
}

func (r *MatchRepository) ListReceivedLikes(userID int64) ([]model.LikeUser, error) {
	return r.listLikes(userID, false)
}

func (r *MatchRepository) listLikes(userID int64, sent bool) ([]model.LikeUser, error) {
	joinUserExpr := "s.from_user_id"
	whereExpr := "s.to_user_id = ?"
	mutualFromExpr := "s.to_user_id"
	mutualToExpr := "s.from_user_id"
	if sent {
		joinUserExpr = "s.to_user_id"
		whereExpr = "s.from_user_id = ?"
		mutualFromExpr = "s.from_user_id"
		mutualToExpr = "s.to_user_id"
	}

	rows, err := r.db.Query(`
		SELECT
			u.id, u.email, u.nickname, u.avatar, u.age, u.bio, u.tags, u.lat, u.lng,
			u.online_status, u.created_at, u.last_active_at,
			s.created_at,
			EXISTS(
				SELECT 1
				FROM swipes reverse_swipe
				WHERE reverse_swipe.from_user_id = `+mutualToExpr+`
					AND reverse_swipe.to_user_id = `+mutualFromExpr+`
					AND reverse_swipe.action = 'like'
			) AS is_mutual,
			COALESCE((
				SELECT m.created_at
				FROM matches m
				WHERE
					(m.user1_id = s.from_user_id AND m.user2_id = s.to_user_id) OR
					(m.user1_id = s.to_user_id AND m.user2_id = s.from_user_id)
				LIMIT 1
			), '') AS matched_at
		FROM swipes s
		JOIN users u ON u.id = `+joinUserExpr+`
		WHERE `+whereExpr+` AND s.action = 'like'
		ORDER BY s.created_at DESC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make([]model.LikeUser, 0)
	for rows.Next() {
		var item model.LikeUser
		var tagsJSON string
		var online int
		var mutual int
		var matchedAtRaw string
		if err := rows.Scan(
			&item.User.ID,
			&item.User.Email,
			&item.User.Nickname,
			&item.User.Avatar,
			&item.User.Age,
			&item.User.Bio,
			&tagsJSON,
			&item.User.Lat,
			&item.User.Lng,
			&online,
			&item.User.CreatedAt,
			&item.User.LastActiveAt,
			&item.LikedAt,
			&mutual,
			&matchedAtRaw,
		); err != nil {
			return nil, err
		}
		item.User.Tags = decodeTags(tagsJSON)
		item.User.OnlineStatus = online == 1
		item.IsMutual = mutual == 1
		if matchedAtRaw != "" {
			parsed, err := parseSQLiteTime(matchedAtRaw)
			if err != nil {
				return nil, err
			}
			item.MatchedAt = parsed
		}
		result = append(result, item)
	}
	return result, rows.Err()
}

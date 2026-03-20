package repository

import (
	"database/sql"
	"time"
)

type SwipeRepository struct {
	db *sql.DB
}

func NewSwipeRepository(db *sql.DB) *SwipeRepository {
	return &SwipeRepository{db: db}
}

func (r *SwipeRepository) SaveSwipe(fromUserID, toUserID int64, action string) error {
	_, err := r.db.Exec(`
		INSERT INTO swipes (from_user_id, to_user_id, action, created_at)
		VALUES (?, ?, ?, ?)
		ON CONFLICT(from_user_id, to_user_id) DO UPDATE SET action = excluded.action, created_at = excluded.created_at
	`, fromUserID, toUserID, action, time.Now().UTC())
	return err
}

func (r *SwipeRepository) HasMutualLike(userA, userB int64) (bool, error) {
	var count int
	err := r.db.QueryRow(`
		SELECT COUNT(1)
		FROM swipes
		WHERE
			((from_user_id = ? AND to_user_id = ?) OR (from_user_id = ? AND to_user_id = ?))
			AND action = 'like'
	`, userA, userB, userB, userA).Scan(&count)
	return count == 2, err
}

func (r *SwipeRepository) GetSwipedTargetIDs(userID int64) (map[int64]struct{}, error) {
	rows, err := r.db.Query(`SELECT to_user_id FROM swipes WHERE from_user_id = ?`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make(map[int64]struct{})
	for rows.Next() {
		var targetID int64
		if err := rows.Scan(&targetID); err != nil {
			return nil, err
		}
		result[targetID] = struct{}{}
	}
	return result, rows.Err()
}

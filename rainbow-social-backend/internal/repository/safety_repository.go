package repository

import (
	"database/sql"
	"time"
)

type SafetyRepository struct {
	db *sql.DB
}

func NewSafetyRepository(db *sql.DB) *SafetyRepository {
	return &SafetyRepository{db: db}
}

func (r *SafetyRepository) CreateReport(reporterID, reportedUserID int64, reason, details string) error {
	_, err := r.db.Exec(`
		INSERT INTO reports (reporter_user_id, reported_user_id, reason, details, created_at)
		VALUES (?, ?, ?, ?, ?)
	`, reporterID, reportedUserID, reason, details, time.Now().UTC())
	return err
}

func (r *SafetyRepository) BlockUser(blockerUserID, blockedUserID int64, reason string) error {
	_, err := r.db.Exec(`
		INSERT INTO blocks (blocker_user_id, blocked_user_id, reason, created_at)
		VALUES (?, ?, ?, ?)
		ON CONFLICT(blocker_user_id, blocked_user_id) DO UPDATE SET reason = excluded.reason, created_at = excluded.created_at
	`, blockerUserID, blockedUserID, reason, time.Now().UTC())
	return err
}

func (r *SafetyRepository) GetBlockedUserIDs(userID int64) (map[int64]struct{}, error) {
	rows, err := r.db.Query(`
		SELECT blocked_user_id FROM blocks WHERE blocker_user_id = ?
		UNION
		SELECT blocker_user_id FROM blocks WHERE blocked_user_id = ?
	`, userID, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make(map[int64]struct{})
	for rows.Next() {
		var blockedID int64
		if err := rows.Scan(&blockedID); err != nil {
			return nil, err
		}
		result[blockedID] = struct{}{}
	}
	return result, rows.Err()
}

func (r *SafetyRepository) AreUsersBlocked(userA, userB int64) (bool, error) {
	var count int
	err := r.db.QueryRow(`
		SELECT COUNT(1)
		FROM blocks
		WHERE (blocker_user_id = ? AND blocked_user_id = ?) OR (blocker_user_id = ? AND blocked_user_id = ?)
	`, userA, userB, userB, userA).Scan(&count)
	return count > 0, err
}

func (r *SafetyRepository) UnblockUser(blockerUserID, blockedUserID int64) error {
	_, err := r.db.Exec(`
		DELETE FROM blocks
		WHERE blocker_user_id = ? AND blocked_user_id = ?
	`, blockerUserID, blockedUserID)
	return err
}

func (r *SafetyRepository) GetBlockStatus(userID, targetUserID int64) (*bool, string, error) {
	var reason string
	err := r.db.QueryRow(`
		SELECT reason
		FROM blocks
		WHERE blocker_user_id = ? AND blocked_user_id = ?
		LIMIT 1
	`, userID, targetUserID).Scan(&reason)
	if err == nil {
		blockedByMe := true
		return &blockedByMe, reason, nil
	}
	if err != sql.ErrNoRows {
		return nil, "", err
	}

	err = r.db.QueryRow(`
		SELECT reason
		FROM blocks
		WHERE blocker_user_id = ? AND blocked_user_id = ?
		LIMIT 1
	`, targetUserID, userID).Scan(&reason)
	if err == nil {
		blockedByMe := false
		return &blockedByMe, reason, nil
	}
	if err != sql.ErrNoRows {
		return nil, "", err
	}

	return nil, "", nil
}

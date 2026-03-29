package repository

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"rainbow-social-backend/internal/model"
)

type UserRepository struct {
	db *sql.DB
}

func NewUserRepository(db *sql.DB) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) GetByID(id int64) (*model.User, error) {
	row := r.db.QueryRow(`
		SELECT id, account, email, nickname, avatar, photos, age, height_cm, weight_kg, birthday, zodiac_sign, mbti_type, bio, tags, position_role, status_id, status_label, status_expires_at, lat, lng, location_label, online_status, created_at, last_active_at
		FROM users
		WHERE id = ?
	`, id)
	return scanUser(row)
}

func (r *UserRepository) GetByEmail(email string) (*model.User, error) {
	row := r.db.QueryRow(`
		SELECT id, account, email, nickname, avatar, photos, age, height_cm, weight_kg, birthday, zodiac_sign, mbti_type, bio, tags, position_role, status_id, status_label, status_expires_at, lat, lng, location_label, online_status, created_at, last_active_at
		FROM users
		WHERE email = ?
	`, email)
	return scanUser(row)
}

func (r *UserRepository) GetByAccount(account string) (*model.User, error) {
	row := r.db.QueryRow(`
		SELECT id, account, email, nickname, avatar, photos, age, height_cm, weight_kg, birthday, zodiac_sign, mbti_type, bio, tags, position_role, status_id, status_label, status_expires_at, lat, lng, location_label, online_status, created_at, last_active_at
		FROM users
		WHERE account = ?
	`, account)
	return scanUser(row)
}

func (r *UserRepository) Create(email, account, nickname, passwordHash string) (*model.User, error) {
	now := time.Now().UTC()
	result, err := r.db.Exec(`
		INSERT INTO users (email, account, password_hash, nickname, avatar, photos, age, height_cm, weight_kg, birthday, zodiac_sign, mbti_type, bio, tags, position_role, status_id, status_label, status_expires_at, lat, lng, location_label, online_status, created_at, last_active_at)
		VALUES (?, ?, ?, ?, '', '[]', 18, 175, 70, '', '', '', '', '[]', '', '', '', '', 0, 0, '', 0, ?, ?)
	`, email, account, passwordHash, nickname, now, now)
	if err != nil {
		return nil, err
	}

	id, err := result.LastInsertId()
	if err != nil {
		return nil, err
	}
	return r.GetByID(id)
}

func (r *UserRepository) UpdateProfile(user *model.User) (*model.User, error) {
	tagsJSON, err := json.Marshal(user.Tags)
	if err != nil {
		return nil, err
	}
	photosJSON, err := json.Marshal(user.Photos)
	if err != nil {
		return nil, err
	}

	_, err = r.db.Exec(`
		UPDATE users
		SET nickname = ?, avatar = ?, photos = ?, age = ?, height_cm = ?, weight_kg = ?, birthday = ?, zodiac_sign = ?, mbti_type = ?, bio = ?, tags = ?, position_role = ?, status_id = ?, status_label = ?, status_expires_at = ?, lat = ?, lng = ?, location_label = ?, last_active_at = ?
		WHERE id = ?
	`, user.Nickname, user.Avatar, string(photosJSON), user.Age, user.HeightCM, user.WeightKG, user.Birthday, user.ZodiacSign, user.MBTIType, user.Bio, string(tagsJSON), user.PositionRole, user.StatusID, user.StatusLabel, user.StatusExpiresAt, user.Lat, user.Lng, user.LocationLabel, time.Now().UTC(), user.ID)
	if err != nil {
		return nil, err
	}

	return r.GetByID(user.ID)
}

func (r *UserRepository) ListUsers(limit int) ([]model.User, error) {
	rows, err := r.db.Query(`
		SELECT id, account, email, nickname, avatar, photos, age, height_cm, weight_kg, birthday, zodiac_sign, mbti_type, bio, tags, position_role, status_id, status_label, status_expires_at, lat, lng, location_label, online_status, created_at, last_active_at
		FROM users
		ORDER BY online_status DESC, last_active_at DESC
		LIMIT ?
	`, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	return scanUsers(rows)
}

func (r *UserRepository) ListOtherUsers(userID int64) ([]model.User, error) {
	rows, err := r.db.Query(`
		SELECT id, account, email, nickname, avatar, photos, age, height_cm, weight_kg, birthday, zodiac_sign, mbti_type, bio, tags, position_role, status_id, status_label, status_expires_at, lat, lng, location_label, online_status, created_at, last_active_at
		FROM users
		WHERE id != ?
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	return scanUsers(rows)
}

func (r *UserRepository) ListRecommendationCandidates(userID int64, limit int) ([]model.User, error) {
	if limit <= 0 {
		limit = 80
	}
	activeSince := time.Now().UTC().Add(-5 * time.Minute)
	rows, err := r.db.Query(`
		SELECT id, account, email, nickname, avatar, photos, age, height_cm, weight_kg, birthday, zodiac_sign, mbti_type, bio, tags, position_role, status_id, status_label, status_expires_at, lat, lng, location_label, online_status, created_at, last_active_at
		FROM users u
		WHERE u.id != ?
		  AND NOT EXISTS (
			SELECT 1 FROM swipes s
			WHERE s.from_user_id = ? AND s.to_user_id = u.id
		  )
		  AND NOT EXISTS (
			SELECT 1 FROM blocks b
			WHERE (b.blocker_user_id = ? AND b.blocked_user_id = u.id)
			   OR (b.blocker_user_id = u.id AND b.blocked_user_id = ?)
		  )
		ORDER BY CASE WHEN u.online_status = 1 OR u.last_active_at >= ? THEN 1 ELSE 0 END DESC, u.last_active_at DESC
		LIMIT ?
	`, userID, userID, userID, userID, activeSince, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanUsers(rows)
}

func (r *UserRepository) ListNearbyCandidates(
	userID int64,
	minAge, maxAge int,
	onlineOnly bool,
	tag, mbtiType, zodiacSign string,
	limit int,
) ([]model.User, error) {
	if limit <= 0 {
		limit = 120
	}
	activeSince := time.Now().UTC().Add(-5 * time.Minute)
	query := `
		SELECT id, account, email, nickname, avatar, photos, age, height_cm, weight_kg, birthday, zodiac_sign, mbti_type, bio, tags, position_role, status_id, status_label, status_expires_at, lat, lng, location_label, online_status, created_at, last_active_at
		FROM users u
		WHERE u.id != ?
		  AND NOT EXISTS (
			SELECT 1 FROM blocks b
			WHERE (b.blocker_user_id = ? AND b.blocked_user_id = u.id)
			   OR (b.blocker_user_id = u.id AND b.blocked_user_id = ?)
		  )`
	args := []any{userID, userID, userID}
	if minAge > 0 {
		query += ` AND u.age >= ?`
		args = append(args, minAge)
	}
	if maxAge > 0 {
		query += ` AND u.age <= ?`
		args = append(args, maxAge)
	}
	if onlineOnly {
		query += ` AND (u.online_status = 1 OR u.last_active_at >= ?)`
		args = append(args, activeSince)
	}
	if tag != "" {
		query += ` AND u.tags LIKE ?`
		args = append(args, fmt.Sprintf("%%%s%%", tag))
	}
	if mbtiType != "" {
		query += ` AND u.mbti_type = ?`
		args = append(args, mbtiType)
	}
	if zodiacSign != "" {
		query += ` AND u.zodiac_sign = ?`
		args = append(args, zodiacSign)
	}
	query += ` ORDER BY CASE WHEN u.online_status = 1 OR u.last_active_at >= ? THEN 1 ELSE 0 END DESC, u.last_active_at DESC LIMIT ?`
	args = append(args, activeSince)
	args = append(args, limit)

	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanUsers(rows)
}

func (r *UserRepository) SetOnlineStatus(userID int64, online bool) error {
	value := 0
	if online {
		value = 1
	}

	_, err := r.db.Exec(`
		UPDATE users
		SET online_status = ?, last_active_at = ?
		WHERE id = ?
	`, value, time.Now().UTC(), userID)
	return err
}

func (r *UserRepository) TouchActive(userID int64) error {
	_, err := r.db.Exec(`
		UPDATE users
		SET last_active_at = ?
		WHERE id = ?
	`, time.Now().UTC(), userID)
	return err
}

func (r *UserRepository) UpdateLocation(userID int64, lat, lng float64, locationLabel string) error {
	_, err := r.db.Exec(`
		UPDATE users
		SET lat = ?, lng = ?, location_label = ?, last_active_at = ?
		WHERE id = ?
	`, lat, lng, locationLabel, time.Now().UTC(), userID)
	return err
}

func (r *UserRepository) SaveDeviceToken(userID int64, token, platform string) error {
	_, err := r.db.Exec(`
		INSERT INTO device_tokens (user_id, token, platform, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?)
		ON CONFLICT(user_id, token) DO UPDATE SET
			platform = excluded.platform,
			updated_at = excluded.updated_at
	`, userID, token, platform, time.Now().UTC(), time.Now().UTC())
	return err
}

func (r *UserRepository) DeleteDeviceToken(userID int64, token string) error {
	_, err := r.db.Exec(`
		DELETE FROM device_tokens
		WHERE user_id = ? AND token = ?
	`, userID, token)
	return err
}

func scanUser(scanner interface{ Scan(dest ...any) error }) (*model.User, error) {
	var user model.User
	var photosJSON string
	var tagsJSON string
	var online int
	err := scanner.Scan(
		&user.ID,
		&user.Account,
		&user.Email,
		&user.Nickname,
		&user.Avatar,
		&photosJSON,
		&user.Age,
		&user.HeightCM,
		&user.WeightKG,
		&user.Birthday,
		&user.ZodiacSign,
		&user.MBTIType,
		&user.Bio,
		&tagsJSON,
		&user.PositionRole,
		&user.StatusID,
		&user.StatusLabel,
		&user.StatusExpiresAt,
		&user.Lat,
		&user.Lng,
		&user.LocationLabel,
		&online,
		&user.CreatedAt,
		&user.LastActiveAt,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, sql.ErrNoRows
		}
		return nil, err
	}

	user.OnlineStatus = online == 1
	if !user.OnlineStatus {
		user.OnlineStatus = user.LastActiveAt.After(time.Now().UTC().Add(-5 * time.Minute))
	}
	user.Photos = decodeTags(photosJSON)
	user.Tags = decodeTags(tagsJSON)
	return &user, nil
}

func (r *UserRepository) GetPasswordHashByAccount(account string) (string, error) {
	var passwordHash string
	err := r.db.QueryRow(`
		SELECT password_hash
		FROM users
		WHERE account = ?
	`, account).Scan(&passwordHash)
	if err != nil {
		return "", err
	}
	return passwordHash, nil
}

func scanUsers(rows *sql.Rows) ([]model.User, error) {
	users := make([]model.User, 0)
	for rows.Next() {
		user, err := scanUser(rows)
		if err != nil {
			return nil, err
		}
		users = append(users, *user)
	}
	return users, rows.Err()
}

func decodeTags(raw string) []string {
	if raw == "" {
		return []string{}
	}
	var tags []string
	if err := json.Unmarshal([]byte(raw), &tags); err != nil {
		return []string{}
	}
	return tags
}

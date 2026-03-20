package repository

import (
	"database/sql"
	"encoding/json"
	"errors"
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
		SELECT id, email, nickname, avatar, age, bio, tags, lat, lng, online_status, created_at, last_active_at
		FROM users
		WHERE id = ?
	`, id)
	return scanUser(row)
}

func (r *UserRepository) GetByEmail(email string) (*model.User, error) {
	row := r.db.QueryRow(`
		SELECT id, email, nickname, avatar, age, bio, tags, lat, lng, online_status, created_at, last_active_at
		FROM users
		WHERE email = ?
	`, email)
	return scanUser(row)
}

func (r *UserRepository) Create(email, nickname string) (*model.User, error) {
	now := time.Now().UTC()
	result, err := r.db.Exec(`
		INSERT INTO users (email, nickname, avatar, age, bio, tags, lat, lng, online_status, created_at, last_active_at)
		VALUES (?, ?, '', 18, '', '[]', 0, 0, 0, ?, ?)
	`, email, nickname, now, now)
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

	_, err = r.db.Exec(`
		UPDATE users
		SET nickname = ?, avatar = ?, age = ?, bio = ?, tags = ?, lat = ?, lng = ?, last_active_at = ?
		WHERE id = ?
	`, user.Nickname, user.Avatar, user.Age, user.Bio, string(tagsJSON), user.Lat, user.Lng, time.Now().UTC(), user.ID)
	if err != nil {
		return nil, err
	}

	return r.GetByID(user.ID)
}

func (r *UserRepository) ListUsers(limit int) ([]model.User, error) {
	rows, err := r.db.Query(`
		SELECT id, email, nickname, avatar, age, bio, tags, lat, lng, online_status, created_at, last_active_at
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
		SELECT id, email, nickname, avatar, age, bio, tags, lat, lng, online_status, created_at, last_active_at
		FROM users
		WHERE id != ?
	`, userID)
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

func scanUser(scanner interface{ Scan(dest ...any) error }) (*model.User, error) {
	var user model.User
	var tagsJSON string
	var online int
	err := scanner.Scan(
		&user.ID,
		&user.Email,
		&user.Nickname,
		&user.Avatar,
		&user.Age,
		&user.Bio,
		&tagsJSON,
		&user.Lat,
		&user.Lng,
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
	user.Tags = decodeTags(tagsJSON)
	return &user, nil
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

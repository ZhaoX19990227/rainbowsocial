package repository

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	_ "modernc.org/sqlite"

	"rainbow-social-backend/internal/config"
)

func NewDatabase(cfg *config.Config) (*sql.DB, error) {
	db, err := sql.Open("sqlite", cfg.DatabasePath)
	if err != nil {
		return nil, err
	}

	db.SetMaxOpenConns(1)
	db.SetMaxIdleConns(1)
	db.SetConnMaxLifetime(time.Hour)

	if err := db.Ping(); err != nil {
		_ = db.Close()
		return nil, err
	}

	if err := migrate(db); err != nil {
		_ = db.Close()
		return nil, err
	}

	if err := seedUsers(db); err != nil {
		_ = db.Close()
		return nil, err
	}

	return db, nil
}

func migrate(db *sql.DB) error {
	statements := []string{
		`PRAGMA foreign_keys = ON;`,
		`PRAGMA journal_mode = WAL;`,
		`CREATE TABLE IF NOT EXISTS users (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			email TEXT NOT NULL UNIQUE,
			account TEXT NOT NULL DEFAULT '' UNIQUE,
			password_hash TEXT NOT NULL DEFAULT '',
			nickname TEXT NOT NULL,
			avatar TEXT NOT NULL DEFAULT '',
			photos TEXT NOT NULL DEFAULT '[]',
			age INTEGER NOT NULL DEFAULT 18,
			bio TEXT NOT NULL DEFAULT '',
			tags TEXT NOT NULL DEFAULT '[]',
			lat REAL NOT NULL DEFAULT 0,
			lng REAL NOT NULL DEFAULT 0,
			online_status INTEGER NOT NULL DEFAULT 0,
			created_at DATETIME NOT NULL,
			last_active_at DATETIME NOT NULL
		);`,
		`CREATE TABLE IF NOT EXISTS otp_codes (
			email TEXT PRIMARY KEY,
			code TEXT NOT NULL,
			expires_at DATETIME NOT NULL
		);`,
		`CREATE TABLE IF NOT EXISTS swipes (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			from_user_id INTEGER NOT NULL,
			to_user_id INTEGER NOT NULL,
			action TEXT NOT NULL CHECK(action IN ('like', 'pass')),
			created_at DATETIME NOT NULL,
			UNIQUE(from_user_id, to_user_id),
			FOREIGN KEY(from_user_id) REFERENCES users(id) ON DELETE CASCADE,
			FOREIGN KEY(to_user_id) REFERENCES users(id) ON DELETE CASCADE
		);`,
		`CREATE TABLE IF NOT EXISTS matches (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user1_id INTEGER NOT NULL,
			user2_id INTEGER NOT NULL,
			created_at DATETIME NOT NULL,
			UNIQUE(user1_id, user2_id),
			FOREIGN KEY(user1_id) REFERENCES users(id) ON DELETE CASCADE,
			FOREIGN KEY(user2_id) REFERENCES users(id) ON DELETE CASCADE
		);`,
		`CREATE TABLE IF NOT EXISTS blocks (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			blocker_user_id INTEGER NOT NULL,
			blocked_user_id INTEGER NOT NULL,
			reason TEXT NOT NULL DEFAULT '',
			created_at DATETIME NOT NULL,
			UNIQUE(blocker_user_id, blocked_user_id),
			FOREIGN KEY(blocker_user_id) REFERENCES users(id) ON DELETE CASCADE,
			FOREIGN KEY(blocked_user_id) REFERENCES users(id) ON DELETE CASCADE
		);`,
		`CREATE TABLE IF NOT EXISTS reports (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			reporter_user_id INTEGER NOT NULL,
			reported_user_id INTEGER NOT NULL,
			reason TEXT NOT NULL,
			details TEXT NOT NULL DEFAULT '',
			created_at DATETIME NOT NULL,
			FOREIGN KEY(reporter_user_id) REFERENCES users(id) ON DELETE CASCADE,
			FOREIGN KEY(reported_user_id) REFERENCES users(id) ON DELETE CASCADE
		);`,
		`CREATE TABLE IF NOT EXISTS messages (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			from_user_id INTEGER NOT NULL,
			to_user_id INTEGER NOT NULL,
			content TEXT NOT NULL,
			type TEXT NOT NULL DEFAULT 'text',
			media_url TEXT NOT NULL DEFAULT '',
			duration_seconds INTEGER NOT NULL DEFAULT 0,
			timestamp DATETIME NOT NULL,
			FOREIGN KEY(from_user_id) REFERENCES users(id) ON DELETE CASCADE,
			FOREIGN KEY(to_user_id) REFERENCES users(id) ON DELETE CASCADE
		);`,
		`CREATE TABLE IF NOT EXISTS conversation_states (
			user_id INTEGER NOT NULL,
			peer_user_id INTEGER NOT NULL,
			last_read_at DATETIME,
			is_pinned INTEGER NOT NULL DEFAULT 0,
			pinned_at DATETIME,
			created_at DATETIME NOT NULL,
			updated_at DATETIME NOT NULL,
			PRIMARY KEY(user_id, peer_user_id),
			FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
			FOREIGN KEY(peer_user_id) REFERENCES users(id) ON DELETE CASCADE
		);`,
		`CREATE TABLE IF NOT EXISTS device_tokens (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id INTEGER NOT NULL,
			token TEXT NOT NULL,
			platform TEXT NOT NULL DEFAULT '',
			created_at DATETIME NOT NULL,
			updated_at DATETIME NOT NULL,
			UNIQUE(user_id, token),
			FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
		);`,
		`CREATE INDEX IF NOT EXISTS idx_swipes_from_user ON swipes(from_user_id);`,
		`CREATE INDEX IF NOT EXISTS idx_swipes_to_user ON swipes(to_user_id);`,
		`CREATE INDEX IF NOT EXISTS idx_matches_user1 ON matches(user1_id);`,
		`CREATE INDEX IF NOT EXISTS idx_matches_user2 ON matches(user2_id);`,
		`CREATE INDEX IF NOT EXISTS idx_blocks_blocker ON blocks(blocker_user_id);`,
		`CREATE INDEX IF NOT EXISTS idx_blocks_blocked ON blocks(blocked_user_id);`,
		`CREATE INDEX IF NOT EXISTS idx_messages_to_user ON messages(to_user_id, timestamp DESC);`,
		`CREATE INDEX IF NOT EXISTS idx_messages_conversation_from_to ON messages(from_user_id, to_user_id, timestamp DESC);`,
		`CREATE INDEX IF NOT EXISTS idx_messages_conversation_to_from ON messages(to_user_id, from_user_id, timestamp DESC);`,
		`CREATE INDEX IF NOT EXISTS idx_conversation_states_user_pinned ON conversation_states(user_id, is_pinned, updated_at DESC);`,
		`CREATE INDEX IF NOT EXISTS idx_users_online_last_active ON users(online_status DESC, last_active_at DESC);`,
		`CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens(user_id, updated_at DESC);`,
	}

	for _, statement := range statements {
		if _, err := db.Exec(statement); err != nil {
			return fmt.Errorf("execute migration: %w", err)
		}
	}

	if err := addColumnIfNotExists(db, "messages", "client_message_id", "TEXT NOT NULL DEFAULT ''"); err != nil {
		return err
	}
	if err := addColumnIfNotExists(db, "messages", "media_url", "TEXT NOT NULL DEFAULT ''"); err != nil {
		return err
	}
	if err := addColumnIfNotExists(db, "messages", "duration_seconds", "INTEGER NOT NULL DEFAULT 0"); err != nil {
		return err
	}
	if err := addColumnIfNotExists(db, "users", "account", "TEXT NOT NULL DEFAULT ''"); err != nil {
		return err
	}
	if err := addColumnIfNotExists(db, "users", "password_hash", "TEXT NOT NULL DEFAULT ''"); err != nil {
		return err
	}
	if err := addColumnIfNotExists(db, "users", "photos", "TEXT NOT NULL DEFAULT '[]'"); err != nil {
		return err
	}
	if _, err := db.Exec(`UPDATE users SET account = email WHERE account = ''`); err != nil {
		return fmt.Errorf("backfill users.account: %w", err)
	}
	if _, err := db.Exec(`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_account_unique ON users(account)`); err != nil {
		return fmt.Errorf("create users account index: %w", err)
	}
	return nil
}

func addColumnIfNotExists(db *sql.DB, tableName, columnName, definition string) error {
	rows, err := db.Query(fmt.Sprintf("PRAGMA table_info(%s);", tableName))
	if err != nil {
		return fmt.Errorf("inspect table columns: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var (
			cid        int
			name       string
			columnType string
			notNull    int
			defaultVal sql.NullString
			primaryKey int
		)
		if err := rows.Scan(&cid, &name, &columnType, &notNull, &defaultVal, &primaryKey); err != nil {
			return fmt.Errorf("scan table info: %w", err)
		}
		if name == columnName {
			return nil
		}
	}

	if _, err := db.Exec(fmt.Sprintf("ALTER TABLE %s ADD COLUMN %s %s;", tableName, columnName, definition)); err != nil {
		return fmt.Errorf("add column %s.%s: %w", tableName, columnName, err)
	}
	return nil
}

func seedUsers(db *sql.DB) error {
	var count int
	if err := db.QueryRow(`SELECT COUNT(1) FROM users`).Scan(&count); err != nil {
		return err
	}
	if count > 0 {
		return nil
	}

	now := time.Now().UTC()
	type seedUser struct {
		Email    string
		Nickname string
		Avatar   string
		Age      int
		Bio      string
		Tags     []string
		Lat      float64
		Lng      float64
		Online   int
	}

	users := []seedUser{
		{Email: "leo@example.com", Nickname: "Leo", Avatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e", Age: 27, Bio: "Coffee, gym, weekend hikes.", Tags: []string{"friendly", "travel", "gym"}, Lat: 31.2304, Lng: 121.4737, Online: 1},
		{Email: "noah@example.com", Nickname: "Noah", Avatar: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d", Age: 29, Bio: "Designer who loves galleries and brunch.", Tags: []string{"design", "art", "brunch"}, Lat: 31.2200, Lng: 121.4300, Online: 1},
		{Email: "kai@example.com", Nickname: "Kai", Avatar: "https://images.unsplash.com/photo-1504593811423-6dd665756598", Age: 25, Bio: "Bookstores, indie music, and late-night chats.", Tags: []string{"books", "music", "night-owl"}, Lat: 31.2150, Lng: 121.5100, Online: 0},
		{Email: "asher@example.com", Nickname: "Asher", Avatar: "https://images.unsplash.com/photo-1507591064344-4c6ce005b128", Age: 31, Bio: "Foodie and runner looking for real connection.", Tags: []string{"running", "foodie", "serious"}, Lat: 31.2400, Lng: 121.4900, Online: 1},
		{Email: "miles@example.com", Nickname: "Miles", Avatar: "https://images.unsplash.com/photo-1463453091185-61582044d556", Age: 26, Bio: "Pet dad. Into films and lazy Sunday mornings.", Tags: []string{"movies", "pets", "chill"}, Lat: 31.2000, Lng: 121.4500, Online: 0},
	}

	stmt, err := db.Prepare(`
		INSERT INTO users (email, nickname, avatar, photos, age, bio, tags, lat, lng, online_status, created_at, last_active_at)
		VALUES (?, ?, ?, '[]', ?, ?, ?, ?, ?, ?, ?, ?)
	`)
	if err != nil {
		return err
	}
	defer stmt.Close()

	for _, user := range users {
		tagsJSON, err := json.Marshal(user.Tags)
		if err != nil {
			return err
		}
		if _, err := stmt.Exec(
			user.Email,
			user.Nickname,
			user.Avatar,
			user.Age,
			user.Bio,
			string(tagsJSON),
			user.Lat,
			user.Lng,
			user.Online,
			now,
			now,
		); err != nil {
			return err
		}
	}

	return nil
}

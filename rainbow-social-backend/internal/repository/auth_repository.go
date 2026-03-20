package repository

import (
	"database/sql"
	"time"

	"rainbow-social-backend/internal/model"
)

type AuthRepository struct {
	db *sql.DB
}

func NewAuthRepository(db *sql.DB) *AuthRepository {
	return &AuthRepository{db: db}
}

func (r *AuthRepository) SaveCode(email, code string, expiresAt time.Time) error {
	_, err := r.db.Exec(`
		INSERT INTO otp_codes (email, code, expires_at)
		VALUES (?, ?, ?)
		ON CONFLICT(email) DO UPDATE SET code = excluded.code, expires_at = excluded.expires_at
	`, email, code, expiresAt)
	return err
}

func (r *AuthRepository) GetCode(email string) (*model.OTPCode, error) {
	var otp model.OTPCode
	err := r.db.QueryRow(`
		SELECT email, code, expires_at
		FROM otp_codes
		WHERE email = ?
	`, email).Scan(&otp.Email, &otp.Code, &otp.ExpiresAt)
	if err != nil {
		return nil, err
	}
	return &otp, nil
}

func (r *AuthRepository) DeleteCode(email string) error {
	_, err := r.db.Exec(`DELETE FROM otp_codes WHERE email = ?`, email)
	return err
}

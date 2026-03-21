package repository

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"rainbow-social-backend/internal/model"
)

type HoroscopeRepository struct {
	db *sql.DB
}

func NewHoroscopeRepository(db *sql.DB) *HoroscopeRepository {
	return &HoroscopeRepository{db: db}
}

func (r *HoroscopeRepository) GetDaily(zodiacSign, date string) (*model.HoroscopeData, bool, error) {
	var payload string
	err := r.db.QueryRow(
		`SELECT payload_json
		FROM horoscope_daily_cache
		WHERE zodiac_sign = ? AND date = ?`,
		zodiacSign,
		date,
	).Scan(&payload)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, false, nil
		}
		return nil, false, fmt.Errorf("query horoscope cache: %w", err)
	}

	var data model.HoroscopeData
	if err := json.Unmarshal([]byte(payload), &data); err != nil {
		return nil, false, fmt.Errorf("decode horoscope cache: %w", err)
	}
	return &data, true, nil
}

func (r *HoroscopeRepository) UpsertDaily(data *model.HoroscopeData, source string, now time.Time) error {
	payload, err := json.Marshal(data)
	if err != nil {
		return fmt.Errorf("encode horoscope cache: %w", err)
	}

	_, err = r.db.Exec(
		`INSERT INTO horoscope_daily_cache (
			zodiac_sign,
			date,
			payload_json,
			source,
			created_at,
			updated_at
		) VALUES (?, ?, ?, ?, ?, ?)
		ON CONFLICT(zodiac_sign, date) DO UPDATE SET
			payload_json = excluded.payload_json,
			source = excluded.source,
			updated_at = excluded.updated_at`,
		data.ZodiacSign,
		data.Date,
		string(payload),
		source,
		now.UTC(),
		now.UTC(),
	)
	if err != nil {
		return fmt.Errorf("upsert horoscope cache: %w", err)
	}
	return nil
}

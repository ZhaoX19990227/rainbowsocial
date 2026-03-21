package model

type HoroscopeScores struct {
	Romance    int `json:"romance"`
	Initiative int `json:"initiative"`
	Luck       int `json:"luck"`
}

type HoroscopeData struct {
	Date       string          `json:"date"`
	ZodiacSign string          `json:"zodiac_sign"`
	Title      string          `json:"title"`
	Summary    string          `json:"summary"`
	Love       string          `json:"love"`
	Social     string          `json:"social"`
	Mood       string          `json:"mood"`
	Suggestion string          `json:"suggestion"`
	Avoid      string          `json:"avoid"`
	Scores     HoroscopeScores `json:"scores"`
	Tags       []string        `json:"tags"`
}

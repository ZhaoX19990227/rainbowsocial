package service

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"

	"rainbow-social-backend/internal/config"
	"rainbow-social-backend/internal/model"
	"rainbow-social-backend/internal/repository"

	"golang.org/x/sync/singleflight"
)

const defaultDashScopeURL = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
const fallbackCacheTTL = 30 * time.Minute

type HoroscopeService struct {
	cfg        *config.Config
	client     *http.Client
	repo       *repository.HoroscopeRepository
	memCache   sync.Map
	fetchGroup singleflight.Group
}

type horoscopeCacheEntry struct {
	data      *model.HoroscopeData
	expiresAt time.Time
}

func NewHoroscopeService(cfg *config.Config, repo *repository.HoroscopeRepository) *HoroscopeService {
	return &HoroscopeService{
		cfg: cfg,
		client: &http.Client{
			Timeout: time.Duration(cfg.AITimeoutSeconds) * time.Second,
		},
		repo: repo,
	}
}

func (s *HoroscopeService) BuildDaily(ctx context.Context, zodiacSign string, date time.Time) (*model.HoroscopeData, error) {
	zodiacSign = sanitizeZodiacSign(zodiacSign)
	if !isValidZodiacSign(zodiacSign) {
		return nil, fmt.Errorf("zodiac_sign is invalid")
	}
	date = date.In(time.Local)
	dateKey := date.Format("2006-01-02")
	cacheKey := zodiacSign + ":" + dateKey

	if cached, ok := s.loadMemoryCache(cacheKey); ok {
		return cloneHoroscopeData(cached), nil
	}
	if s.repo != nil {
		if cached, ok, err := s.repo.GetDaily(zodiacSign, dateKey); err == nil && ok {
			s.storeMemoryCache(cacheKey, cached, nextDayStart(date))
			return cloneHoroscopeData(cached), nil
		}
	}

	result, err, _ := s.fetchGroup.Do(cacheKey, func() (any, error) {
		if cached, ok := s.loadMemoryCache(cacheKey); ok {
			return cloneHoroscopeData(cached), nil
		}
		if s.repo != nil {
			if cached, ok, err := s.repo.GetDaily(zodiacSign, dateKey); err == nil && ok {
				s.storeMemoryCache(cacheKey, cached, nextDayStart(date))
				return cloneHoroscopeData(cached), nil
			}
		}

		data, err := s.buildDailyWithAI(ctx, zodiacSign, date)
		if err == nil {
			expiry := nextDayStart(date)
			s.storeMemoryCache(cacheKey, data, expiry)
			if s.repo != nil {
				_ = s.repo.UpsertDaily(data, "ai", time.Now())
			}
			return cloneHoroscopeData(data), nil
		}

		fallback := buildFallbackHoroscope(zodiacSign, date)
		s.storeMemoryCache(cacheKey, fallback, time.Now().Add(fallbackCacheTTL))
		return fallback, nil
	})
	if err != nil {
		return nil, err
	}
	data, ok := result.(*model.HoroscopeData)
	if !ok || data == nil {
		return nil, fmt.Errorf("invalid horoscope result")
	}
	return cloneHoroscopeData(data), nil
}

func (s *HoroscopeService) buildDailyWithAI(ctx context.Context, zodiacSign string, date time.Time) (*model.HoroscopeData, error) {
	if strings.TrimSpace(s.cfg.DashScopeAPIKey) == "" {
		return nil, fmt.Errorf("DASHSCOPE_API_KEY is not configured")
	}

	payload := map[string]any{
		"model": s.cfg.DashScopeModel,
		"messages": []map[string]string{
			{
				"role":    "system",
				"content": "你是一个服务于男同性恋社交平台的星座运势文案助手。你要输出适合移动端展示的中文 JSON，不要输出 markdown，不要输出解释，不要输出代码块。",
			},
			{
				"role": "user",
				"content": fmt.Sprintf(
					`请基于以下信息生成今日运势内容：
- 日期：%s
- 星座：%s

要求：
1. 风格清爽、细腻、带一点暧昧感，像高质量中文社交产品。
2. 不要迷信口吻，不要恐吓，不要负能量。
3. 重点围绕感情、社交、情绪、是否适合主动、是否适合推进关系。
4. 所有字段必须是中文。
5. tags 必须正好 3 个，都是短词。
6. 分数范围 0 到 100。

请严格返回 JSON：
{
  "title": "12到24字标题",
  "summary": "40到80字总述",
  "love": "30到60字",
  "social": "30到60字",
  "mood": "20到50字",
  "suggestion": "20到50字",
  "avoid": "20到50字",
  "scores": {
    "romance": 0,
    "initiative": 0,
    "luck": 0
  },
  "tags": ["", "", ""]
}`,
					date.Format("2006-01-02"),
					zodiacSign,
				),
			},
		},
		"temperature": 0.8,
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, s.baseURL(), bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+s.cfg.DashScopeAPIKey)

	resp, err := s.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	rawResp, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode >= http.StatusBadRequest {
		return nil, fmt.Errorf("dashscope request failed: %s", strings.TrimSpace(string(rawResp)))
	}

	var completion struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}
	if err := json.Unmarshal(rawResp, &completion); err != nil {
		return nil, fmt.Errorf("decode ai response: %w", err)
	}
	if len(completion.Choices) == 0 {
		return nil, fmt.Errorf("empty ai response")
	}

	content := extractJSON(completion.Choices[0].Message.Content)
	var generated struct {
		Title      string                `json:"title"`
		Summary    string                `json:"summary"`
		Love       string                `json:"love"`
		Social     string                `json:"social"`
		Mood       string                `json:"mood"`
		Suggestion string                `json:"suggestion"`
		Avoid      string                `json:"avoid"`
		Scores     model.HoroscopeScores `json:"scores"`
		Tags       []string              `json:"tags"`
	}
	if err := json.Unmarshal([]byte(content), &generated); err != nil {
		return nil, fmt.Errorf("decode horoscope payload: %w", err)
	}

	data := &model.HoroscopeData{
		Date:       date.Format("2006-01-02"),
		ZodiacSign: zodiacSign,
		Title:      strings.TrimSpace(generated.Title),
		Summary:    strings.TrimSpace(generated.Summary),
		Love:       strings.TrimSpace(generated.Love),
		Social:     strings.TrimSpace(generated.Social),
		Mood:       strings.TrimSpace(generated.Mood),
		Suggestion: strings.TrimSpace(generated.Suggestion),
		Avoid:      strings.TrimSpace(generated.Avoid),
		Scores: model.HoroscopeScores{
			Romance:    clampScore(generated.Scores.Romance),
			Initiative: clampScore(generated.Scores.Initiative),
			Luck:       clampScore(generated.Scores.Luck),
		},
		Tags: sanitizeHoroscopeTags(generated.Tags),
	}
	if data.Title == "" || data.Summary == "" {
		return nil, fmt.Errorf("incomplete horoscope payload")
	}
	return data, nil
}

func (s *HoroscopeService) baseURL() string {
	if strings.TrimSpace(s.cfg.DashScopeBaseURL) != "" {
		return strings.TrimSpace(s.cfg.DashScopeBaseURL)
	}
	return defaultDashScopeURL
}

func extractJSON(raw string) string {
	raw = strings.TrimSpace(raw)
	raw = strings.TrimPrefix(raw, "```json")
	raw = strings.TrimPrefix(raw, "```")
	raw = strings.TrimSuffix(raw, "```")
	raw = strings.TrimSpace(raw)
	start := strings.Index(raw, "{")
	end := strings.LastIndex(raw, "}")
	if start >= 0 && end >= start {
		return raw[start : end+1]
	}
	return raw
}

func clampScore(value int) int {
	if value < 0 {
		return 0
	}
	if value > 100 {
		return 100
	}
	return value
}

func sanitizeHoroscopeTags(tags []string) []string {
	result := make([]string, 0, 3)
	seen := make(map[string]struct{}, 3)
	for _, tag := range tags {
		tag = strings.TrimSpace(tag)
		if tag == "" {
			continue
		}
		if _, ok := seen[tag]; ok {
			continue
		}
		seen[tag] = struct{}{}
		result = append(result, tag)
		if len(result) == 3 {
			return result
		}
	}
	for len(result) < 3 {
		result = append(result, "今日有感")
	}
	return result
}

func (s *HoroscopeService) loadMemoryCache(key string) (*model.HoroscopeData, bool) {
	value, ok := s.memCache.Load(key)
	if !ok {
		return nil, false
	}
	entry, ok := value.(horoscopeCacheEntry)
	if !ok || entry.data == nil {
		s.memCache.Delete(key)
		return nil, false
	}
	if time.Now().After(entry.expiresAt) {
		s.memCache.Delete(key)
		return nil, false
	}
	return entry.data, true
}

func (s *HoroscopeService) storeMemoryCache(key string, data *model.HoroscopeData, expiresAt time.Time) {
	if data == nil {
		return
	}
	s.memCache.Store(key, horoscopeCacheEntry{
		data:      cloneHoroscopeData(data),
		expiresAt: expiresAt,
	})
}

func nextDayStart(date time.Time) time.Time {
	date = date.In(time.Local)
	return time.Date(date.Year(), date.Month(), date.Day()+1, 0, 0, 0, 0, date.Location())
}

func cloneHoroscopeData(data *model.HoroscopeData) *model.HoroscopeData {
	if data == nil {
		return nil
	}
	cloned := *data
	cloned.Tags = append([]string(nil), data.Tags...)
	return &cloned
}

func buildFallbackHoroscope(zodiacSign string, date time.Time) *model.HoroscopeData {
	zodiacLabel := zodiacSign
	switch zodiacSign {
	case "Aries":
		zodiacLabel = "白羊座"
	case "Taurus":
		zodiacLabel = "金牛座"
	case "Gemini":
		zodiacLabel = "双子座"
	case "Cancer":
		zodiacLabel = "巨蟹座"
	case "Leo":
		zodiacLabel = "狮子座"
	case "Virgo":
		zodiacLabel = "处女座"
	case "Libra":
		zodiacLabel = "天秤座"
	case "Scorpio":
		zodiacLabel = "天蝎座"
	case "Sagittarius":
		zodiacLabel = "射手座"
	case "Capricorn":
		zodiacLabel = "摩羯座"
	case "Aquarius":
		zodiacLabel = "水瓶座"
	case "Pisces":
		zodiacLabel = "双鱼座"
	}

	seed := int(date.Month())*13 + date.Day()*7 + len(zodiacSign)*11
	romance := 62 + seed%24
	initiative := 55 + (seed/2)%28
	luck := 60 + (seed/3)%26
	dayLabel := weekdayLabel(date)

	return &model.HoroscopeData{
		Date:       date.Format("2006-01-02"),
		ZodiacSign: zodiacSign,
		Title:      fmt.Sprintf("%s的今天，适合温柔靠近", zodiacLabel),
		Summary:    fmt.Sprintf("%s更适合先把聊天氛围铺柔一点，再慢慢推进关系。今天是%s，节奏放松反而更容易被接住。", zodiacLabel, dayLabel),
		Love:       "桃花感知在线，适合从轻松回应、自然接话开始，不必急着把关系推进到很明确的位置。",
		Social:     "社交状态偏顺，认真回应、语气放松，会比用力表现更容易拉近距离。",
		Mood:       "情绪起伏不算大，只要别急着验证结果，今天整体会更舒展。",
		Suggestion: "如果想主动，可以先从日常感受或轻松兴趣切入，让对方更容易接近你。",
		Avoid:      "别因为回复速度或一句话的温度变化，就过早下结论。",
		Scores: model.HoroscopeScores{
			Romance:    clampScore(romance),
			Initiative: clampScore(initiative),
			Luck:       clampScore(luck),
		},
		Tags: []string{"适合慢聊", "情绪顺滑", "轻推关系"},
	}
}

func weekdayLabel(date time.Time) string {
	switch date.Weekday() {
	case time.Monday:
		return "周一"
	case time.Tuesday:
		return "周二"
	case time.Wednesday:
		return "周三"
	case time.Thursday:
		return "周四"
	case time.Friday:
		return "周五"
	case time.Saturday:
		return "周六"
	default:
		return "周日"
	}
}

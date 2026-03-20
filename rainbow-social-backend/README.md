# Rainbow Social Backend

Production-oriented Golang backend scaffold for a mobile LGBTQ+ social app. It uses Gin, SQLite, WebSocket, email OTP login, JWT auth, and a clean architecture split into handler, service, and repository layers.

## Features

- Email OTP authentication with SMTP support for QQ Mail
- JWT-protected REST APIs
- User profile management and user listing
- Recommendations, swipe like/pass, and automatic match creation
- Nearby users sorted by distance
- Safety endpoints for report and block
- WebSocket chat hub for private messaging
- SQLite schema bootstrap and demo seed users for local testing
- Ready for mobile debugging through ngrok or Cloudflare Tunnel

## Project Structure

```text
rainbow-social-backend/
├── cmd/
├── internal/
│   ├── api/
│   ├── config/
│   ├── middleware/
│   ├── model/
│   ├── repository/
│   ├── service/
│   └── ws/
├── pkg/
│   ├── email/
│   └── utils/
├── .env.example
├── go.mod
├── main.go
└── README.md
```

## Quick Start

1. Enter the project directory.
2. Copy `.env.example` to `.env`.
3. Update `JWT_SECRET` and SMTP settings if you want real email delivery.
4. Install dependencies and run the server.

```bash
cd /Users/zhaoxiang/IdeaProjects/ados-java/rainbow-social-backend
cp .env.example .env
go mod tidy
go run main.go
```

The server starts on `http://localhost:8088` by default.

## SMTP Notes

- For QQ Mail, enable SMTP in QQ Mail settings.
- Use the QQ SMTP authorization code, not your mailbox login password.
- Set `SMTP_ENABLED=true` to send real emails.
- When `SMTP_ENABLED=false`, OTP codes are logged to the server console for local development.

## API Overview

### Auth

- `POST /auth/send-code`
- `POST /auth/login`

Sample request:

```json
{
  "email": "demo@example.com"
}
```

```json
{
  "email": "demo@example.com",
  "code": "123456"
}
```

### User

- `GET /user/profile`
- `PUT /user/profile`
- `GET /users/list?limit=50`
- `GET /users/nearby?lat=31.23&lng=121.47`

### Swipe and Match

- `POST /swipe/like`
- `POST /swipe/pass`
- `GET /recommendations`
- `GET /matches`

Sample swipe request:

```json
{
  "target_user_id": 2
}
```

### Safety

- `POST /report`
- `POST /block`

### WebSocket

- `GET /ws?user_id=1&token=<jwt>`

Client message payload:

```json
{
  "to_user": 2,
  "content": "Hey there",
  "type": "text"
}
```

Server push payload:

```json
{
  "event": "message",
  "data": {
    "id": 1,
    "from_user": 1,
    "to_user": 2,
    "content": "Hey there",
    "type": "text",
    "timestamp": "2026-03-20T12:00:00Z"
  }
}
```

## Suggested Flutter Integration

- `AuthService.sendCode(email)` -> `POST /auth/send-code`
- `AuthService.login(email, code)` -> `POST /auth/login`
- `SwipeService.getRecommendations()` -> `GET /recommendations`
- `SwipeService.like(userId)` -> `POST /swipe/like`
- `SwipeService.passUser(userId)` -> `POST /swipe/pass`
- `UserService.getNearby(lat, lng)` -> `GET /users/nearby`
- `ChatService.connect(token, userId)` -> `GET /ws`

This aligns well with the Flutter page split you described:

- `HomePage` uses recommendations and swipe APIs
- `NearbyPage` uses nearby users API
- `ChatPage` consumes the WebSocket stream
- `ProfilePage` uses profile get/update APIs

## Example curl Flow

Send OTP:

```bash
curl -X POST http://localhost:8088/auth/send-code \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com"}'
```

Login:

```bash
curl -X POST http://localhost:8088/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","code":"123456"}'
```

Use the returned JWT:

```bash
curl http://localhost:8088/user/profile \
  -H "Authorization: Bearer <token>"
```

## Production Notes

- Replace SQLite with PostgreSQL or MySQL for multi-instance production deployment.
- Move OTP storage to Redis if you need horizontal scaling.
- Restrict CORS origins in `.env` before public exposure.
- Add rate limiting around OTP and auth endpoints before internet-facing launch.
- Add message history and unread counters if the chat module grows.

## Local Mobile Testing

After local startup, expose the server:

```bash
ngrok http 8088
```

or

```bash
cloudflared tunnel --url http://localhost:8088
```

Then point the Flutter app's API base URL and WebSocket URL at the public tunnel address.

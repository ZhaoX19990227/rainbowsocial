# Rainbow Social Frontend

Flutter client generated from the `stitch_chat_interface.zip` visual reference pack.

## Structure

```text
lib/
 ├── controllers/
 ├── models/
 ├── pages/
 ├── routes/
 ├── services/
 ├── theme/
 └── widgets/
```

## Highlights

- Riverpod state management
- Luminous dark editorial UI based on the provided designs
- Login, swipe, nearby, chat, profile, and edit profile flows
- HTTP + WebSocket services ready for the Go backend
- Real backend-first wiring for auth, profile, nearby, swipe, match, report, and block
- Optional mock fallback mode controlled by `USE_MOCK_FALLBACKS`

## Run

```bash
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=http://127.0.0.1:8088 \
  --dart-define=WS_BASE_URL=ws://127.0.0.1:8088/ws
```

For a real device, replace `127.0.0.1` with your tunnel or LAN address.

To force demo data when the backend is unavailable:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://127.0.0.1:8088 \
  --dart-define=WS_BASE_URL=ws://127.0.0.1:8088/ws \
  --dart-define=USE_MOCK_FALLBACKS=true
```

## Backend Mapping

- `POST /auth/send-code`
- `POST /auth/login`
- `GET /user/profile`
- `PUT /user/profile`
- `GET /users/list`
- `GET /users/nearby`
- `GET /recommendations`
- `POST /swipe/like`
- `POST /swipe/pass`
- `GET /matches`
- `POST /report`
- `POST /block`
- `GET /ws`

## Notes

- Chat list is built from `/matches` plus local conversation preview text because the backend does not yet expose a full conversation summary endpoint.
- OTP login works against the backend; when the backend runs with SMTP disabled, the code is printed in server logs.
- New users created by OTP login are automatically bootstrapped with a default test location so recommendations and nearby sorting remain meaningful during local demos.
- Web and Chrome targets run in the current environment. iOS and macOS builds still require you to accept the local Xcode license with `sudo xcodebuild -license accept`.

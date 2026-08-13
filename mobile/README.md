# Ambulance Coordination — Mobile App

Flutter app for the AI-Driven Traffic Ambulance Coordination System. Two roles in one app: **drivers** (run emergency activations, navigate, push live GPS) and **traffic officers** (live map, emergency alerts over WebSocket).

## Features

- **Driver flow** — login, emergency activation with AI incident estimation, interactive OpenStreetMap location picker (center-pin drag + device locate; picked coordinates override the AI estimate), turn-by-turn navigation with live GPS tracking, status sync (available/en-route/emergency), in-app alerts and notifications over WebSocket
- **Officer flow** — live ambulance map, incoming emergency alerts with acknowledgment, alert history
- **White/red flat design** consistent across screens; Inter typeface

## Tech

Flutter · Provider · Dio · go_router · flutter_map (OpenStreetMap) · geolocator · web_socket_channel · google_fonts

## Run

```bash
flutter pub get

# Web (dev backend on localhost:8000)
flutter run -d chrome

# Physical device / API on another host
flutter run --dart-define=API_BASE_URL=http://<host>:8000 \
  --dart-define=WS_BASE_URL=ws://<host>:8000/ws
```

Press `R` in the terminal for a hot restart. The backend API docs live at `http://localhost:8000/docs`.

## Seed accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@ambulance.gov | Admin@12345 |
| Driver | driver@ambulance.gov | Driver@12345 |
| Officer | officer@ambulance.gov | Officer@12345 |

## Backend

See the repository root `README.md` for the full system setup and the AI model overview.
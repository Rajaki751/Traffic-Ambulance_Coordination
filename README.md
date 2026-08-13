# AI-Driven Traffic Ambulance Coordination System

Production-ready full-stack system for coordinating ambulances through traffic during emergencies with real-time GPS tracking, route optimization, and traffic officer alerts.

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Flutter Mobile │     │  React Dashboard │     │ Traffic Officers │
│  Driver/Officer │     │      (Admin)     │     │   Notifications  │
└────────┬────────┘     └────────┬─────────┘     └────────┬────────┘
         │ REST + WS               │ REST + WS                │
         └─────────────────────────┼──────────────────────────┘
                                   ▼
                    ┌──────────────────────────────┐
                    │     FastAPI Backend          │
                    │  JWT · RBAC · WebSockets     │
                    │  Hybrid AI Estimator         │
                    │  Learned ETA · OSRM Routing  │
                    └──────────────┬───────────────┘
                                   ▼
                    ┌──────────────────────────────┐
                    │       PostgreSQL             │
                    └──────────────────────────────┘
```

## Tech Stack

| Layer | Technologies |
|-------|-------------|
| Backend | FastAPI, SQLAlchemy, Alembic, PostgreSQL, JWT, WebSockets |
| Mobile | Flutter, Provider, Dio, flutter_map, geolocator, go_router |
| Dashboard | React, Vite, Tailwind CSS, React Leaflet, Axios |
| Routing | OpenStreetMap + OSRM shortest-path |
| AI / ML | Hotspot-anchored incident estimator + learned ETA model (gradient boosting) + auto-discovered hotspots |

## Project Structure

```
ambulance-coordination-system/
├── backend/          # FastAPI API
├── mobile/           # Flutter app (driver + officer)
├── dashboard/        # React admin panel
├── database/         # SQL schema reference
└── docker-compose.yml
```

## Quick Start (Local)

### Prerequisites

- Python 3.12+
- PostgreSQL 16+ (or Docker)
- Node.js 18+
- Flutter 3.16+ (for mobile)

### 1. Database & Backend

```bash
# Start PostgreSQL
docker compose up postgres -d

cd backend
python -m venv venv
# Windows: venv\Scripts\activate
# macOS/Linux: source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env

# Run migrations
alembic upgrade head

# Seed sample users
python -m scripts.seed_data

# Start API
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API docs: http://localhost:8000/docs

### 2. Admin Dashboard

```bash
cd dashboard
npm install
cp .env.example .env
npm run dev
```

Open http://localhost:5173

### 3. Flutter Mobile

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Use `http://localhost:8000` for iOS simulator or your machine IP for physical devices.

## Sample Credentials (after seed)

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@ambulance.gov | Admin@12345 |
| Driver | driver@ambulance.gov | Driver@12345 |
| Officer | officer@ambulance.gov | Officer@12345 |

## How the AI Works

### Incident location estimation (`hybrid-v1`)

A deterministic, hotspot-anchored estimator — no model file, no training set:

- starts from the caller's position with a per-type reach profile (cardiac incidents are close, fires imprecise)
- attracts the estimate toward a curated table of ~48 Kathmandu risk hotspots (junctions, arterial roads, markets, hospital access) using inverse-square weighting, modulated by rush hour, night-time, and traffic
- confidence is geometric (hotspot proximity + agreement), clamped to 0.35–0.98

### Learned ETA model (`eta-v1`)

Every completed emergency session records its ground truth: the OSRM baseline duration vs. the actual wall-clock duration. Once **≥25 trips** exist, a gradient-boosting regressor learns each trip's `actual / baseline` ratio from distance, hour, weekday, traffic factor, and incident type. New activations then get ETA = baseline × predicted ratio (clamped 0.7–2.2); before that, a static traffic heuristic is used. Training runs automatically at startup (or via the admin `retrain-model` endpoint) and persists to `backend/models/eta_model.joblib` (gitignored).

### Auto-discovered hotspots

Completed sessions also record their actual incident coordinates. With **≥20 records**, KMeans (k chosen by silhouette score) clusters them into recurring accident zones, kind-tagged by their dominant incident type. The clusters join the curated table inside the estimator, so predictions tune themselves to observed reality (`backend/models/hotspots.json`, gitignored).

### Map pin override

Instead of typing a destination, drivers can pin the incident spot on an interactive OpenStreetMap picker (center-pin drag, device-locate button). The picked coordinates are reverse-geocoded for confirmation, fill the destination field with exact lat/lon, and override the AI estimate even when AI prediction is enabled.

## API Overview

### Authentication
- `POST /api/v1/auth/register` - Register user
- `POST /api/v1/auth/login` - Login (returns JWT)
- `GET /api/v1/auth/me` - Current user

### Emergency
- `POST /api/v1/emergencies/activate` - Start emergency with AI route prediction (driver)
- `POST /api/v1/emergencies/{id}/end` - End emergency
- `GET /api/v1/emergencies/active` - List active (admin)

### AI Prediction & Learned Models (OSRM + scikit-learn)
- `GET /api/v1/ai/model-info` - Estimator & learned-model metadata
- `POST /api/v1/ai/predict-incident` - Estimate incident coordinates
- `POST /api/v1/ai/route-to-incident` - Estimate incident + fastest traffic-aware route
- `POST /api/v1/ai/retrain-model` - (admin) Train the ETA model + rediscover hotspots from completed trips

### GPS
- `POST /api/v1/gps/update` - Send GPS coordinates
- `GET /api/v1/gps/live` - Live ambulance positions
- `GET /api/v1/gps/live/all` - All live (admin)

### Routes
- `POST /api/v1/routes/optimize` - OSRM route + congestion score
- `GET /api/v1/directions/geocode` - Place search (Nominatim)
- `GET /api/v1/directions/reverse-geocode` - Coordinates → place name (Nominatim)
- `GET /api/v1/directions/preview` - Route preview with traffic

### Notifications
- `GET /api/v1/notifications/` - Officer alerts
- `POST /api/v1/notifications/acknowledge` - Acknowledge alert

### Analytics
- `GET /api/v1/analytics/summary` - Dashboard stats
- `GET /api/v1/analytics/ambulances` - Per-ambulance stats

### WebSocket
- `WS /ws/live?token={jwt}&channel=admin|driver|officer&identifier={id}`

## Testing

```bash
# Backend health
curl http://localhost:8000/health

# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@ambulance.gov","password":"Admin@12345"}'

# Use token for protected routes
curl http://localhost:8000/api/v1/analytics/summary \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Deployment

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)

- **Backend**: Render
- **Frontend**: Vercel
- **Database**: Render PostgreSQL / managed PostgreSQL

## License

MIT

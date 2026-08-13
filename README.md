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
                    │  OSRM Route Optimization     │
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
| AI / ML | scikit-learn Random Forest (incident location) + traffic-aware ETA |

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

# Train ML incident model (auto-runs on startup if missing)
python -m scripts.generate_incident_data
python -m scripts.train_incident_model

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

## API Overview

### Authentication
- `POST /api/v1/auth/register` - Register user
- `POST /api/v1/auth/login` - Login (returns JWT)
- `GET /api/v1/auth/me` - Current user

### Emergency
- `POST /api/v1/emergencies/activate` - Start emergency with AI route prediction (driver)
- `POST /api/v1/emergencies/{id}/end` - End emergency
- `GET /api/v1/emergencies/active` - List active (admin)

### AI Route Prediction (scikit-learn + OSRM)
- `GET /api/v1/ai/model-info` - ML model metadata
- `POST /api/v1/ai/predict-incident` - Forecast incident coordinates
- `POST /api/v1/ai/route-to-incident` - Predict incident + fastest traffic-aware route
- `POST /api/v1/ai/retrain-model` - Retrain from `backend/data/incidents_history.csv`

### GPS
- `POST /api/v1/gps/update` - Send GPS coordinates
- `GET /api/v1/gps/live` - Live ambulance positions
- `GET /api/v1/gps/live/all` - All live (admin)

### Routes
- `POST /api/v1/routes/optimize` - OSRM route + congestion score

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

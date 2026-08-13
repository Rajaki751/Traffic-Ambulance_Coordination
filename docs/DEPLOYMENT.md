# Deployment Guide

## Backend (Render)

1. Create a **PostgreSQL** database on Render.
2. Create a **Web Service** pointing to `/backend`:
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - **Root Directory**: `backend`

3. Environment variables:

```
DATABASE_URL=postgresql+asyncpg://user:pass@host/dbname
DATABASE_URL_SYNC=postgresql://user:pass@host/dbname
SECRET_KEY=<generate-strong-random-key>
CORS_ORIGINS=https://your-dashboard.vercel.app
ENVIRONMENT=production
DEBUG=false
OSRM_BASE_URL=https://router.project-osrm.org
```

4. Run migrations on deploy (one-time shell or release command):

```bash
alembic upgrade head
python -m scripts.seed_data
```

## Dashboard (Vercel)

1. Import the `dashboard` folder to Vercel.
2. Set environment variables:

```
VITE_API_BASE_URL=https://your-api.onrender.com
VITE_WS_BASE_URL=wss://your-api.onrender.com
```

3. Deploy. Vercel auto-detects Vite.

## Mobile App

Update `lib/core/constants.dart` or use dart-define:

```bash
flutter build apk --dart-define=API_BASE_URL=https://your-api.onrender.com \
  --dart-define=WS_BASE_URL=wss://your-api.onrender.com
```

### Firebase Push Notifications (optional)

1. Create Firebase project and add Android/iOS apps.
2. Add `google-services.json` / `GoogleService-Info.plist`.
3. Set `FCM_SERVER_KEY` on backend for server-side push (extend `NotificationService`).

## Docker (full stack local)

```bash
docker compose up --build
```

Backend: http://localhost:8000  
PostgreSQL: localhost:5432

## Health Checks

- `GET /health` - Use for Render/Vercel uptime monitoring

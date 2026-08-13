-- AI-Driven Traffic Ambulance Coordination System
-- PostgreSQL Schema Reference

CREATE TYPE user_role AS ENUM ('admin', 'driver', 'officer');
CREATE TYPE ambulance_status AS ENUM ('available', 'on_duty', 'emergency', 'offline');
CREATE TYPE emergency_status AS ENUM ('active', 'completed', 'cancelled');

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX ix_users_email ON users(email);
CREATE INDEX ix_users_role ON users(role);

CREATE TABLE ambulances (
    id SERIAL PRIMARY KEY,
    driver_id INTEGER UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    vehicle_number VARCHAR(50) UNIQUE NOT NULL,
    status ambulance_status NOT NULL DEFAULT 'available'
);

CREATE INDEX ix_ambulances_status ON ambulances(status);

CREATE TABLE traffic_officers (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assigned_zone VARCHAR(255) NOT NULL,
    zone_latitude DOUBLE PRECISION,
    zone_longitude DOUBLE PRECISION,
    zone_radius_km DOUBLE PRECISION NOT NULL DEFAULT 5.0
);

CREATE TABLE emergency_sessions (
    id SERIAL PRIMARY KEY,
    ambulance_id INTEGER NOT NULL REFERENCES ambulances(id) ON DELETE CASCADE,
    destination VARCHAR(500) NOT NULL,
    dest_latitude DOUBLE PRECISION,
    dest_longitude DOUBLE PRECISION,
    status emergency_status NOT NULL DEFAULT 'active',
    route_polyline TEXT,
    eta_minutes DOUBLE PRECISION,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ
);

CREATE INDEX ix_emergency_sessions_ambulance_id ON emergency_sessions(ambulance_id);
CREATE INDEX ix_emergency_sessions_status ON emergency_sessions(status);

CREATE TABLE gps_logs (
    id SERIAL PRIMARY KEY,
    emergency_session_id INTEGER NOT NULL REFERENCES emergency_sessions(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    speed_kmh DOUBLE PRECISION,
    heading DOUBLE PRECISION,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX ix_gps_logs_session ON gps_logs(emergency_session_id);
CREATE INDEX ix_gps_logs_timestamp ON gps_logs(timestamp);

CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    officer_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL DEFAULT 'emergency_alert',
    emergency_session_id INTEGER REFERENCES emergency_sessions(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    is_acknowledged BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX ix_notifications_officer_id ON notifications(officer_id);
CREATE INDEX ix_notifications_user_id ON notifications(user_id);

CREATE TABLE junction_clearances (
    id SERIAL PRIMARY KEY,
    officer_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emergency_session_id INTEGER REFERENCES emergency_sessions(id) ON DELETE SET NULL,
    junction_name VARCHAR(255) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    notes TEXT,
    cleared_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX ix_junction_clearances_officer_id ON junction_clearances(officer_id);

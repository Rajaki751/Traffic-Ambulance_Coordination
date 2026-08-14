import joblib
import numpy as np
from pathlib import Path
import logging

logger = logging.getLogger(__name__)

KDE_MODEL_PATH = Path(__file__).resolve().parents[2] / "models" / "kde_models.joblib"

def train_kde_models(records):
    try:
        from sklearn.neighbors import KernelDensity
    except ImportError:
        logger.warning("scikit-learn not available")
        return False

    if len(records) < 10:
        return False
        
    models = {}
    # group by incident type
    type_records = {}
    for lat, lon, itype in records:
        if itype not in type_records:
            type_records[itype] = []
        type_records[itype].append([lat, lon])
        
    for itype, coords in type_records.items():
        if len(coords) < 3:
            continue
        X = np.array(coords)
        kde = KernelDensity(kernel='gaussian', bandwidth=0.005).fit(X)
        models[itype] = kde
        
    if models:
        KDE_MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
        joblib.dump(models, KDE_MODEL_PATH)
        logger.info(f"Trained KDE models for {len(models)} incident types")
        return True
    return False

class KDEPredictor:
    def __init__(self):
        self.models = {}
        if KDE_MODEL_PATH.exists():
            try:
                self.models = joblib.load(KDE_MODEL_PATH)
            except Exception as e:
                logger.error(f"Failed to load KDE models: {e}")

    def predict(self, caller_lat, caller_lon, incident_type):
        if not self.models or incident_type not in self.models:
            return None
            
        kde = self.models[incident_type]
        
        # Create a grid around caller (e.g. +/- 0.015 degrees ~ 1.5km)
        lat_grid = np.linspace(caller_lat - 0.015, caller_lat + 0.015, 20)
        lon_grid = np.linspace(caller_lon - 0.015, caller_lon + 0.015, 20)
        X, Y = np.meshgrid(lat_grid, lon_grid)
        positions = np.vstack([X.ravel(), Y.ravel()]).T
        
        # Evaluate density
        log_dens = kde.score_samples(positions)
        
        # Get point with max density
        best_idx = np.argmax(log_dens)
        best_pos = positions[best_idx]
        
        confidence = float(np.exp(log_dens[best_idx])) 
        # normalize confidence heuristically
        confidence = min(0.95, max(0.4, confidence * 0.1))
        
        return {
            "latitude": float(best_pos[0]),
            "longitude": float(best_pos[1]),
            "confidence": confidence,
            "source": "kde_ml"
        }

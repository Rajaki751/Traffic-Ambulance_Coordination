"""
Train the scikit-learn incident location prediction model.

Usage:
    cd backend
    python -m scripts.train_incident_model
"""

from app.ai.incident_predictor import IncidentLocationPredictor


def main() -> None:
    predictor = IncidentLocationPredictor()
    metrics = predictor.train()
    print("Training complete:", metrics)


if __name__ == "__main__":
    main()

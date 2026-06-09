# Insider Threat Detection - ML-projekt

## Översikt
Detta projekt använder maskininlärning för att upptäcka insiderhot i ett sjukvårdssystem.

## Resultat
- **Precision:** 99.1%
- **Recall:** 96.7%  
- **F1-score:** 0.979

## Teknologier
- Databricks
- MLflow
- Scikit-learn (Random Forest)
- Groq (LLM-analys)
- Slack-integration

## Projektstruktur
- `databricks/` - Alla notebook-filer (steg 1-14)
- `model_backup_*.zip` - Tränad modell och scaler
- `model_performance_history.csv` - Historik över alla körningar
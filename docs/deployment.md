# Deployment

## Firebase (free tier)

- Enable Authentication (Email/Password + Google optional)
- Create Firestore in production mode with rules
- Deploy Functions from backend/cloud_functions

## Flutter

- Deploy web to Firebase Hosting (optional)
- Mobile builds via standard Flutter pipeline

## Secrets

Set secrets in Firebase Functions environment:

- GEMINI_API_KEY
- JUDGE0_BASE_URL
- JUDGE0_API_KEY
- RATE_LIMIT_PER_MINUTE

## Notes

Judge0 free endpoints can have queue latency. Keep polling intervals low and timeout bounded.

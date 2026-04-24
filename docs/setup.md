# Setup

## Prerequisites

- Flutter SDK (stable)
- Node.js 20+
- Firebase CLI
- A Firebase project (Spark free tier)
- Gemini API key
- Judge0 endpoint and token (free CE host or self-host)

## Environment variables

Backend and AI services use:

- GEMINI_API_KEY
- JUDGE0_BASE_URL
- JUDGE0_API_KEY
- FIREBASE_PROJECT_ID
- RATE_LIMIT_PER_MINUTE (default: 30)

## Install

1. Backend
   - cd backend/cloud_functions
   - npm install
2. AI flows
   - cd ai/genkit_flows
   - npm install
3. Judge service
   - cd compiler/judge_service
   - npm install
4. Flutter
   - cd frontend/flutter_app
   - flutter pub get

## Run locally

- Cloud Functions emulator: npm run serve
- Genkit dev: npm run genkit:dev
- Judge service: npm run dev
- Flutter web: flutter run -d chrome

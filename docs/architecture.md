# Architecture

## High-level

Client (Flutter Web/Mobile) -> Firebase Auth -> Cloud Functions -> Firestore

AI tasks:
- Cloud Functions invokes Genkit flows (Gemini)

Code execution:
- Cloud Functions/Judge service sends code to Judge0 API
- Polls for completion and returns stdout/stderr/time/memory

Realtime:
- Firestore streams for session state + analytics updates

## Security

- Firebase Auth ID token required for all write APIs
- Basic per-user rate limiting in Firestore
- Input validation on all request payloads
- No direct Judge0 key exposure to client

## Firestore collections

- users/{userId}
- questions/{questionId}
- sessions/{sessionId}
- submissions/{submissionId}
- designSubmissions/{designId}
- cheatFlags/{flagId}

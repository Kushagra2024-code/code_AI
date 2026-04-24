# API Endpoints

Base URL (emulator):
- http://localhost:5001/<project>/us-central1

Auth:
- Pass Firebase ID token as Authorization: Bearer <token>

## POST /generateQuestion
Input:
- difficulty: string
- tags: string[]

## POST /runCode
Input:
- code: string
- language: cpp|python|java|javascript
- stdin?: string

## POST /startSession
Input:
- sessionId: string
- type: coding|system_design|mixed

## POST /endSession
Input:
- sessionId: string

## POST /submitCode
Input:
- sessionId: string
- code: string
- language: cpp|python|java|javascript
- sampleTests?: [{input, output}]
- hiddenTests?: [{input, output}]
- result?: fallback local result object

## POST /evaluateDesign
Input:
- sessionId: string
- diagram: JSON graph
- question?: string

## POST /detectCheating
Input:
- sessionId: string
- signals: { tabSwitches, largePaste, tooFast, similarityHigh }

## POST /generateFeedback
Input:
- submissionId: string
- code: string
- language?: string
- problem?: string

## POST /interviewTurn
Input:
- stage: intro|clarify|optimize|edge_cases
- context: string
- sessionId?: string

## GET /sessionScore
Query:
- sessionId: string

Score formula:
- Coding Correctness 40%
- Efficiency 20%
- Code Quality 20%
- System Design 20%

## GET /analytics
Returns aggregated per-user metrics.

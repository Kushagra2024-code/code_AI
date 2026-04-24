# Firestore Schema

## users/{userId}
- name: string
- email: string
- rating: number

## sessions/{sessionId}
- userId: string
- type: coding|system_design|mixed
- startTime: timestamp
- endTime: timestamp
- score: number

## questions/{questionId}
- title: string
- difficulty: string
- tags: string[]
- statement: string
- constraints: string[]
- examples: array
- hiddenTests: array

## submissions/{submissionId}
- sessionId: string
- userId: string
- language: string
- code: string
- correctness: number
- performance: number
- quality: number
- passedTests: number
- execution: map
- score: number

## designSubmissions/{designId}
- sessionId: string
- userId: string
- diagram: map
- evaluation: map

## cheatFlags/{flagId}
- sessionId: string
- userId: string
- signals: map
- suspiciousScore: number
- flagged: boolean

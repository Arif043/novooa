# Firestore Rules Analysis

## Project
- Firebase project: `syscat-90bff`
- Firestore database: `(default)`
- Edition/type: `STANDARD` / `FIRESTORE_NATIVE`
- Location: `europe-west3`

## Collections
- `/users/{uid}`
  - Created/updated from Flutter after successful Firebase Auth sign-up/sign-in.
  - Contains PII (`email`), so reads must be owner-only.
  - Document ID must match `request.auth.uid`.

## User Document Shape
- `uid`: string, required, immutable, equals document ID and `request.auth.uid`
- `email`: string, required, valid email format, max 254 chars
- `displayName`: string, required, 2-120 chars
- `createdAt`: timestamp, required, immutable
- `updatedAt`: timestamp, required

## Access Patterns
- App reads a single profile document by ID: `/users/{uid}`.
- App creates a profile document when a Firebase Auth user signs up.
- App updates `email`, `displayName`, and `updatedAt` when a user signs in/up.
- No collection list/query access is required for `/users`.

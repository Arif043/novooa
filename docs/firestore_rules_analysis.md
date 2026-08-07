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
- `/users/{uid}/settings/aiModel`
  - Readable owner-only metadata for the selected AI provider.
  - Contains only non-secret display data, including a masked key hint.
- `/users/{uid}/secrets/aiProvider`
  - Write-only owner document for the provider API key.
  - Client writes the key, but Firestore rules deny all client reads/lists.
- `/teams/{teamId}/knowledgeBases/{knowledgeBaseId}/notes/{noteId}`
  - Team-scoped Markdown notes for the node attachment RAG.
  - Client can read/list/create/update/delete notes as a team member.
  - Creates/updates validate title, path, type, content size, link list size,
    and timestamps.

## User Document Shape
- `uid`: string, required, immutable, equals document ID and `request.auth.uid`
- `email`: string, required, valid email format, max 254 chars
- `displayName`: string, required, 2-120 chars
- `createdAt`: timestamp, required, immutable
- `updatedAt`: timestamp, required

## AI Model Settings Shape
- `provider`: string, required, one of `openai`, `google_ai`, `anthropic`
- `hasApiKey`: bool, required, must be `true` for persisted settings
- `maskedApiKey`: string, required, `**** 1234` format
- `updatedAt`: timestamp, required

## AI Provider Secret Shape
- `provider`: string, required, one of `openai`, `google_ai`, `anthropic`
- `apiKey`: string, required, 8-4096 chars
- `updatedAt`: timestamp, required

## Access Patterns
- App reads a single profile document by ID: `/users/{uid}`.
- App creates a profile document when a Firebase Auth user signs up.
- App updates `email`, `displayName`, and `updatedAt` when a user signs in/up.
- No collection list/query access is required for `/users`.
- App reads `/users/{uid}/settings/aiModel` to render provider and masked status.
- App writes `/users/{uid}/settings/aiModel` and
  `/users/{uid}/secrets/aiProvider` in one batch when saving the AI settings.
- App never reads or lists `/users/{uid}/secrets/*`; backend code can use Admin
  SDK access for actual model calls later.
- Client deletes are denied for secret documents to avoid stale settings/secret
  drift until a dedicated "Key entfernen" workflow exists.
- Task Builder reads knowledge notes from
  `/teams/{teamId}/knowledgeBases/default/notes` ordered by `title`.
- Wissensbasis page reads and writes the same collection, ordered by `title`.
- Prompt nodes persist selected note references inside task graph config as
  `knowledgeAttachments`.
- Backend Functions use Admin SDK to resolve selected notes, recursively expand
  MOC links, and expose Markdown files through Genkit filesystem middleware.
- Zeitplan page reads and writes
  `/teams/{teamId}/taskTriggers`. `type=schedule` requires `config`;
  `type=event` requires `eventConfig.source` in the allowed event source list
  and an optional `filter` up to 240 characters. Event triggers may optionally
  reference `eventConfig.channelId`; when present, rules require the referenced
  communication channel to exist in the same team.
- Twilio-Kommunikationskanäle leben unter
  `/teams/{teamId}/communicationChannels/{channelId}`. Team members may read,
  create, update, and delete validated WhatsApp- and SMS-channel documents.
  Mail-Connectoren liegen separat unter `mailConnectors`; SendGrid kann nicht
  als Nutzerkanal gespeichert werden. Provider secrets are not stored in these
  documents.

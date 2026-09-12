# Love Advisor Backend

This is the backend repository for the Love Advisor application, built with Python, FastAPI, and Firebase.

## Important Note

**The Flutter repository (`d:\Ourly-App`) was completely empty during the initialization.**
Since there was no Flutter source to use as a "source of truth", the frontend-backend contract was established from scratch based purely on the product requirements in the prompt.

Please ensure the Flutter app aligns with this contract when it is initialized.

## Architecture

- **Framework**: FastAPI
- **Authentication**: Firebase Admin SDK (verifies ID token passed in `Authorization: Bearer <token>`)
- **Database Architecture (Planned)**: Cloud Firestore (with data scoped by authenticated UID)
- **AI Logic**: Mock implementation provided in `recommendations.py` which can easily be replaced by calling Gemini via `google-genai` or `langchain`.
- **Directory Structure**:
  - `app/api`: FastAPI routes.
  - `app/domain/schemas`: Pydantic models for request/response serialization (camelCase compliant for Flutter).
  - `app/core`: Shared configurations and error handlers.
  - `app/infrastructure`: External services adapters (Firebase, etc.).

## Frontend-Backend Contract Summary

| Concept | Implementation Details |
|---|---|
| **JSON Serialization** | All fields use `camelCase` (e.g. `partnerId`, `estimatedCost`). |
| **Authentication** | Pass Firebase ID Token in HTTP header: `Authorization: Bearer <token>`. The backend verifies it and extracts `uid`. |
| **Date/Time** | ISO 8601 strings with timezone (UTC). |
| **Budget** | Object with `amount` (float/int) and `currency` (string, e.g. "VND"). |
| **Errors** | Structured JSON: `{"error": {"code": "...", "message": "...", "details": {}}}` |

## API Endpoints (MVP)

- `GET /health` : Health check.
- `GET /v1/me` : Returns authenticated user info.
- `POST /v1/partners` : Create a new partner profile.
- `GET /v1/partners` : List user's partners.
- `POST /v1/partners/{partner_id}/memories` : Add a memory for a partner.
- `GET /v1/partners/{partner_id}/memories` : List memories for a partner.
- `POST /v1/recommendations` : Request a date plan recommendation.
- `POST /v1/date-plans` : Create a date plan.
- `GET /v1/date-plans` : List date plans.
- `PATCH /v1/date-plans/{plan_id}/complete` : Complete a date plan, earn points/streaks (idempotent).

## How to Run Locally

1. Create a virtual environment: `python -m venv venv`
2. Activate it: `source venv/bin/activate` or `.\venv\Scripts\Activate.ps1`
3. Install dependencies: `pip install -e ".[dev]"`
4. Copy `.env.example` to `.env` and fill in your Firebase credentials.
5. Run the server: `uvicorn app.main:app --reload`
6. Access Swagger UI at `https://apricot-freezable-chemicals.ngrok-free.dev/docs` (or local `http://127.0.0.1:8000/docs`)

## AI Mock

Currently, the `POST /v1/recommendations` endpoint uses a deterministic mock fallback to ensure the endpoint is functional without requiring an actual AI API key. You can swap this out in `app/api/routes/recommendations.py` with an actual LLM call.

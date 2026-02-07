# Local Setup

## Backend
\\\powershell
cd backend
.\run_backend.ps1
\\\

Then open:
- http://127.0.0.1:8000/docs
- http://127.0.0.1:8000/openapi.json

## Frontend
Android emulator base URL:
- http://10.0.2.2:8000

\\\powershell
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
\\\

> iOS simulator can usually use http://127.0.0.1:8000

## Notes
- If Swagger fails: check backend terminal logs and ensure the venv is activated.
- Avoid naming files: typing.py, fastapi.py, pydantic.py, httpx.py (module shadowing).

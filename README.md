# Prayer Compass

A location-aware prayer companion built with **Flutter + FastAPI**.

It gives you daily prayer times, a Qibla compass, and a world-map Qibla route in a single app. The goal is simple: keep the UX clean while still exposing the details that matter for trust (method, madhhab, coordinates, timezone).

## Why This Exists

Prayer apps usually optimize for one side only:

- Good visuals, weak transparency
- Accurate backend, rough UX

Prayer Compass tries to bridge both:

- explicit calculation controls
- visible location/timezone data
- resilient local fallback behavior
- clear error states instead of silent failures

## What You Get

- Live prayer times from your current location
- Manual coordinate mode with persisted settings
- Calculation method selector (`method` for AlAdhan)
- Madhhab selector (`Shafi` / `Hanafi` affects Asr)
- Next-prayer highlighting and live countdown
- Qibla compass using device heading + computed bearing
- Qibla line map with geodesic route to the Kaaba
- Open-in-Google-Maps with robust Android/web fallback
- Backend endpoints for prayer times, geocoding, and health

## One-Minute Tour

When you press **Aktualisieren**, this is the path:

1. Frontend resolves coordinates (live GPS or manual saved values).
2. Backend receives `/api/v1/prayer-times?lat=...&lon=...`.
3. Backend calls AlAdhan and normalizes the response.
4. Frontend renders times, next-prayer countdown, location chip, and timezone chip.
5. Qibla widgets use the same active coordinates for bearing, route, and maps deep-linking.

## Tech Stack

### Frontend

- Flutter (Material)
- `ChangeNotifier` controller layer
- `dio` for API calls
- `geolocator` for device position
- `geocoding` for reverse labels
- `flutter_compass` for heading
- `flutter_map` + OpenStreetMap tiles for in-app route view
- `shared_preferences` for local settings
- `url_launcher` for external maps

### Backend

- FastAPI
- `httpx` upstream client
- `pydantic` schemas
- AlAdhan Timings API (`/v1/timings`)
- Nominatim geocoding (`openstreetmap.org`)

## Architecture

```mermaid
flowchart LR
  A["Flutter App"] -->|"GET /api/v1/prayer-times"| B["FastAPI"]
  A -->|"GET /api/v1/geocode"| B
  B -->|"HTTPS"| C["AlAdhan API"]
  B -->|"HTTPS"| D["Nominatim API"]
  A --> E["SharedPreferences"]
  A --> F["Geolocator"]
  A --> G["Flutter Compass"]
```

## Project Layout

```text
prayer-times-app/
  backend/
    app/
      api/v1/routes/
        prayer_times.py
        geocode.py
      services/
        aladhan_client.py
        geocode_client.py
      schemas/
        prayer_times.py
        geocode.py
      main.py
    requirements.txt
    run_backend.ps1

  frontend/
    lib/
      src/
        controllers/
          prayer_times_controller.dart
        services/
          prayer_api_client.dart
          location_service.dart
          settings_store.dart
        ui/
          prayer_home_page.dart
          qibla_map_page.dart
          widgets/qibla_compass_card.dart
        utils/
          qibla_utils.dart
          prayer_time_utils.dart
    android/app/src/main/AndroidManifest.xml
    pubspec.yaml
```

## API Endpoints

Base URL (local): `http://127.0.0.1:8000`

### `GET /health`

Returns backend status.

Example:

```bash
curl http://127.0.0.1:8000/health
```

Response:

```json
{"status":"ok"}
```

### `GET /api/v1/prayer-times`

Query params:

- `lat` (required, float)
- `lon` (required, float)
- `method` (optional, default `2`)
- `school` (optional, default `0`; `0=Shafi`, `1=Hanafi`)

Example:

```bash
curl "http://127.0.0.1:8000/api/v1/prayer-times?lat=52.5174&lon=13.3951&method=13&school=1"
```

Response shape:

```json
{
  "date": "11 Feb 2026",
  "timezone": "Europe/Berlin",
  "location": {"lat": 52.5173885, "lon": 13.3951309},
  "method": 13,
  "school": 1,
  "times": {
    "Fajr": "05:35",
    "Sunrise": "07:24",
    "Dhuhr": "12:26",
    "Asr": "15:23",
    "Maghrib": "17:19",
    "Isha": "19:01"
  }
}
```

### `GET /api/v1/geocode`

Text lookup endpoint for city/district/address to coordinates.

Query params:

- `q` (required, min length `2`)

Example:

```bash
curl "http://127.0.0.1:8000/api/v1/geocode?q=Berlin"
```

Response shape:

```json
{
  "query": "Berlin",
  "label": "Berlin, Deutschland",
  "location": {"lat": 52.5173885, "lon": 13.3951309}
}
```

## Qibla Implementation Notes

Kaaba reference used by the app:

- latitude: `21.422487`
- longitude: `39.826206`

The app computes:

- **bearing** from user coordinates to Kaaba
- **great-circle distance** (haversine)
- **geodesic path** (interpolated points for map polyline)

The map route renderer splits at dateline jumps so the line remains visually stable.

## Location Behavior (Important)

The app supports two modes:

- **Live location** (GPS / device services)
- **Manual location** (saved coords + label)

There is also a repair guard for a common mismatch:

- if manual label is city-like (for example `Berlin`)
- but saved coordinates are still default fallback values
- app calls `/api/v1/geocode` and updates manual coordinates automatically

This prevents the "Berlin label but America/New_York timezone" inconsistency.

## Google Maps Launch Behavior

On some devices/emulators, URL intents fail depending on package visibility or available browser apps.

Current behavior:

- tries multiple launch modes (`platformDefault`, `externalApplication`, `inAppBrowserView`)
- if all fail, copies the full Maps URL to clipboard
- shows a snackbar explaining fallback

Android manifest also includes `queries` for URL intent schemes (`https`, `geo`) to improve Android 11+ compatibility.

## Requirements

- Flutter SDK compatible with Dart `>=3.2.3 <4.0.0`
- Python `3.9+`
- Android emulator or physical device (for location/compass tests)

## Local Setup

### 1) Backend

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Windows PowerShell helper:

```powershell
cd backend
.\run_backend.ps1
```

Check:

```bash
curl http://127.0.0.1:8000/health
```

Open docs:

- `http://127.0.0.1:8000/docs`
- `http://127.0.0.1:8000/openapi.json`

### 2) Frontend

```bash
cd frontend
flutter pub get
```

Run on Android emulator:

```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Run on iOS simulator:

```bash
flutter run -d ios --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Run on web (Chrome):

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Runtime Config

`API_BASE_URL` is provided via `--dart-define`.

Defaults in app code:

- Android: `http://10.0.2.2:8000`
- Web/others: `http://127.0.0.1:8000`

## Useful Dev Commands

Frontend:

```bash
cd frontend
flutter test
flutter analyze
```

Backend quick syntax check:

```bash
python3 -m py_compile backend/app/main.py
python3 -m py_compile backend/app/services/aladhan_client.py
python3 -m py_compile backend/app/services/geocode_client.py
```

## Troubleshooting

### 1) Timezone shows `America/New_York` unexpectedly

Usually means the request was sent with fallback coords (`40.7128,-74.0060`).

Fix:

- switch to manual mode and set correct coords explicitly
- or keep manual label (`Berlin`) and refresh so geocode repair can update coords
- verify backend logs show expected `lat/lon`

### 2) Google Maps doesn’t open

- ensure emulator/device has a browser/maps handler
- retry from Qibla card or Qibla map action
- if still blocked, app copies the URL to clipboard automatically

### 3) Backend unreachable from Android emulator

Use `10.0.2.2`, not `localhost`.

### 4) Port `8000` already in use

```bash
lsof -nP -iTCP:8000 -sTCP:LISTEN
kill <PID>
```

### 5) Compass data unavailable

- emulators often have no real compass stream
- test on physical device
- move phone in figure-8 for sensor calibration

## Notes for Production Hardening

- Restrict CORS origin list
- Add API rate limiting and caching
- Add structured logging + metrics
- Add retry/backoff policy for upstream failures
- Add integration tests for endpoint contracts

## License

MIT. See `LICENSE`.

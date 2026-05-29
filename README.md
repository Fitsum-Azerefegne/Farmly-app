# Farmly

Farmly is a farming assistant with a FastAPI backend, a Flutter app, voice input/output, crop advice, and a local sorghum disease model.

## Project Structure

```text
backend/   FastAPI API, auth, chat, crop diagnosis, voice, recommendations
mobile/    Flutter app for web/mobile
```

The backend runs as two services:

```text
Main API:             http://localhost:8000
Sorghum model server: http://127.0.0.1:8001
```

The sorghum model server is private and is called by the main API.

## Backend Setup

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

Create `backend/.env` by copying `backend/.env.example`:

```powershell
Copy-Item .env.example .env
```

Then fill in the required values.

Minimum local values:

```env
DATABASE_URL=sqlite:///./farmly.db
JWT_SECRET_KEY=replace_with_a_long_random_secret_at_least_16_chars
DEBUG=true
SORGHUM_MODEL_SERVER_URL=http://127.0.0.1:8001
```

For full functionality, also configure:

```env
GEMINI_API_KEY=...
SMS_ETHIOPIA_API_KEY=...
KINDWISE_PLANT_ID_API_KEY=...
KINDWISE_CROP_HEALTH_API_KEY=...
ISDA_USERNAME=...
ISDA_PASSWORD=...
GOOGLE_CLOUD_PROJECT=...
GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\service-account.json
```

Google Cloud must have billing enabled and these APIs enabled:

```text
Cloud Text-to-Speech API
Cloud Speech-to-Text API
```

## Run Locally

Terminal 1, main API:

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
python -m uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

Terminal 2, sorghum model:

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
python -m uvicorn src.model_server:app --host 127.0.0.1 --port 8001
```

Health checks:

```text
http://localhost:8000/health
http://127.0.0.1:8001/health
```

## Flutter Setup

```powershell
cd mobile
flutter pub get
```

Run web locally:

```powershell
flutter run -d chrome
```

Run web against hosted backend:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=https://farmlyapi.birukabza.me
```

Run Android emulator against local backend:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Run Android/real device against hosted backend:

```powershell
flutter run --dart-define=API_BASE_URL=https://farmlyapi.birukabza.me
```

## Build APK

If the Android platform folder does not exist yet:

```powershell
cd mobile
flutter create --platforms=android .
```

Add location permissions to `mobile/android/app/src/main/AndroidManifest.xml` inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

Build release APK:

```powershell
cd mobile
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://farmlyapi.birukabza.me
```

Output:

```text
mobile/build/app/outputs/flutter-apk/app-release.apk
```

## Features

- Phone OTP registration and password login
- Forgot-password reset flow
- Onboarding with GPS or manual location search
- Chat sessions with rename/delete
- Text chat and image upload
- Voice input using browser recording
- Voice playback for assistant responses
- Sorghum disease diagnosis through the local `.pt` model
- Crop, fertilizer, weather, and soil-aware recommendations

## Hosted Backend

The production backend is hosted at:

```text
https://farmlyapi.birukabza.me
```

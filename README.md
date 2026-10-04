# Mchina 🛴 Campus Scooter Booking App

Mchina is a cross-platform mobile app for booking and riding electric scooters on the Al Akhawayn University campus in Ifrane, Morocco. Riders find nearby scooters on a live map, unlock one by scanning its QR code, and pay per minute, with ride history, ratings, and campus safety information built in.

## Features

- **Phone-number login with OTP:** sign up and sign in with a Moroccan phone number and a one-time verification code, with token-based sessions.
- **Live scooter map:** Google Maps view of available scooters with battery level, price, and status (available or out of service), plus the rider's real-time GPS position and distance to each scooter.
- **QR code unlock:** scan the code on a scooter to start a ride; invalid codes are rejected.
- **Ride tracking and pricing:** live ride timer and running cost at 1.00 DH per minute.
- **Ride summary and rating:** duration and cost at the end of each ride, plus a 1–5 star rating saved to the backend.
- **Ride history:** list of past rides with date, duration, and cost.
- **Payment method:** card entry with formatting and validation; only the last four digits and card brand are stored.
- **Profile setup, safety guide, and support:** onboarding slides, campus riding rules with an emergency contact button, FAQ, and issue reporting.

## Tech Stack

| Layer | Technologies |
|---|---|
| Mobile app | Flutter, Dart |
| Maps and location | google_maps_flutter, geolocator |
| QR scanning | mobile_scanner |
| Networking and storage | http (REST API with Bearer token auth), shared_preferences |
| Backend | REST API (separate repository) |

## Project Structure

```
lib/
├── main.dart            # App entry, map screen, auth flow, ride logic, ride history
├── api_service.dart     # REST API client (auth, profile, payments)
├── scooter_model.dart   # Scooter data model
├── payment.dart         # Payment method screen
├── profile_setup.dart   # New user profile setup
├── ride_summary.dart    # End-of-ride summary
├── rides.dart           # Ride history items
├── safety.dart          # Campus safety guide
└── support.dart         # Help, FAQ and issue reporting
```

## Getting Started

### Prerequisites

- Flutter SDK (Dart 3.10 or later)
- Android Studio or Xcode with an emulator or device
- A Google Maps API key with the Maps SDK for Android/iOS enabled
- The Mchina backend running locally (default: port 3000)

### Setup

1. Clone the repository and install dependencies:
   ```bash
   git clone https://github.com/YOUR-USERNAME/mchina.git
   cd mchina
   flutter pub get
   ```

2. Add your Google Maps API key to `android/local.properties` (this file is git-ignored):
   ```properties
   MAPS_API_KEY=your_google_maps_api_key
   ```

3. Run the app. By default it connects to `http://10.0.2.2:3000` (the Android emulator's alias for your computer). To use another backend URL:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://localhost:3000
   ```

## Screenshots

| Map | Ride in progress | Ride summary | Ride history |
|---|---|---|---|
| ![Map](docs/screenshots/map.png) | ![Ride](docs/screenshots/ride.png) | ![Summary](docs/screenshots/summary.png) | ![History](docs/screenshots/history.png) |

## Roadmap

- Integrate a real payment provider (card verification is currently simulated)
- Load scooter locations from the backend instead of sample data
- Push notifications for reservations and ride receipts

## Author

**Ouzair Bouaouida**, Computer Science, Al Akhawayn University in Ifrane

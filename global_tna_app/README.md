# MenteCart Flutter App

Production-ready Flutter client for the MenteCart service booking platform.

## Overview
This app integrates with a Node.js + Express + MongoDB backend for:
- JWT authentication (login/register/session restore)
- Service discovery with search/filter/pagination
- Slot-based booking and cart management
- Cash + PayHere checkout
- Booking history and booking detail tracking

## Tech Stack
- Flutter (stable)
- Dart 3
- `flutter_bloc` (BLoC architecture)
- Dio (HTTP client)
- GetIt (dependency injection)
- SharedPreferences (session + cart persistence)
- GoRouter (typed routing + route guards)

## Architecture
Clean architecture per feature:
- `data`: remote models, repositories, data sources
- `domain`: entities, repository contracts
- `presentation`: BLoCs, pages, UI widgets

Core cross-cutting modules:
- `core/network`: Dio client, auth interceptor, API error mapper
- `core/theme`: modern light/dark themes
- `core/widgets`: reusable empty/error/status/skeleton/snackbar widgets
- `config/env_config.dart`: environment-aware runtime config

## Implemented Highlights
- Complete register flow with validation:
  - email format
  - password min length
  - confirm password match
- Auth persistence:
  - token cache
  - auto-login state check on app start
  - logout cleanup (token + cart cache)
- Route guards for protected routes:
  - `/services`, `/services/:id`
  - `/cart`
  - `/bookings`, `/bookings/:id`
  - `/checkout`
- Services:
  - debounced search
  - category filters
  - pull-to-refresh
  - infinite scroll pagination
  - service detail page with slot UX
- Slot booking UX:
  - date picker
  - slot chips/cards
  - full-slot disable handling
  - selection validation before add-to-cart
- Booking management:
  - booking list with status chips
  - booking detail screen
  - payment status
  - cancel pending booking
  - status timeline
- Cart persistence:
  - cached cart survives app restart
- Error UX:
  - centralized Dio error mapping
  - user-friendly retry/empty/error states

## API Contract Notes
Implementation follows backend behavior represented in `postman_collection.json`, including:
- `/auth/register`, `/auth/login`, `/auth/me`
- `/services`, `/services/:id?bookingDate=YYYY-MM-DD`
- `/cart`, `/cart/items`
- `/bookings`, `/bookings/checkout`, `/bookings/:id`, `/bookings/:id/cancel`
- `/bookings/payhere/notify`

## Environment Setup
Use `--dart-define` values:

- `APP_ENV=dev|prod`
- `API_URL` (explicit override)
- `API_URL_DEV`
- `API_URL_PROD`
- `PAYHERE_MERCHANT_ID`
- `PAYHERE_MERCHANT_SECRET`
- `PAYHERE_NOTIFY_URL`

Example:

```bash
flutter run \
  --dart-define=APP_ENV=dev \
  --dart-define=API_URL_DEV=http://10.0.2.2:6001 \
  --dart-define=PAYHERE_MERCHANT_ID=1211142
```

## Getting Started
```bash
flutter pub get
flutter run
```

## Testing
```bash
flutter test
```

Included tests:
- Auth BLoC tests
- Services BLoC tests
- Auth repository tests
- Widget validation tests

## Build
```bash
flutter build apk --release --dart-define=APP_ENV=prod
flutter build ios --release --dart-define=APP_ENV=prod
```

## Suggested Screenshots Section
Add screenshots under `docs/screenshots/` and reference them:
- Login
- Register
- Services list
- Service detail + slots
- Cart
- Checkout
- Bookings list
- Booking detail

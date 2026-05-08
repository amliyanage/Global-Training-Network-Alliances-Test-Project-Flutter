# GlobalTNA Mobile Workspace

## Project Summary
This repository contains the Flutter client app for the GlobalTNA technical assessment (`global_tna_app`) and an API test suite (`postman_collection.json`).

The mobile app supports:
- JWT-based authentication
- Service browsing with search/filter/pagination
- Cart and booking flow
- PayHere-based online checkout
- Booking history and detail views

## Tech Stack
- Flutter
- Dart (project constraint: `^3.11.0`)
- `flutter_bloc` (state management)
- `dio` (HTTP client)
- `get_it` (dependency injection)
- `shared_preferences` (local token/cart persistence)
- `go_router` (routing)
- `payhere_mobilesdk_flutter` (payment SDK)

## Prerequisites
- Flutter SDK installed and available in `PATH`
- Dart SDK compatible with `^3.11.0` (bundled with recent Flutter versions)
- Android Studio + Android SDK (for Android builds) or Xcode (for iOS builds)
- Running backend API for auth/services/cart/bookings endpoints
- PayHere sandbox merchant credentials for online payment testing

## Environment Variables
Set values with `--dart-define`.

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `APP_ENV` | No | `dev` | Selects environment (`dev` or `prod`) |
| `API_URL` | No | `` | Explicit API base URL override (highest priority) |
| `API_URL_DEV` | No | `https://2nhghgh5-6001.asse.devtunnels.ms` | Dev API URL when `APP_ENV=dev` and `API_URL` is empty |
| `API_URL_PROD` | No | `https://api.mentecart.com` | Prod API URL when `APP_ENV=prod` and `API_URL` is empty |
| `PAYHERE_MERCHANT_ID` | No | `1211142` | PayHere merchant ID |
| `PAYHERE_MERCHANT_SECRET` | Yes (for real payment calls) | `` | PayHere merchant secret |
| `PAYHERE_NOTIFY_URL` | Yes (recommended) | `` | Backend notification URL for PayHere callbacks |

## Step-by-Step Run Instructions
1. Open terminal at the repository root.
2. Move to the Flutter app:
```bash
cd global_tna_app
```
3. Install dependencies:
```bash
flutter pub get
```
4. Ensure your backend API is reachable from emulator/device.
5. Run the app in dev mode (example for Android emulator localhost mapping):
```bash
flutter run \
  --dart-define=APP_ENV=dev \
  --dart-define=API_URL_DEV=http://10.0.2.2:6001 \
  --dart-define=PAYHERE_MERCHANT_ID=1211142 \
  --dart-define=PAYHERE_MERCHANT_SECRET=YOUR_SANDBOX_SECRET \
  --dart-define=PAYHERE_NOTIFY_URL=https://your-backend.example.com/bookings/payhere/notify
```
6. Run unit/widget tests:
```bash
flutter test
```

## Test Card Numbers Used (PayHere Sandbox)
Use these in PayHere sandbox checkout screens.

For `Name on Card`, `CVV`, and `Expiry`, enter any valid values.

### Successful Payment
| Card Type | Number |
|---|---|
| Visa | `4916217501611292` |
| MasterCard | `5307732125531191` |
| AMEX | `346781005510225` |

### Decline Scenarios
| Scenario | Visa | MasterCard | AMEX |
|---|---|---|---|
| Insufficient Funds | `4024007194349121` | `5459051433777487` | `370787711978928` |
| Limit Exceeded | `4929119799365646` | `5491182243178283` | `340701811823469` |
| Do Not Honor | `4929768900837248` | `5388172137367973` | `374664175202812` |
| Network Error | `4024007120869333` | `5237980565185003` | `373433500205887` |

Source: PayHere Knowledge Base, "Sandbox & Testing" (updated March 29, 2024): https://support.payhere.lk/sandbox-and-testing

## Known Limitations
- Backend service is not included in this repository; app behavior depends on external API availability.
- Authentication token is persisted in `SharedPreferences` (not secure hardware-backed storage).
- No refresh-token flow is implemented; on API `401 Unauthorized`, cached auth/cart data is cleared and user must re-authenticate.
- End-to-end PayHere success state depends on backend notification handling (`/bookings/payhere/notify`) and merchant sandbox configuration.
- Automated test coverage currently focuses on core auth/services/cart flows; full payment and platform-specific integration tests are limited.

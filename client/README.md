# Budget App - Flutter Frontend

Flutter frontend for the Budget App.

## Setup

1. Install Flutter: https://flutter.dev/docs/get-started/install

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
# For development on Chrome
flutter run -d chrome

# For mobile (with emulator running)
flutter run
```

## Project Structure

```
lib/
├── main.dart              # App entry point
├── models/                # Data models
│   ├── transaction.dart
│   └── account.dart
├── screens/               # UI screens
│   ├── home_screen.dart
│   ├── plaid_link_screen.dart
│   └── transactions_screen.dart
└── services/              # API and business logic
    └── api_service.dart
```

## TODO

### Plaid Integration
- [ ] Configure plaid_flutter package properly
- [ ] Handle Plaid Link callbacks
- [ ] Implement token storage

### State Management
- [ ] Implement proper state management (Provider, Riverpod, or Bloc)
- [ ] Store access token securely
- [ ] Handle offline mode

### UI/UX
- [ ] Add loading indicators
- [ ] Implement error handling
- [ ] Add transaction filtering and search
- [ ] Create dashboard with charts
- [ ] Add category selection UI

### Features
- [ ] Implement transaction sync
- [ ] Add manual categorization
- [ ] Show ML predictions
- [ ] Add budget tracking
- [ ] Implement spending insights

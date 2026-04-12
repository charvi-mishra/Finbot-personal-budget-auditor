# 🐷 Finbot — Smart Expense Tracking Chatbot

A Flutter + Firebase app where you talk to a friendly AI piggy bank bot in plain English to track your expenses. Just say *"I spent ₹500 on groceries"* and everything is logged automatically!

---

## ✨ Features

- **Conversational expense logging** — tell PiggyBot in plain English
- **Auto-categorization** — AI extracts category, amount, date, and currency
- **Real-time home screen** — savings and spending update instantly
- **Pie chart + category grid** — visual breakdown of your spending
- **Recent transactions list** — with emoji per category
- **Secure auth** — Firebase email/password with field validation
- **Occupation-aware** — monthly income is optional for unemployed/student users
- **Multi-currency aware** — supports ₹, $, £, € and more

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── firebase_options.dart        # Firebase config (auto-generated)
├── models/
│   ├── user_model.dart
│   └── expense_model.dart
├── services/
│   ├── auth_service.dart
│   ├── expense_service.dart
│   ├── chat_service.dart        # Anthropic API integration
│   └── app_provider.dart       # State management (Provider)
├── screens/
│   ├── splash_screen.dart
│   ├── signup_screen.dart
│   ├── signin_screen.dart
│   ├── home_screen.dart
│   └── chat_screen.dart
├── widgets/
│   └── piggy_icon.dart          # Custom-painted piggy bank icon
└── utils/
    └── theme.dart
```

---

## 🚀 Setup Instructions

### Step 1 — Clone & Install Flutter

```bash
git clone <your-repo>
cd piggy_bank_app
flutter pub get
```

### Step 2 — Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project: `piggy-bank-chatbot`
3. Enable **Authentication → Email/Password**
4. Create **Firestore Database** (start in test mode, then apply `firestore.rules`)
5. Add a **Flutter app** to the project
6. Install FlutterFire CLI and run:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This auto-generates `lib/firebase_options.dart` with your real credentials.

7. For **Android**: Download `google-services.json` → place in `android/app/`
8. For **iOS**: Download `GoogleService-Info.plist` → place in `ios/Runner/`

### Step 3 — Gemini API Key

Open `lib/services/chat_service.dart` and replace:

```dart
static const String _apiKey = 'YOUR_Gemini_API_KEY';
```


### Step 4 — Deploy Firestore Rules

In Firebase Console → Firestore → Rules, paste the contents of `firestore.rules`.

### Step 5 — Run the App

```bash
flutter run
```

---

## 🗣️ How to Use PiggyBot

Just open the chat and type naturally:

| What you say | What PiggyBot does |
|---|---|
| "I spent ₹500 on groceries today" | Logs ₹500 under Groceries |
| "Bought clothes for 2000 from Zara" | Logs ₹2000 under Clothing |
| "Paid $20 for Netflix subscription" | Logs $20 under Subscriptions |
| "Spent 105 on milk" | Logs ₹105 under Groceries |
| "What have I spent this month?" | PiggyBot summarizes spending |

---

## 🏗️ Architecture

```
User types message
       ↓
ChatScreen sends to ChatService
       ↓
ChatService calls Gemini API
       ↓
Claude parses: amount, category, currency, date
       ↓
ChatService saves Expense to Firestore
       ↓
ChatService updates user savings in Firestore
       ↓
AppProvider (StreamBuilder) detects change
       ↓
HomeScreen re-renders with new data ✅
```

---

## 🔐 Sign Up Fields

| Field | Required | Notes |
|---|---|---|
| Full Name | ✅ | |
| Email | ✅ | |
| Country | ✅ | Country picker |
| Occupation | ✅ | Auto-detects unemployed/student |
| Monthly Income | ⚠️ Optional if unemployed | |
| Current Savings | ⚠️ Optional | |
| Password | ✅ | Obscured, min 6 chars |
| Re-enter Password | ✅ | Must match |

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `firebase_core`, `firebase_auth` | Authentication |
| `cloud_firestore` | Database |
| `http` | Gemini API calls |
| `provider` | State management |
| `fl_chart` | Pie charts |
| `google_fonts` | Nunito font |
| `country_picker` | Country selection |
| `intl` | Date formatting |
| `uuid` | Unique IDs |

---

## 🎨 App Icon

The app icon is a custom-painted Flutter `CustomPainter` piggy bank with:
- Pink piggy body, snout, curly tail
- Coin slot on top with a gold coin entering
- Scattered coins showing ₹, $, £, € symbols

For the launcher icon, generate a PNG from the `PiggyBankIcon` widget and place it at `assets/icons/app_icon.png`, then run:

```bash
flutter pub run flutter_launcher_icons
```

---

## 🤝 Contributing

PRs welcome! Please follow the existing code style and add comments for complex logic.

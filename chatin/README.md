# ChatIn — Flutter Mobile App 📱

Cross-platform AI chatbot mobile application built with Flutter (Dart).  
This is the main client application of the **ChatIn** ecosystem.

---

## 🌟 Overview

ChatIn mobile app menyediakan antarmuka pengguna untuk berinteraksi dengan berbagai **agen AI spesialis**. Setiap agen memiliki persona unik (Psikolog, Mentor UI/UX, Asisten Koding) dengan konteks obrolan yang terisolasi.

---

## ⚡ Tech Stack

| Package                  | Version   | Purpose                              |
| ------------------------ | --------- | ------------------------------------ |
| `flutter`                | SDK ^3.12 | Cross-platform UI framework          |
| `supabase_flutter`       | ^2.12.4   | Auth & database client               |
| `provider`               | ^6.1.5    | State management (ChangeNotifier)    |
| `google_sign_in`         | ^7.2.0    | Google authentication                |
| `http`                   | ^1.6.0    | HTTP client for API calls            |
| `sqflite`                | ^2.4.2    | SQLite local database                |
| `encrypt`                | ^5.0.3    | AES-256 chat content encryption      |
| `shared_preferences`     | ^2.2.3    | Persistent theme & settings storage  |
| `easy_localization`      | ^3.0.7    | Multi-language support (EN, ID)      |
| `gpt_markdown`           | ^1.1.7    | Markdown rendering for AI responses  |
| `flutter_dotenv`         | ^6.0.1    | Environment variable management      |
| `uuid`                   | ^4.5.3    | Unique ID generation                 |

---

## 📂 Project Structure

```
lib/
├── main.dart                          # App entry point, Supabase init, providers
├── models/
│   └── chat_message.dart              # Chat message data model
├── providers/
│   ├── auth_provider.dart             # Authentication state (Email, Google)
│   └── theme_provider.dart            # Dark/Light/System theme management
├── screens/
│   ├── home_screen.dart               # Welcome/landing screen
│   ├── login_screen.dart              # Login with Email & Google Sign-In
│   ├── register_screen.dart           # User registration
│   ├── otp_verification_screen.dart   # Email OTP verification
│   ├── dashboard_screen.dart          # Main hub: agents & recent chats
│   ├── agents_screen.dart             # Browse all available AI agents
│   ├── chat_screen.dart               # Real-time AI chat interface
│   ├── history_screen.dart            # Chat session history list
│   └── profile_screen.dart            # User profile & settings
├── services/
│   └── chat_service.dart              # HTTP calls to Next.js Chat API
├── utils/
│   └── encryption_helper.dart         # AES-256 encrypt/decrypt helper
└── widgets/
    ├── agent_card.dart                # Agent display card widget
    ├── agent_selector.dart            # Agent selection bottom sheet
    ├── chat_bubble.dart               # Chat message bubble (user/AI)
    ├── chat_input_bar.dart            # Message input field
    ├── history_chip.dart              # History session chip
    ├── screen_background.dart         # Gradient background wrapper
    ├── section_header.dart            # Section title header
    ├── social_button.dart             # Social auth button (Google/Apple)
    └── typing_indicator.dart          # AI typing animation dots
```

---

## 🔑 Key Features

- **Multi-Agent Chat** — Pilih agen AI spesialis dengan persona unik
- **Auth** — Email/Password + Google Sign-In via Supabase Auth
- **OTP Verification** — Verifikasi email menggunakan kode OTP
- **Streaming Responses** — Render balasan AI secara real-time (word-by-word)
- **Dark/Light Mode** — Tema otomatis mengikuti sistem atau manual
- **Localization** — Mendukung Bahasa Inggris & Bahasa Indonesia
- **Chat Encryption** — Enkripsi AES-256 untuk konten chat
- **Beautiful UI** — Material 3, custom widgets, animasi smooth

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>= 3.x` (Dart `>= 3.12`)
- Android Studio / Xcode
- Supabase project
- Google Cloud Console project (for Google Sign-In)

### Setup

```bash
# Navigate to the Flutter app directory
cd chatin

# Create .env file
cat > .env << EOF
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
NEXT_API_URL=http://localhost:3000/api/chat
API_SECRET_KEY=your_secret_key
ENCRYPTION_KEY=your_32_char_encryption_key
EOF

# Install dependencies
flutter pub get

# Run on Android emulator or iOS simulator
flutter run
```

### Environment Variables

| Variable           | Description                           |
| ------------------ | ------------------------------------- |
| `SUPABASE_URL`     | Supabase project URL                  |
| `SUPABASE_ANON_KEY`| Supabase anonymous/public key         |
| `NEXT_API_URL`     | Next.js Chat API endpoint             |
| `API_SECRET_KEY`   | API key for authenticating API calls  |
| `ENCRYPTION_KEY`   | 32-char key for AES-256 encryption    |

---

## 🎨 Theming

Aplikasi menggunakan **Material 3** dengan seed color `#FFD500` (kuning). Mendukung:
- Light Mode
- Dark Mode (true black `#000000`)
- System Mode (mengikuti pengaturan OS)

Preferensi tema disimpan secara persisten menggunakan `shared_preferences`.

---

## 📝 Notes

- Chat API menggunakan Next.js Dashboard sebagai proxy (API key tidak di-expose ke client)
- Semua konten chat dienkripsi dengan AES-256 sebelum dikirim/disimpan
- Lokalisasi menggunakan JSON files di `assets/translations/`

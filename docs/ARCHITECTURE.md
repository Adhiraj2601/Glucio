# Glucio — Architecture & Design

## 1. Clean, Feature-First Architecture
The project follows a pragmatic feature-first directory structure under `/app/lib`:

```
app/lib/
├── core/                   # Shared utilities, constants, theme, network client
│   ├── constants/          # Colors, strings, nutrition thresholds
│   ├── network/            # HTTP client wrappers, error handlers
│   ├── theme/              # Material 3 light/dark themes
│   └── utils/              # Conversion math (sugar grams to teaspoons & cubes)
├── data/                   # Data sources, SQLite cache, repositories
│   ├── local/              # SQLite database (sqflite) helper & DAOs
│   ├── remote/             # Supabase client, Open Food Facts API client
│   └── repositories/       # ProductRepository, FoodLogRepository, UserRepository
└── features/               # Functional modules
    ├── scan/               # Barcode scanning screen & camera permissions
    ├── product/            # Product result screen, sugar visualizer widgets
    ├── log/                # Daily tracker, servings editor, weekly chart
    ├── contribute/         # Nutrition label OCR camera, regex parser, form
    └── settings/           # Daily limit preference, medical disclaimer, about
```

## 2. State Management with Riverpod
- **Notifiers & AsyncNotifiers**: Business logic encapsulated in small, testable controllers.
- **Dependency Injection**: Repositories and external clients exposed via compile-time safe providers (`Provider`, `FutureProvider`).
- **Reactive UI**: Flutter widgets extend `ConsumerWidget` or `ConsumerStatefulWidget` to observe state with automatic rebuilds on changes.

## 3. Data Tier & Offline-First Strategy
- All fetched products are saved locally in SQLite (`sqflite`).
- Scans prioritize checking the local cache first before hitting network endpoints, guaranteeing response times under 2 seconds.
- User food logs are mirrored locally so that the daily tracker functions seamlessly without an active internet connection.

## 4. Privacy & Security
- **No unnecessary tracking**: Minimal anonymous identifiers; user logs are protected by Postgres Row Level Security (RLS).
- **Secrets Isolation**: Keys reside only in `.env` and are loaded via `flutter_dotenv`.
- **Client Security**: App uses only the Supabase `anon` public key; never the `service_role` key.

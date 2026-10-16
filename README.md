# Glucio 🍯🚫

> **An Android-first mobile app helping health-conscious Indian consumers limit sugar intake by transforming abstract nutritional grams into visual teaspoons and sugar cubes.**

---

## 🎯 The Problem

1. **Grams Are Abstract**: Nutrition labels state sugar in grams per 100 g or per arbitrary tiny serving size. Consumers cannot intuitively gauge what 24 g of sugar represents.
2. **Hidden Sugars**: Significant sugar is hidden in Indian savory staples—ketchup, namkeen, instant noodles, sliced bread, and flavored yogurts.
3. **No Indian-First Solution**: Existing scanner apps are tuned for Western diets and lack comprehensive data for Indian packaged goods.

> **Note on Barcodes**: Barcodes (EAN-13, Indian prefixes starting with `890`) store **only a numeric identifier**. They do not store nutrition information. All product metrics are retrieved via database lookup or extracted on-device via OCR.

---

## 🚀 Key Features

- **Instant Barcode Scanning**: Sub-second scan-to-result for packaged snacks and beverages.
- **Teaspoon & Sugar Cube Visualization**: $1\text{ tsp} \approx 4\text{ g}$ sugar. Visual sugar cubes give instant tangible intuition.
- **Dual Presentation**: Displays both **Per Serving** and **Whole Pack** sugar content.
- **Daily Limit Context**: Compares sugar against WHO recommended adult guideline ($25\text{ g}$ added sugar/day) with clear green / amber / red indicators.
- **Hidden Sugar Alerts**: Flags savory products containing $\ge 5\text{ g}$ sugar per $100\text{ g}$.
- **Offline First**: Scanned items and daily logs are stored locally in SQLite (`sqflite`).
- **Community Label Contribution**: Capture nutrition label photos with on-device ML Kit OCR to add unlisted products.

---

## 🛠️ Tech Stack

- **Framework**: Flutter (Dart), Android-first, null-safe, Material 3
- **State Management**: Riverpod (`flutter_riverpod`)
- **Barcode Scanner**: `mobile_scanner` (ML Kit based)
- **Label OCR**: `google_mlkit_text_recognition` (on-device)
- **Backend / Database**: Supabase (Postgres, Row Level Security, Auth, Storage)
- **External Data Fallback**: Open Food Facts API v2
- **Local Cache**: `sqflite`
- **Configuration**: `flutter_dotenv`

---

## 📁 Repository Structure

```
Glucio/
├── app/                  # Flutter application source code
│   └── lib/
│       ├── core/         # Theme, constants, math utilities, network
│       ├── data/         # SQLite cache, Supabase client, repositories
│       └── features/     # scan, product, log, contribute, settings
├── supabase/             # SQL migrations and seed scripts
├── data/                 # seed_products.csv (Indian packaged goods dataset)
├── docs/                 # SPEC.md, ARCHITECTURE.md, DECISIONS.md, TESTING.md
├── .env.example          # Template for environment secrets
└── README.md
```

---

## 🔒 Privacy & Security

- **Minimal Personal Data**: Glucio does not track advertising IDs or require personal identifiable information.
- **Client Security**: App communicates with Supabase strictly via the public `anon` key. Sensitive keys are never committed.
- **Row Level Security (RLS)**: User consumption logs and profiles are strictly restricted to their respective owners.
- **Medical Disclaimer**: Glucio provides informational content only and is not medical advice.

---

## 📱 Getting Started

### Prerequisites
- Flutter SDK (stable channel)
- Android SDK with platform-tools (`adb`)
- Physical Android phone with USB Debugging enabled

### Environment Setup
1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example app/.env
   ```
2. Populate `.env` with your Supabase credentials:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   ```
3. Connect your Android phone via USB and verify ADB detection:
   ```bash
   adb devices
   ```
4. Run the app:
   ```bash
   cd app
   flutter run
   ```

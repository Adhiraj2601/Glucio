# Glucio — Product Specification

## 1. Product Overview
**Glucio** is an Android-first mobile application built for health-conscious Indian consumers who want to limit sugar intake. The user scans the barcode (EAN-13/EAN-8/UPC) on a packaged snack, biscuit, namkeen, or beverage and instantly visualizes the sugar content in intuitive real-world units—**teaspoons** and **sugar cubes**—in addition to grams, evaluated directly against their daily limit.

### Problem Statement
- **Abstract Metric Problem**: Nutrition labels state sugar in grams per 100 g or per small serving. Most consumers cannot intuitively visualize what 18 g or 34 g of sugar looks like.
- **Serving Size Deception**: Manufacturers frequently use unrealistically small serving sizes (e.g., 15 g for a 100 g biscuit pack) to disguise high sugar amounts.
- **Hidden Sugars**: Significant sugar is hidden in savory items commonly perceived as non-sweet (ketchup, namkeen, masala crackers, sliced bread, instant noodles, flavored yogurts).
- **Indian Market Gap**: Existing global apps (e.g., MyFitnessPal, Yuka) have poor Indian packaged food coverage or lack intuitive visual translation into teaspoons/cubes.

> **Crucial Barcode Fact**: A barcode (EAN-13, with Indian products typically starting with the prefix `890`) contains **only an identification number**. It does not encode nutritional data. All nutritional information must be retrieved via database lookup or extracted via on-device OCR.

---

## 2. Core Target Audience & Use Cases
1. **Health-conscious Indian Shoppers**: Quickly scanning snacks in supermarkets (Reliance Smart, Blinkit, Zepto, local Kirana stores) to make informed purchasing choices within 2 seconds.
2. **Parents**: Monitoring hidden sugars in snacks marketed for children (cereals, juices, flavored milk, energy drinks).
3. **Individuals with Dietary Constraints**: Individuals looking to control added sugars as recommended by the World Health Organization (WHO).

---

## 3. Technology Stack

| Component | Choice | Rationale |
|---|---|---|
| **Framework** | Flutter (Dart), Android-first, Null-safe, Material 3 | Single codebase, native-quality Android rendering, expressive UI. |
| **State Management** | Riverpod (`flutter_riverpod`) | Compile-safe, testable, decoupled dependency injection and reactive state. |
| **Barcode Scanner** | `mobile_scanner` (Google ML Kit based) | High-performance, fast, hardware-accelerated scanning on camera feed. |
| **OCR Text Recognition**| `google_mlkit_text_recognition` | On-device, privacy-preserving label parsing without cloud API fees. |
| **Backend & Auth** | Supabase (Postgres, Auth, Storage) | Relational integrity, built-in Row-Level Security (RLS), simple auth. |
| **External Data Fallback** | Open Food Facts API v2 | Extensive open-source database of international and Indian products. |
| **Local Cache / Offline** | `sqflite` | Robust local SQLite database for instant offline scan resolution and food logs. |
| **Configuration** | `flutter_dotenv` | Strict separation of configuration and secrets via `.env`. |

---

## 4. Core Business & Nutrition Logic

### 4.1 Teaspoon & Sugar Cube Conversions
- **Standard Baseline**: $1\text{ teaspoon (tsp)} \approx 4\text{ grams of sugar}$.
- **Teaspoon Calculation**: $\text{Teaspoons} = \frac{\text{Sugar (g)}}{4}$, displayed rounded to 1 decimal place.
- **Sugar Cube Visual**: 1 full sugar cube icon per $4\text{ g}$. Partial cubes are rounded to the nearest quarter ($0.25, 0.50, 0.75, 1.0$).

### 4.2 Dual Presentation Rule
Every product result screen must always display both:
1. **Per Serving**: $\frac{\text{serving\_size\_g} \times \text{sugar\_per\_100g}}{100}$
2. **Whole Pack**: $\frac{\text{pack\_size\_g} \times \text{sugar\_per\_100g}}{100}$
3. Small reference text for **Per 100 g** baseline.

### 4.3 Daily Sugar Limit & Thresholds
- **Default Limit**: $25\text{ g}$ of added sugar per day (WHO recommended intake for adults).
- **Customizable**: User can adjust their personal daily target in Settings.
- **Fallback Rule**: If `added_sugar_per_100g` is `NULL`, fall back to total `sugar_per_100g` and explicitly display the label:  
  `"total sugar (added not listed)"`.
- **Percent of Daily Limit**: $\frac{\text{Sugar (g)}}{\text{Daily Limit (g)}} \times 100$.

### 4.4 Color Scale
- **Green**: $< 50\%$ of daily limit (low impact).
- **Amber**: $50\% - 100\%$ of daily limit (moderate warning).
- **Red**: $> 100\%$ of daily limit (exceeds total daily allowance).

### 4.5 Hidden Sugar Flag
A warning badge/chip is shown when:
- The product belongs to a savory category (`sauces`, `namkeen`, `bread`, `chips`, `instant noodles`, `yogurt`, `masala biscuits`).
- `sugar_per_100g >= 5.0 g`.

### 4.6 Medical Disclaimer
Displayed persistently in Settings and About screens:
> *"Glucio is not medical advice. People with diabetes or specific medical conditions should consult their healthcare provider."*

---

## 5. Database Architecture & Schema

### Tables
1. **`products`**
   - `barcode` (TEXT, Primary Key)
   - `name` (TEXT, Not Null)
   - `brand` (TEXT)
   - `category` (TEXT)
   - `pack_size_g` (NUMERIC)
   - `serving_size_g` (NUMERIC)
   - `sugar_per_100g` (NUMERIC, Not Null)
   - `added_sugar_per_100g` (NUMERIC, Nullable)
   - `ingredients_text` (TEXT)
   - `hidden_sugar_flag` (BOOLEAN, Default False)
   - `source` (TEXT: `seed` | `openfoodfacts` | `user`)
   - `verified` (BOOLEAN, Default False)
   - `label_image_url` (TEXT)
   - `created_at` (TIMESTAMPTZ, Default NOW())
   - `updated_at` (TIMESTAMPTZ, Default NOW())

2. **`food_logs`**
   - `id` (UUID, Primary Key, Default gen_random_uuid())
   - `user_id` (UUID, References auth.users(id), Not Null)
   - `barcode` (TEXT, References products(barcode), Not Null)
   - `servings` (NUMERIC, Not Null, Default 1.0)
   - `sugar_g` (NUMERIC, Not Null)
   - `logged_at` (TIMESTAMPTZ, Default NOW())

3. **`profiles`**
   - `user_id` (UUID, Primary Key, References auth.users(id))
   - `daily_limit_g` (NUMERIC, Default 25.0)

4. **`reports`**
   - `id` (UUID, Primary Key, Default gen_random_uuid())
   - `barcode` (TEXT, Not Null)
   - `user_id` (UUID, References auth.users(id))
   - `reason` (TEXT, Not Null)
   - `created_at` (TIMESTAMPTZ, Default NOW())

### Row Level Security (RLS) Policies
- `products`: Public read for all users. User inserts allowed with `verified = false`.
- `food_logs`: Select, Insert, Update, Delete restricted to `auth.uid() = user_id`.
- `profiles`: Select, Insert, Update restricted to `auth.uid() = user_id`.
- `reports`: Insert allowed for authenticated or anonymous users; select restricted to admin.

---

## 6. Lookup & Scanning Flow

```
[Barcode Scanned: EAN-13/EAN-8/UPC]
                 │
                 ▼
        [Validate Barcode Format]
                 │
                 ├── Valid ──────────┐
                 │                   ▼
                 │         [Local Cache (SQLite)]
                 │                   │
                 │         Found? ───┴─── No
                 │           │            │
                 │          Yes           ▼
                 │           │     [Supabase products]
                 │           │            │
                 │           │   Found? ──┴─── No
                 │           │     │            │
                 │           │    Yes           ▼
                 │           │     │     [Open Food Facts API v2]
                 │           │     │            │
                 │           │     │   Found? ──┴─── No
                 │           │     │     │            │
                 │           │     │    Yes           ▼
                 │           │     │     │     [Show "Product Not Found"]
                 │           │     │     │            │
                 │           │     │     │            ▼
                 │           │     │     │     [Contribute Flow via OCR]
                 │           │     │     │            │
                 │           ▼     ▼     ▼            ▼
                 └──────► [Show Product Result Screen with Teaspoons/Cubes]
```

---

## 7. Vertical Slices Roadmap

- **Slice 0**: Repo scaffolding, `.gitignore`, `.env.example`, README, docs, Flutter skeleton with fixed `applicationId = com.glucio.app`, Android permissions (`CAMERA`, `INTERNET`), clean `flutter analyze`, running on physical phone over USB.
- **Slice 1**: Barcode scan flow with `mobile_scanner`, 20 bundled Indian seed products (JSON), result screen with teaspoons, sugar cubes, % daily limit, unit tests for conversions, verified on physical phone.
- **Slice 2**: Supabase integration: SQL migration, seed script for `data/seed_products.csv` (30 rows baseline, template for 300), Supabase fetch with local SQLite caching.
- **Slice 3**: Supabase Auth (anonymous/email), "Add to today's log" with servings counter, Today dashboard with daily limit progress ring, Weekly screen with bar chart.
- **Slice 4**: Open Food Facts API v2 fallback, hidden-sugar warning flag chip, "Report wrong data" dialogue.
- **Slice 5**: Community contribution flow: label photo capture, Google ML Kit OCR text parsing with regex heuristics, pre-filled editable review form, Supabase Storage image upload, save with `verified = false`.
- **Slice 6**: Lower-sugar swap recommendations (same category, lower sugar, top 3), customizable daily limit in Settings, medical disclaimer screen.
- **Slice 7**: Hindi localization, onboarding carousel, app branding/icon polish, release APK preparation.

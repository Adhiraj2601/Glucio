# Glucio — Physical Device Testing Checklists

This document tracks all manual verification checkpoints to be executed on the physical Android phone (Samsung Galaxy M31, `RZ8N702ND4E`).

---

## Checkpoint A (After Slice 1: Barcode Scanning & Sugar Visualizer)
**Status:** Ready for Human Physical Verification 📱

### What Was Built & Verified
1. **Barcode Scanner (`MobileScanner` with Google ML Kit)**:
   - Fullscreen camera viewfinder with real-time EAN-13 scanning reticle.
   - Android runtime camera permission flow with fallback explanation dialog.
   - Torch / flashlight toggle and front/rear camera switcher.
   - Debug-only manual barcode entry sheet with 1-tap test chips.
2. **Indian Seed Catalog (`assets/seed_products.json`)**:
   - 30 popular Indian packaged snacks, biscuits, beverages, noodles, and namkeen.
   - Dual-mode lookup: Local seed memory cache first, fallback to Open Food Facts v2 API.
   - All seed items explicitly tagged with `source: "seed-unverified"` and `verified: false`.
3. **Sugar Nutrition Engine & Cube Visualizer**:
   - Teaspoons calculation: $1\text{ tsp} = 4.0\text{ g}$, rounded to 1 decimal place.
   - Isometric visual sugar cubes with fractional increments (¼, ½, ¾, 1).
   - WHO Daily Free Sugar Limit progress bar ($25\text{ g/day}$ target) with dynamic color thresholds:
     - **Green (< 50%)**: Safe / Low sugar.
     - **Amber (50% - 100%)**: Caution / Moderate sugar.
     - **Red (> 100%)**: High sugar / Exceeds recommended daily limit.
   - Dual portion toggle: **Per Serving** vs **Whole Pack**.
   - **Hidden Sugar Alert**: Automatically detects savory items (sauces, namkeen, instant noodles, chips, breads) containing $\ge 5\text{ g} / 100\text{ g}$ sugar.
4. **Product Not Found Screen**:
   - Monospace barcode display, clear empty state, and contribution placeholder for Slice 5.

---

### Step-by-Step Device Testing Checklist for Checkpoint A

Please pick up your connected Android phone (`Samsung Galaxy M31`), where Glucio is currently running, and perform the following 3 tests:

#### Test 1: Real Camera Scan — Parle-G Biscuit Pack
1. On the home screen, tap **"Launch Camera Scanner"**.
2. Point your camera at a real **Parle-G** biscuit pack's barcode (`8901063012130`).
3. **Expected Result**:
   - Viewfinder immediately locks onto the barcode and navigates to the Result Screen.
   - **Per Serving (25g)** shows **1.6 teaspoons** (6.4g sugar) with **1 solid cube + 1 ½ cube** and a **Green (26% of limit)** progress bar.
   - Tap **"Entire Pack (250g)"**: Screen switches to **15.9 teaspoons** (63.8g sugar) with **15 full cubes + 1 ¾ cube** and a **Red (255% of limit)** warning bar!

#### Test 2: Savory Item Hidden Sugar Alert — Kissan Tomato Ketchup
1. Return to the scanner or home screen.
2. Scan (or enter via debug manual entry) **Kissan Fresh Tomato Ketchup** (`8901030383454`).
3. **Expected Result**:
   - Result screen displays prominent amber/orange **"Hidden Sugar Alert"** card:
     > *"This item belongs to 'sauces', but contains 25.4g of sugar per 100g. Hidden sugars are common in savory snacks and sauces!"*
   - Per 15g serving shows **1.0 teaspoons** (3.8g sugar, 15% of daily limit).

#### Test 3: Unregistered Barcode / 404 Flow
1. Scan any non-catalog barcode or enter `8909999999999` in the debug manual sheet.
2. **Expected Result**:
   - The app opens the **"Product Not Found"** screen displaying `8909999999999`.
   - Tapping **"Scan Another Product"** brings you smoothly back to the camera viewfinder.

---

### Automated Verification Summary
- `flutter analyze`: **0 issues found**
- `flutter test`: **18/18 tests passed (100%)**
  - `sugar_calculator_test.dart`: 14 tests (teaspoons math, cube fractions, WHO limit percentages, color thresholds, savory hidden sugar heuristics)
  - `product_result_screen_test.dart`: 3 tests (Parle-G serving/pack toggle, ketchup hidden sugar banner, not found screen)
  - `widget_test.dart`: 1 test (HomeScreen smoke test)
- Device APK: Built with locked `applicationId = "com.glucio.app"`, `minSdk = 21`, deployed directly over USB.
- Screen captures saved in `docs/screenshots/`:
  - `slice1_home.png`
  - `slice1_parleg_result.png`
  - `slice1_parleg_whole_pack.png`
  - `slice1_ketchup_hidden_sugar.png`
  - `slice1_scanner_screen.png`
  - `slice1_scanner_active.png`
  - `slice1_manual_dialog.png`
  - `slice1_not_found.png`

---

## Checkpoint A2 (After Slice 1.5: Fix Data Bugs, Household Portions, Neo-Brutalist UI)
**Status:** Ready for Human Physical Verification 📱

### What Was Built & Verified in Slice 1.5
1. **Nullable Sugar & Missing-Data Safety**:
   - Fixed Maggi Rich Tomato Sauce (EAN-8 `89080443`) which previously defaulted unknown sugar to `0.0g` ("Low Sugar").
   - Unknown/missing nutrition values now strictly model as `null` everywhere (models, repository, calculator, OFF v2 mapper).
   - Missing sugar displays a neutral "Sugar data missing" card with no cubes, no misleading 0%, and an "Add or correct this product" button.
   - `0.0g` is now only accepted when explicitly declared and verified (`isVerifiedZero = true`).
2. **Mathematical Checksum & Seed Validation**:
   - Mathematical EAN-13 and EAN-8 check digit validation implemented in `validate_and_sync_seed.py` and unit-tested in `app/test/core/checksum_test.dart`.
   - Seed catalog of 30 Indian items completely validated.
3. **Household Portions UX & Sugar Multiplier**:
   - Relatable portion units: `1 tbsp`, `1 biscuit`, `1 handful`, `1 glass`, and `Whole pack` (always positioned last).
   - Servings multiplier pills: `x1`, `x2`, `x3`.
   - Plain-language teaspoon fractions: `"about ½ teaspoon"`, `"less than ¼ teaspoon"`, `"about 1½ teaspoons"`, `"No sugar"`.
4. **Neo-Brutalist Visual Design**:
   - Cream background (`#FBF7E6`), card surfaces (`#FFFDF5`), 2px solid black ink borders, and 4px zero-blur drop shadows.
   - Distinctive typography using local offline fonts: `LilitaOne` for display headlines and `SpaceMono` for numbers/labels.
   - Neo-brutalist sugar cubes with a max cap of 12 cubes plus a `+N more` badge.
5. **Debug Trace Panel (Debug Builds Only)**:
   - Diagnostic sheet on result and 404 screens displaying scanned code, detected format, and lookup trace (`local SQLite -> seed -> OFF v2`).
6. **Local SQLite "Add This Product" Flow**:
   - Allows users to add unknown barcodes or correct missing sugar offline into a local SQLite database (`user_products` table).
   - Live sentence preview updates as the user types.

---

### Step-by-Step Device Testing Checklist for Checkpoint A2

Pick up your connected Android phone (`Samsung Galaxy M31`), where Glucio is running:

#### Test 1: Maggi Tomato Sauce (EAN-8 `89080443`) Missing-Sugar Safety State
1. On the home screen, tap the quick test tile for **"Maggi Rich Tomato Sauce"** (or scan barcode `89080443`).
2. **Expected Result**:
   - The result screen loads without error.
   - Displays a neutral gray "Sugar data missing" card: *"Sugar content is not specified on this product label or database."*
   - There are **no sugar cubes**, **no false 0% bar**, and **no false "Low Sugar" badge**.
   - An **"Add or correct this product"** button is present.
3. Tap **"Add or correct this product"**:
   - The form opens pre-filled with barcode `89080443`, name `"Maggi Rich Tomato Sauce"`, and category `"sauces"`.
   - Enter `33` in the Sugar per 100g field.
   - Watch the **Live Preview** update instantly to: *"1 tbsp has about 1¼ teaspoons of sugar (20% of your daily limit)."*
   - Tap **"Save to My Glucio"**: The product saves to local SQLite and reloads the result screen with an amber 20% limit bar and 1 cube!

#### Test 2: Parle-G Household Portions & Multiplier (`8901063012134`)
1. From the home screen, tap **"Parle-G Gluco Biscuits"** (or scan `8901063012134`).
2. **Expected Result**:
   - Default portion is **1 biscuit (5g)**.
   - Sentence hero reads: *"1 biscuit has about ½ teaspoon of sugar (8% of your daily limit)."*
   - Displays 1 half-cube and a green 8% progress bar.
3. Tap the **"x2"** multiplier pill:
   - Sentence updates to: *"2 portions have about 1 teaspoon of sugar (16% of your daily limit)."*
4. Tap the **"Whole pack (250g)"** portion chip:
   - Sentence hero updates to: *"Whole pack has about 16 teaspoons of sugar (255% of your daily limit)."*
   - Cube grid displays 12 cubes and a **"+3 more"** badge (respecting the 12-cube visual cap).
   - Progress bar shows coral/red with `255% of daily limit`.

#### Test 3: Kissan Fresh Tomato Ketchup Hidden Sugar (`8901030383458`)
1. Tap the quick test tile for **"Kissan Fresh Tomato Ketchup"**.
2. **Expected Result**:
   - Displays portion chips: **1 tsp (5g)**, **1 tbsp (15g)**, **Whole pack (1000g)**.
   - Prominent **"Hidden Sugar Alert"** card appears with black border and offset shadow:
     > *"This item belongs to 'sauces', but contains 25.4g of sugar per 100g. Hidden sugars are common in savory snacks and sauces!"*

#### Test 4: Barcode Not Found & Debug Trace (`8909999999999`)
1. Tap **"Unknown Barcode (404 Test)"** from the home screen quick test tiles.
2. **Expected Result**:
   - Displays the Neo-Brutalist **"Barcode Not Found"** screen with monospace code `8909999999999`.
   - Below it, the **Debug Lookup Trace** accordion shows:
     - `Local User DB: Miss`
     - `Seed Catalog: Miss`
     - `Open Food Facts v2: Miss (HTTP 404)`
   - Tapping **"Add This Product"** opens the product creation screen.

---

### Automated Verification Summary
- `flutter analyze`: **0 issues found** (clean in 18.8s)
- `flutter test`: **39/39 tests passed (100%)**
  - `checksum_test.dart`: EAN-13 and EAN-8 checksum algorithms (valid and corrupt digits)
  - `portion_builder_test.dart`: Portions generation, unit math, category defaults, Whole pack ordering
  - `sugar_calculator_test.dart`: Nullable math, plain-language rounding, multiplier calculations, thresholds
  - `product_result_screen_test.dart`: Sentence hero, portion chips, cube cap, missing-sugar neutral state
  - `widget_test.dart`: Smoke test
- Physical Device: Running on Samsung Galaxy M31 (`RZ8N702ND4E`) over USB (`com.glucio.app`).
- Screenshots saved in `docs/screenshots/`:
  - `slice1_5_home.png`
  - `slice1_5_home_scrolled.png`
  - `slice1_5_parleg_result.png`
  - `slice1_5_parleg_whole_pack.png`
  - `slice1_5_ketchup_hidden_sugar.png`
  - `slice1_5_missing_sugar.png`
  - `slice1_5_not_found.png`
  - `slice1_5_add_product.png`
  - `slice1_5_add_product_preview.png`
  - `slice1_5_add_product_bottom.png`
  - `slice1_5_maggi_saved_result.png`


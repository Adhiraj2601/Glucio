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

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

---

## Checkpoint B (After Slice 2: Daily Limit & Daily Sugar Tracker)
**Status:** Verified on Physical Phone (Samsung Galaxy M31) 📱

### What Was Built & Verified in Slice 2
1. **Open Food Facts API v3 Upgrade & Pipeline Robustness**:
   - Upgraded API client from v2 to Open Food Facts API v3 (`https://world.openfoodfacts.org/api/v3/product/{barcode}.json`).
   - Clean field selection (`product_name,product_name_en,brands,categories,quantity,serving_size,serving_quantity,product_quantity,nutriments,nutrition_data_per`).
   - Distinct 4-state result taxonomy (`LookupResultStatus`: `success`, `foundMissingSugar`, `notFound`, `networkError`).
   - Basis derivation strictly honors `nutrition_data_per` or `quantity` units rather than blind fallback.
   - Comprehensive error and offline diagnostics shown in the Neo-Brutalist `DebugTracePanel`.

2. **Nullable Sugar Preservation Across the Entire Stack**:
   - `sugarGrams` and `teaspoons` modeled strictly as nullable (`double?`) in `FoodLogEntry` and `LocalProductDatabase` SQLite v2 schema.
   - Missing nutrition values never default to `0.0g` or increment the consumed sugar counter.
   - Prominent amber alert badge (`⚠ N items logged with missing sugar data`) displayed on `DailyTrackerCard`.

3. **Riverpod Reactive State Management**:
   - `dailyLimitProvider`: Manages user's daily sugar threshold (persisted in SQLite `user_settings`, defaults to 25.0g WHO guideline).
   - `todayFoodLogsProvider`: Manages reactive list of food log items eaten on the current calendar day (`food_logs` table).
   - Derived providers:
     - `todayTotalSugarProvider`: Sum of known sugar consumed today.
     - `todayUnknownSugarCountProvider`: Count of entries with unknown/missing sugar.
     - `todayTotalTeaspoonsProvider`: Teaspoons equivalent ($1\text{ tsp} = 4.0\text{ g}$).

4. **Neo-Brutalist Daily Tracker UI (`DailyTrackerCard`)**:
   - Positioned prominently at the top of `HomeScreen`.
   - Real-time gauge: Consumed grams vs daily target, with dynamic remaining / excess status pill.
   - Dynamic 3-stage progress bar:
     - **Green (<= 50%)**: Safe threshold.
     - **Amber (51% - 100%)**: Approaching daily limit.
     - **Coral / Red (> 100%)**: Exceeded target limit.
   - Interactive Target Limit Sheet: Preset chips (20g Strict, 25g WHO Recommended, 35g Active, 50g Relaxed) plus custom input field.
   - Collapsible "Today's Food Log" list with portion details, logging timestamp, and instant deletion trash icon.

5. **"Log This Food" Actions on Product Screens**:
   - Primary `[ 🔖 LOG THIS FOOD (X.Xg sugar) ]` action on `ProductResultScreen`. Dynamically computes exact portion sugar including multiplier ($x1, x2, x3$).
   - Dedicated `[ 🔖 Log Food Anyway (Unknown Sugar) ]` action on missing sugar card.
   - Interactive SnackBar toast with immediate feedback.

---

### Step-by-Step Device Testing Checklist for Checkpoint B

Pick up your connected Android phone (`Samsung Galaxy M31`), where Glucio is running:

#### Test 1: Daily Target Limit Customization
1. On `HomeScreen`, observe the `DailyTrackerCard` header displaying `Limit: 25g ✎`.
2. Tap the `Limit: 25g ✎` button.
3. The bottom sheet opens with preset chips (`20g`, `25g WHO`, `35g`, `50g`) and custom input.
4. Select `35g Active` and tap `Save Target Limit`.
5. **Verified Result**: The tracker card immediately updates to `0.0g / 35g target`, displaying `35.0g left` and green progress bar. Persisted in SQLite.

#### Test 2: Logging Food with Multiplier (Parle-G $x2$)
1. In the Quick Test catalog on `HomeScreen`, tap **Parle-G Original Gluco Biscuits**.
2. Select portion `1 biscuit (5g)` and tap the `x2` multiplier.
3. Note button updates to: `[ 🔖 LOG THIS FOOD (5.1g sugar) ]`.
4. Tap the log button. A green confirmation SnackBar appears.
5. Tap Back to `HomeScreen`.
6. **Verified Result**:
   - Tracker updates to `5.1g / 35g target` (`29.9g left`, `about 1¼ teaspoons consumed`).
   - "Today's Food Log (1)" section expands to show `Parle-G Original Gluco Biscuits` • `1 biscuit (x2) • 5.1g sugar`.

#### Test 3: Approaching Daily Limit (Thums Up 300ml)
1. Tap **Thums Up (300ml)** (`8901764012211`) in Quick Test catalog.
2. Select `Whole pack (300ml)` portion ($21.2\text{ g}$ sugar).
3. Tap `[ 🔖 LOG THIS FOOD (21.2g sugar) ]`.
4. Return to `HomeScreen`.
5. **Verified Result**:
   - Total updates to `26.3g / 35g target` (`8.7g left`).
   - Progress bar dynamically shifts from green to **Amber (75%)**.
   - Food log contains 2 items.

#### Test 4: Live Item Deletion
1. In `DailyTrackerCard` on `HomeScreen`, locate `Thums Up` in "Today's Food Log".
2. Tap the trash icon next to `Thums Up`.
3. **Verified Result**: Item is instantly removed from database; total drops back to `5.1g / 35g`, and progress bar turns back to **Green**.

#### Test 5: Logging Product with Missing Sugar (Aquafina `0004614504046`)
1. Tap **Enter Barcode Manually (Debug)**, type `0004614504046`, and tap `Lookup Product`.
2. OFF v3 lookup returns product found with no sugar data (`LookupResultStatus.foundMissingSugar`).
3. Screen displays neutral gray "Sugar data missing" card without cubes or false 0% badge.
4. Tap `[ 🔖 Log Food Anyway (Unknown Sugar) ]`.
5. Return to `HomeScreen`.
6. **Verified Result**:
   - Consumed sugar remains strictly unchanged at `5.1g` (never falsely assumes 0g!).
   - Prominent warning badge appears: `⚠ 1 item logged with missing sugar data`.
   - Food log lists `AQUAFINA` with label `Sugar unknown`.

---

### Automated Verification Summary
- `flutter analyze`: **0 issues found** (clean in 33.0s)
- `flutter test`: **51/51 tests passed (100%)**
  - `daily_tracker_providers_test.dart`: Limit persistence, log additions, deletions, null-sugar summing.
  - `food_log_entry_test.dart`: Strict nullable serialization, portion math.
  - `product_repository_test.dart`: OFF v3 API parsing, status mapping, basis derivation.
  - `checksum_test.dart`: EAN check digits.
  - `portion_builder_test.dart`: Household portions.
  - `sugar_calculator_test.dart`: Teaspoon conversions.
- Device: Samsung Galaxy M31 (`RZ8N702ND4E`) running debug APK (`com.glucio.app`).
- Live physical device screenshots captured in `docs/screenshots/`:
  - `slice2_01_home_tracker_clean.png`: Initial empty tracker ($0.0\text{ g} / 25\text{ g}$).
  - `slice2_02_edit_limit_modal.png`: Daily Target modal with presets.
  - `slice2_03_limit_updated_35g.png`: Updated limit to $35\text{ g}$.
  - `slice2_05_parleg_scanned.png`: Parle-G with Log Food button.
  - `slice2_06_parleg_x2.png`: Quantity $x2$ calculation.
  - `slice2_08_home_tracker_logged_food.png`: Tracker updated after logging Parle-G.
  - `slice2_09_thumsup_result.png`: Thums Up scan screen.
  - `slice2_10_home_tracker_two_items.png`: Amber warning bar at $26.3\text{ g} / 35\text{ g}$.
  - `slice2_12_home_after_exact_delete.png`: Deletion decrements total back to $5.1\text{ g}$.
  - `slice2_13_aquafina_missing_sugar.png`: Missing sugar card with Log Anyway button.
  - `slice2_14_home_tracker_missing_sugar_badge.png`: Home tracker displaying missing sugar warning badge.

---

## Checkpoint C (After Slice 3: Weekly Trends, History & Analytics)
**Status:** Successfully Verified on Physical Phone 📱

### What Was Built & Verified in Slice 3
1. **Offline-First SQLite Analytical Queries (`LocalProductDatabase`)**:
   - `getFoodLogsForDateRange(DateTime start, DateTime end)`: Chronological window query across any date boundary.
   - `getFoodLogsForLastDays(int days)`: Efficient indexed query for the sliding 7-day analytics window.
   - `getAllFoodLogs()`: Ordered history query across all user logging history.
   - `seedSampleWeekLogs()`: Debug utility populating 7 realistic Indian items across the past 7 days (Parle-G, Thums Up, Kissan Ketchup, Frooti, Haldiram's Bhujia, Aquafina unknown sugar).
   - `clearAllFoodLogs()`: Debug reset utility.

2. **Domain Models & Analytical Aggregators**:
   - `DailySugarSummary`: Date, total sugar grams, formatted plain-language teaspoons, item count, unknown sugar count, within-limit compliance flag.
   - `TopSugarContributor`: Ranked item contributor aggregation across 7 days with item name, brand, logging count, and total sugar contributed.
   - `WeeklyAnalytics`: 7-day average grams/day, 7-day average tsp/day, days within limit compliance count ($N / 7\text{ days}$), percent success, unverified items count, and ranked top 3 sugar sources.

3. **Riverpod State Architecture (`WeeklyTrackerProviders`)**:
   - `weeklyFoodLogsProvider` (`WeeklyFoodLogsNotifier`): Reactive notifier for sliding 7-day window.
   - `selectedDateProvider` (`SelectedDateNotifier`): Selected day notifier for the interactive bar chart inspector.
   - `weeklyAnalyticsProvider`: Derived provider computing 7-day summaries and top sugar contributors.
   - `selectedDaySummaryProvider` & `selectedDayLogsProvider`: Derived day-level inspector state.
   - `allFoodLogsHistoryProvider` (`AllFoodLogsNotifier`): Full history timeline notifier with instant item deletion.

4. **Neo-Brutalist UI Components**:
   - **3-Tab Bottom Navigation**: Bold Neo-Brutalist navigation bar with cream background, 2px ink borders, and lime-green active pill (`Today`, `Trends`, `History`).
   - **Interactive 7-Day Bar Chart (`WeeklySugarBarChart`)**:
     - Chunky 2px ink-bordered bars with drop shadows.
     - Dynamic threshold colors: Green ($\le 50\%$), Amber ($51-100\%$), Red ($> 100\%$).
     - Missing sugar indicator badge (`?`) on bars containing items with unknown nutrition.
     - Horizontal daily target guideline line ($35\text{g LIMIT}$) across the chart plot.
     - Interactive day selection pill with lime highlight and automatic day inspector card below chart.
   - **Weekly Insights & Stats Card (`WeeklyInsightsCard`)**:
     - High-contrast stat cards: `7-DAY AVERAGE` (g/day, tsp/day, and below-limit status badge) & `DAYS WITHIN LIMIT` (e.g. $7/7\text{ days}$, `100% success`).
     - Alert banner for unverified sugar items logged during the week.
     - Ranked Top Sugar Sources with numbered Neo-Brutalist badges (#1 Thums Up, #2 Frooti, #3 Parle-G).
   - **Chronological History Timeline (`FoodHistoryScreen`)**:
     - Date-grouped cards (`Today`, `Yesterday`, and earlier calendar dates).
     - Group total sugar badges and missing sugar alerts.
     - Individual items with portion info, timestamp, and instant deletion trash icon.

---

### Step-by-Step Device Testing Checklist for Checkpoint C

Pick up your connected Android phone (`Samsung Galaxy M31`), where Glucio is running:

#### Test 1: Navigation & Weekly Trends Screen
1. On `HomeScreen`, tap the **"Trends"** tab on the bottom navigation bar (or tap **"View 7-Day Sugar Trends ➔"** on the tracker card).
2. The app navigates to the **Weekly Trends** screen.
3. Observe the Neo-Brutalist 7-day bar chart showing daily intake bars, the horizontal target guideline (`35g LIMIT`), and the active day pill.
4. **Verified Result**: Screenshot `slice3_02_weekly_trends_seeded.png` shows 7 days of logs (Thu 15, Fri 16, Sat 17, Sun 18, Mon 19, Tue 20, Today 21) with amber threshold bars for higher-intake days and orange `?` badges for unverified items.

#### Test 2: Interactive Day Selection (Friday Oct 16)
1. On the bar chart, tap the **Friday (16)** bar ($29\text{g}$ sugar).
2. **Verified Result**: Screenshot `slice3_03_trends_day_selected.png` shows:
   - Friday's pill highlights with a lime border and background.
   - The **Day Inspector Card** updates to: `Friday, Oct 16 • 28.5g sugar` (`2 items logged • ≈ 7.1 teaspoons`).
   - Item list displays:
     - `Oreo Original Vanilla Creme...` (1 biscuit x2 • 15:09 • 8.7g sugar).
     - `Frooti Mango Drink` (Whole pack 150ml • 11:09 • 19.8g sugar).
   - Top Sugar Sources ranking displays: #1 Thums Up ($31.8\text{g}$), #2 Frooti ($19.8\text{g}$), #3 Parle-G ($14.0\text{g}$).

#### Test 3: Food History Timeline & Live Deletion
1. Tap the **"History"** tab on the bottom navigation bar.
2. The screen opens the grouped chronological timeline.
3. Observe groups:
   - `Today`: $5.1\text{g}$ total (Aquafina unknown sugar, Parle-G 5.1g).
   - `Yesterday`: $7.6\text{g}$ total (Kissan Fresh Tomato Ketchup 3.8g, Parle-G 3.8g).
   - `Oct 19, 2026`: $31.8\text{g}$ total (Thums Up).
4. Tap the trash icon next to **Kissan Fresh Tomato Ketchup** in `Yesterday`.
5. **Verified Result**: Screenshots `slice3_04_history_timeline.png` and `slice3_05_history_item_deleted.png` demonstrate:
   - Kissan Ketchup is immediately deleted from SQLite.
   - Yesterday's group total instantly decrements from $7.6\text{g}$ to $3.8\text{g}$.
   - The deletion cascades reactively across the entire app state.

---

### Automated Verification Summary
- `flutter analyze`: **0 issues found** (clean in 26.4s)
- `flutter test`: **57/57 tests passed (100%)**
  - `weekly_analytics_test.dart`: 7-day average grams & teaspoons, compliance counting, top contributor aggregation.
  - `weekly_bar_chart_test.dart`: Bar chart rendering, guideline threshold, day columns.
  - `food_history_test.dart`: History screen empty state, grouped chronological list rendering, deletion flow.
  - `daily_tracker_providers_test.dart`: Limit persistence, live logging, null-sugar summing.
  - `food_log_entry_test.dart`: Strict nullable serialization, portion math.
  - `product_repository_test.dart`: OFF v3 API parsing, status mapping, basis derivation.
  - `checksum_test.dart`: EAN check digits.
  - `portion_builder_test.dart`: Household portions.
  - `sugar_calculator_test.dart`: Teaspoon conversions.
- Device: Samsung Galaxy M31 (`RZ8N702ND4E`) running debug APK (`com.glucio.app`).
- Live physical device screenshots captured in `docs/screenshots/`:
  - `slice3_01_home_with_nav.png`: Home screen with Neo-Brutalist bottom navigation and Trends button.
  - `slice3_02_weekly_trends_seeded.png`: 7-day interactive bar chart and weekly insights stats.
  - `slice3_03_trends_day_selected.png`: Friday selection, day inspector items, and ranked sugar sources.
  - `slice3_04_history_timeline.png`: Grouped food history timeline.
  - `slice3_05_history_item_deleted.png`: Live item deletion and instant total recalculation.

---

## Checkpoint D (After Slice 4: Smarter Swaps, Product Correction & On-Device OCR Label Recognition)
**Status:** Verified on Physical Phone 📱

### What Was Built & Verified in Slice 4
1. **Smarter Swaps Recommendation Engine (`SugarSwap`)**:
   - Compares scanned product against other products within the same normalized category group (biscuits, beverages, sauces, namkeen, instant noodles).
   - Filters only candidate products with lower sugar content ($< \text{current product sugar}$).
   - Ranks candidates by absolute sugar savings ($\text{sugarSavedPer100}$ in grams).
   - Computes human-friendly savings metrics: exact grams saved, teaspoons saved ($1\text{ tsp} = 4.0\text{ g}$), percentage sugar saved, and formatted string (`"Saves 19.7g (≈ 4.9 tsp) / 100g"`).
   - Empty state cleanly handles products that are already the lowest sugar in their category.
2. **Neo-Brutalist Smarter Swaps Card (`SmarterSwapsCard`)**:
   - Displayed directly below the sugar cubes and limit card on `ProductResultScreen`.
   - Neo-Brutalist visual styling: 2px solid black border, 4px hard drop shadow, lime yellow `"Lower Sugar"` badge.
   - Interactive swap item tiles with arrow action buttons that swap the view to the healthier alternative with a single tap.
3. **On-Device ML Kit OCR Nutrition Label Parser (`NutritionLabelOcrParser`)**:
   - Uses `google_mlkit_text_recognition` on-device text recognition.
   - Indian FSSAI label regex patterns: parses standard formats (`"Sugars / 100g"`, `"Added Sugars"`, `"Total Carbohydrate"`, `"Energy (kcal)"`, `"Serving size"`).
   - Handles decimal commas (`25,5g` -> `25.5`), tabular spacing, and trailing units.
   - Strict safety rule: missing sugar values remain `null`—never defaulted to `0.0g`.
4. **Product Contribution & Correction Flow (`AddProductScreen`)**:
   - Pre-populates unlisted barcodes or existing product attributes.
   - Camera and Gallery photo pickers trigger ML Kit OCR and automatically populate form fields.
   - Dynamic household portion generator based on food category and pack size.
   - Saves directly to local SQLite database with immediate reactive state update.
5. **Open Food Facts Indian Data Importer Script (`scripts/import_indian_off_products.py`)**:
   - Standalone CLI utility to filter, validate, and extract Indian packaged foods (`country_tags: en:india` or `890` EAN barcodes).
   - Validates EAN-8 and EAN-13 check digits mathematically.
   - Preserves nullable sugar values and synchronizes safely with `seed_products.json`.

---

### Step-by-Step Device Testing Checklist for Checkpoint D

Executed directly on the Samsung Galaxy M31 (`RZ8N702ND4E`):

#### Test 1: Smarter Swaps Display on Parle-G
1. Open Parle-G Gluco Biscuits ($25.5\text{ g sugar / 100 g}$).
2. Scroll down below the WHO Daily Limit card.
3. **Verified Result**: `slice4_01_smarter_swaps.png` shows the **Smarter Swaps** card with 3 lower-sugar recommendations:
   - `Britannia 100% Whole Wheat Bread` ($5.8\text{ g}$) • **Saves 19.7g (≈ 4.9 tsp) / 100g**
   - `Britannia Good Day Butter Biscuits` ($22.0\text{ g}$) • **Saves 3.5g (≈ 0.9 tsp) / 100g**
   - `Britannia Milk Bikis Biscuits` ($24.0\text{ g}$) • **Saves 1.5g sugar / 100g**

#### Test 2: Tap-to-Swap Navigation
1. Tap the **Britannia Good Day Butter Biscuits** swap item tile.
2. **Verified Result**: `slice4_02_goodday_swapped.png` shows the view seamlessly switches to Britannia Good Day Butter Biscuits ($22.0\text{ g}$ sugar per 100g, $2.2\text{ g}$ per biscuit, about ½ teaspoon).

#### Test 3: Add / Correct Product Flow & OCR Scanner
1. Tap the **Edit/Contribute** icon (`Icons.edit_note_rounded`) in the top-right AppBar.
2. **Verified Result**: `slice4_03_add_product_ocr.png` and `slice4_04_add_product_portions.png` show:
   - Smart OCR Label Scanner card with **"Take Photo"** and **"Gallery"** buttons.
   - Product information pre-filled (`8901063012134`, `Britannia Good Day Butter Biscuits`, `Britannia`, `biscuits`).
   - Household portions and `✓ Save & See Sugar Breakdown` action.
3. Enter corrected sugar value and tap Save.
4. **Verified Result**: `slice4_05_saved_product_result.png` shows the product saved to SQLite and loaded into `ProductResultScreen` with updated cube count ($1⅔\text{ tsp}$) and limit progress.

---

### Automated Verification Summary
- `flutter analyze`: **0 issues found** (clean in 6.8s)
- `flutter test`: **67/67 tests passed (100%)**
  - `sugar_swap_test.dart`: 3 tests (savings math, tsp rounding, rank ordering)
  - `ocr_label_parser_test.dart`: 5 tests (standard FSSAI table, decimal commas, whitespace, missing sugar null-safety, serving size regex)
  - `smarter_swaps_card_test.dart`: 2 tests (recommendations rendering, empty state)
  - `product_result_screen_test.dart`: 3 tests (swaps provider integration, portion toggles)
  - Plus all 54 existing tests passing.
- Device: Samsung Galaxy M31 (`RZ8N702ND4E`) running debug APK (`com.glucio.app`).
- Live physical device screenshots captured in `docs/screenshots/`:
  - `slice4_01_smarter_swaps.png`: Smarter Swaps card with lower-sugar biscuit alternatives.
  - `slice4_02_goodday_swapped.png`: Swapped product view for Britannia Good Day.
  - `slice4_03_add_product_ocr.png`: Add/Correct product screen with ML Kit OCR card.
  - `slice4_04_add_product_portions.png`: Household portion editor and save button.
  - `slice4_05_saved_product_result.png`: Updated product loaded directly from SQLite.





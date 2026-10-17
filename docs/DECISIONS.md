# Architecture Decision Records (ADR)

## ADR-001: Mobile-First Framework Selection
- **Decision**: Use Flutter (Dart) with Material 3.
- **Rationale**: Flutter provides high-performance on-device camera integration via `mobile_scanner` and `google_mlkit_text_recognition`, single-language full-stack mobile development, and predictable UI across Android devices.

## ADR-002: Fixed Application ID
- **Decision**: Fix `applicationId` to `com.glucio.app` from Slice 0.
- **Rationale**: Preserves application data and cache across incremental development builds via `flutter run -d <device_id>` on the developer's physical Android phone, preventing unwanted uninstalls and data wipe.

## ADR-003: Sugar Measurement Baseline (4 grams per Teaspoon)
- **Decision**: Standardize 1 teaspoon $\approx$ 4.0 grams of sugar, and 1 sugar cube $\approx$ 4.0 grams of sugar.
- **Rationale**: Aligns with international nutritional standards (USDA, WHO) and makes mental math intuitive for consumers. Partial cubes are rounded to quarters ($0.25, 0.5, 0.75$).

## ADR-004: Dual Presentation (Per Serving + Whole Pack)
- **Decision**: Always show both per-serving and whole-pack sugar values.
- **Rationale**: Manufacturers exploit tiny serving sizes on multi-serve packs (e.g. 15 g serving on a 100 g biscuit pack). Consumers frequently consume the full pack, so displaying both prevents deceptive under-representation.

## ADR-005: Offline-First Caching Layer
- **Decision**: Cache all scanned and retrieved products locally in SQLite (`sqflite`).
- **Rationale**: Eliminates latency on repeated scans and enables reliable operation in low-connectivity retail store environments.

## ADR-006: Household Portions, Nullable Sugar Data, and Neo-Brutalist Design System
- **Context**: Real-world store scans on physical devices revealed that products with missing nutrition facts on Open Food Facts (such as Maggi Tomato Sauce EAN-8) were erroneously defaulting to `0.0g` ("Low Sugar"). Furthermore, grams per 100g do not communicate true intake to consumers who consume by natural measures (spoons, handfuls, glasses, biscuits).
- **Decisions**:
  1. **Strictly Nullable Sugar**: Nutrition models (`Product`, `SugarCalculator`, API mappers) treat missing sugar as `null`, never `0.0`. Zero is only valid when explicitly zero and verified or label-checked. Missing sugar renders a neutral "Sugar data missing" UI state with a one-tap contribution flow.
  2. **Household Portions Data Representation**: Modeled as `List<Portion>` with `{label, amount, basis, kind, source}` stored in a JSONB column in Supabase and SQLite `user_products`. This eliminates relational table joins, prevents N+1 query latency on mobile, and automatically inherits RLS policies from `public.products`.
  3. **Portion Ordering & Multipliers**: Portions are ordered with smallest natural units or spoons first, servings in the middle, and Whole pack last. A servings multiplier (`x1`, `x2`, `x3`) updates both hero sentence and cube count live.
  4. **Plain-Language Rounding**: Replaces technical decimal quantities with natural fractions and rounding:
     - Verified 0: "No sugar"
     - < 0.3 tsp: "less than ¼ teaspoon"
     - 0.4 - 0.65 tsp: "about ½ teaspoon"
     - 0.7 - 0.85 tsp: "about ¾ teaspoon"
     - 0.9 - 1.15 tsp: "about 1 teaspoon"
     - > 1.15 tsp: glyphs (`1½`, `2¼`, `3`)
  5. **Neo-Brutalist Design System**: Standardized on warm cream backgrounds (`#FBF7E6`), card surfaces (`#FFFDF5`), 2px solid black ink borders, 4px hard zero-blur offset shadows, bundled offline fonts (`LilitaOne` and `SpaceMono`), and high-contrast color coding for daily limit thresholds (green $\le 25\%$, amber $26-50\%$, red $> 50\%$).


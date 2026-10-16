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

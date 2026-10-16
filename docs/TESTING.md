# Glucio — Testing Strategy & Manual Checklist

## 1. Testing Strategy

### Unit Testing
- Mathematical conversions: grams $\leftrightarrow$ teaspoons, sugar cubes rounding.
- Percentage calculation against daily limit with boundary tests (zero, negative, exact limit, double limit).
- Color threshold logic (Green $< 50\%$, Amber $50\% - 100\%$, Red $> 100\%$).
- Hidden sugar rule logic across savory categories.
- OCR text regex parser against varied label formats.

### Widget Testing
- Result screen displays both per-serving and whole-pack figures correctly.
- Fallback text rendered when `added_sugar` is `NULL`.
- Warning chips correctly displayed for hidden sugars.
- Servings counter updates totals interactively.

### Physical Device Validation
Camera, barcode detection, and OCR hardware features cannot be verified via automated emulators or desktop targets alone; they require verification on the USB-connected physical Android phone.

---

## 2. On-Device Manual Checklist

| Scenario | Steps to Reproduce | Expected Behavior |
|---|---|---|
| **1. Fast Barcode Scan** | Point camera at Indian snack barcode (e.g. Parle-G, Maggi) | Recognizes barcode within $< 500\text{ ms}$, navigates to result screen. |
| **2. Low Light Scanning** | Scan barcode in dim room or shadow | Camera auto-exposure adjusts or user can toggle torch; barcode recognized. |
| **3. Camera Permission Denied** | Deny camera permission dialog | Friendly fallback screen explains why camera is needed with "Open App Settings" button. |
| **4. Offline Scans** | Toggle Airplane mode; scan previously cached product | Product loads instantly from local SQLite cache with no network errors. |
| **5. Product Not Found** | Scan an unseeded/unknown barcode | Clear "Product not found" state with "Add by photographing label" call-to-action. |
| **6. Invalid Barcode Input** | Manually input bad barcode digits | Validation error clearly indicates invalid length/checksum. |
| **7. Dual Unit Clarity** | Inspect result screen on multi-serve product | Both "Per Serving" and "Whole Pack" sugar amounts and cubes are clearly displayed. |
| **8. Servings Counter** | Increase servings from 1 to 2.5 | Grams, teaspoons, cubes, and daily percentage scale accordingly in real time. |

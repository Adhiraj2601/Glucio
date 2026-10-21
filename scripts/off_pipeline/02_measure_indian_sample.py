"""
02_measure_indian_sample.py - Measures and samples Indian products from Open Food Facts TSV export
Streams a slice of the Open Food Facts TSV dump and extracts qualifying Indian items.
"""
import urllib.request
import zlib
import json
import os
import csv
import io

CSV_GZ_URL = "https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz"

def is_valid_ean_checksum(code: str) -> bool:
    code = code.strip()
    if not code.isdigit() or len(code) not in (8, 13):
        return False
    digits = [int(c) for c in code]
    check = digits[-1]
    core = digits[:-1]
    if len(code) == 13:
        total = sum(d if i % 2 == 0 else d * 3 for i, d in enumerate(core))
    else:  # EAN-8
        total = sum(d * 3 if i % 2 == 0 else d for i, d in enumerate(core))
    computed = (10 - (total % 10)) % 10
    return computed == check

def sample_indian_products(max_bytes=10 * 1024 * 1024):  # 10 MB compressed slice
    print(f"==> Streaming {max_bytes / (1024*1024):.1f} MB slice from Open Food Facts...")
    req = urllib.request.Request(
        CSV_GZ_URL,
        headers={
            "Range": f"bytes=0-{max_bytes}",
            "User-Agent": "GlucioPipeline/1.0 (adhir@glucio.app)"
        }
    )

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            chunk = resp.read()
    except Exception as e:
        print(f"[ERROR] Failed to fetch chunk: {e}")
        return

    print(f"==> Received {len(chunk)} bytes. Decompressing streaming TSV...")
    d = zlib.decompressobj(16 + zlib.MAX_WBITS)
    try:
        text = d.decompress(chunk).decode("utf-8", errors="ignore")
    except Exception as e:
        print(f"[WARN] Decompression stopped at boundary: {e}")
        text = d.unused_data.decode("utf-8", errors="ignore")

    lines = text.split("\n")
    if len(lines) < 2:
        print("[ERROR] Insufficient lines decoded.")
        return

    headers = lines[0].strip().split("\t")
    col_idx = {col: i for i, col in enumerate(headers)}

    def get_val(row, col_name):
        idx = col_idx.get(col_name, -1)
        return row[idx].strip() if 0 <= idx < len(row) else ""

    indian_products = []
    stats = {
        "scanned_rows": 0,
        "indian_candidates": 0,
        "valid_barcode": 0,
        "with_sugar_data": 0,
        "missing_sugar_data": 0,
        "by_barcode_890": 0,
        "by_country_tag": 0,
        "by_both": 0,
    }

    # Parse rows using csv.reader to handle quotes/tabs cleanly
    reader = csv.reader(io.StringIO("\n".join(lines[1:])), delimiter="\t")
    for row in reader:
        stats["scanned_rows"] += 1
        code = get_val(row, "code")
        if not code:
            continue

        countries_tags = get_val(row, "countries_tags").lower()
        countries_en = get_val(row, "countries_en").lower()
        is_890 = code.startswith("890")
        is_india_country = "en:india" in countries_tags or "india" in countries_en

        if is_890 or is_india_country:
            stats["indian_candidates"] += 1
            is_valid_code = is_valid_ean_checksum(code)
            if is_valid_code:
                stats["valid_barcode"] += 1

            if is_890 and is_india_country:
                reason = "both"
                stats["by_both"] += 1
            elif is_890:
                reason = "barcode_890"
                stats["by_barcode_890"] += 1
            else:
                reason = "country_tag"
                stats["by_country_tag"] += 1

            raw_sugar = get_val(row, "sugars_100g")
            sugar_val = None
            if raw_sugar != "":
                try:
                    sugar_val = float(raw_sugar)
                    stats["with_sugar_data"] += 1
                except ValueError:
                    stats["missing_sugar_data"] += 1
            else:
                stats["missing_sugar_data"] += 1

            product_record = {
                "barcode": code,
                "name": get_val(row, "product_name"),
                "brand": get_val(row, "brands_en") or get_val(row, "brands_tags"),
                "category": get_val(row, "categories_en") or get_val(row, "categories_tags"),
                "quantity": get_val(row, "quantity"),
                "serving_size": get_val(row, "serving_size"),
                "sugar_per_100g": sugar_val,
                "qualification_reason": reason,
                "is_valid_checksum": is_valid_code,
                "last_modified_t": get_val(row, "last_modified_t"),
                "source": "openfoodfacts",
                "verified": False,
            }
            indian_products.append(product_record)

    print("\n" + "="*50)
    print("OPEN FOOD FACTS INDIAN SLICE MEASUREMENT")
    print("="*50)
    for k, v in stats.items():
        print(f"  {k:<24}: {v}")

    os.makedirs("data", exist_ok=True)
    out_path = os.path.join("data", "indian_products_sample.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(indian_products, f, indent=2)

    print(f"\n[SUCCESS] Wrote {len(indian_products)} sample Indian products to {out_path}")
    if indian_products:
        print(f"Sample product preview: {indian_products[0]}")

if __name__ == "__main__":
    sample_indian_products()

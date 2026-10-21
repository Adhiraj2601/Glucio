#!/usr/bin/env python3
"""
Open Food Facts Indian Product Importer & Validator for Glucio.

Fetches Indian packaged food products from Open Food Facts API v2 / search mirror,
strictly validates EAN-13/EAN-8 checksums, preserves NULL for missing sugar data,
synthesizes household portions, and merges into assets/seed_products.json.

Usage:
    python scripts/import_indian_off_products.py --count 200 --sync
    python scripts/import_indian_off_products.py --brands-only --sync
    python scripts/import_indian_off_products.py --file path/to/dump.jsonl --sync
"""

import argparse
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

USER_AGENT = "GlucioApp - Android/1.0 (contact: student-dev@glucio.app)"
API_HOST = "https://in.openfoodfacts.net"

POPULAR_INDIAN_BRANDS = [
    "amul",
    "haldiram-s",
    "haldiram",
    "britannia",
    "parle",
    "cadbury",
    "kurkure",
    "lays",
    "sunfeast",
    "dabur",
    "mtr",
    "paper-boat",
    "bikaji",
    "bikano",
    "kissan",
    "patanjali",
    "tata",
    "real",
    "frooti",
    "nestle",
    "mother-dairy",
    "maggi",
]


def validate_ean_checksum(code: str) -> bool:
    """Validates EAN-13, EAN-8, or UPC-A checksums mathematically."""
    s = str(code).strip()
    if not s.isdigit():
        return False
    if len(s) == 8:
        weights = [3, 1, 3, 1, 3, 1, 3]
        total = sum(int(s[i]) * weights[i] for i in range(7))
        check = (10 - (total % 10)) % 10
        return check == int(s[7])
    elif len(s) == 13:
        weights = [1, 3] * 6
        total = sum(int(s[i]) * weights[i] for i in range(12))
        check = (10 - (total % 10)) % 10
        return check == int(s[12])
    elif len(s) == 12:
        weights = [3, 1] * 5 + [3]
        total = sum(int(s[i]) * weights[i] for i in range(11))
        check = (10 - (total % 10)) % 10
        return check == int(s[11])
    return False


def normalize_category(categories_str: str, product_name: str = "") -> str:
    """Classifies a product into one of the supported Glucio category buckets."""
    cat = f"{categories_str} {product_name}".lower()
    if any(k in cat for k in ["biscuit", "cookie", "cracker", "wafer", "rusk"]):
        return "biscuits"
    if any(k in cat for k in ["beverage", "drink", "juice", "soda", "cola", "tea", "coffee", "lassi", "sharbat"]):
        return "beverage"
    if any(k in cat for k in ["namkeen", "bhujia", "sev", "mixture", "dal moth", "makhana", "chana", "peanuts"]):
        return "namkeen"
    if any(k in cat for k in ["noodle", "maggi", "pasta", "yippee"]):
        return "instant noodles"
    if any(k in cat for k in ["sauce", "ketchup", "chutney"]):
        return "sauces"
    if any(k in cat for k in ["chip", "crisp", "kurkure", "wafer snack", "nacho"]):
        return "chips"
    if any(k in cat for k in ["chocolate", "candy", "confectionery", "toffee", "bar"]):
        return "confectionery"
    if any(k in cat for k in ["milk", "yogurt", "curd", "dahi", "dairy", "paneer", "cheese", "butter"]):
        return "dairy"
    if any(k in cat for k in ["cereal", "oat", "muesli", "corn flake"]):
        return "cereals"
    if any(k in cat for k in ["bread", "toast", "pav", "bun", "bakery"]):
        return "bread"
    if any(k in cat for k in ["sweet", "mithai", "halwa", "laddu", "jamun", "rasgulla"]):
        return "sweets"
    return "snacks"


def build_portions(category: str, pack_size: float, serving_size: float, is_liquid: bool) -> list:
    """Builds standard household portions for Indian products."""
    unit = "ml" if is_liquid else "g"
    portions = []

    # Category default unit portion
    if category == "biscuits":
        portions.append({
            "label": "1 biscuit",
            "amount": 10.0,
            "basis": "g",
            "kind": "unit",
            "source": "estimate"
        })
    elif category == "sauces":
        portions.append({
            "label": "1 tsp",
            "amount": 5.0,
            "basis": "g",
            "kind": "spoon",
            "source": "estimate"
        })
        portions.append({
            "label": "1 tbsp",
            "amount": 15.0,
            "basis": "g",
            "kind": "spoon",
            "source": "estimate"
        })
    elif category == "beverage":
        portions.append({
            "label": "1 glass",
            "amount": 200.0,
            "basis": "ml",
            "kind": "glass",
            "source": "estimate"
        })
    elif category in ["chips", "namkeen", "snacks"]:
        portions.append({
            "label": "1 handful",
            "amount": 25.0,
            "basis": "g",
            "kind": "serving",
            "source": "estimate"
        })
    elif category == "instant noodles":
        portions.append({
            "label": "1 bowl",
            "amount": serving_size if serving_size > 0 else 70.0,
            "basis": "g",
            "kind": "serving",
            "source": "estimate"
        })
    elif category == "dairy":
        portions.append({
            "label": "1 cup",
            "amount": 100.0,
            "basis": unit,
            "kind": "serving",
            "source": "estimate"
        })
    elif category == "confectionery":
        portions.append({
            "label": "1 piece",
            "amount": 15.0,
            "basis": "g",
            "kind": "unit",
            "source": "estimate"
        })

    # Standard serving portion
    if serving_size > 0 and not any(p["amount"] == serving_size for p in portions):
        portions.append({
            "label": f"1 serving ({serving_size:g}{unit})",
            "amount": serving_size,
            "basis": unit,
            "kind": "serving",
            "source": "label"
        })

    # Whole pack is always last
    portions.append({
        "label": f"Whole pack ({pack_size:g}{unit})",
        "amount": pack_size,
        "basis": unit,
        "kind": "pack",
        "source": "label"
    })

    return portions


def parse_off_product(raw: dict) -> dict | None:
    """Maps and validates an Open Food Facts product dict into Glucio Product schema."""
    barcode = str(raw.get("code") or raw.get("barcode") or raw.get("_id") or "").strip()
    if not barcode:
        return None

    # Validate Checksum strictly
    if not validate_ean_checksum(barcode):
        return None

    name = raw.get("product_name_en") or raw.get("product_name") or raw.get("name") or ""
    name = name.strip()
    if not name or len(name) < 2:
        return None

    brand = raw.get("brands") or raw.get("brand") or ""
    brand = brand.split(",")[0].strip()
    if not brand:
        brand = "Generic"

    categories_raw = raw.get("categories") or raw.get("category") or ""
    category = normalize_category(categories_raw, name)

    nutriments = raw.get("nutriments") or {}
    sugar_raw = nutriments.get("sugars_100g") if "nutriments" in raw else raw.get("sugar_per_100g")
    sugar = None
    if sugar_raw is not None and str(sugar_raw).strip() != "":
        try:
            val = float(sugar_raw)
            if val >= 0:
                sugar = round(val, 2)
        except (ValueError, TypeError):
            sugar = None

    added_sugar_raw = nutriments.get("added-sugars_100g") if "nutriments" in raw else raw.get("added_sugar_per_100g")
    added_sugar = None
    if added_sugar_raw is not None and str(added_sugar_raw).strip() != "":
        try:
            val = float(added_sugar_raw)
            if val >= 0:
                added_sugar = round(val, 2)
        except (ValueError, TypeError):
            added_sugar = None

    is_liquid = category == "beverage" or "ml" in str(raw.get("quantity", "")).lower() or raw.get("sugar_basis") == "per_100ml"
    basis = "per_100ml" if is_liquid else "per_100g"

    # Pack and Serving size
    pack_size = 100.0
    try:
        if raw.get("pack_size_g"):
            pack_size = float(raw["pack_size_g"])
        elif raw.get("product_quantity"):
            pack_size = float(raw["product_quantity"])
        elif raw.get("quantity"):
            m = re.search(r"(\d+(?:\.\d+)?)", str(raw["quantity"]))
            if m:
                pack_size = float(m.group(1))
    except Exception:
        pack_size = 100.0

    serving_size = 30.0
    try:
        if raw.get("serving_size_g"):
            serving_size = float(raw["serving_size_g"])
        elif raw.get("serving_quantity"):
            serving_size = float(raw["serving_quantity"])
        elif raw.get("serving_size"):
            m = re.search(r"(\d+(?:\.\d+)?)", str(raw["serving_size"]))
            if m:
                serving_size = float(m.group(1))
    except Exception:
        serving_size = 30.0

    portions = build_portions(category, pack_size, serving_size, is_liquid)

    # Savory hidden sugar detection
    savory_categories = ["sauces", "instant noodles", "chips", "namkeen", "bread"]
    hidden_sugar = (category in savory_categories) and (sugar is not None and sugar >= 5.0)

    return {
        "barcode": barcode,
        "name": name,
        "brand": brand,
        "category": category,
        "pack_size_g": pack_size,
        "serving_size_g": serving_size,
        "sugar_per_100g": sugar,
        "added_sugar_per_100g": added_sugar,
        "sugar_basis": basis,
        "portions": portions,
        "hidden_sugar_flag": hidden_sugar,
        "source": "openfoodfacts-import",
        "verified": False,
    }


def fetch_page(url: str, retries: int = 2) -> list:
    """Fetches a single page of products with retry logic."""
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    for attempt in range(retries + 1):
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                return data.get("products", [])
        except Exception as e:
            if attempt == retries:
                print(f"  [Error] {url}: {e}")
                return []
            time.sleep(1.0)
    return []


def fetch_popular_brands(limit_per_brand: int = 20) -> list:
    """Fetches products for top Indian packaged food brands."""
    print(f"\n[Brand Ingestion] Querying {len(POPULAR_INDIAN_BRANDS)} iconic Indian consumer brands...")
    all_raw = []
    fields = "code,product_name,product_name_en,brands,categories,quantity,product_quantity,serving_size,serving_quantity,nutriments"

    for brand in POPULAR_INDIAN_BRANDS:
        url = (
            f"{API_HOST}/api/v2/search?"
            f"brands_tags={brand}&page_size={limit_per_brand}&fields={fields}"
        )
        products = fetch_page(url)
        print(f"  • {brand.capitalize():<15} -> {len(products)} products")
        all_raw.extend(products)
        time.sleep(0.3)  # Respect API rate limits

    return all_raw


def fetch_country_india(total_target: int = 200) -> list:
    """Fetches paginated Indian products from Open Food Facts."""
    print(f"\n[Country Ingestion] Fetching up to {total_target} Indian products across pages...")
    all_raw = []
    page = 1
    page_size = min(100, total_target)
    fields = "code,product_name,product_name_en,brands,categories,quantity,product_quantity,serving_size,serving_quantity,nutriments"

    while len(all_raw) < total_target:
        url = (
            f"{API_HOST}/api/v2/search?"
            f"countries_tags_en=india&page_size={page_size}&page={page}&fields={fields}"
        )
        prods = fetch_page(url)
        if not prods:
            print(f"  No more products returned on page {page}.")
            break
        all_raw.extend(prods)
        print(f"  • Page {page:<2} -> received {len(prods)} products (Total: {len(all_raw)})")
        if len(prods) < page_size:
            break
        page += 1
        time.sleep(0.4)

    return all_raw[:total_target]


def main():
    parser = argparse.ArgumentParser(description="Import Indian products from Open Food Facts.")
    parser.add_argument("--count", type=int, default=200, help="Target total products to fetch from country search")
    parser.add_argument("--brands-only", action="store_true", help="Fetch only popular Indian brands")
    parser.add_argument("--include-brands", action="store_true", default=True, help="Include popular Indian brands in query")
    parser.add_argument("--file", type=str, default="", help="Read from local JSON or JSONL file")
    parser.add_argument("--output", type=str, default="data/imported_indian_products.json", help="Output JSON path")
    parser.add_argument("--sync", action="store_true", help="Sync directly into app/assets/seed_products.json")
    args = parser.parse_args()

    raw_items = []
    if args.file and os.path.exists(args.file):
        print(f"Reading from file: {args.file}")
        with open(args.file, "r", encoding="utf-8") as f:
            if args.file.endswith(".jsonl"):
                for line in f:
                    if line.strip():
                        raw_items.append(json.loads(line))
            else:
                raw_items = json.load(f)
    else:
        if args.brands_only:
            raw_items = fetch_popular_brands(limit_per_brand=25)
        else:
            # Combined strategy: Popular Indian brands + General country query
            country_items = fetch_country_india(total_target=args.count)
            brand_items = fetch_popular_brands(limit_per_brand=15)
            raw_items = country_items + brand_items

    print(f"\nProcessing {len(raw_items)} raw items...")
    parsed_by_barcode = {}
    skipped_checksum = 0
    missing_sugar = 0

    for item in raw_items:
        p = parse_off_product(item)
        if p is None:
            skipped_checksum += 1
            continue
        if p["sugar_per_100g"] is None:
            missing_sugar += 1
        # Deduplicate
        parsed_by_barcode[p["barcode"]] = p

    parsed = list(parsed_by_barcode.values())

    print(f"\n==========================================")
    print(f"       OPEN FOOD FACTS IMPORT SUMMARY      ")
    print(f"==========================================")
    print(f"Raw items fetched:         {len(raw_items)}")
    print(f"Unique valid products:     {len(parsed)}")
    print(f"Skipped (checksum/no-name):{skipped_checksum}")
    print(f"Products missing sugar:    {missing_sugar} (strictly preserved as NULL)")
    
    # Category Breakdown
    cats = {}
    for p in parsed:
        cats[p["category"]] = cats.get(p["category"], 0) + 1
    print("\nCategory Distribution:")
    for c, cnt in sorted(cats.items(), key=lambda x: -x[1]):
        print(f"  • {c:<16}: {cnt}")

    os.makedirs(os.path.dirname(args.output) or ".", exist_ok=True)
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(parsed, f, indent=2, ensure_ascii=False)
    print(f"\n[Saved] Backup catalog saved to: {args.output}")

    if args.sync:
        seed_path = "app/assets/seed_products.json"
        if os.path.exists(seed_path):
            with open(seed_path, "r", encoding="utf-8") as f:
                existing = json.load(f)

            # Preserve existing seed products and their verified status
            existing_barcodes = {p["barcode"]: p for p in existing}
            initial_count = len(existing_barcodes)
            added = 0

            for p in parsed:
                b = p["barcode"]
                if b not in existing_barcodes:
                    existing_barcodes[b] = p
                    added += 1
                else:
                    existing_item = existing_barcodes[b]
                    if not any(pt["label"].lower().startswith("whole pack") for pt in existing_item.get("portions", [])):
                        existing_item["portions"] = p["portions"]

            merged = list(existing_barcodes.values())
            with open(seed_path, "w", encoding="utf-8") as f:
                json.dump(merged, f, indent=2, ensure_ascii=False)

            print(f"\n[Synced] Added {added} new Indian products into {seed_path}!")
            print(f"Total Offline Seed Catalog now: {len(merged)} products (was {initial_count}).")


if __name__ == "__main__":
    main()

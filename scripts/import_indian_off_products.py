#!/usr/bin/env python3
"""
Open Food Facts Indian Product Importer & Validator for Glucio.

Fetches Indian packaged food products from Open Food Facts API v2 / export dumps,
strictly validates EAN checksums, preserves NULL for missing sugar data,
synthesizes household portions, and merges into assets/seed_products.json.

Usage:
    python scripts/import_indian_off_products.py --sample 30 --sync
    python scripts/import_indian_off_products.py --file path/to/dump.jsonl --output data/imported.json
"""

import argparse
import json
import os
import re
import sys
import urllib.request
import urllib.parse

USER_AGENT = "Glucio - Android - Version 1.5 (Student Pair Programming - FSSAI Nutrition)"


def validate_ean_checksum(code: str) -> bool:
    """Validates EAN-13 or EAN-8 checksums."""
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
        # UPC-A
        weights = [3, 1] * 5 + [3]
        total = sum(int(s[i]) * weights[i] for i in range(11))
        check = (10 - (total % 10)) % 10
        return check == int(s[11])
    return False


def normalize_category(categories_str: str) -> str:
    """Classifies a product into one of the supported Glucio category buckets."""
    cat = (categories_str or "").lower()
    if any(k in cat for k in ["biscuit", "cookie", "cracker", "wafer"]):
        return "biscuits"
    if any(k in cat for k in ["beverage", "drink", "juice", "soda", "cola", "tea", "coffee"]):
        return "beverage"
    if any(k in cat for k in ["namkeen", "bhujia", "sev", "mixture", "dal"]):
        return "namkeen"
    if any(k in cat for k in ["noodle", "maggi", "pasta"]):
        return "instant noodles"
    if any(k in cat for k in ["sauce", "ketchup", "chutney"]):
        return "sauces"
    if any(k in cat for k in ["chip", "crisp", "kurkure", "snack"]):
        return "chips"
    if any(k in cat for k in ["chocolate", "candy", "confectionery"]):
        return "confectionery"
    if any(k in cat for k in ["milk", "yogurt", "curd", "dahi", "dairy", "paneer"]):
        return "dairy"
    if any(k in cat for k in ["cereal", "oat", "muesli", "corn flake"]):
        return "cereals"
    if any(k in cat for k in ["bread", "toast", "rusk", "bakery"]):
        return "bread"
    if any(k in cat for k in ["sweet", "mithai", "halwa", "laddu", "jamun"]):
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
    elif category in ["chips", "namkeen"]:
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
    barcode = str(raw.get("code") or raw.get("_id") or "").strip()
    if not barcode:
        return None

    # Validate Checksum
    if not validate_ean_checksum(barcode):
        return None

    name = raw.get("product_name_en") or raw.get("product_name") or ""
    name = name.strip()
    if not name:
        return None

    brand = raw.get("brands") or "Generic"
    brand = brand.split(",")[0].strip()

    categories_raw = raw.get("categories") or ""
    category = normalize_category(categories_raw)

    nutriments = raw.get("nutriments") or {}
    sugar_raw = nutriments.get("sugars_100g")
    sugar = float(sugar_raw) if sugar_raw is not None else None

    # Enforce safety rule: sugar must never be falsely defaulted to 0.0
    if sugar is not None and sugar < 0:
        sugar = 0.0

    added_sugar_raw = nutriments.get("added-sugars_100g")
    added_sugar = float(added_sugar_raw) if added_sugar_raw is not None else None

    is_liquid = category == "beverage" or "ml" in str(raw.get("quantity", "")).lower()
    basis = "per_100ml" if is_liquid else "per_100g"

    # Pack and Serving size
    pack_size = 100.0
    try:
        if raw.get("product_quantity"):
            pack_size = float(raw["product_quantity"])
        elif raw.get("quantity"):
            m = re.search(r"(\d+(?:\.\d+)?)", str(raw["quantity"]))
            if m:
                pack_size = float(m.group(1))
    except Exception:
        pack_size = 100.0

    serving_size = 30.0
    try:
        if raw.get("serving_quantity"):
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
        "verified": False
    }


def fetch_from_api(count: int = 30) -> list:
    """Fetches popular Indian products from Open Food Facts Search API v2."""
    print(f"Fetching {count} Indian products from Open Food Facts API v2...")
    url = (
        f"https://world.openfoodfacts.org/cgi/search.pl?"
        f"action=process&tagtype_0=countries&tag_contains_0=contains&tag_0=india"
        f"&page_size={count}&json=1"
        f"&fields=code,product_name,product_name_en,brands,categories,quantity,product_quantity,serving_size,serving_quantity,nutriments"
    )

    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            products = data.get("products", [])
            print(f"Received {len(products)} raw products from API.")
            return products
    except Exception as e:
        print(f"Error calling Open Food Facts API: {e}")
        return []


def main():
    parser = argparse.ArgumentParser(description="Import Indian products from Open Food Facts.")
    parser.add_argument("--sample", type=int, default=0, help="Fetch sample count from live API")
    parser.add_argument("--file", type=str, default="", help="Read from local JSON or JSONL file")
    parser.add_argument("--output", type=str, default="", help="Output JSON path")
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
    elif args.sample > 0:
        raw_items = fetch_from_api(args.sample)
    else:
        print("Nothing to do. Specify --sample <N> or --file <path>.")
        sys.exit(0)

    parsed = []
    skipped_checksum = 0
    missing_sugar = 0

    for item in raw_items:
        p = parse_off_product(item)
        if p is None:
            skipped_checksum += 1
            continue
        if p["sugar_per_100g"] is None:
            missing_sugar += 1
        parsed.append(p)

    print(f"\n--- IMPORT SUMMARY ---")
    print(f"Total processed:       {len(raw_items)}")
    print(f"Valid parsed products: {len(parsed)}")
    print(f"Skipped (checksum/bad):{skipped_checksum}")
    print(f"Products missing sugar:{missing_sugar} (strictly preserved as NULL)")

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(parsed, f, indent=2, ensure_ascii=False)
        print(f"Saved to: {args.output}")

    if args.sync:
        seed_path = "app/assets/seed_products.json"
        if os.path.exists(seed_path):
            with open(seed_path, "r", encoding="utf-8") as f:
                existing = json.load(f)
            
            existing_barcodes = {p["barcode"]: p for p in existing}
            added = 0
            for p in parsed:
                if p["barcode"] not in existing_barcodes:
                    existing_barcodes[p["barcode"]] = p
                    added += 1

            merged = list(existing_barcodes.values())
            with open(seed_path, "w", encoding="utf-8") as f:
                json.dump(merged, f, indent=2, ensure_ascii=False)
            print(f"Synced {added} new products into {seed_path} (Total catalog: {len(merged)})")


if __name__ == "__main__":
    main()

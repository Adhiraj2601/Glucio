#!/usr/bin/env python3
"""
Seed validation and sync script for Glucio.

Validates:
1. EAN-13 and EAN-8 barcode checksums.
2. Sugar values: flags rows where sugar is null or 0 outside allowed zero categories
   (plain water, unsweetened tea, zero-sugar drinks).
3. Portions column formatting: label=amount|label=amount.
4. Preserves and validates the expanded offline seed catalog (280+ products).

Syncs:
Merges data/seed_products.csv with app/assets/seed_products.json without dropping products.
"""

import csv
import json
import os
import sys

ALLOWED_ZERO_CATEGORIES = {
    'plain water', 'water', 'unsweetened tea', 'tea',
    'zero-sugar drinks', 'zero-sugar drink', 'diet beverage',
    'black coffee', 'diet soda'
}

def validate_ean13(code: str) -> bool:
    if len(code) != 13 or not code.isdigit():
        return False
    # EAN-13: Odd indices (0-based) * 1, even indices * 3
    s = sum(int(c) * (1 if i % 2 == 0 else 3) for i, c in enumerate(code[:12]))
    check = (10 - (s % 10)) % 10
    return check == int(code[12])

def validate_ean8(code: str) -> bool:
    if len(code) != 8 or not code.isdigit():
        return False
    # EAN-8: Odd indices (0-based) * 3, even indices * 1
    s = sum(int(c) * (3 if i % 2 == 0 else 1) for i, c in enumerate(code[:7]))
    check = (10 - (s % 10)) % 10
    return check == int(code[7])

def validate_barcode(code: str) -> bool:
    clean = code.strip()
    if len(clean) == 13:
        return validate_ean13(clean)
    elif len(clean) == 8:
        return validate_ean8(clean)
    return False

def calc_expected_barcode(code: str) -> str:
    clean = code.strip()
    if len(clean) == 13:
        s = sum(int(c) * (1 if i % 2 == 0 else 3) for i, c in enumerate(clean[:12]))
        check = (10 - (s % 10)) % 10
        return clean[:12] + str(check)
    elif len(clean) == 8:
        s = sum(int(c) * (3 if i % 2 == 0 else 1) for i, c in enumerate(clean[:7]))
        check = (10 - (s % 10)) % 10
        return clean[:7] + str(check)
    return clean

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    csv_path = os.path.join(root, 'data', 'seed_products.csv')
    json_path = os.path.join(root, 'app', 'assets', 'seed_products.json')

    errors = []
    csv_products = []

    if os.path.exists(csv_path):
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for idx, row in enumerate(reader, start=2):
                barcode = row.get('barcode', '').strip()
                name = row.get('name', '').strip()
                category = row.get('category', '').strip().lower()
                sugar_str = row.get('sugar_per_100g', '').strip()
                sugar_basis = row.get('sugar_basis', 'per_100g').strip()
                portions_str = row.get('portions', '').strip()

                # 1. Barcode check
                if not validate_barcode(barcode):
                    expected = calc_expected_barcode(barcode)
                    errors.append(f"CSV Row {idx} ({name}): Invalid barcode checksum '{barcode}'. Expected '{expected}'.")

                # 2. Sugar check
                sugar_val = None
                if sugar_str:
                    try:
                        sugar_val = float(sugar_str)
                    except ValueError:
                        errors.append(f"CSV Row {idx} ({name}): Invalid sugar value '{sugar_str}'.")

                if (sugar_val is None or sugar_val == 0.0) and not any(zc in category for zc in ALLOWED_ZERO_CATEGORIES):
                    if row.get('verified', 'false').lower() != 'true':
                        errors.append(f"CSV Row {idx} ({name}): Sugar is '{sugar_str}' for category '{category}' (not in allowed zero categories).")

                # 3. Portions parse
                portions_list = []
                if portions_str:
                    for part in portions_str.split('|'):
                        if '=' in part:
                            plabel, pamt = part.split('=', 1)
                            try:
                                amt = float(pamt.strip())
                                kind = 'serving'
                                lk = plabel.lower()
                                if 'tbsp' in lk or 'tsp' in lk or 'spoon' in lk:
                                    kind = 'spoon'
                                elif 'biscuit' in lk or 'piece' in lk or 'slice' in lk or 'bar' in lk:
                                    kind = 'unit'
                                elif 'handful' in lk:
                                    kind = 'handful'
                                elif 'glass' in lk or 'cup' in lk:
                                    kind = 'glass'
                                elif 'pack' in lk:
                                    kind = 'pack'

                                portions_list.append({
                                    'label': plabel.strip(),
                                    'amount': amt,
                                    'basis': 'ml' if sugar_basis == 'per_100ml' else 'g',
                                    'kind': kind,
                                    'source': 'label'
                                })
                            except ValueError:
                                errors.append(f"CSV Row {idx} ({name}): Invalid portion amount '{pamt}' in '{part}'.")

                added_sugar = None
                if row.get('added_sugar_per_100g', '').strip():
                    try:
                        added_sugar = float(row.get('added_sugar_per_100g', '').strip())
                    except ValueError:
                        pass

                csv_products.append({
                    'barcode': barcode,
                    'name': name,
                    'brand': row.get('brand', '').strip(),
                    'category': row.get('category', '').strip(),
                    'pack_size_g': float(row.get('pack_size_g', '100') or 100),
                    'serving_size_g': float(row.get('serving_size_g', '30') or 30),
                    'sugar_per_100g': sugar_val,
                    'added_sugar_per_100g': added_sugar,
                    'sugar_basis': sugar_basis,
                    'portions': portions_list,
                    'hidden_sugar_flag': row.get('hidden_sugar_flag', 'false').lower() == 'true',
                    'source': row.get('source', 'seed-unverified'),
                    'verified': row.get('verified', 'false').lower() == 'true',
                })

    # Load existing JSON products to preserve the expanded catalog
    final_products_map = {}
    if os.path.exists(json_path):
        with open(json_path, 'r', encoding='utf-8') as f:
            existing_json = json.load(f)
            for p in existing_json:
                final_products_map[p['barcode']] = p

    # Merge CSV products over existing JSON
    for p in csv_products:
        final_products_map[p['barcode']] = p

    # Comprehensive validation of all catalog products
    for barcode, p in final_products_map.items():
        if not validate_barcode(barcode):
            errors.append(f"Catalog Product '{p.get('name')}' ({barcode}): Invalid barcode checksum.")

    if errors:
        print(f"[FAIL] Found {len(errors)} validation error(s):", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        sys.exit(1)

    merged_products = list(final_products_map.values())
    os.makedirs(os.path.dirname(json_path), exist_ok=True)
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(merged_products, f, indent=2, ensure_ascii=False)

    print(f"[SUCCESS] Validated {len(merged_products)} catalog products and verified {json_path}")

if __name__ == '__main__':
    main()

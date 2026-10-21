"""
01_probe_schema.py - Open Food Facts Schema & Header Verification
Probes the official Open Food Facts CSV/TSV export header and verifies column definitions.
"""
import urllib.request
import zlib
import csv
import io

CSV_GZ_URL = "https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz"

def probe_off_tsv_header():
    print(f"==> Probing Open Food Facts TSV header from: {CSV_GZ_URL}")
    req = urllib.request.Request(
        CSV_GZ_URL,
        headers={
            "Range": "bytes=0-500000",
            "User-Agent": "GlucioDataPipeline/1.0 (adhir@glucio.app)"
        }
    )

    with urllib.request.urlopen(req, timeout=15) as resp:
        chunk = resp.read()

    print(f"==> Downloaded initial probe chunk: {len(chunk)} bytes")
    d = zlib.decompressobj(16 + zlib.MAX_WBITS)
    decompressed = d.decompress(chunk)
    text = decompressed.decode("utf-8", errors="ignore")

    lines = text.split("\n")
    if not lines:
        print("[ERROR] No lines decoded from probe chunk.")
        return

    header_cols = lines[0].strip().split("\t")
    print(f"\n[SUCCESS] Successfully probed schema. Total columns: {len(header_cols)}")
    
    # Key columns for Glucio
    target_columns = [
        "code", "product_name", "brands", "brands_tags", "categories", 
        "categories_tags", "quantity", "serving_size", "serving_quantity", 
        "sugars_100g", "added-sugars_100g", "countries", "countries_tags", 
        "last_modified_t", "image_url"
    ]

    print("\nTarget Column Verification:")
    print("-" * 50)
    for col in target_columns:
        present = col in header_cols
        status = "FOUND" if present else "MISSING"
        idx = header_cols.index(col) if present else -1
        print(f"  {col:<24} [{status}] (index {idx})")

    # Sample rows from the chunk
    reader = csv.reader(io.StringIO("\n".join(lines[:10])), delimiter="\t")
    rows = list(reader)
    print(f"\nSample Rows Decoded in Chunk: {len(rows) - 1}")
    headers = rows[0]
    code_idx = headers.index("code") if "code" in headers else 0
    name_idx = headers.index("product_name") if "product_name" in headers else 10
    sugar_idx = headers.index("sugars_100g") if "sugars_100g" in headers else 117
    for i, r in enumerate(rows[1:]):
        if len(r) > sugar_idx:
            print(f"Row {i+1} preview: code={r[code_idx]}, name={r[name_idx]}, sugar={r[sugar_idx]}")
            break

if __name__ == "__main__":
    probe_off_tsv_header()

"""
Import Shopee JSON data into PostgreSQL.

Usage:
    python import_data.py                          # import all *.json in /app/data
    python import_data.py /path/to/file.json       # import a specific file
"""

import json
import os
import sys
import glob
import time
from datetime import datetime
from decimal import Decimal, InvalidOperation
from urllib.parse import unquote, urlparse, parse_qs

import psycopg2
from psycopg2.extras import execute_values


def get_connection(max_retries=10, delay=3):
    """Connect to PostgreSQL with retry logic for Docker startup ordering."""
    dsn = {
        "host": os.getenv("DB_HOST", "localhost"),
        "port": os.getenv("DB_PORT", "5432"),
        "dbname": os.getenv("POSTGRES_DB", "shopee_db"),
        "user": os.getenv("POSTGRES_USER", "shopee_user"),
        "password": os.getenv("POSTGRES_PASSWORD", "shopee_pass_2026"),
    }
    for attempt in range(1, max_retries + 1):
        try:
            conn = psycopg2.connect(**dsn)
            conn.autocommit = False
            print(f"[OK] Connected to PostgreSQL at {dsn['host']}:{dsn['port']}/{dsn['dbname']}")
            return conn
        except psycopg2.OperationalError as e:
            print(f"[RETRY {attempt}/{max_retries}] DB not ready: {e}")
            time.sleep(delay)
    raise RuntimeError("Could not connect to PostgreSQL after retries")


def parse_decimal(value):
    if value is None:
        return None
    try:
        return Decimal(str(value))
    except (InvalidOperation, ValueError):
        return None


def parse_timestamp(value):
    if not value:
        return None
    for fmt in ("%Y-%m-%dT%H:%M:%S.%fZ", "%Y-%m-%dT%H:%M:%SZ"):
        try:
            return datetime.strptime(value, fmt)
        except ValueError:
            continue
    return None


def extract_keyword(source_url):
    """Pull the search keyword from a Shopee source URL."""
    if not source_url:
        return None
    try:
        qs = parse_qs(urlparse(source_url).query)
        raw = qs.get("keyword", [None])[0]
        return unquote(raw) if raw else None
    except Exception:
        return None


def upsert_shops(cur, items):
    shops = {}
    for item in items:
        sid = item["shopid"]
        if sid not in shops:
            shops[sid] = {
                "shop_id": sid,
                "shop_name": (item.get("shop_name") or "").strip(),
                "shop_location": item.get("shop_location") or None,
                "is_official": item.get("is_official_shop", False) or False,
            }
        elif item.get("is_official_shop"):
            shops[sid]["is_official"] = True

    rows = [(s["shop_id"], s["shop_name"], s["shop_location"], s["is_official"]) for s in shops.values()]
    execute_values(
        cur,
        """
        INSERT INTO shops (shop_id, shop_name, shop_location, is_official)
        VALUES %s
        ON CONFLICT (shop_id) DO UPDATE SET
            shop_name     = EXCLUDED.shop_name,
            shop_location = EXCLUDED.shop_location,
            is_official   = EXCLUDED.is_official OR shops.is_official,
            updated_at    = CURRENT_TIMESTAMP
        """,
        rows,
    )
    print(f"  Shops upserted: {len(rows)}")


def upsert_categories(cur, items):
    cat_ids = {item["category"] for item in items if item.get("category")}
    rows = [(cid, None, None) for cid in cat_ids]
    execute_values(
        cur,
        """
        INSERT INTO categories (category_id, category_name, parent_id)
        VALUES %s
        ON CONFLICT (category_id) DO NOTHING
        """,
        rows,
    )
    print(f"  Categories upserted: {len(rows)}")


def upsert_products(cur, items):
    seen = set()
    rows = []
    for item in items:
        pid = item["id"]
        if pid in seen:
            continue
        seen.add(pid)
        rows.append((
            item["id"],
            item["shopid"],
            item.get("category"),
            item["name"],
            item["url"],
            item.get("image"),
            parse_decimal(item.get("price")),
            parse_decimal(item.get("price_max")),
            parse_decimal(item.get("price_min")),
            parse_decimal(item.get("price_before_discount")),
            parse_decimal(item.get("original_price")),
            item.get("discount", 0) or 0,
            item.get("discount_text"),
            item.get("rating", 0) or 0,
            item.get("rating_count", 0) or 0,
            item.get("star_1_count", 0) or 0,
            item.get("star_2_count", 0) or 0,
            item.get("star_3_count", 0) or 0,
            item.get("star_4_count", 0) or 0,
            item.get("star_5_count", 0) or 0,
            item.get("sold_count", 0) or 0,
            item.get("sold_count_text"),
            item.get("monthly_sold_count", 0) or 0,
            item.get("liked_count", 0) or 0,
            item.get("colors") or None,
            item.get("sizes") or None,
            item.get("variations") or None,
            item.get("is_adult", False) or False,
            item.get("is_service_by_shopee", False) or False,
            item.get("is_shopee_choice", False) or False,
            item.get("is_on_flash_sale", False) or False,
            item.get("is_preferred_plus_seller", False) or False,
            item.get("is_lowest_price", False) or False,
            item.get("is_live_streaming_price"),
            item.get("is_mart", False) or False,
            item.get("can_use_cod", False) or False,
            item.get("can_use_wholesale", False) or False,
            item.get("has_lowest_price_guarantee", False) or False,
            item.get("show_free_shipping", False) or False,
            parse_timestamp(item.get("created_time")),
        ))

    execute_values(
        cur,
        """
        INSERT INTO products (
            product_id, shop_id, category_id, name, url, thumbnail_url,
            price, price_max, price_min, price_before_discount, original_price,
            discount, discount_text,
            rating, rating_count,
            star_1_count, star_2_count, star_3_count, star_4_count, star_5_count,
            sold_count, sold_count_text, monthly_sold_count, liked_count,
            colors, sizes, variations,
            is_adult, is_service_by_shopee, is_shopee_choice, is_on_flash_sale,
            is_preferred_plus_seller, is_lowest_price, is_live_streaming_price,
            is_mart, can_use_cod, can_use_wholesale,
            has_lowest_price_guarantee, show_free_shipping,
            shopee_created_at
        ) VALUES %s
        ON CONFLICT (product_id) DO UPDATE SET
            name                    = EXCLUDED.name,
            price                   = EXCLUDED.price,
            price_max               = EXCLUDED.price_max,
            price_min               = EXCLUDED.price_min,
            discount                = EXCLUDED.discount,
            discount_text           = EXCLUDED.discount_text,
            rating                  = EXCLUDED.rating,
            rating_count            = EXCLUDED.rating_count,
            star_1_count            = EXCLUDED.star_1_count,
            star_2_count            = EXCLUDED.star_2_count,
            star_3_count            = EXCLUDED.star_3_count,
            star_4_count            = EXCLUDED.star_4_count,
            star_5_count            = EXCLUDED.star_5_count,
            sold_count              = EXCLUDED.sold_count,
            sold_count_text         = EXCLUDED.sold_count_text,
            monthly_sold_count      = EXCLUDED.monthly_sold_count,
            liked_count             = EXCLUDED.liked_count,
            is_on_flash_sale        = EXCLUDED.is_on_flash_sale,
            is_lowest_price         = EXCLUDED.is_lowest_price,
            updated_at              = CURRENT_TIMESTAMP
        """,
        rows,
    )
    print(f"  Products upserted: {len(rows)}")


def insert_images(cur, items):
    cur.execute("CREATE TEMP TABLE _seen_img (product_id BIGINT) ON COMMIT DROP")
    existing = set()
    product_ids = [item["id"] for item in items]
    for pid in product_ids:
        cur.execute("SELECT 1 FROM product_images WHERE product_id = %s LIMIT 1", (pid,))
        if cur.fetchone():
            existing.add(pid)

    product_rows = []
    variation_rows = []

    for item in items:
        pid = item["id"]
        if pid in existing:
            continue

        raw_images = item.get("images") or ""
        for order, url in enumerate(raw_images.split("\n")):
            url = url.strip()
            if url:
                product_rows.append((pid, url, "product", order))

        raw_var_images = item.get("variations_images") or ""
        for order, url in enumerate(raw_var_images.split("\n")):
            url = url.strip()
            if url:
                variation_rows.append((pid, url, "variation", order))

    all_rows = product_rows + variation_rows
    if all_rows:
        execute_values(
            cur,
            "INSERT INTO product_images (product_id, image_url, image_type, display_order) VALUES %s",
            all_rows,
        )
    print(f"  Images inserted: {len(product_rows)} product + {len(variation_rows)} variation")


def insert_extraction(cur, items, file_name):
    if not items:
        return None
    first = items[0]
    source_url = first.get("source_url", "")
    keyword = extract_keyword(source_url)
    extracted_at = parse_timestamp(first.get("extracted_at")) or datetime.utcnow()

    cur.execute(
        """
        INSERT INTO search_extractions (source_url, keyword, extracted_at, total_items, file_name)
        VALUES (%s, %s, %s, %s, %s)
        RETURNING id
        """,
        (source_url, keyword, extracted_at, len(items), file_name),
    )
    extraction_id = cur.fetchone()[0]

    rows = [(extraction_id, item["id"], idx) for idx, item in enumerate(items)]
    execute_values(
        cur,
        "INSERT INTO extraction_products (extraction_id, product_id, position) VALUES %s ON CONFLICT DO NOTHING",
        rows,
    )
    print(f"  Extraction #{extraction_id} created: keyword='{keyword}', {len(items)} products")
    return extraction_id


def import_file(conn, filepath):
    filename = os.path.basename(filepath)
    print(f"\n{'='*60}")
    print(f"Importing: {filename}")
    print(f"{'='*60}")

    with open(filepath, "r", encoding="utf-8") as f:
        items = json.load(f)

    if not isinstance(items, list) or not items:
        print(f"  [SKIP] File is empty or not a JSON array")
        return

    print(f"  Items in file: {len(items)}")

    cur = conn.cursor()
    try:
        upsert_categories(cur, items)
        upsert_shops(cur, items)
        upsert_products(cur, items)
        insert_images(cur, items)
        insert_extraction(cur, items, filename)
        conn.commit()
        print(f"  [DONE] Successfully imported {filename}")
    except Exception as e:
        conn.rollback()
        print(f"  [ERROR] {e}")
        raise
    finally:
        cur.close()


def main():
    if len(sys.argv) > 1:
        files = sys.argv[1:]
    else:
        data_dir = os.getenv("DATA_DIR", "/app/data")
        files = sorted(glob.glob(os.path.join(data_dir, "*.json")))

    if not files:
        print("[WARN] No JSON files found. Put *.json files in the data/ folder.")
        return

    print(f"Found {len(files)} JSON file(s) to import")

    conn = get_connection()
    try:
        for filepath in files:
            import_file(conn, filepath)
    finally:
        conn.close()
        print("\n[DONE] All imports finished.")


if __name__ == "__main__":
    main()

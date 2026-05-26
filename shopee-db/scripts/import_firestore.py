"""
Import Shopee JSON data into Firebase Firestore.

Usage:
    python import_firestore.py <json_file> <service_account_key>

Example:
    python import_firestore.py ../data/SHOPEE_xxx.json ../prm-shopee-be-firebase-adminsdk-xxx.json
"""

import json
import sys
import os
from datetime import datetime
from decimal import Decimal

import firebase_admin
from firebase_admin import credentials, firestore


def parse_timestamp(value):
    if not value:
        return None
    for fmt in ("%Y-%m-%dT%H:%M:%S.%fZ", "%Y-%m-%dT%H:%M:%SZ"):
        try:
            return datetime.strptime(value, fmt)
        except ValueError:
            continue
    return None


def parse_price(value):
    if value is None:
        return None
    try:
        return float(value)
    except (ValueError, TypeError):
        return None


def build_shop(item):
    return {
        "shop_id": item["shopid"],
        "shop_name": (item.get("shop_name") or "").strip(),
        "shop_location": item.get("shop_location") or None,
        "is_official": item.get("is_official_shop", False) or False,
    }


def build_product(item):
    images = [url.strip() for url in (item.get("images") or "").split("\n") if url.strip()]
    var_images = [url.strip() for url in (item.get("variations_images") or "").split("\n") if url.strip()]

    return {
        "product_id": item["id"],
        "shop_id": item["shopid"],
        "category_id": item.get("category"),
        "name": item["name"],
        "url": item["url"],
        "thumbnail_url": item.get("image"),
        "images": images,
        "variations_images": var_images,

        "price": parse_price(item.get("price")),
        "price_max": parse_price(item.get("price_max")),
        "price_min": parse_price(item.get("price_min")),
        "price_before_discount": parse_price(item.get("price_before_discount")),
        "original_price": parse_price(item.get("original_price")),
        "discount": item.get("discount", 0) or 0,
        "discount_text": item.get("discount_text"),

        "rating": item.get("rating", 0) or 0,
        "rating_count": item.get("rating_count", 0) or 0,
        "star_1_count": item.get("star_1_count", 0) or 0,
        "star_2_count": item.get("star_2_count", 0) or 0,
        "star_3_count": item.get("star_3_count", 0) or 0,
        "star_4_count": item.get("star_4_count", 0) or 0,
        "star_5_count": item.get("star_5_count", 0) or 0,

        "sold_count": item.get("sold_count", 0) or 0,
        "sold_count_text": item.get("sold_count_text"),
        "monthly_sold_count": item.get("monthly_sold_count", 0) or 0,
        "liked_count": item.get("liked_count", 0) or 0,

        "colors": item.get("colors") or None,
        "sizes": item.get("sizes") or None,
        "variations": item.get("variations") or None,

        "is_adult": item.get("is_adult", False) or False,
        "is_service_by_shopee": item.get("is_service_by_shopee", False) or False,
        "is_shopee_choice": item.get("is_shopee_choice", False) or False,
        "is_on_flash_sale": item.get("is_on_flash_sale", False) or False,
        "is_official_shop": item.get("is_official_shop", False) or False,
        "is_preferred_plus_seller": item.get("is_preferred_plus_seller", False) or False,
        "is_lowest_price": item.get("is_lowest_price", False) or False,
        "is_live_streaming_price": item.get("is_live_streaming_price"),
        "is_mart": item.get("is_mart", False) or False,
        "can_use_cod": item.get("can_use_cod", False) or False,
        "can_use_wholesale": item.get("can_use_wholesale", False) or False,
        "has_lowest_price_guarantee": item.get("has_lowest_price_guarantee", False) or False,
        "show_free_shipping": item.get("show_free_shipping", False) or False,

        "shopee_created_at": parse_timestamp(item.get("created_time")),
        "source_url": item.get("source_url"),
        "extracted_at": parse_timestamp(item.get("extracted_at")),
    }


def main():
    if len(sys.argv) < 3:
        print("Usage: python import_firestore.py <json_file> <service_account_key>")
        sys.exit(1)

    json_file = sys.argv[1]
    key_file = sys.argv[2]

    # Init Firebase
    cred = credentials.Certificate(key_file)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("[OK] Connected to Firestore")

    # Load JSON
    with open(json_file, "r", encoding="utf-8") as f:
        items = json.load(f)
    print(f"Loaded {len(items)} items from {os.path.basename(json_file)}")

    # --- Import Shops ---
    shops_ref = db.collection("shops")
    seen_shops = set()
    shop_count = 0
    for item in items:
        sid = str(item["shopid"])
        if sid in seen_shops:
            continue
        seen_shops.add(sid)
        shops_ref.document(sid).set(build_shop(item), merge=True)
        shop_count += 1
    print(f"  Shops: {shop_count}")

    # --- Import Categories ---
    cats_ref = db.collection("categories")
    seen_cats = set()
    cat_count = 0
    for item in items:
        cid = str(item["category"])
        if cid in seen_cats:
            continue
        seen_cats.add(cid)
        cats_ref.document(cid).set({"category_id": item["category"], "category_name": None}, merge=True)
        cat_count += 1
    print(f"  Categories: {cat_count}")

    # --- Import Products ---
    products_ref = db.collection("products")
    seen_products = set()
    product_count = 0
    for item in items:
        pid = str(item["id"])
        if pid in seen_products:
            continue
        seen_products.add(pid)
        products_ref.document(pid).set(build_product(item), merge=True)
        product_count += 1
    print(f"  Products: {product_count}")

    print(f"\n[DONE] Imported to Firestore: {shop_count} shops, {cat_count} categories, {product_count} products")


if __name__ == "__main__":
    main()

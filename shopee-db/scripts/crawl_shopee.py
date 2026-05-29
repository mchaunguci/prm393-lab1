#!/usr/bin/env python3
"""
Crawl sản phẩm Shopee VN qua API nội bộ (cần cookie từ browser đã login).

Usage:
    # 1. Copy Cookie từ DevTools (tab Network → request shopee.vn → Request Headers → Cookie)
    #    Lưu vào file cookies.txt hoặc biến SHOPEE_COOKIE trong .env

    python crawl_shopee.py --keyword "rtx5090" --limit 60
    python crawl_shopee.py --keyword "rtx5090" --limit 60 --with-details
    python crawl_shopee.py --keyword "gpu" --limit 30 --cookie-file ../cookies.txt

Output: ../data/SHOPEE_<uuid>_<count>.json  (cùng format file JSON hiện có)
Sau đó: python import_firestore.py ../data/SHOPEE_xxx.json <service_account.json>
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import quote, urlencode

import requests

BASE_URL = "https://shopee.vn"
SEARCH_API = f"{BASE_URL}/api/v4/search/search_items"
PDP_API = f"{BASE_URL}/api/v4/pdp/get_pc"
IMAGE_CDN = "https://down-sg.img.susercontent.com/file"


def load_cookie_file(cookie_file: Path | None = None) -> str:
    if cookie_file and cookie_file.exists():
        return cookie_file.read_text(encoding="utf-8").strip()
    env_cookie = os.getenv("SHOPEE_COOKIE", "").strip()
    if env_cookie:
        return env_cookie
    default = Path(__file__).resolve().parent.parent / "cookies.txt"
    if default.exists():
        return default.read_text(encoding="utf-8").strip()
    raise FileNotFoundError(
        "Thiếu cookie. Lưu Cookie từ Chrome vào shopee-db/cookies.txt"
    )


def load_cookie(args: argparse.Namespace) -> str:
    if args.cookie:
        return args.cookie.strip()
    if args.cookie_file:
        return Path(args.cookie_file).read_text(encoding="utf-8").strip()
    return load_cookie_file()


def build_session(cookie: str) -> requests.Session:
    session = requests.Session()
    csrf = ""
    for part in cookie.split(";"):
        part = part.strip()
        if part.startswith("csrftoken="):
            csrf = part.split("=", 1)[1]
            break

    headers = {
        "User-Agent": (
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
            "(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
        ),
        "Accept": "application/json",
        "Accept-Language": "vi-VN,vi;q=0.9,en;q=0.8",
        "x-api-source": "pc",
        "x-requested-with": "XMLHttpRequest",
        "x-shopee-language": "vi",
        "af-ac-enc-dat": "null",
        "Cookie": cookie,
    }
    if csrf:
        headers["x-csrftoken"] = csrf
    session.headers.update(headers)
    return session


def price_to_str(raw: int | float | None) -> str:
    if raw is None:
        return "0.00"
    return f"{float(raw) / 100_000:.2f}"


def image_url(key: str | None) -> str | None:
    if not key:
        return None
    return f"{IMAGE_CDN}/{key}"


def _images_field(basic: dict[str, Any]) -> str:
    keys = basic.get("images") or []
    if isinstance(keys, list) and keys:
        urls = [image_url(k) for k in keys if k]
        urls = [u for u in urls if u]
        if urls:
            return "\n".join(urls)
    return image_url(basic.get("image")) or ""


def cookie_header_to_playwright(cookie: str) -> list[dict[str, Any]]:
    parsed: list[dict[str, Any]] = []
    for part in cookie.split(";"):
        part = part.strip()
        if not part or "=" not in part:
            continue
        name, value = part.split("=", 1)
        parsed.append(
            {
                "name": name.strip(),
                "value": value.strip(),
                "domain": ".shopee.vn",
                "path": "/",
                "secure": True,
            }
        )
    return parsed


def fetch_search_playwright(keyword: str, limit: int = 60) -> dict[str, Any]:
    """Gọi Shopee search API trong browser (tránh anti-bot 90309999)."""
    try:
        from playwright.sync_api import sync_playwright
    except ImportError as e:
        raise RuntimeError("Cài playwright: pip install playwright && playwright install chromium") from e

    cookie = load_cookie_file()
    fetch_limit = min(max(limit, 1), 60)

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            user_agent=(
                "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
                "(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
            ),
        )
        context.add_cookies(cookie_header_to_playwright(cookie))
        page = context.new_page()
        page.goto(f"{BASE_URL}/search?{urlencode({'keyword': keyword})}", wait_until="domcontentloaded")
        page.wait_for_timeout(2500)
        payload = page.evaluate(
            """async ({ keyword, limit }) => {
                const params = new URLSearchParams({
                    by: 'relevancy',
                    keyword,
                    limit: String(limit),
                    newest: '0',
                    order: 'desc',
                    page_type: 'search',
                    scenario: 'PAGE_GLOBAL_SEARCH',
                    version: '2',
                });
                const res = await fetch(`/api/v4/search/search_items?${params}`);
                return await res.json();
            }""",
            {"keyword": keyword, "limit": fetch_limit},
        )
        browser.close()

    if payload.get("error"):
        raise RuntimeError(
            f"Shopee API error {payload.get('error')}. Cookie hết hạn — copy lại từ Chrome."
        )
    return payload


def search_products_live(keyword: str, limit: int = 60) -> list[dict[str, Any]]:
    payload = fetch_search_playwright(keyword, limit)
    return convert_api_response(payload, keyword, limit)


def slugify(name: str) -> str:
    slug = re.sub(r"[^\w\s-]", "", name, flags=re.UNICODE)
    slug = re.sub(r"[\s_]+", "-", slug.strip())
    return slug[:80] or "product"


def product_url(name: str, shop_id: int, item_id: int) -> str:
    return f"{BASE_URL}/{slugify(name)}-i.{shop_id}.{item_id}"


def unix_to_iso(ts: int | None) -> str | None:
    if not ts:
        return None
    return datetime.fromtimestamp(ts, tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z")


def rating_counts(item_rating: dict[str, Any] | None) -> dict[str, int]:
    counts = (item_rating or {}).get("rating_count") or [0, 0, 0, 0, 0, 0]
    while len(counts) < 6:
        counts.append(0)
    return {
        "rating_count": int(counts[0] or 0),
        "star_1_count": int(counts[1] or 0),
        "star_2_count": int(counts[2] or 0),
        "star_3_count": int(counts[3] or 0),
        "star_4_count": int(counts[4] or 0),
        "star_5_count": int(counts[5] or 0),
    }


def map_search_item(item: dict[str, Any], source_url: str, extracted_at: str) -> dict[str, Any]:
    basic = item.get("item_basic") or item
    shop_id = int(item.get("shopid") or basic.get("shopid") or 0)
    item_id = int(item.get("itemid") or basic.get("itemid") or 0)
    name = basic.get("name") or ""
    item_rating = basic.get("item_rating") or {}
    stars = rating_counts(item_rating)
    sold = int(basic.get("sold") or 0)
    historical = int(basic.get("historical_sold") or sold)

    return {
        "id": item_id,
        "category": basic.get("catid"),
        "url": product_url(name, shop_id, item_id),
        "name": name,
        "price": price_to_str(basic.get("price")),
        "price_max": price_to_str(basic.get("price_max") or basic.get("price")),
        "price_min": price_to_str(basic.get("price_min") or basic.get("price")),
        "price_before_discount": price_to_str(
            basic.get("price_before_discount") or basic.get("price")
        ),
        "original_price": price_to_str(basic.get("price_before_discount") or basic.get("price")),
        "discount": _parse_discount(basic.get("discount") or basic.get("raw_discount") or 0),
        "discount_text": basic.get("discount") if isinstance(basic.get("discount"), str) else None,
        "image": image_url(basic.get("image")),
        "images": _images_field(basic),
        "shopid": shop_id,
        "shop_name": basic.get("shop_name") or item.get("shop_name") or "",
        "shop_location": basic.get("shop_location") or "",
        "rating": float(item_rating.get("rating_star") or 0),
        **stars,
        "sold_count": historical,
        "sold_count_text": str(historical),
        "monthly_sold_count": sold,
        "liked_count": int(basic.get("liked_count") or 0),
        "colors": "",
        "sizes": "",
        "variations": "",
        "variations_images": "",
        "is_adult": bool(basic.get("is_adult")),
        "is_service_by_shopee": bool(basic.get("is_service_by_shopee")),
        "is_shopee_choice": bool(basic.get("is_shopee_choice")),
        "is_on_flash_sale": bool(basic.get("is_on_flash_sale")),
        "is_official_shop": bool(basic.get("is_official_shop") or basic.get("show_official_shop_label")),
        "is_preferred_plus_seller": bool(basic.get("is_preferred_plus_seller")),
        "is_lowest_price": bool(basic.get("is_lowest_price") or basic.get("has_lowest_price_guarantee")),
        "is_live_streaming_price": basic.get("is_live_streaming_price"),
        "is_mart": bool(basic.get("is_mart")),
        "can_use_cod": bool(basic.get("can_use_cod", True)),
        "can_use_wholesale": bool(basic.get("can_use_wholesale")),
        "has_lowest_price_guarantee": bool(basic.get("has_lowest_price_guarantee")),
        "show_free_shipping": bool(basic.get("show_free_shipping")),
        "created_time": unix_to_iso(basic.get("ctime")),
        "source_url": source_url,
        "extracted_at": extracted_at,
    }


def _parse_discount(value: Any) -> int:
    if isinstance(value, int):
        return value
    if isinstance(value, str) and value.endswith("%"):
        try:
            return int(value.rstrip("%"))
        except ValueError:
            return 0
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


def fetch_search_page(
    session: requests.Session,
    keyword: str,
    limit: int,
    offset: int,
) -> dict[str, Any]:
    params = {
        "by": "relevancy",
        "keyword": keyword,
        "limit": limit,
        "newest": offset,
        "order": "desc",
        "page_type": "search",
        "scenario": "PAGE_GLOBAL_SEARCH",
        "version": "2",
    }
    source_url = f"{BASE_URL}/search?{urlencode({'keyword': keyword})}"
    session.headers["Referer"] = source_url
    resp = session.get(SEARCH_API, params=params, timeout=30)
    resp.raise_for_status()
    data = resp.json()
    if data.get("error"):
        raise RuntimeError(
            f"Shopee API error {data.get('error')}: {data.get('tracking_id', '')}. "
            "Cookie có thể hết hạn hoặc bị chặn — copy lại Cookie từ browser."
        )
    return data


def enrich_with_pdp(session: requests.Session, product: dict[str, Any]) -> dict[str, Any]:
    params = {"shop_id": product["shopid"], "item_id": product["id"]}
    session.headers["Referer"] = product["url"]
    resp = session.get(PDP_API, params=params, timeout=30)
    if resp.status_code != 200:
        return product
    payload = resp.json()
    if payload.get("error"):
        return product

    item = (payload.get("data") or {}).get("item") or {}
    images = [
        image_url(img.get("image") if isinstance(img, dict) else img)
        for img in (item.get("images") or [])
    ]
    images = [u for u in images if u]
    if images:
        product["images"] = "\n".join(images)
        product["image"] = images[0]

    tier_variations = item.get("tier_variations") or []
    if tier_variations:
        options = []
        for tier in tier_variations:
            name = tier.get("name") or "Option"
            vals = ", ".join(tier.get("options") or [])
            if vals:
                options.append(f"{name}: {vals}")
        product["variations"] = ", ".join(options)

    models = item.get("models") or []
    var_images = []
    for model in models:
        key = model.get("extinfo", {}).get("image") if isinstance(model.get("extinfo"), dict) else None
        url = image_url(key)
        if url:
            var_images.append(url)
    if var_images:
        product["variations_images"] = "\n".join(var_images)

    shop_det = (payload.get("data") or {}).get("shop_detailed") or {}
    if shop_det.get("name"):
        product["shop_name"] = shop_det["name"]
    if shop_det.get("shop_location"):
        product["shop_location"] = shop_det["shop_location"]

    return product


def crawl(
    session: requests.Session,
    keyword: str,
    limit: int,
    with_details: bool,
    delay: float,
) -> list[dict[str, Any]]:
    extracted_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"
    source_url = f"{BASE_URL}/search?{urlencode({'keyword': keyword})}"
    products: list[dict[str, Any]] = []
    offset = 0
    page_size = min(60, limit)

    while len(products) < limit:
        batch_limit = min(page_size, limit - len(products))
        data = fetch_search_page(session, keyword, batch_limit, offset)
        items = data.get("items") or []
        if not items:
            break

        for raw in items:
            product = map_search_item(raw, source_url, extracted_at)
            if with_details:
                time.sleep(delay)
                product = enrich_with_pdp(session, product)
            products.append(product)
            if len(products) >= limit:
                break

        if len(items) < batch_limit:
            break
        offset += batch_limit
        time.sleep(delay)

    return products


def convert_api_response(
    payload: dict[str, Any],
    keyword: str,
    limit: int,
) -> list[dict[str, Any]]:
    extracted_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"
    source_url = f"{BASE_URL}/search?{urlencode({'keyword': keyword})}"
    items = payload.get("items") or []
    return [
        map_search_item(raw, source_url, extracted_at)
        for raw in items[:limit]
    ]


def main() -> None:
    parser = argparse.ArgumentParser(description="Crawl Shopee VN search → JSON")
    parser.add_argument("--keyword", help='Từ khóa, vd: "rtx5090"')
    parser.add_argument(
        "--from-response",
        help="File JSON copy từ DevTools → search_items → Response (khi Python bị chặn)",
    )
    parser.add_argument("--limit", type=int, default=60, help="Số sản phẩm (mặc định 60)")
    parser.add_argument("--with-details", action="store_true", help="Gọi thêm API chi tiết SP (ảnh, variations)")
    parser.add_argument("--delay", type=float, default=0.8, help="Delay giữa các request (giây)")
    parser.add_argument("--cookie", help="Cookie header copy từ browser")
    parser.add_argument("--cookie-file", help="File chứa cookie")
    parser.add_argument(
        "--output-dir",
        default=str(Path(__file__).resolve().parent.parent / "data"),
        help="Thư mục output JSON",
    )
    args = parser.parse_args()

    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    file_id = str(uuid.uuid4())

    if args.from_response:
        if not args.keyword:
            raise SystemExit("--keyword bắt buộc khi dùng --from-response")
        payload = json.loads(Path(args.from_response).read_text(encoding="utf-8"))
        products = convert_api_response(payload, args.keyword, args.limit)
        if not products:
            raise SystemExit("Response không có items. Kiểm tra file JSON.")
    else:
        if not args.keyword:
            raise SystemExit("--keyword bắt buộc")
        cookie = load_cookie(args)
        session = build_session(cookie)
        print(f'Đang crawl keyword="{args.keyword}" limit={args.limit} ...')
        try:
            products = crawl(session, args.keyword, args.limit, args.with_details, args.delay)
        except RuntimeError as e:
            raise SystemExit(
                f"{e}\n\n"
                "Shopee thường chặn request từ Python (90309999).\n"
                "Dùng cách browser:\n"
                "  1. DevTools → search_items → tab Response → save JSON\n"
                '  2. python crawl_shopee.py --from-response raw.json --keyword "rtx5090"'
            ) from e
        if not products:
            raise SystemExit("Không lấy được sản phẩm nào. Kiểm tra cookie hoặc keyword.")

    out_path = out_dir / f"SHOPEE_{file_id}_{len(products)}.json"
    out_path.write_text(json.dumps(products, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"✓ Đã lưu {len(products)} sản phẩm → {out_path}")
    print(f"  Import Firestore: python import_firestore.py {out_path} <service_account.json>")


if __name__ == "__main__":
    main()

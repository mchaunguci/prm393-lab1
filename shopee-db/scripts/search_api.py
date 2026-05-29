#!/usr/bin/env python3
"""
API local cho Flutter app — wrap crawl Shopee bằng Playwright.

Chạy:
    cd shopee-db/scripts
    ./setup_venv.sh          # cài vào pydeps/ (ổ DATA, tránh / đầy)
    ./start_api.sh           # hoặc: python3 search_api.py

Flutter gọi: GET http://127.0.0.1:8765/api/search?keyword=rtx5090&limit=60
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

_SCRIPT_DIR = Path(__file__).resolve().parent
_PROJECT_ROOT = _SCRIPT_DIR.parent.parent
_PYDEPS = _SCRIPT_DIR / "pydeps"

if _PYDEPS.is_dir() and str(_PYDEPS) not in sys.path:
    sys.path.insert(0, str(_PYDEPS))
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

os.environ.setdefault("TMPDIR", str(_PROJECT_ROOT / ".tmp"))
os.environ.setdefault(
    "PLAYWRIGHT_BROWSERS_PATH",
    str(_PROJECT_ROOT / ".playwright-browsers"),
)

import uvicorn
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware

from crawl_shopee import search_products_live

app = FastAPI(title="Shopee Crawl API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/api/search")
def search(
    keyword: str = Query(..., min_length=1),
    limit: int = Query(60, ge=1, le=60),
):
    try:
        products = search_products_live(keyword.strip(), limit)
    except FileNotFoundError as e:
        raise HTTPException(status_code=503, detail=str(e)) from e
    except RuntimeError as e:
        raise HTTPException(status_code=502, detail=str(e)) from e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) from e

    return {
        "keyword": keyword,
        "count": len(products),
        "products": products,
    }


if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8765, log_level="info")

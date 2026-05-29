# Shopee Product Database

PostgreSQL database chứa dữ liệu sản phẩm Shopee, chạy bằng Docker.

## Cấu trúc project

```
Lap1/
├── docker-compose.yml          # PostgreSQL + Importer services
├── .env                        # Biến môi trường (DB credentials)
├── .env.example                # Template cho server
├── db/
│   └── init.sql                # Schema - tự chạy khi khởi tạo DB
├── scripts/
│   ├── Dockerfile              # Image cho importer
│   ├── import_data.py          # Script import JSON → DB
│   └── requirements.txt        # Python dependencies
├── data/
│   └── *.json                  # Đặt file JSON vào đây để import
└── README.md
```

## Khởi chạy nhanh

### 1. Chuẩn bị

```bash
# Clone project và vào thư mục
cd Lap1

# Copy file .env (đổi password nếu trên server)
cp .env.example .env
```

### 2. Đặt file JSON vào thư mục `data/`

```bash
cp /path/to/SHOPEE_*.json data/
```

### 3. Khởi chạy DB + Import

```bash
# Chạy tất cả (DB khởi tạo schema + import JSON)
docker compose up --build

# Hoặc chạy nền
docker compose up -d --build

# Xem log importer
docker compose logs importer
```

### 4. Kiểm tra dữ liệu

```bash
# Kết nối vào PostgreSQL
docker compose exec db psql -U shopee_user -d shopee_db

# Một số query test
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM shops;
SELECT COUNT(*) FROM product_images;
SELECT * FROM search_extractions;
```

## Chạy trên Server

```bash
# 1. Copy project lên server
scp -r Lap1/ user@server:/path/to/

# 2. SSH vào server
ssh user@server

# 3. Sửa .env cho phù hợp
cd /path/to/Lap1
nano .env

# 4. Chạy
docker compose up -d --build
```

## Chỉ chạy DB (không import)

```bash
docker compose up -d db
```

## Import thêm file JSON sau

```bash
# Đặt file mới vào data/
cp new_file.json data/

# Chạy lại importer
docker compose run --rm importer
```

## Crawl dữ liệu mới từ Shopee

Playwright MCP **không phù hợp** crawl hàng loạt (Shopee chặn bot). Dùng script gọi API nội bộ + **cookie từ browser**.

### Bước 1: Lấy Cookie

1. Mở **Chrome** → vào [shopee.vn](https://shopee.vn) (login nếu cần)
2. **F12** → tab **Network** → reload trang
3. Chọn request `search_items` hoặc bất kỳ request `api/v4/...`
4. Copy toàn bộ header **Cookie**
5. Lưu vào `shopee-db/cookies.txt` (file này không commit)

### Bước 2: Cài dependencies (dùng venv — Ubuntu không cho pip global)

```bash
cd shopee-db/scripts
chmod +x setup_venv.sh
./setup_venv.sh
source .venv/bin/activate
```

### Bước 3: Chạy crawler

```bash
python crawl_shopee.py --keyword "rtx5090" --limit 60
# Đầy đủ ảnh + variations (chậm hơn):
python crawl_shopee.py --keyword "rtx5090" --limit 60 --with-details
```

Output: `data/SHOPEE_<uuid>_<count>.json`

### Bước 4: Chạy API cho Flutter app (tab Tìm keyword)

```bash
cd shopee-db/scripts
python3 search_api.py
# API: http://127.0.0.1:8765/api/search?keyword=rtx5090&limit=60
```

Flutter tab **Tìm keyword** → chọn **Crawl Python** → nhập keyword → Phân tích.

Cần `cookies.txt` hợp lệ + `playwright install chromium`.

### Bước 5: Import lên Firestore

```bash
python import_firestore.py ../data/SHOPEE_xxx.json ../prm-shopee-be-firebase-adminsdk-xxx.json
```

> Cookie hết hạn sau vài ngày/tuần — copy lại nếu API trả lỗi `90309999` hoặc HTTP 403.

## Import thủ công (không dùng Docker)

```bash
pip install psycopg2-binary
export DB_HOST=localhost
python scripts/import_data.py data/your_file.json
```

## Dừng & xóa

```bash
# Dừng containers
docker compose down

# Dừng + xóa data (reset hoàn toàn)
docker compose down -v
```

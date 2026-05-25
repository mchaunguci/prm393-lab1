-- =============================================
-- Shopee Product Database Schema
-- Auto-runs on first PostgreSQL container start
-- =============================================

-- 1. SHOPS
CREATE TABLE shops (
    shop_id         BIGINT PRIMARY KEY,
    shop_name       VARCHAR(100) NOT NULL,
    shop_location   VARCHAR(100),
    is_official     BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. CATEGORIES
CREATE TABLE categories (
    category_id     INT PRIMARY KEY,
    category_name   VARCHAR(200),
    parent_id       INT REFERENCES categories(category_id),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. PRODUCTS
CREATE TABLE products (
    product_id              BIGINT PRIMARY KEY,
    shop_id                 BIGINT NOT NULL REFERENCES shops(shop_id),
    category_id             INT REFERENCES categories(category_id),
    name                    VARCHAR(300) NOT NULL,
    url                     VARCHAR(500) NOT NULL,
    thumbnail_url           VARCHAR(200),

    price                   DECIMAL(15,2) NOT NULL,
    price_max               DECIMAL(15,2),
    price_min               DECIMAL(15,2),
    price_before_discount   DECIMAL(15,2),
    original_price          DECIMAL(15,2),
    discount                SMALLINT DEFAULT 0,
    discount_text           VARCHAR(20),

    rating                  DECIMAL(3,2) DEFAULT 0,
    rating_count            INT DEFAULT 0,
    star_1_count            INT DEFAULT 0,
    star_2_count            INT DEFAULT 0,
    star_3_count            INT DEFAULT 0,
    star_4_count            INT DEFAULT 0,
    star_5_count            INT DEFAULT 0,

    sold_count              INT DEFAULT 0,
    sold_count_text         VARCHAR(20),
    monthly_sold_count      INT DEFAULT 0,
    liked_count             INT DEFAULT 0,

    colors                  TEXT,
    sizes                   VARCHAR(500),
    variations              TEXT,

    is_adult                BOOLEAN DEFAULT FALSE,
    is_service_by_shopee    BOOLEAN DEFAULT FALSE,
    is_shopee_choice        BOOLEAN DEFAULT FALSE,
    is_on_flash_sale        BOOLEAN DEFAULT FALSE,
    is_preferred_plus_seller BOOLEAN DEFAULT FALSE,
    is_lowest_price         BOOLEAN DEFAULT FALSE,
    is_live_streaming_price BOOLEAN,
    is_mart                 BOOLEAN DEFAULT FALSE,
    can_use_cod             BOOLEAN DEFAULT FALSE,
    can_use_wholesale       BOOLEAN DEFAULT FALSE,
    has_lowest_price_guarantee BOOLEAN DEFAULT FALSE,
    show_free_shipping      BOOLEAN DEFAULT FALSE,

    shopee_created_at       TIMESTAMP,
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. PRODUCT_IMAGES
CREATE TABLE product_images (
    id              BIGSERIAL PRIMARY KEY,
    product_id      BIGINT NOT NULL REFERENCES products(product_id),
    image_url       VARCHAR(500) NOT NULL,
    image_type      VARCHAR(20) DEFAULT 'product',
    display_order   SMALLINT DEFAULT 0,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. SEARCH_EXTRACTIONS
CREATE TABLE search_extractions (
    id              BIGSERIAL PRIMARY KEY,
    source_url      VARCHAR(500) NOT NULL,
    keyword         VARCHAR(200),
    extracted_at    TIMESTAMP NOT NULL,
    total_items     INT,
    file_name       VARCHAR(300),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. EXTRACTION_PRODUCTS
CREATE TABLE extraction_products (
    extraction_id   BIGINT REFERENCES search_extractions(id),
    product_id      BIGINT REFERENCES products(product_id),
    position        SMALLINT,
    PRIMARY KEY (extraction_id, product_id)
);

-- INDEXES
CREATE INDEX idx_products_shop_id ON products(shop_id);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_products_rating ON products(rating);
CREATE INDEX idx_products_monthly_sold ON products(monthly_sold_count);
CREATE INDEX idx_products_created ON products(shopee_created_at);
CREATE INDEX idx_product_images_product ON product_images(product_id);
CREATE INDEX idx_extraction_products_product ON extraction_products(product_id);
CREATE INDEX idx_shops_location ON shops(shop_location);

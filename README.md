# ShopTrack Analytics Pro

**PRM393 - SE1808 - Group 6**

Flutter Desktop app phân tích dữ liệu sản phẩm Shopee, kết nối Firestore.

---

## Yêu cầu

- Flutter SDK >= 3.41
- Windows 10/11 (desktop build)
- Firebase project: `prm-shopee-be`

## Chạy dự án

```bash
# 1. Clone repo
git clone https://github.com/mchaunguci/prm393-lab1.git
cd prm393-lab1
git checkout huynh-dev

# 2. Cài dependencies
flutter pub get

# 3. Chạy app
flutter run -d windows
```

> Lần đầu build mất ~1-2 phút (compile Firebase C++ SDK). Các lần sau nhanh hơn.
> Bỏ qua warning `LNK4099: PDB not found` - không ảnh hưởng gì.

---

## Cấu trúc project

```
lib/
├── main.dart                          # Entry point, khởi tạo Firebase + Provider
├── firebase_options.dart              # Firebase config (auto-generated)
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart         # Tên app, padding...
│   │   └── app_colors.dart            # Bảng màu dark theme
│   ├── theme/
│   │   └── app_theme.dart             # ThemeData
│   └── utils/
│       └── formatters.dart            # Format giá, số, ngày
│
├── models/                            # Data models (match Firestore)
│   ├── product.dart                   # Product - 40+ fields
│   ├── shop.dart                      # Shop
│   └── category.dart                  # Category
│
├── services/
│   └── firestore_service.dart         # Gọi Firestore, trả về List<Model>
│
├── providers/
│   └── dashboard_provider.dart        # State management cho Dashboard
│
├── screens/
│   ├── home_screen.dart               # Shell layout (sidebar + topbar)
│   ├── dashboard_screen.dart          # ✅ Dashboard - đã implement
│   ├── products_screen.dart           # 🔲 Placeholder - chờ team
│   ├── shop_analysis_screen.dart      # 🔲 Placeholder - chờ team
│   └── price_compare_screen.dart      # 🔲 Placeholder - chờ team
│
└── widgets/                           # Reusable widgets
    ├── sidebar.dart
    ├── stat_card.dart
    ├── price_chart.dart
    ├── location_chart.dart
    └── top_products_table.dart

shopee-db/                             # Database setup (tách riêng)
├── docker-compose.yml
├── db/init.sql
├── scripts/
│   ├── import_data.py                 # Import JSON → PostgreSQL
│   └── import_firestore.py            # Import JSON → Firestore
└── data/*.json                        # File dữ liệu gốc
```

---

## Firestore - Cấu trúc dữ liệu

Firestore có **3 collections**:

### Collection: `products` (55 documents)

| Field | Type | Mô tả |
|---|---|---|
| `product_id` | number | ID sản phẩm Shopee |
| `shop_id` | number | ID shop (FK → shops) |
| `category_id` | number | ID danh mục |
| `name` | string | Tên sản phẩm |
| `url` | string | Link Shopee |
| `thumbnail_url` | string | Ảnh thumbnail |
| `images` | array\<string\> | Danh sách URL ảnh |
| `price` | number | Giá hiện tại |
| `price_max`, `price_min` | number | Giá max/min (biến thể) |
| `original_price` | number | Giá gốc |
| `discount` | number | % giảm giá (int) |
| `discount_text` | string? | Text giảm giá ("31%") |
| `rating` | number | Điểm đánh giá (0-5) |
| `rating_count` | number | Tổng lượt đánh giá |
| `star_1_count`...`star_5_count` | number | Số lượng từng sao |
| `sold_count` | number | Tổng đã bán |
| `monthly_sold_count` | number | Bán trong 30 ngày |
| `liked_count` | number | Lượt thích |
| `variations` | string? | Biến thể ("Mẫu: A, B, C") |
| `is_on_flash_sale` | bool | Đang flash sale? |
| `is_official_shop` | bool | Shop chính hãng? |
| `can_use_cod` | bool | Hỗ trợ COD? |
| `shopee_created_at` | timestamp | Ngày tạo trên Shopee |
| `extracted_at` | timestamp | Ngày crawl dữ liệu |

### Collection: `shops` (32 documents)

| Field | Type | Mô tả |
|---|---|---|
| `shop_id` | number | ID shop |
| `shop_name` | string | Tên shop |
| `shop_location` | string? | Địa chỉ (TP.HCM, Hà Nội...) |
| `is_official` | bool | Shop chính hãng? |

### Collection: `categories` (3 documents)

| Field | Type | Mô tả |
|---|---|---|
| `category_id` | number | ID danh mục |
| `category_name` | string? | Tên danh mục (hiện null) |

---

## Hướng dẫn code cho team

### 1. Lấy dữ liệu từ Firestore

Dùng `FirestoreService` trong `lib/services/firestore_service.dart`:

```dart
final service = FirestoreService();

// Lấy tất cả sản phẩm
List<Product> products = await service.getProducts();

// Lấy tất cả shops
List<Shop> shops = await service.getShops();

// Lấy categories
List<Category> categories = await service.getCategories();

// Hoặc dùng Stream (real-time)
Stream<List<Product>> stream = service.watchProducts();
```

### 2. Dùng Provider để quản lý state

Xem `DashboardProvider` làm mẫu. Tạo provider mới:

```dart
// lib/providers/product_list_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shopee_app/models/product.dart';
import 'package:shopee_app/services/firestore_service.dart';

class ProductListProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  List<Product> _products = [];
  bool _isLoading = true;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    _products = await _service.getProducts();

    _isLoading = false;
    notifyListeners();
  }
}
```

Rồi đăng ký trong `main.dart`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => DashboardProvider()..loadData()),
    ChangeNotifierProvider(create: (_) => ProductListProvider()..loadProducts()),
  ],
  ...
)
```

### 3. Implement màn hình mới

Mở file placeholder (ví dụ `products_screen.dart`), thay nội dung:

```dart
class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductListProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: provider.products.length,
          itemBuilder: (context, index) {
            final p = provider.products[index];
            return ListTile(
              title: Text(p.name),
              subtitle: Text(Formatters.priceFull(p.price)),
            );
          },
        );
      },
    );
  }
}
```

### 4. Thêm field mới vào Model

Nếu Firestore có thêm field mới, sửa trong `lib/models/product.dart`:
1. Thêm property vào class
2. Thêm vào constructor
3. Thêm vào `fromFirestore()`

### 5. Màu sắc & Style

Dùng các hằng số trong `AppColors`:

```dart
import 'package:shopee_app/core/constants/app_colors.dart';

Container(
  color: AppColors.card,        // nền card
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.textPrimary),
  ),
)
```

---

## Phân công team

| Tab | File | Mô tả |
|---|---|---|
| Sản phẩm | `products_screen.dart` | Danh sách, search, filter sản phẩm |
| Phân tích Shop | `shop_analysis_screen.dart` | Thống kê theo shop, so sánh shop |
| So sánh giá | `price_compare_screen.dart` | So sánh giá giữa các shop/sản phẩm |

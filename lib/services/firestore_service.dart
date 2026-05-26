import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopee_app/models/product.dart';
import 'package:shopee_app/models/shop.dart';
import 'package:shopee_app/models/category.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _productsRef => _db.collection('products');
  CollectionReference get _shopsRef => _db.collection('shops');
  CollectionReference get _categoriesRef => _db.collection('categories');

  Future<List<Product>> getProducts() async {
    final snapshot = await _productsRef.get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  Future<List<Shop>> getShops() async {
    final snapshot = await _shopsRef.get();
    return snapshot.docs.map((doc) => Shop.fromFirestore(doc)).toList();
  }

  Future<List<Category>> getCategories() async {
    final snapshot = await _categoriesRef.get();
    return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
  }

  Stream<List<Product>> watchProducts() {
    return _productsRef.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
    );
  }

  Stream<List<Shop>> watchShops() {
    return _shopsRef.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Shop.fromFirestore(doc)).toList(),
    );
  }
}

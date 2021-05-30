import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import './product.dart';
import '../models/http_exception.dart';

class Products with ChangeNotifier {
  final String _authToken;
  final String _userId;
  List<Product> _items = [];

  Products(this._authToken, this._userId, this._items);

  List<Product> get favoriteItems {
    return _items.where((prod) => prod.isFavorite).toList();
  }

  List<Product> get items {
    return [..._items];
  }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    final filterString =
        filterByUser ? 'orderBy="creatorId"&equalTo="$_userId"' : '';
    var url =
        'https://flutter-complete-guide-7b3cd-default-rtdb.asia-southeast1.firebasedatabase.app/products.json?$filterString&auth=$_authToken';
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      }
      url =
          'https://flutter-complete-guide-7b3cd-default-rtdb.asia-southeast1.firebasedatabase.app/userFavorites/$_userId.json?auth=$_authToken';
      final favoriteResponse = await http.get(url);
      final favoriteData = json.decode(favoriteResponse.body);
      final List<Product> loadedProducts = [];
      extractedData.forEach((prodId, prodData) {
        loadedProducts.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          imageUrl: prodData['imageUrl'],
          price: prodData['price'],
          isFavorite:
              favoriteData == null ? false : favoriteData[prodId] ?? false,
        ));
      });
      _items = loadedProducts;
      notifyListeners();
    } catch (err) {
      throw err;
    }
  }

  Future<void> addProduct(Product product) async {
    final url =
        'https://flutter-complete-guide-7b3cd-default-rtdb.asia-southeast1.firebasedatabase.app/products.json?auth=$_authToken';
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'creatorId': _userId,
        }),
      );
      final newProduct = Product(
        id: json.decode(response.body)['name'],
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
      );
      _items.add(newProduct);
      notifyListeners();
    } catch (err) {
      throw err;
    }
  }

  Future<void> updateProduct(String id, Product updatedProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      final url =
          'https://flutter-complete-guide-7b3cd-default-rtdb.asia-southeast1.firebasedatabase.app/products/$id.json?auth=$_authToken';
      await http.patch(url,
          body: json.encode({
            'title': updatedProduct.title,
            'description': updatedProduct.description,
            'imageUrl': updatedProduct.imageUrl,
            'price': updatedProduct.price,
          }));
      _items[prodIndex] = updatedProduct;
      notifyListeners();
    } else {
      // ...
    }
  }

  Future<void> deleteProduct(String id) async {
    final url =
        'https://flutter-complete-guide-7b3cd-default-rtdb.asia-southeast1.firebasedatabase.app/products/$id.json?auth=$_authToken';
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    var existingProduct = _items[existingProductIndex];
    final response = await http.delete(url);
    _items.removeAt(existingProductIndex);
    notifyListeners();
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete product.');
    }
    existingProduct = null;
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }
}

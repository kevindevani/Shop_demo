import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import './product.dart';
import '../models/http_exception.dart';

class Products with ChangeNotifier {
  List<Product> _items = [
    // Product(
    //   id: 'p1',
    //   title: 'Man Black Shirt',
    //   description: 'it is really cool!',
    //   price: 25.99,
    //   imageUrl:
    //       'https://5.imimg.com/data5/UC/IS/MY-7837511/mens-black-shirt-500x500.jpg',
    // ),
    // Product(
    //   id: 'p2',
    //   title: 'Women Black Shirt',
    //   description: 'it is really cool!',
    //   price: 25.99,
    //   imageUrl:
    //       'https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcSUPLZieTi36L07uzFL8lk0HfARAXd-enn1USDb0SD2tSTcvnkG&usqp=CAU',
    // ),
    // Product(
    //   id: 'p3',
    //   title: 'Toy Car',
    //   description: 'it is really for kid!!',
    //   price: 25.99,
    //   imageUrl:
    //       'https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcRk3WaWiIbJl_zEScTH8SLNiIG9mTdUmskClIFPl-9CjI9MMs9qUKq6uXPAZ1C6hYNO46f7d055&usqp=CAc',
    // ),
    // Product(
    //   id: 'p4',
    //   title: 'Hand Bag',
    //   description: 'it is really cool!',
    //   price: 25.99,
    //   imageUrl:
    //       'https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcTE6CS-SOQ5j1qGk5wbF0yHSdfIeEzuKopGswpBu6yi6XSbLsnL&usqp=CAU',
    // ),
  ];
  //var _showFavoritesOnly = false;

  final String authToken;
  final String userId;

  Products(this.authToken, this.userId, this._items);

  List<Product> get items {
    // if(_showFavoritesOnly){
    //   return items.where((prodItem) => prodItem.isFvorite).toList();
    // }
    return [..._items];
  }

  List<Product> get favoriteItems {
    return items.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  // void showFavoritesOnly(){
  //   _showFavoritesOnly = true;
  //   notifyListeners();
  // }

  // void showAll(){
  //   _showFavoritesOnly = false;
  //   notifyListeners();
  // }

  Future<void> fetchandSetProducts([bool filterByUser = false]) async {
    final filterString =
        filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
    var url =
        'https://shop-demo-e49df.firebaseio.com/products.json?auth=$authToken&$filterString';
    try {
      final response = await http.get(url);
      //print(json.decode(response.body));
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      }
      url =
          'https://shop-demo-e49df.firebaseio.com/userFavorites/$userId.json?auth=$authToken';
      final favoriteResponse = await http.get(url);
      final favoriteData = json.decode(favoriteResponse.body);
      final List<Product> loadedProducts = [];
      extractedData.forEach((prodId, prodData) {
        loadedProducts.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          price: prodData['price'],
          isFavorite:
              favoriteData == null ? false : favoriteData[prodId] ?? false,
          imageUrl: prodData['imageUrl'],
        ));
      });
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      throw (error);
    }
  }

  Future<void> addproduct(Product product) async {
    final url =
        'https://shop-demo-e49df.firebaseio.com/products.json?auth=$authToken';
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'creatorId': userId,
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
      //_items.insert(0, newProduct);
      notifyListeners();
    } catch (error) {
      throw (error);
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      final url =
          'https://shop-demo-e49df.firebaseio.com/products/$id.json?auth=$authToken';
      await http.patch(url,
          body: json.encode({
            'title': newProduct.title,
            'description': newProduct.description,
            'price': newProduct.price,
            'imageUrl': newProduct.imageUrl,
          }));
      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {
      print('...');
    }
  }

  Future<void> deleteProduct(String id) async {
    final url =
        'https://shop-demo-e49df.firebaseio.com/products/$id.json?auth=$authToken';
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    var existingProduct = _items[existingProductIndex];
    _items.removeAt(existingProductIndex);
    notifyListeners();
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete product.');
    }
    existingProduct = null;
  }
}

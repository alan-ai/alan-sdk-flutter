// Copyright 2018-present the Flutter authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:alan_voice/alan_voice.dart';
import 'package:scoped_model/scoped_model.dart';
import 'dart:convert';

import 'dispatcher.dart';
import 'product.dart';
import 'products_repository.dart';

double _salesTaxRate = 0.06;
double _shippingCostPerItem = 7.0;

class AppStateModel extends Model {

  Dispatcher dispatcher = new Dispatcher();

  String _highlightedValue = "";

  // All the available products.
  List<Product> _availableProducts;

  // The currently selected category of products.
  Category _selectedCategory = Category.all;

  // The IDs and quantities of products currently in the cart.
  Map<int, int> _productsInCart = {};

  Map<int, int> get productsInCart => Map.from(_productsInCart);

  // Total number of items in the cart.
  int get totalCartQuantity => _productsInCart.values.fold(0, (v, e) => v + e);

  Category get selectedCategory => _selectedCategory;

  String _currentScreen = "all";

  // Totaled prices of the items in the cart.
  double get subtotalCost => _productsInCart.keys
      .map((id) => ProductsRepository.findById(id).price * _productsInCart[id])
      .fold(0.0, (sum, e) => sum + e);

  // Total shipping cost for the items in the cart.
  double get shippingCost =>
      _shippingCostPerItem *
      _productsInCart.values.fold(0.0, (sum, e) => sum + e);

  // Sales tax for the items in the cart
  double get tax => subtotalCost * _salesTaxRate;

  // Total cost to order everything in the cart.
  double get totalCost => subtotalCost + shippingCost + tax;

  // Returns a copy of the list of available products, filtered by category.
  List<Product> getProducts() {
    if (_availableProducts == null) return List<Product>();

    if (_selectedCategory == Category.all) {
      return List.from(_availableProducts);
    } else {
      return _availableProducts
          .where((p) => p.category == _selectedCategory)
          .toList();
    }
  }

  String cartToJson() {
    var orderedCart = List<Map<String, dynamic>>(); //we need this to persist item ordering
    _productsInCart.forEach((k, v) => {
      orderedCart.add({"id": k, "qty": v})
    });
    var str = json.encode(orderedCart);
    if (str == "{}") {
      str = null;
    }
    return str;
  }

  // Adds a product to the cart.
  void addProductToCart(int productId, [int quantity = 1]) {
    for (int i = 0; i < quantity; i++) {
      if (!_productsInCart.containsKey(productId)) {
        _productsInCart[productId] = 1;
      } else {
        _productsInCart[productId]++;
      }

      if (_productsInCart[productId] <= 0) {
        removeItemFromCart(productId);
      }

      notifyListeners();
    }
  }

  // Removes an item from the cart.
  void removeItemFromCart(int productId) {
    if (_productsInCart.containsKey(productId)) {
      if (_productsInCart[productId] == 1) {
        _productsInCart.remove(productId);
      } else {
        _productsInCart[productId]--;
      }
    }

    notifyListeners();
  }

  // Returns the Product instance matching the provided id.
  Product getProductById(int id) {
    return ProductsRepository.findById(id);
  }

  int _highlightedProduct = -1;

  void highlightProduct(int id) {
    getProductById(id).isHighlighted = true;
    _highlightedProduct = id;
    notifyListeners();
  }

  void deHighlight() {
    getProductById(_highlightedProduct).isHighlighted = false;
    notifyListeners();
  }

  // Removes everything from the cart.
  void clearCart() {
    _productsInCart.clear();
    notifyListeners();
  }

  // Loads the list of available products from the repo.
  void loadProducts() {
    _availableProducts = ProductsRepository.loadProducts();
    notifyListeners();
  }

  void filterProductsById(Iterable<int> products) {
    _availableProducts = ProductsRepository.loadProducts()
        .where((product) => products.contains(product.id))
        .toList();
    notifyListeners();
  }

  void setCategory(Category newCategory) {
    _availableProducts = ProductsRepository.loadProducts();
    _selectedCategory = newCategory;
    _currentScreen = _getCategoryString(_selectedCategory);
    notifyListeners();
  }

  void setVisuals() {
    var visual =
        "{\"screen\":\"$_currentScreen\", \"order\":${cartToJson()}, \"total\":${totalCost}}";
    print(visual);
    AlanVoice.setVisualState(visual);
  }

  void highlightValue(String value) {
    _highlightedValue = value;
    notifyListeners();
  }

  bool isValueHighlighted(String value) {
    return this._highlightedValue == value;
  }

  String _getCategoryString(Category category) {
    return category.toString().replaceAll('Category.', '').toLowerCase();
  }

  void cartIsOpened() {
    _currentScreen = "cart";
    setVisuals();
  }

  void cartIsClosed() {
    _currentScreen = _getCategoryString(_selectedCategory);
    setVisuals();
  }
}

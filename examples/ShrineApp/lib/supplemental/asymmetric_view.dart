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

import 'package:shrine/model/dispatcher.dart';
import 'package:flutter/material.dart';

import '../model/product.dart';
import 'product_columns.dart';


class ProductScrollController extends ScrollController {

  final List<Product> products;
  final double defItemWidth;

  ProductScrollController({this.products, this.defItemWidth});

  void scrollToItem(int itemId) {
    if (positions.isEmpty) {
      debugPrint("Scroll Container is not attached");
      return;
    }
    var productNumber = products.indexOf(products.firstWhere((p) => p.id == itemId)) - 1;
    double position = defItemWidth * productNumber / 3 * 2;
    position += (productNumber - 1) / 2 * 32.0;
    if (productNumber % 3 == 1) {
      position += 16;
    }
    animateTo(position,
        duration: const Duration(milliseconds: 400),
        curve: Curves.linearToEaseOut
    );
  }
}

class AsymmetricView extends StatelessWidget {
  final List<Product> products;
  final Dispatcher dispatcher;

  ProductScrollController _scrollController;

  AsymmetricView({Key key, this.products, this.dispatcher}) {
  }

  List<Container> _buildColumns(BuildContext context) {
    if (products == null || products.isEmpty) {
      return const <Container>[];
    }

    /// This will return a list of columns. It will oscillate between the two
    /// kinds of columns. Even cases of the index (0, 2, 4, etc) will be
    /// TwoProductCardColumn and the odd cases will be OneProductCardColumn.
    ///
    /// Each pair of columns will advance us 3 products forward (2 + 1). That's
    /// some kinda awkward math so we use _evenCasesIndex and _oddCasesIndex as
    /// helpers for creating the index of the product list that will correspond
    /// to the index of the list of columns.
    return List.generate(_listItemCount(products.length), (int index) {
      double width = .59 * MediaQuery.of(context).size.width;
      Widget column;
      if (index % 2 == 0) {
        /// Even cases
        int bottom = _evenCasesIndex(index);
        column = TwoProductCardColumn(
            bottom: products[bottom],
            top: products.length - 1 >= bottom + 1
                ? products[bottom + 1]
                : null);
        width += 32.0;
      } else {
        /// Odd cases
        column = OneProductCardColumn(
          product: products[_oddCasesIndex(index)],
        );
      }
      return Container(
        width: width,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: column,
        ),
      );
    }).toList();
  }

  int _evenCasesIndex(int input) {
    /// The operator ~/ is a cool one. It's the truncating division operator. It
    /// divides the number and if there's a remainder / decimal, it cuts it off.
    /// This is like dividing and then casting the result to int. Also, it's
    /// functionally equivalent to floor() in this case.
    return input ~/ 2 * 3;
  }

  int _oddCasesIndex(int input) {
    assert(input > 0);
    return (input / 2).ceil() * 3 - 1;
  }

  int _listItemCount(int totalItems) {
    if (totalItems % 3 == 0) {
      return totalItems ~/ 3 * 2;
    } else {
      return (totalItems / 3).ceil() * 2 - 1;
    }
  }

  @override
  Widget build(BuildContext context) {

    _scrollController =  ProductScrollController(
        products: products,
        defItemWidth: .59 * MediaQuery.of(context).size.width
    );

    dispatcher.commandListeners.add(((str, [arg]) {
      if (str == "scrollToItem") {
        _scrollController.scrollToItem(arg);
      }
    }));

    return ListView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(0.0, 34.0, 16.0, 44.0),
      children: _buildColumns(context),
      physics: AlwaysScrollableScrollPhysics(),
    );
  }
}

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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';

import 'colors.dart';
import 'expanding_bottom_sheet.dart';
import 'model/app_state_model.dart';
import 'model/product.dart';
import 'model/products_repository.dart';

const _leftColumnWidth = 60.0;

class ShoppingCartPage extends StatefulWidget {
  @override
  _ShoppingCartPageState createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  List<Widget> _createShoppingCartRows(AppStateModel model) {
    return model.productsInCart.keys
        .map(
          (id) => ShoppingCartRow(
                product: ProductsRepository.findById(id),
                quantity: model.productsInCart[id],
                onPressed: () {
                  model.removeItemFromCart(id);
                },
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final localTheme = Theme.of(context);

    return Scaffold(
      backgroundColor: kShrinePink50,
      body: SafeArea(
        child: Container(
          child: ScopedModelDescendant<AppStateModel>(
            builder: (context, child, model) {
              return Stack(
                children: [
                  ListView(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: _leftColumnWidth,
                            child: IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down),
                                onPressed: () =>
                                    ExpandingBottomSheet.of(context).close()),
                          ),
                          Text(
                            'CART',
                            style: localTheme.textTheme.subtitle1
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 16.0),
                          Text('${model.totalCartQuantity} ITEMS'),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Column(
                        children: _createShoppingCartRows(model),
                      ),
                      ShoppingCartSummary(model: model),
                      const SizedBox(height: 100.0),
                    ],
                  ),
                  Positioned(
                    bottom: 16.0,
                    left: 16.0,
                    right: 16.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(7.0)),
                        color: kShrinePink100,
                      ),
                      child: ElevatedButton(
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text('CLEAR CART'),
                        ),
                        onPressed: () {
                          model.clearCart();
                          ExpandingBottomSheet.of(context).close();
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class ShoppingCartSummary extends StatefulWidget {
  ShoppingCartSummary({this.model});

  final AppStateModel model;

  @override
  _ShoppingCartSummaryState createState() =>
      _ShoppingCartSummaryState();
}

class _ShoppingCartSummaryState extends State<ShoppingCartSummary> {
  _ShoppingCartSummaryState();

  Color _borderColor(AppStateModel model, String value) {
    if (model.isValueHighlighted(value)) {
      return Colors.blue;
    } else {
      return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final smallAmountStyle =
        Theme.of(context).textTheme.bodyText1.copyWith(color: kShrineBrown600);
    final largeAmountStyle = Theme.of(context).textTheme.displaySmall;
    final formatter = NumberFormat.simpleCurrency(
        decimalDigits: 2, locale: Localizations.localeOf(context).toString());

    return ScopedModelDescendant<AppStateModel>(
      builder: (context, child, model) {
        return Row(
          children: [
            SizedBox(width: _leftColumnWidth),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(
                          top: 2.0, left: 2.0, right: 16.0, bottom: 2.0),
                      decoration: BoxDecoration(
                          border: Border.all(color: _borderColor(model, "total"))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Text('TOTAL'),
                          ),
                          Text(
                            formatter.format(model.totalCost),
                            style: largeAmountStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Subtotal:'),
                        ),
                        Text(
                          formatter.format(model.subtotalCost),
                          style: smallAmountStyle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Shipping:'),
                        ),
                        Text(
                          formatter.format(model.shippingCost),
                          style: smallAmountStyle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Tax:'),
                        ),
                        Text(
                          formatter.format(model.tax),
                          style: smallAmountStyle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ShoppingCartRow extends StatelessWidget {
  ShoppingCartRow(
      {@required this.product, @required this.quantity, this.onPressed});

  final Product product;
  final int quantity;
  final VoidCallback onPressed;

  Color _borderColor() {
    if (product.isHighlighted) {
      return Colors.blue;
    } else {
      return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.simpleCurrency(
        decimalDigits: 0, locale: Localizations.localeOf(context).toString());
    final localTheme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        key: ValueKey(product.id),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _leftColumnWidth,
            child: IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: onPressed,
            ),
          ),
          Expanded(
              child: Container(
                padding: EdgeInsets.only(
                    top: 2.0, left: 2.0, right: 16.0, bottom: 2.0),
                decoration:
                BoxDecoration(border: Border.all(color: _borderColor())),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        product.assetName,
                        package: product.assetPackage,
                        fit: BoxFit.cover,
                        width: 75.0,
                        height: 75.0,
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Quantity: $quantity'),
                                ),
                                Text('x ${formatter.format(product.price)}'),
                              ],
                            ),
                            Text(
                              product.name,
                              style: localTheme.textTheme.subtitle1
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  const Divider(
                    color: kShrineBrown900,
                    height: 10.0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

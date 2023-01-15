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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:scoped_model/scoped_model.dart';

import 'colors.dart';
import 'model/app_state_model.dart';
import 'model/dispatcher.dart';
import 'model/product.dart';
import 'shopping_cart.dart';

// These curves define the emphasized easing curve.
const Cubic _kAccelerateCurve = Cubic(0.548, 0.0, 0.757, 0.464);
const Cubic _kDecelerateCurve = Cubic(0.23, 0.94, 0.41, 1.0);
// The time at which the accelerate and decelerate curves switch off
const double _kPeakVelocityTime = 0.248210;
// Percent (as a decimal) of animation that should be completed at _peakVelocityTime
const double _kPeakVelocityProgress = 0.379146;
const double _kCartHeight = 56.0;
// Radius of the shape on the top left of the sheet.
const double _kCornerRadius = 24.0;
// Width for just the cart icon and no thumbnails.
const double _kWidthForCartIcon = 64.0;

class ExpandingBottomSheet extends StatefulWidget {
  const ExpandingBottomSheet(
      {Key key, @required this.hideController, @required this.dispatcher})
      : assert(hideController != null),
        super(key: key);

  final AnimationController hideController;
  final Dispatcher dispatcher;

  @override
  _ExpandingBottomSheetState createState() =>
      _ExpandingBottomSheetState(dispatcher: this.dispatcher);

  static _ExpandingBottomSheetState of(BuildContext context,
      {bool isNullOk = false}) {
    assert(isNullOk != null);
    assert(context != null);
    final _ExpandingBottomSheetState result = context
        .findAncestorStateOfType();
    if (isNullOk || result != null) {
      return result;
    }
    throw FlutterError(
        'ExpandingBottomSheet.of() called with a context that does not contain a ExpandingBottomSheet.\n');
  }
}

// Emphasized Easing is a motion curve that has an organic, exciting feeling.
// It's very fast to begin with and then very slow to finish. Unlike standard
// curves, like [Curves.fastOutSlowIn], it can't be expressed in a cubic bezier
// curve formula. It's quintic, not cubic. But it _can_ be expressed as one
// curve followed by another, which we do here.
Animation<T> _getEmphasizedEasingAnimation<T>(
    {@required T begin,
    @required T peak,
    @required T end,
    @required bool isForward,
    @required Animation parent}) {
  Curve firstCurve;
  Curve secondCurve;
  double firstWeight;
  double secondWeight;

  if (isForward) {
    firstCurve = _kAccelerateCurve;
    secondCurve = _kDecelerateCurve;
    firstWeight = _kPeakVelocityTime;
    secondWeight = 1.0 - _kPeakVelocityTime;
  } else {
    firstCurve = _kDecelerateCurve.flipped;
    secondCurve = _kAccelerateCurve.flipped;
    firstWeight = 1.0 - _kPeakVelocityTime;
    secondWeight = _kPeakVelocityTime;
  }

  return TweenSequence(
    <TweenSequenceItem<T>>[
      TweenSequenceItem<T>(
        weight: firstWeight,
        tween: Tween<T>(
          begin: begin,
          end: peak,
        ).chain(CurveTween(curve: firstCurve)),
      ),
      TweenSequenceItem<T>(
        weight: secondWeight,
        tween: Tween<T>(
          begin: peak,
          end: end,
        ).chain(CurveTween(curve: secondCurve)),
      ),
    ],
  ).animate(parent);
}

// Calculates the value where two double Animations should be joined. Used by
// callers of _getEmphasisedEasing<double>().
double _getPeakPoint({double begin, double end}) {
  return begin + (end - begin) * _kPeakVelocityProgress;
}

class _ExpandingBottomSheetState extends State<ExpandingBottomSheet>
    with TickerProviderStateMixin {
  _ExpandingBottomSheetState({@required this.dispatcher});

  final GlobalKey _expandingBottomSheetKey =
      GlobalKey(debugLabel: 'Expanding bottom sheet');

  Dispatcher dispatcher;
  StreamSubscription<String> _controlStreamSubscription;
  AppStateModel _model;

  // The width of the Material, calculated by _widthFor() & based on the number
  // of products in the cart. 64.0 is the width when there are 0 products
  // (_kWidthForZeroProducts)
  double _width = _kWidthForCartIcon;

  // Controller for the opening and closing of the ExpandingBottomSheet
  AnimationController _controller;

  // Animations for the opening and closing of the ExpandingBottomSheet
  Animation<double> _widthAnimation;
  Animation<double> _heightAnimation;
  Animation<double> _thumbnailOpacityAnimation;
  Animation<double> _cartOpacityAnimation;
  Animation<double> _shapeAnimation;
  Animation<Offset> _slideAnimation;

  @override
  void initState() {
    dispatcher.commandListeners.add(((str, [arg]) => _handleEvent(str)));

    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _handleEvent(String event) {
    debugPrint("Got new event: ${event}");
    switch (event) {
      case "openCart":
        open();
        break;
      case "closeCart":
        close();
        break;
      default:
        print("Unknown event ${event}");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _controlStreamSubscription?.cancel();
    super.dispose();
  }

  Animation<double> _getWidthAnimation(double screenWidth) {
    if (_controller.status == AnimationStatus.forward) {
      // Opening animation
      return Tween<double>(begin: _width, end: screenWidth).animate(
        CurvedAnimation(
          parent: _controller.view,
          curve: Interval(0.0, 0.3, curve: Curves.fastOutSlowIn),
        ),
      );
    } else {
      // Closing animation
      return _getEmphasizedEasingAnimation(
        begin: _width,
        peak: _getPeakPoint(begin: _width, end: screenWidth),
        end: screenWidth,
        isForward: false,
        parent: CurvedAnimation(
            parent: _controller.view, curve: Interval(0.0, 0.87)),
      );
    }
  }

  Animation<double> _getHeightAnimation(double screenHeight) {
    if (_controller.status == AnimationStatus.forward) {
      // Opening animation

      return _getEmphasizedEasingAnimation(
        begin: _kCartHeight,
        peak: _kCartHeight +
            (screenHeight - _kCartHeight) * _kPeakVelocityProgress,
        end: screenHeight,
        isForward: true,
        parent: _controller.view,
      );
    } else {
      // Closing animation
      return Tween<double>(
        begin: _kCartHeight,
        end: screenHeight,
      ).animate(
        CurvedAnimation(
          parent: _controller.view,
          curve: Interval(0.434, 1.0, curve: Curves.linear), // not used
          // only the reverseCurve will be used
          reverseCurve:
              Interval(0.434, 1.0, curve: Curves.fastOutSlowIn.flipped),
        ),
      );
    }
  }

  // Animation of the cut corner. It's cut when closed and not cut when open.
  Animation<double> _getShapeAnimation() {
    if (_controller.status == AnimationStatus.forward) {
      return Tween<double>(begin: _kCornerRadius, end: 0.0).animate(
        CurvedAnimation(
          parent: _controller.view,
          curve: Interval(0.0, 0.3, curve: Curves.fastOutSlowIn),
        ),
      );
    } else {
      return _getEmphasizedEasingAnimation(
        begin: _kCornerRadius,
        peak: _getPeakPoint(begin: _kCornerRadius, end: 0.0),
        end: 0.0,
        isForward: false,
        parent: _controller.view,
      );
    }
  }

  Animation<double> _getThumbnailOpacityAnimation() {
    return Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller.view,
        curve: _controller.status == AnimationStatus.forward
            ? Interval(0.0, 0.3)
            : Interval(0.532, 0.766),
      ),
    );
  }

  Animation<double> _getCartOpacityAnimation() {
    return CurvedAnimation(
      parent: _controller.view,
      curve: _controller.status == AnimationStatus.forward
          ? Interval(0.3, 0.6)
          : Interval(0.766, 1.0),
    );
  }

  // Returns the correct width of the ExpandingBottomSheet based on the number of
  // products in the cart.
  double _widthFor(int numProducts) {
    switch (numProducts) {
      case 0:
        return _kWidthForCartIcon;
        break;
      case 1:
        return 136.0;
        break;
      case 2:
        return 192.0;
        break;
      case 3:
        return 248.0;
        break;
      default:
        return 278.0;
    }
  }

  // Returns true if the cart is open or opening and false otherwise.
  bool get _isOpen {
    final AnimationStatus status = _controller.status;
    return status == AnimationStatus.completed ||
        status == AnimationStatus.forward;
  }

  // Opens the ExpandingBottomSheet if it's closed, otherwise does nothing.
  void open() {
    if (!_isOpen) {
      _controller.forward();
      _model.cartIsOpened();
    }
  }

  // Closes the ExpandingBottomSheet if it's open or opening, otherwise does nothing.
  void close() {
    if (_isOpen) {
      _controller.reverse();
      _model.cartIsClosed();
    }
  }

  // Changes the padding between the start edge of the Material and the cart icon
  // based on the number of products in the cart (padding increases when > 0
  // products.)
  EdgeInsetsDirectional _cartPaddingFor(int numProducts) {
    if (numProducts == 0) {
      return EdgeInsetsDirectional.only(start: 20.0, end: 8.0);
    } else {
      return EdgeInsetsDirectional.only(start: 32.0, end: 8.0);
    }
  }

  bool get _cartIsVisible => _thumbnailOpacityAnimation.value == 0.0;

  Widget _buildThumbnails(int numProducts) {
    return ExcludeSemantics(
      child: Opacity(
        opacity: _thumbnailOpacityAnimation.value,
        child: Column(children: <Widget>[
          Row(children: <Widget>[
            AnimatedPadding(
              padding: _cartPaddingFor(numProducts),
              child: Icon(Icons.shopping_cart),
              duration: Duration(milliseconds: 225),
            ),
            Container(
              // Accounts for the overflow number
              width: numProducts > 3 ? _width - 94.0 : _width - 64.0,
              height: _kCartHeight,
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: ProductThumbnailRow(),
            ),
            ExtraProductsNumber()
          ]),
        ]),
      ),
    );
  }

  Widget _buildShoppingCartPage() {
    return Opacity(
      opacity: _cartOpacityAnimation.value,
      child: ShoppingCartPage(),
    );
  }

  Widget _buildCart(BuildContext context, Widget child) {
    // numProducts is the number of different products in the cart (does not
    // include multiples of the same product).
    final AppStateModel model = ScopedModel.of<AppStateModel>(context);
    final int numProducts = model.productsInCart.keys.length;
    final int totalCartQuantity = model.totalCartQuantity;
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    _width = _widthFor(numProducts);
    _widthAnimation = _getWidthAnimation(screenWidth);
    _heightAnimation = _getHeightAnimation(screenHeight);
    _shapeAnimation = _getShapeAnimation();
    _thumbnailOpacityAnimation = _getThumbnailOpacityAnimation();
    _cartOpacityAnimation = _getCartOpacityAnimation();

    return Semantics(
      button: true,
      value: 'Shopping cart, $totalCartQuantity items',
      child: Container(
        width: _widthAnimation.value,
        height: _heightAnimation.value,
        child: Material(
          animationDuration: Duration(milliseconds: 0),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(_shapeAnimation.value),
            ),
          ),
          elevation: 4.0,
          color: kShrinePink50,
          child: _cartIsVisible
              ? _buildShoppingCartPage()
              : _buildThumbnails(numProducts),
        ),
      ),
    );
  }

  // Builder for the hide and reveal animation when the backdrop opens and closes
  Widget _buildSlideAnimation(BuildContext context, Widget child) {
    _slideAnimation = _getEmphasizedEasingAnimation(
      begin: Offset(1.0, 0.0),
      peak: Offset(_kPeakVelocityProgress, 0.0),
      end: Offset(0.0, 0.0),
      isForward: widget.hideController.status == AnimationStatus.forward,
      parent: widget.hideController,
    );

    return SlideTransition(
      position: _slideAnimation,
      child: child,
    );
  }

  // Closes the cart if the cart is open, otherwise exits the app (this should
  // only be relevant for Android).
  Future<bool> _onWillPop() async {
    if (!_isOpen) {
      await SystemNavigator.pop();
      return true;
    }

    close();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      key: _expandingBottomSheetKey,
      duration: Duration(milliseconds: 225),
      curve: Curves.easeInOut,
      vsync: this,
      alignment: FractionalOffset.topLeft,
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: AnimatedBuilder(
          animation: widget.hideController,
          builder: _buildSlideAnimation,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: open,
            child: ScopedModelDescendant<AppStateModel>(
              builder: (context, child, model) {
                _model = model;
                return AnimatedBuilder(
                  builder: _buildCart,
                  animation: _controller,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ProductThumbnailRow extends StatefulWidget {
  @override
  _ProductThumbnailRowState createState() => _ProductThumbnailRowState();
}

class _ProductThumbnailRowState extends State<ProductThumbnailRow> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  // _list represents what's currently on screen. If _internalList updates,
  // it will need to be updated to match it.
  _ListModel _list;

  // _internalList represents the list as it is updated by the AppStateModel.
  List<int> _internalList;

  @override
  void initState() {
    super.initState();
    _list = _ListModel(
      listKey: _listKey,
      initialItems:
          ScopedModel.of<AppStateModel>(context).productsInCart.keys.toList(),
      removedItemBuilder: _buildRemovedThumbnail,
    );
    _internalList = List<int>.from(_list.list);
  }

  Product _productWithId(int productId) {
    final AppStateModel model = ScopedModel.of<AppStateModel>(context);
    final Product product = model.getProductById(productId);
    assert(product != null);
    return product;
  }

  Widget _buildRemovedThumbnail(
      int item, BuildContext context, Animation<double> animation) {
    return ProductThumbnail(animation, animation, _productWithId(item));
  }

  Widget _buildThumbnail(
      BuildContext context, int index, Animation<double> animation) {
    Animation<double> thumbnailSize =
        Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        curve: Interval(0.33, 1.0, curve: Curves.easeIn),
        parent: animation,
      ),
    );

    Animation<double> opacity = CurvedAnimation(
      curve: Interval(0.33, 1.0, curve: Curves.linear),
      parent: animation,
    );

    return ProductThumbnail(
        thumbnailSize, opacity, _productWithId(_list[index]));
  }

  // If the lists are the same length, assume nothing has changed.
  // If the internalList is shorter than the ListModel, an item has been removed.
  // If the internalList is longer, then an item has been added.
  void _updateLists() {
    // Update _internalList based on the model
    _internalList =
        ScopedModel.of<AppStateModel>(context).productsInCart.keys.toList();
    Set<int> internalSet = Set<int>.from(_internalList);
    Set<int> listSet = Set<int>.from(_list.list);

    Set<int> difference = internalSet.difference(listSet);
    if (difference.isEmpty) {
      return;
    }

    difference.forEach((product) {
      if (_internalList.length < _list.length) {
        _list.remove(product);
      } else if (_internalList.length > _list.length) {
        _list.add(product);
      }
    });

    while (_internalList.length != _list.length) {
      int index = 0;
      // Check bounds and that the list elements are the same
      while (_internalList.isNotEmpty &&
          _list.length > 0 &&
          index < _internalList.length &&
          index < _list.length &&
          _internalList[index] == _list[index]) {
        index++;
      }
    }
  }

  Widget _buildAnimatedList() {
    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      itemBuilder: _buildThumbnail,
      initialItemCount: _list.length,
      scrollDirection: Axis.horizontal,
      physics: NeverScrollableScrollPhysics(), // Cart shouldn't scroll
    );
  }

  @override
  Widget build(BuildContext context) {
    _updateLists();
    return ScopedModelDescendant<AppStateModel>(
      builder: (context, child, model) => _buildAnimatedList(),
    );
  }
}

class ExtraProductsNumber extends StatelessWidget {
  // Calculates the number to be displayed at the end of the row if there are
  // more than three products in the cart. This calculates overflow products,
  // including their duplicates (but not duplicates of products shown as
  // thumbnails).
  int _calculateOverflow(AppStateModel model) {
    Map<int, int> productMap = model.productsInCart;
    // List created to be able to access products by index instead of ID.
    // Order is guaranteed because productsInCart returns a LinkedHashMap.
    List<int> products = productMap.keys.toList();
    int overflow = 0;
    int numProducts = products.length;
    if (numProducts > 3) {
      for (int i = 3; i < numProducts; i++) {
        overflow += productMap[products[i]];
      }
    }
    return overflow;
  }

  Widget _buildOverflow(AppStateModel model, BuildContext context) {
    if (model.productsInCart.length > 3) {
      int numOverflowProducts = _calculateOverflow(model);
      // Maximum of 99 so padding doesn't get messy.
      int displayedOverflowProducts =
          numOverflowProducts <= 99 ? numOverflowProducts : 99;
      return Container(
        child: Text(
          '+$displayedOverflowProducts',
          style: Theme.of(context).primaryTextTheme.button,
        ),
      );
    } else {
      return Container(); // build() can never return null.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<AppStateModel>(
      builder: (builder, child, model) => _buildOverflow(model, context),
    );
  }
}

class ProductThumbnail extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> opacityAnimation;
  final Product product;

  ProductThumbnail(this.animation, this.opacityAnimation, this.product);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacityAnimation,
      child: ScaleTransition(
        scale: animation,
        child: Container(
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: ExactAssetImage(
                product.assetName, // asset name
                package: product.assetPackage, // asset package
              ),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          margin: EdgeInsets.only(left: 16.0),
        ),
      ),
    );
  }
}

// _ListModel manipulates an internal list and an AnimatedList
class _ListModel {
  _ListModel(
      {@required this.listKey,
      @required this.removedItemBuilder,
      Iterable<int> initialItems})
      : assert(listKey != null),
        assert(removedItemBuilder != null),
        _items = List<int>.from(initialItems ?? <int>[]);

  final GlobalKey<AnimatedListState> listKey;
  final dynamic removedItemBuilder;
  final List<int> _items;

  AnimatedListState get _animatedList => listKey.currentState;

  void add(int product) {
    _insert(_items.length, product);
  }

  void _insert(int index, int item) {
    _items.insert(index, item);
    _animatedList.insertItem(index, duration: Duration(milliseconds: 225));
  }

  void remove(int product) {
    final int index = _items.indexOf(product);
    if (index >= 0) {
      _removeAt(index);
    }
  }

  void _removeAt(int index) {
    final int removedItem = _items.removeAt(index);
    if (removedItem != null) {
      _animatedList.removeItem(index,
          (BuildContext context, Animation<double> animation) {
        return removedItemBuilder(removedItem, context, animation);
      });
    }
  }

  int get length => _items.length;

  int operator [](int index) => _items[index];

  int indexOf(int item) => _items.indexOf(item);

  List<int> get list => _items;
}

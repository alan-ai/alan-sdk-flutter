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

import 'package:alan_voice/alan_voice.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import 'backdrop.dart';
import 'category_menu_page.dart';
import 'colors.dart';
import 'expanding_bottom_sheet.dart';
import 'home.dart';
import 'model/app_state_model.dart';
import 'model/product.dart';
import 'order_confirm.dart';
import 'supplemental/cut_corners_border.dart';

class ShrineApp extends StatefulWidget {
  static final navKey = new GlobalKey<NavigatorState>();

  @override
  _ShrineAppState createState() => _ShrineAppState();
}

class _ShrineAppState extends State<ShrineApp>
    with SingleTickerProviderStateMixin {
  // Controller to coordinate both the opening/closing of backdrop and sliding
  // of expanding bottom sheet.
  AnimationController _controller;

  AppStateModel _model;

  Backdrop _backdrop;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: Duration(milliseconds: 450), value: 1.0);

    AlanVoice.addButton(
        "23f609792aedd5734d0bf347580da6fd2e956eca572e1d8b807a3e2338fdd0dc/prod",
      buttonAlign: AlanVoice.BUTTON_ALIGN_LEFT
    );
    _printVersion();

    AlanVoice.callbacks.add((command) => _handleCommand(command.data));
    AlanVoice.addConnectionCallback((state) => _handleConnectionState(state));
  }

  Backdrop _initBackdrop() {
    _backdrop =  Backdrop(
      frontLayer: ProductPage(),
      backLayer: CategoryMenuPage(
          onCategoryTap: (categoryName) => {
            _controller.forward(),
            //                      _model.menuIsClosed()
          }),
      frontTitle: Text('SHRINE'),
      backTitle: Text('MENU'),
      controller: _controller,
      dispatcher: _model.dispatcher,
    );
    return _backdrop;
  }

  //Resend visuals in case of disconnect from tutor
  void _handleConnectionState(String state) {
    if (state == "CONNECTED") {
      _model.setVisuals();
    }
  }

  void _handleCommand(Map<String, dynamic> command) {
    debugPrint("New command: ${command}");
    switch (command["command"]) {
      case "clearOrder":
        _handleClearOrder();
        break;
      case "addToCart":
        _addToCart(command["item"], command["quantity"]);
        break;
      case "removeFromCart":
        _removeFromCart(command["item"], command["quantity"]);
        break;
      case "highlightProducts":
        _highlightProduct(command["value"]);
        break;
      case "screen":
        _navigateTo(command["data"]);
        break;
      case "navigation":
        _navigateTo(command["route"]);
        break;
      case "highlight":
        _highlightWidget(command["value"]);
        break;
      case "show_products":
        _filterProducts(command["items"]);
        break;
      case "finishOrder":
        _handleFinishOrder();
        break;
      default:
        debugPrint("Unknown command: ${command}");
    }
  }

  void _filterProducts(List<dynamic> items) {
    List<int> products = items.cast();
    _model.filterProductsById(products);
  }

  void _handleFinishOrder() {
    _model.clearCart();
    _model.dispatcher.closeCart();

    final materialContext = ShrineApp.navKey.currentState.overlay.context;
    showDialog(
      context: materialContext,
      builder: (BuildContext context) => OrderConfirmDialog(),
    );
    new Timer(const Duration(seconds: 2), () => Navigator.pop(materialContext));
  }

  void _highlightWidget(String name) {
    _model.highlightValue(name);
  }

  void _navigateTo(String screen) {
    switch (screen) {
      case "/all":
        _openCategory(Category.all);
        break;
      case "/accessories":
        _openCategory(Category.accessories);
        break;
      case "/clothing":
        _openCategory(Category.clothing);
        break;
      case "/home":
        _openCategory(Category.home);
        break;
      case "/cart":
        _model.dispatcher.openCart();
        break;
      case "/menu":
        _model.dispatcher.openMenu();
        break;
      case "back":
        _model.dispatcher.closeCart();
        _model.dispatcher.closeMenu();
        break;
      default:
        print("Unknown screen: $screen");
    }
  }

  void _openCategory(Category category) {
    _model.dispatcher.closeCart();
    _model.dispatcher.closeMenu();
    _model.setCategory(category);
  }

  void _highlightProduct(int id) {
    _model.deHighlight();
    if (id != null) {
      _model.highlightProduct(id);
      _model.dispatcher.scrollTo(id);
    }
  }

  void _handleClearOrder() {
    _model.clearCart();
  }

  void _addToCart(int itemId, int quantity) {
    _model.addProductToCart(itemId, quantity);
  }

  void _removeFromCart(int itemId, int quantity) {
    _model.removeItemFromCart(itemId, quantity);
  }

  void _printVersion() async {
    var version = await AlanVoice.version;
    debugPrint(version);
  }

  @override
  Widget build(BuildContext context) {

    return ScopedModelDescendant<AppStateModel>(
        builder: (context, child, model) {
      _model = model;
      _backdrop = _initBackdrop();
      return MaterialApp(
        navigatorKey: ShrineApp.navKey,
        title: 'Shrine',
        home: HomePage(
          backdrop: _backdrop,
          expandingBottomSheet: ExpandingBottomSheet(
            hideController: _controller,
            dispatcher: _model.dispatcher,
          ),
        ),
        initialRoute: '/',
        onGenerateRoute: _getRoute,
        theme: _kShrineTheme,
      );
    });
  }
}

Route<dynamic> _getRoute(RouteSettings settings) {
  return null;
}

final ThemeData _kShrineTheme = _buildShrineTheme();

IconThemeData _customIconTheme(IconThemeData original) {
  return original.copyWith(color: kShrineBrown900);
}

ThemeData _buildShrineTheme() {
  final ThemeData base = ThemeData.light();
  return base.copyWith(
    colorScheme: kShrineColorScheme,
    // accentColor: kShrineBrown900,
    primaryColor: kShrinePink100,
    // buttonColor: kShrinePink100,
    scaffoldBackgroundColor: kShrineBackgroundWhite,
    cardColor: kShrineBackgroundWhite,
    // textSelectionColor: kShrinePink100,
    errorColor: kShrineErrorRed,
    buttonTheme: const ButtonThemeData(
      colorScheme: kShrineColorScheme,
      textTheme: ButtonTextTheme.normal,
    ),
    primaryIconTheme: _customIconTheme(base.iconTheme),
    inputDecorationTheme:
        const InputDecorationTheme(border: CutCornersBorder()),
    textTheme: _buildShrineTextTheme(base.textTheme),
    primaryTextTheme: _buildShrineTextTheme(base.primaryTextTheme),
    // accentTextTheme: _buildShrineTextTheme(base.accentTextTheme),
    iconTheme: _customIconTheme(base.iconTheme),
  );
}

TextTheme _buildShrineTextTheme(TextTheme base) {
  return base
      .copyWith(
        headlineLarge: base.headlineLarge.copyWith(fontWeight: FontWeight.w500),
        titleLarge: base.titleLarge.copyWith(fontSize: 18.0),
        // caption: base.caption.copyWith(
        //   fontWeight: FontWeight.w400,
        //   fontSize: 14.0,
        // ),
        bodyLarge: base.bodyLarge.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 16.0,
        ),
        // button: base.button.copyWith(
        //   fontWeight: FontWeight.w500,
        //   fontSize: 14.0,
        // ),
      )
      .apply(
        fontFamily: 'Rubik',
        displayColor: kShrineBrown900,
        bodyColor: kShrineBrown900,
      );
}

const ColorScheme kShrineColorScheme = ColorScheme(
  primary: kShrinePink100,
  // primaryVariant: kShrineBrown900,
  secondary: kShrinePink50,
  // secondaryVariant: kShrineBrown900,
  surface: kShrineSurfaceWhite,
  background: kShrineBackgroundWhite,
  error: kShrineErrorRed,
  onPrimary: kShrineBrown900,
  onSecondary: kShrineBrown900,
  onSurface: kShrineBrown900,
  onBackground: kShrineBrown900,
  onError: kShrineSurfaceWhite,
  brightness: Brightness.light,
);

// copyright 2018-present the flutter authors. all rights reserved.
//
// licensed under the apache license, version 2.0 (the "license");
// you may not use this file except in compliance with the license.
// you may obtain a copy of the license at
//
// http://www.apache.org/licenses/license-2.0
//
// unless required by applicable law or agreed to in writing, software
// distributed under the license is distributed on an "as is" basis,
// without warranties or conditions of any kind, either express or implied.
// see the license for the specific language governing permissions and
// limitations under the license.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scoped_model/scoped_model.dart';

import 'app.dart';
import 'model/app_state_model.dart';

void main() {
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  var model = AppStateModel();
  model.loadProducts();

  model.addListener(() => {
    model.setCurrentVisuals()
  });

  runApp(
    ScopedModel<AppStateModel>(
      model: model,
      child: ShrineApp(),
    )
  );
}
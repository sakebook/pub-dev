// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub_package_reader/pub_package_reader.dart'
    show reducePackageName;

/// Package names that are reserved for the Dart or Flutter team.
final _reservedPackageNames = <String>[
  'core',
  'dart',
  'dart2js',
  'dart2native',
  'dartanalyzer',
  'dartaotruntime',
  'dartdevc',
  'dartfmt',
  'flutter_web',
  'flutter_web_test',
  'flutter_web_ui',
  'google_maps_flutter',
  'hummingbird',
  'in_app_purchase',
  'location_background',
  'math',
  'mirrors',
  'developer',
  'pub',
  'versions',
  'webview_flutter',
  'firebaseui',
  // removed in https://github.com/dart-lang/pub-dev/issues/2853
  'fluttery',
  'fluttery_audio',
  'fluttery_seekbar',
].map(reducePackageName).toList();

/// 'internal' packages are developed by the Dart team, and they are allowed to
/// point their URLs to *.dartlang.org (others would get a penalty for it).
const internalPackageNames = <String>[
  'angular',
  'angular_components',
];

const redirectPackageUrls = <String, String>{
  'flutter': 'https://api.flutter.dev/',
  'flutter_driver':
      'https://api.flutter.dev/flutter/flutter_driver/flutter_driver-library.html',
  'flutter_driver_extension':
      'https://api.flutter.dev/flutter/flutter_driver_extension/flutter_driver_extension-library.html',
  'flutter_localizations':
      'https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html',
  'flutter_test':
      'https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html',
  'flutter_web_plugins':
      'https://api.flutter.dev/flutter/package-flutter_web_plugins_flutter_web_plugins/package-flutter_web_plugins_flutter_web_plugins-library.html',
};

/// Known packages that should be put in `dev_dependencies`
///
/// This is a temporary hack that should be removed when INSTALL.md extraction
/// is implemented: https://github.com/dart-lang/pub-dev/issues/3403
const devDependencyPackages = <String>{
  'build_runner',
  'build_test',
  'build_verify',
  'build_web_compilers',
  'flutter_lints',
  'lint',
  'lints',
  'test',
  'test_descriptor',
  'test_process',
};

// TODO: remove this after all of the flutter plugins have a proper issue tracker entry in their pubspec.yaml
const _issueTrackerUrlOverrides = <String, String>{
  'https://github.com/flutter/plugins/issues':
      'https://github.com/flutter/flutter/issues',
};

String? overrideIssueTrackerUrl(String? url) {
  if (url == null) {
    return null;
  }
  return _issueTrackerUrlOverrides[url] ?? url;
}

/// A package is soft-removed when we keep it in the archives and index, but we
/// won't serve the package or the documentation page, or any data about it.
bool isSoftRemoved(String packageName) =>
    redirectPackageUrls.containsKey(packageName);

/// Whether the [name] is (very similar) to a reserved package name.
bool matchesReservedPackageName(String name) =>
    _reservedPackageNames.contains(reducePackageName(name));

/// Whether the [publisherId] is part of dart.dev.
/// Packages under dart.dev are considered 'internal', and allowed to have homepage
/// URLs pointing to e.g. dart.dev.
bool isDartDevPublisher(String? publisherId) {
  if (publisherId == null) return false;
  if (publisherId == 'dart.dev') return true;
  if (publisherId.endsWith('.dart.dev')) return true;
  if (publisherId == 'flutter.dev') return true;
  if (publisherId.endsWith('.flutter.dev')) return true;
  if (publisherId.endsWith('.google.com')) return true;
  return false;
}

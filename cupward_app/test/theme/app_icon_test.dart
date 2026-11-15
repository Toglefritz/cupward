import 'dart:io';

import 'package:cupward/theme/app_icon.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the paths in [AppIcon], which are the single place where icon assets are named.
void main() {
  /// Two icons with one path would show the same image, which is almost always a copy-and-paste mistake.
  test('every icon has its own path', () {
    final Set<String> paths = AppIcon.values.map((AppIcon icon) => icon.path).toSet();

    expect(paths, hasLength(AppIcon.values.length));
  });

  /// The enum documents that icons live in assets/icons/, which is the directory that pubspec.yaml must list.
  test('every path is in assets/icons', () {
    for (final AppIcon icon in AppIcon.values) {
      expect(icon.path, startsWith('assets/icons/'), reason: icon.name);
    }
  });

  /// A path with no file behind it fails only when a screen draws the icon, so every path is checked here.
  test('every path points to an existing file', () {
    for (final AppIcon icon in AppIcon.values) {
      expect(File(icon.path).existsSync(), isTrue, reason: '${icon.name}: ${icon.path}');
    }
  });
}

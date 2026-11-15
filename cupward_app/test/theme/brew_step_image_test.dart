import 'dart:io';

import 'package:cupward/theme/brew_step_image.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the paths in [BrewStepImage], which are the single place where the brewing screen's illustrations are
/// named.
void main() {
  /// A path with no file behind it fails only when a step shows the image, so every path is checked here.
  test('every path points to an existing file', () {
    for (final BrewStepImage image in BrewStepImage.values) {
      expect(File(image.path).existsSync(), isTrue, reason: '${image.name}: ${image.path}');
    }
  });

  /// Two steps with one path would show the same picture, which is almost always a copy-and-paste mistake.
  test('every image has its own path', () {
    final Set<String> paths = BrewStepImage.values.map((BrewStepImage image) => image.path).toSet();

    expect(paths, hasLength(BrewStepImage.values.length));
  });
}

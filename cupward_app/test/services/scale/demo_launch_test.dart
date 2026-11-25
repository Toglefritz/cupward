import 'package:cupward/services/scale/demo_launch.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies which web addresses start the app in demo mode.
void main() {
  group('DemoLaunch.isRequested', () {
    /// The documented link must work.
    test('accepts demo=true and demo=1', () {
      expect(DemoLaunch.isRequested(Uri.parse('https://cupward-2b4bc.web.app/?demo=true')), isTrue);
      expect(DemoLaunch.isRequested(Uri.parse('https://cupward-2b4bc.web.app/?demo=1')), isTrue);
    });

    /// A bare `?demo` and any letter case are friendly to type by hand.
    test('accepts a bare demo and any letter case', () {
      expect(DemoLaunch.isRequested(Uri.parse('https://cupward-2b4bc.web.app/?demo')), isTrue);
      expect(DemoLaunch.isRequested(Uri.parse('https://cupward-2b4bc.web.app/?demo=TRUE')), isTrue);
    });

    /// Demo mode stays off unless it is asked for.
    test('rejects a missing parameter and other values', () {
      expect(DemoLaunch.isRequested(Uri.parse('https://cupward-2b4bc.web.app/')), isFalse);
      expect(DemoLaunch.isRequested(Uri.parse('https://cupward-2b4bc.web.app/?demo=false')), isFalse);
      expect(DemoLaunch.isRequested(Uri.parse('https://cupward-2b4bc.web.app/?other=true')), isFalse);
    });

    /// The parameter is kept when other parameters are present.
    test('finds the parameter among others', () {
      expect(DemoLaunch.isRequested(Uri.parse('https://cupward-2b4bc.web.app/?a=b&demo=true')), isTrue);
    });
  });
}

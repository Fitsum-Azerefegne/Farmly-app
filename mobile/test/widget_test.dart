import 'package:flutter_test/flutter_test.dart';
import 'package:farmly/main.dart';

void main() {
  test('Farmly app root is available', () {
    const app = FarmlyApp();

    expect(app, isA<FarmlyApp>());
  });
}

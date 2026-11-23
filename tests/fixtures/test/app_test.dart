import 'package:flutter_test/flutter_test.dart';
import 'package:test_app/sign.dart';

void main() {
  test('positive', () => expect(sign(1), 1));
  test('generated', () {
    const p = Point(x: 1, y: 2);
    expect(Point.fromJson(p.toJson()), p);
  });
}

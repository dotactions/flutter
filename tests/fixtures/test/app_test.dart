import 'package:flutter_test/flutter_test.dart';
import 'package:test_app/sign.dart';
import 'package:test_app/sign.freezed.dart';
import 'package:test_app/sign.g.dart';

void main() {
  test('positive', () => expect(sign(1), 1));
  test('generated', () => expect(generated() + frozen(), 49));
}

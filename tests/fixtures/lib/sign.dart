import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign.freezed.dart';
part 'sign.g.dart';

int sign(int n) {
  if (n >= 0) {
    return 1;
  }
  return -1;
}

@freezed
abstract class Point with _$Point {
  const factory Point({required int x, required int y}) = _Point;

  factory Point.fromJson(Map<String, dynamic> json) => _$PointFromJson(json);
}

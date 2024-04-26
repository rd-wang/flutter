import 'package:sprintf/sprintf.dart';

extension NullableStringExtension on String? {
  /// 判断字符串空或null
  bool isNullOrEmpty() {
    return this?.isEmpty ?? true;
  }

  /// 判断字符串非空或非null
  bool isNotNullOrEmpty() {
    return this?.isNotEmpty ?? false;
  }

  /// 判断字符串非空且大于0
  bool isNotNullOrGreaterZero() {
    return this != null && this!.length > 0;
  }

  /// 返回自身或空字符串
  String orEmptyString() => this ?? '';
}

extension StringExtension on String {
  /// 格式化字符串
  /// Text("number %d %.2f".format([21, 22.3])),
  /// Text("string %s".format(["test"])),
  /// Text("string number %s %d".format(["test", 0])),
  String format(List<dynamic> args) => sprintf(this, args);
}

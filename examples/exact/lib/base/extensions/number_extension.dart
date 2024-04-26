import 'package:exact/base/utils/date_util.dart';

@Deprecated('method name is not standard')
extension NullableNumberExtension on num? {
  /// 判断number空或0
  bool isNullOrZero() {
    return this == null || this == 0;
  }

  /// 判断number非空或0
  bool isNotNullOrZero() {
    return this != null || this != 0;
  }

  /// 判断number非空且大于0
  bool isNotNullOrGreaterZero() {
    return this != null && this! > 0;
  }
}

extension NumberExtension on num {}

extension IntExt on int? {
  /// 1小时2分20秒
  String toHHMMSS() {
    if (this == null) {
      return "";
    }
    var temp = (this ?? 0) * TimeConstants.second;
    int hours = temp ~/ TimeConstants.hour;
    temp -= hours * TimeConstants.hour;
    int minutes = temp ~/ TimeConstants.minute;
    temp -= minutes * TimeConstants.minute;
    int seconds = temp ~/ TimeConstants.second;
    return "$hours${"时"}$minutes${"分"}$seconds${"秒"}";
  }

  String toMMdd() {
    if (this != null) {
      var date = DateTime.fromMillisecondsSinceEpoch(this ?? 0);

      /// 英文格式较复杂
      return "${date.month}月${date.day}日";
    }
    return "";
  }

  /// 01:22:32
  String toHHMMSS2() {
    if (this != null) {
      return DateUtil.formatDateToString(this ?? 0, "HH:mm:ss");
    }
    return "";
  }
}

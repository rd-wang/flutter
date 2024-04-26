import 'package:intl/intl.dart';

/// 日期工具类
class DateUtil {
  static String formatDateToString(int timestamp, String format) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat(format).format(dateTime);
  }

  /// 获取时区：GMT+8:00
  static String getTimeZone() {
    var offsetHours = DateTime.now().timeZoneOffset.inHours;
    var symbol = "";
    if (offsetHours >= 0) {
      symbol = "+";
    } else {
      symbol = "-";
    }
    return "GMT$symbol${offsetHours.toString().padLeft(2, '0')}:00";
  }
}

class TimeConstants {
  static const millSecond = 1;
  static const second = 1000 * millSecond;
  static const minute = 60 * second;
  static const hour = 60 * minute;
  static const day = 24 * hour;
}

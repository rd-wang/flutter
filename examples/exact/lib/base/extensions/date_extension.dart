import 'package:intl/intl.dart';

extension DateTimeExt on DateTime? {
  String formatContent(String formatTemplate, {String defaultStr = "00:00"}) {
    if (this == null) {
      return defaultStr;
    }
    return DateFormat(formatTemplate).format(this!);
  }
}

extension TimeStampExt on int? {
  String toDateContent(String formatTemplate) {
    if (this == null) {
      return "";
    }

    DateTime? dateTime;
    if (this.toString().length == 13) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(this!);
    } else if (this.toString().length == 16) {
      dateTime = DateTime.fromMicrosecondsSinceEpoch(this!);
    }

    return dateTime.formatContent(formatTemplate);
  }
}

enum DurationType {
  day,
  week,
  month,
}

extension DateRangeExtensions on DateTime {
  bool isSameDay(DateTime other) => year == other.year && month == other.month && day == other.day;

  bool get isToday => DateTime.now().isSameDay(this);

  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  DateTime get startOfWeek => subtract(Duration(days: weekday - 1)).startOfDay;

  DateTime get endOfWeek => add(Duration(days: 7 - weekday)).endOfDay;

  DateTime get startOfMonth => DateTime(year, month, 1);

  DateTime get endOfMonth => DateTime(year, month + 1, 0).endOfDay;

  DateTime minus(int n, {DurationType type = DurationType.day}) {
    switch (type) {
      case DurationType.day:
        return DateTime(year, month, day - n, hour, minute, second, millisecond);
      case DurationType.week:
        return DateTime(year, month, day - 7 * n, hour, minute, second, millisecond);
      case DurationType.month:
        return DateTime(year, month - n, day, hour, minute, second, millisecond);
    }
  }

  DateTime plus(int n, {DurationType type = DurationType.day}) {
    switch (type) {
      case DurationType.day:
        return DateTime(year, month, day + n, hour, minute, second, millisecond);
      case DurationType.week:
        return DateTime(year, month, day + 7 * n, hour, minute, second, millisecond);
      case DurationType.month:
        return DateTime(year, month + n, day, hour, minute, second, millisecond);
    }
  }

  String formatYMD() => DateFormat("yyyy-MM-dd").format(this);

  String formatFull() => DateFormat("yyyy-MM-dd HH:mm:ss.SSS").format(this);
}

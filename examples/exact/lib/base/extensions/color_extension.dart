import 'package:flutter/material.dart';
import 'dart:math' as math;

extension Random on Color {
  static Color randomOpaqueColor() {
    return Color(math.Random().nextInt(0xffffffff)).withAlpha(0xff);
  }

  static Color randomColor() {
    return Color(math.Random().nextInt(0xffffffff));
  }
}

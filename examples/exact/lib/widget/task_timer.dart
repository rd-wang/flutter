import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';

class TaskTimer {
  /// 计数
  int _seconds = 0;

  /// 定时器
  Timer? _timer;

  ValueNotifier<int> totalSeconds = ValueNotifier(0);

  int initSeconds;

  /// 当前秒数
  int get currentSeconds => initSeconds + _seconds;

  /// 计时中
  ValueNotifier<bool> isTiming = ValueNotifier(false);

  TaskTimer({this.initSeconds = 0});

  /// 开启定时器
  void startTimer() {
    if (_timer != null) {
      destroyTimer();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds = timer.tick;
      // print("tick:${timer.tick}");
      _updateSeconds();
    });
    isTiming.value = true;
    _updateSeconds();
  }

  /// 更新秒数
  void _updateSeconds() {
    totalSeconds.value = _seconds + initSeconds;
  }

  /// 销毁定时器
  void destroyTimer() {
    _timer?.cancel();
    _timer = null;
    initSeconds = 0;
    _seconds = 0;
    isTiming.value = false;
  }

  String timeString(int seconds) {
    final second = seconds % 60;
    final minutes = seconds ~/ 60;
    final minute = minutes % 60;
    final hour = minutes ~/ 60;
    // debugPrint(sprintf("%02d:%02d:%02d", [hour, minute, second]));
    return sprintf("%02d:%02d:%02d", [hour, minute, second]);
  }
}

import 'dart:async';

import 'package:awesome_notifications/android_foreground_service.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:exact/base/base/base_controller.dart';
import 'package:exact/base/notifications/notifications_controller.dart';
import 'package:exact/base/notifications/utils/common_functions.dart'
    if (dart.library.html) 'package:exact/base/notifications/utils/common_web_functions.dart';
import 'package:get/get.dart';
import 'package:vibration/vibration.dart';

import '../../base/notifications/notifications_util.dart';
import 'repo_call.dart';

class CallController extends RrController<CallRepo> {
  late ReceivedAction receivedAction;
  Timer? timer;
  var secondsElapsed = Duration.zero.obs;

  @override
  onInit() {
    receivedAction = Get.arguments ?? NotificationsController.initialCallAction;
    super.onInit();
    repo.loadNothing();
    lockScreenPortrait();
    if (receivedAction.buttonKeyPressed == 'ACCEPT') {
      startCallingTimer();
    }
  }

  @override
  void onClose() {
    timer?.cancel();
    unlockScreenPortrait();
    NotificationUtils.cancelNotification(receivedAction.id!);
    AndroidForegroundService.stopForeground(receivedAction.id!);
    super.onClose();
  }

  void startCallingTimer() {
    const oneSec = Duration(seconds: 1);
    NotificationUtils.cancelNotification(receivedAction.id!);
    AndroidForegroundService.stopForeground(receivedAction.id!);

    timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        secondsElapsed.value += oneSec;
      },
    );
  }

  void finishCall() {
    Vibration.vibrate(duration: 100);
    NotificationUtils.cancelNotification(receivedAction.id!);
    AndroidForegroundService.stopForeground(receivedAction.id!);
    Get.back();
  }
}

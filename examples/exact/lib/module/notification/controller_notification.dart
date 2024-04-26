import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:exact/base/base/base_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../base/notifications/notifications_util.dart';
import '../../widget/infinite_listview/number_picker.dart';
import 'repo_notification.dart';

class NotificationPageController extends RrController<NotificationRepo> {
  @override
  onInit() {
    super.onInit();
    repo.loadNothing();
    for (NotificationPermission permission in channelPermissions) {
      scheduleChannelPermissions[permission] = false;
    }

    for (NotificationPermission permission in dangerousPermissions) {
      dangerousPermissionsStatus[permission] = false;
    }

    refreshPermissionsIcons().then((_) => NotificationUtils.requestBasicPermissionToSendNotifications().then((allowed) {
          if (allowed != globalNotificationsAllowed) refreshPermissionsIcons();
        }));
  }

  var delayLEDTests = false.obs;
  var secondsToWakeUp = 5.0.obs;
  var secondsToCallCategory = 5.0.obs;

  var globalNotificationsAllowed = false.obs;
  var schedulesFullControl = false.obs;
  var isCriticalAlertsEnabled = false.obs;
  var isPreciseAlarmEnabled = false.obs;
  var isOverrideDnDEnabled = false.obs;

  Map<NotificationPermission, bool> scheduleChannelPermissions = {};
  Map<NotificationPermission, bool> dangerousPermissionsStatus = {};

  List<NotificationPermission> channelPermissions = [
    NotificationPermission.Alert,
    NotificationPermission.Sound,
    NotificationPermission.Badge,
    NotificationPermission.Light,
    NotificationPermission.Vibration,
    NotificationPermission.CriticalAlert,
    NotificationPermission.FullScreenIntent
  ];

  List<NotificationPermission> dangerousPermissions = [
    NotificationPermission.CriticalAlert,
    NotificationPermission.OverrideDnD,
    NotificationPermission.PreciseAlarms,
  ];

  String packageName = 'me.carda.awesome_notifications_example';

  var _pickAmount = 50.obs;

  Future<int?> pickBadgeCounter(int initialAmount) async {
    _pickAmount.value = initialAmount;
    // show the dialog
    return Get.dialog(AlertDialog(
      title: const Text("Choose the new badge amount"),
      content: NumberPicker(
          value: _pickAmount.value, minValue: 0, maxValue: 9999, onChanged: (newValue) => _pickAmount.value = newValue),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () {
            Get.back();
          },
        ),
        TextButton(
          child: const Text("OK"),
          onPressed: () {
            Get.back(result: _pickAmount.value);
          },
        ),
      ],
    ));
  }

  Future<void> refreshPermissionsIcons() async {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) async {
      globalNotificationsAllowed.value = isAllowed;
    });
    refreshScheduleChannelPermissions();
    refreshDangerousChannelPermissions();
  }

  void refreshScheduleChannelPermissions() {
    AwesomeNotifications()
        .checkPermissionList(channelKey: 'scheduled', permissions: channelPermissions)
        .then((List<NotificationPermission> permissionsAllowed) {
      schedulesFullControl.value = true;
      for (NotificationPermission permission in channelPermissions) {
        scheduleChannelPermissions[permission] = permissionsAllowed.contains(permission);
        schedulesFullControl.value = schedulesFullControl.value && scheduleChannelPermissions[permission]!;
      }
    });
  }

  void refreshDangerousChannelPermissions() {
    AwesomeNotifications()
        .checkPermissionList(permissions: dangerousPermissions)
        .then((List<NotificationPermission> permissionsAllowed) {
      for (NotificationPermission permission in dangerousPermissions) {
        dangerousPermissionsStatus[permission] = permissionsAllowed.contains(permission);
      }
      isCriticalAlertsEnabled.value = dangerousPermissionsStatus[NotificationPermission.CriticalAlert]!;
      isPreciseAlarmEnabled.value = dangerousPermissionsStatus[NotificationPermission.PreciseAlarms]!;
      isOverrideDnDEnabled.value = dangerousPermissionsStatus[NotificationPermission.OverrideDnD]!;
    });
  }
}

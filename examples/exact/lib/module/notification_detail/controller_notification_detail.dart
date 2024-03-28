import 'package:exact/base/base/base_controller.dart';
import 'repo_notification_detail.dart';

class NotificationDetailPageController extends RrController<NotificationDetailRepo> {
  @override
  onInit() {
    super.onInit();
    repo.loadNothing();
  }
}

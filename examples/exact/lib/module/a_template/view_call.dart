import 'package:exact/base/base/base_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../base/config/translations/strings_enum.dart';
import 'controller_call.dart';

class CallView extends RrView<CallController> {
  CallView({super.key});

  @override
  String setTitle() {
    return Strings.notification.tr;
  }

  @override
  bool isShowDefaultAppBar() {
    return false;
  }

  @override
  Widget buildContent(BuildContext context) {
    return Container();
  }
}

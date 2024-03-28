import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'test_logic.dart';

class TestWidget extends StatelessWidget {
  const TestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<TestLogic>();

    return Container();
  }
}

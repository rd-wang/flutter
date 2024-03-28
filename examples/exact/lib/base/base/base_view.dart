import 'package:exact/base/components/widgets_state_change_animator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../components/api_error_widget.dart';
import 'base_controller.dart';

///注册子类传入的controller 注册类型为子类泛型为 ，
///若多个公用的controller 则需要额外传入tag  find<S>(tag: tag)
///根据controller中的data状态渲染不同的页面
abstract class RrView<T extends RrController> extends GetView<T> {
  //
  // RrView(T t, {String? tag, super.key}) {
  //   Get.put<T>(t, tag: tag);
  // }

  // get repo => controller.repo;
  final String title = "RrView";

  const RrView({super.key});

  bool isShowDefaultAppBar() {
    return true;
  }

  String setTitle() {
    return title;
  }

  @override
  Widget build(BuildContext context) {
    if (isShowDefaultAppBar()) {
      return Scaffold(
          appBar: AppBar(
            title: Text(setTitle()),
          ),
          body: _buildView(context));
    }
    return Scaffold(body: _buildView(context));
  }

  Widget _buildView(BuildContext context) {
    return Obx(() {
      return RrLoadingStateWidgetsAnimator(
        apiCallStatus: controller.pageState.value,
        animationDuration: const Duration(milliseconds: 1500),
        loadingWidget: () => buildLoading(context),
        errorWidget: () => buildContent(context),
        successWidget: () => buildContent(context),
        emptyWidget: () => buildEmpty(context),
      );
    });
  }

  Widget buildContent(BuildContext context);

  Widget buildEmpty(BuildContext context) {
    return const Center(
      child: Text('Empty'),
    );
  }

  Widget buildError(BuildContext context) {
    return ApiErrorWidget(
      message: 'Error',
      retryAction: () {
        Get.find<T>().repo.reloadData();
      },
    );
  }

  Widget buildLoading(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

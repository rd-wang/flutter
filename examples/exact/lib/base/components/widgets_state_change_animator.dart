import 'package:exact/base/network/api_call_status.dart';
import 'package:flutter/cupertino.dart';

// 根据 api 调用状态在带有动画的不同小部件之间切换
class RrLoadingStateWidgetsAnimator extends StatelessWidget {
  final ApiCallStatus apiCallStatus;
  final Widget Function() loadingWidget;
  final Widget Function() successWidget;
  final Widget Function() errorWidget;
  final Widget Function()? emptyWidget;
  final Widget Function()? holdingWidget;
  final Widget Function()? refreshWidget;
  final Duration? animationDuration;
  final Widget Function(Widget, Animation<double>)? transitionBuilder;
  // 这将用于刷新时不隐藏成功小部件
  // 如果为 true 仍会显示其真正成功的小部件
  // 如果为 false，则显示刷新小部件，或者如果传递 (refreshWidget) 为空，则显示空框
  final bool hideSuccessWidgetWhileRefreshing;

  const RrLoadingStateWidgetsAnimator({
    super.key,
    required this.apiCallStatus,
    required this.loadingWidget,
    required this.errorWidget,
    required this.successWidget,
    this.holdingWidget,
    this.emptyWidget,
    this.refreshWidget,
    this.animationDuration,
    this.transitionBuilder,
    this.hideSuccessWidgetWhileRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
        duration: animationDuration ?? const Duration(milliseconds: 300),
        transitionBuilder: transitionBuilder ?? AnimatedSwitcher.defaultTransitionBuilder,
        child: switch (apiCallStatus) {
          (ApiCallStatus.success) => successWidget,
          (ApiCallStatus.error) => errorWidget,
          (ApiCallStatus.holding) => holdingWidget ??
              () {
                return const SizedBox();
              },
          (ApiCallStatus.loading) => loadingWidget,
          (ApiCallStatus.empty) => emptyWidget ??
              () {
                return const SizedBox();
              },
          (ApiCallStatus.refresh) => refreshWidget ??
              (hideSuccessWidgetWhileRefreshing
                  ? successWidget
                  : () {
                      return const SizedBox();
                    }),
          (ApiCallStatus.cache) => successWidget,
        }());
  }
}

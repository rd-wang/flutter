// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.ui;

@pragma('vm:entry-point')
void _addView(
  int viewId,
  double devicePixelRatio,
  double width,
  double height,
  double viewPaddingTop,
  double viewPaddingRight,
  double viewPaddingBottom,
  double viewPaddingLeft,
  double viewInsetTop,
  double viewInsetRight,
  double viewInsetBottom,
  double viewInsetLeft,
  double systemGestureInsetTop,
  double systemGestureInsetRight,
  double systemGestureInsetBottom,
  double systemGestureInsetLeft,
  double physicalTouchSlop,
  List<double> displayFeaturesBounds,
  List<int> displayFeaturesType,
  List<int> displayFeaturesState,
  int displayId,
) {
  final _ViewConfiguration viewConfiguration = _buildViewConfiguration(
    devicePixelRatio,
    width,
    height,
    viewPaddingTop,
    viewPaddingRight,
    viewPaddingBottom,
    viewPaddingLeft,
    viewInsetTop,
    viewInsetRight,
    viewInsetBottom,
    viewInsetLeft,
    systemGestureInsetTop,
    systemGestureInsetRight,
    systemGestureInsetBottom,
    systemGestureInsetLeft,
    physicalTouchSlop,
    displayFeaturesBounds,
    displayFeaturesType,
    displayFeaturesState,
    displayId,
  );
  PlatformDispatcher.instance._addView(viewId, viewConfiguration);
}

@pragma('vm:entry-point')
void _removeView(int viewId) {
  PlatformDispatcher.instance._removeView(viewId);
}

@pragma('vm:entry-point')
void _updateDisplays(
  List<int> ids,
  List<double> widths,
  List<double> heights,
  List<double> devicePixelRatios,
  List<double> refreshRates,
) {
  assert(ids.length == widths.length);
  assert(ids.length == heights.length);
  assert(ids.length == devicePixelRatios.length);
  assert(ids.length == refreshRates.length);
  final List<Display> displays = <Display>[];
  for (int index = 0; index < ids.length; index += 1) {
    final int displayId = ids[index];
    displays.add(Display._(
      id: displayId,
      size: Size(widths[index], heights[index]),
      devicePixelRatio: devicePixelRatios[index],
      refreshRate: refreshRates[index],
    ));
  }

  PlatformDispatcher.instance._updateDisplays(displays);
}

List<DisplayFeature> _decodeDisplayFeatures({
  required List<double> bounds,
  required List<int> type,
  required List<int> state,
  required double devicePixelRatio,
}) {
  assert(bounds.length / 4 == type.length, 'Bounds are rectangles, requiring 4 measurements each');
  assert(type.length == state.length);
  final List<DisplayFeature> result = <DisplayFeature>[];
  for(int i = 0; i < type.length; i++) {
    final int rectOffset = i * 4;
    result.add(DisplayFeature(
      bounds: Rect.fromLTRB(
        bounds[rectOffset] / devicePixelRatio,
        bounds[rectOffset + 1] / devicePixelRatio,
        bounds[rectOffset + 2] / devicePixelRatio,
        bounds[rectOffset + 3] / devicePixelRatio,
      ),
      type: DisplayFeatureType.values[type[i]],
      state: state[i] < DisplayFeatureState.values.length
          ? DisplayFeatureState.values[state[i]]
          : DisplayFeatureState.unknown,
    ));
  }
  return result;
}

_ViewConfiguration _buildViewConfiguration(
  double devicePixelRatio,
  double width,
  double height,
  double viewPaddingTop,
  double viewPaddingRight,
  double viewPaddingBottom,
  double viewPaddingLeft,
  double viewInsetTop,
  double viewInsetRight,
  double viewInsetBottom,
  double viewInsetLeft,
  double systemGestureInsetTop,
  double systemGestureInsetRight,
  double systemGestureInsetBottom,
  double systemGestureInsetLeft,
  double physicalTouchSlop,
  List<double> displayFeaturesBounds,
  List<int> displayFeaturesType,
  List<int> displayFeaturesState,
  int displayId,
) {
  return _ViewConfiguration(
    devicePixelRatio: devicePixelRatio,
    size: Size(width, height),
    viewPadding: ViewPadding._(
      top: viewPaddingTop,
      right: viewPaddingRight,
      bottom: viewPaddingBottom,
      left: viewPaddingLeft,
    ),
    viewInsets: ViewPadding._(
      top: viewInsetTop,
      right: viewInsetRight,
      bottom: viewInsetBottom,
      left: viewInsetLeft,
    ),
    padding: ViewPadding._(
      top: math.max(0.0, viewPaddingTop - viewInsetTop),
      right: math.max(0.0, viewPaddingRight - viewInsetRight),
      bottom: math.max(0.0, viewPaddingBottom - viewInsetBottom),
      left: math.max(0.0, viewPaddingLeft - viewInsetLeft),
    ),
    systemGestureInsets: ViewPadding._(
      top: math.max(0.0, systemGestureInsetTop),
      right: math.max(0.0, systemGestureInsetRight),
      bottom: math.max(0.0, systemGestureInsetBottom),
      left: math.max(0.0, systemGestureInsetLeft),
    ),
    gestureSettings: GestureSettings(
      physicalTouchSlop: physicalTouchSlop == _kUnsetGestureSetting ? null : physicalTouchSlop,
    ),
    displayFeatures: _decodeDisplayFeatures(
      bounds: displayFeaturesBounds,
      type: displayFeaturesType,
      state: displayFeaturesState,
      devicePixelRatio: devicePixelRatio,
    ),
    displayId: displayId,
  );
}

@pragma('vm:entry-point')
void _updateWindowMetrics(
  int viewId,
  double devicePixelRatio,
  double width,
  double height,
  double viewPaddingTop,
  double viewPaddingRight,
  double viewPaddingBottom,
  double viewPaddingLeft,
  double viewInsetTop,
  double viewInsetRight,
  double viewInsetBottom,
  double viewInsetLeft,
  double systemGestureInsetTop,
  double systemGestureInsetRight,
  double systemGestureInsetBottom,
  double systemGestureInsetLeft,
  double physicalTouchSlop,
  List<double> displayFeaturesBounds,
  List<int> displayFeaturesType,
  List<int> displayFeaturesState,
  int displayId,
) {
  final _ViewConfiguration viewConfiguration = _buildViewConfiguration(
    devicePixelRatio,
    width,
    height,
    viewPaddingTop,
    viewPaddingRight,
    viewPaddingBottom,
    viewPaddingLeft,
    viewInsetTop,
    viewInsetRight,
    viewInsetBottom,
    viewInsetLeft,
    systemGestureInsetTop,
    systemGestureInsetRight,
    systemGestureInsetBottom,
    systemGestureInsetLeft,
    physicalTouchSlop,
    displayFeaturesBounds,
    displayFeaturesType,
    displayFeaturesState,
    displayId,
  );
  PlatformDispatcher.instance._updateWindowMetrics(viewId, viewConfiguration);
}

typedef _LocaleClosure = String Function();

@pragma('vm:entry-point')
_LocaleClosure? _getLocaleClosure() => PlatformDispatcher.instance._localeClosure;

@pragma('vm:entry-point')
void _updateLocales(List<String> locales) {
  PlatformDispatcher.instance._updateLocales(locales);
}

@pragma('vm:entry-point')
void _updateUserSettingsData(String jsonData) {
  PlatformDispatcher.instance._updateUserSettingsData(jsonData);
}

@pragma('vm:entry-point')
void _updateInitialLifecycleState(String state) {
  PlatformDispatcher.instance._updateInitialLifecycleState(state);
}

@pragma('vm:entry-point')
void _updateSemanticsEnabled(bool enabled) {
  PlatformDispatcher.instance._updateSemanticsEnabled(enabled);
}

@pragma('vm:entry-point')
void _updateAccessibilityFeatures(int values) {
  PlatformDispatcher.instance._updateAccessibilityFeatures(values);
}

@pragma('vm:entry-point')
void _dispatchPlatformMessage(String name, ByteData? data, int responseId) {
  PlatformDispatcher.instance._dispatchPlatformMessage(name, data, responseId);
}

@pragma('vm:entry-point')
void _dispatchPointerDataPacket(ByteData packet) {
  PlatformDispatcher.instance._dispatchPointerDataPacket(packet);
}

@pragma('vm:entry-point')
void _dispatchSemanticsAction(int nodeId, int action, ByteData? args) {
  PlatformDispatcher.instance._dispatchSemanticsAction(nodeId, action, args);
}

@pragma('vm:entry-point')
void _beginFrame(int microseconds, int frameNumber) {
  PlatformDispatcher.instance._beginFrame(microseconds);
  PlatformDispatcher.instance._updateFrameData(frameNumber);
}

@pragma('vm:entry-point')
void _reportTimings(List<int> timings) {
  PlatformDispatcher.instance._reportTimings(timings);
}

@pragma('vm:entry-point')
void _drawFrame() {
  PlatformDispatcher.instance._drawFrame();
}

@pragma('vm:entry-point')
bool _onError(Object error, StackTrace? stackTrace) {
  return PlatformDispatcher.instance._dispatchError(error, stackTrace ?? StackTrace.empty);
}

typedef _ListStringArgFunction = Object? Function(List<String> args);

@pragma('vm:entry-point')
void _runMain(Function startMainIsolateFunction,
              Function userMainFunction,
              List<String> args) {
  startMainIsolateFunction(() { // ignore: avoid_dynamic_calls
    if (userMainFunction is _ListStringArgFunction) {
      userMainFunction(args);
    } else {
      userMainFunction(); // ignore: avoid_dynamic_calls
    }
  }, null);
}

/// 在给定的 [zone] 内调用 [callback]
void _invoke(void Function()? callback, Zone zone) {
  if (callback == null) {
    return;
  }
  if (identical(zone, Zone.current)) {
    callback();
  } else {
    zone.runGuarded(callback);
  }
}

/// 在给定的 [zone] 内调用 [callback]，传递给它 [arg]。
///
/// 函数名中的 "1" 表示该函数期望回调函数的参数个数为 1，
/// 即除了回调函数本身和执行回调的区域之外，还期望一个额外的参数。
///   callback 参数是一个可空的、期望一个参数的回调函数。
///   zone 参数表示在其中执行回调的区域。
///   arg 参数是传递给回调函数的参数。
/// 函数会首先检查 callback 是否为 null，如果是，则直接返回，不执行任何操作。
/// 接着，函数会检查当前执行的区域是否与给定的 zone 相同。
///   如果相同，则直接调用 callback(arg)；
///   否则，使用 zone.runUnaryGuarded<A>(callback, arg) 在指定的区域中运行回调。
void _invoke1<A>(void Function(A a)? callback, Zone zone, A arg) {
  if (callback == null) {
    return;
  }
  if (identical(zone, Zone.current)) {
    callback(arg);
  } else {
    zone.runUnaryGuarded<A>(callback, arg);
  }
}

/// 在给定的 [zone] 内调用 [callback]，传递给它 [arg1] 和 [arg2]。
///
/// 名称中的 2 指的是回调所需的参数数量（因此除了回调本身和执行回调的区域之外，还传递给此函数）。
void _invoke2<A1, A2>(void Function(A1 a1, A2 a2)? callback, Zone zone, A1 arg1, A2 arg2) {
  if (callback == null) {
    return;
  }
  if (identical(zone, Zone.current)) {
    callback(arg1, arg2);
  } else {
    zone.runGuarded(() {
      callback(arg1, arg2);
    });
  }
}

/// 在给定的 [zone] 内调用 [callback]，传递 [arg1]、[arg2] 和 [arg3]。
///
/// 名称中的 3 指的是回调所需的参数数量（因此除了回调本身和执行回调的区域之外，还传递给此函数）。
void _invoke3<A1, A2, A3>(void Function(A1 a1, A2 a2, A3 a3)? callback, Zone zone, A1 arg1, A2 arg2, A3 arg3) {
  if (callback == null) {
    return;
  }
  if (identical(zone, Zone.current)) {
    callback(arg1, arg2, arg3);
  } else {
    zone.runGuarded(() {
      callback(arg1, arg2, arg3);
    });
  }
}

bool _isLoopback(String host) {
  if (host.isEmpty) {
    return false;
  }
  if ('localhost' == host) {
    return true;
  }
  try {
    return InternetAddress(host).isLoopback;
  } on ArgumentError {
    return false;
  }
}

/// Loopback connections are always allowed.
/// Zone override with 'flutter.io.allow_http' takes first priority.
/// If zone override is not provided, engine setting is checked.
@pragma('vm:entry-point')
void Function(Uri) _getHttpConnectionHookClosure(bool mayInsecurelyConnectToAllDomains) {
  return (Uri uri) {
      final Object? zoneOverride = Zone.current[#flutter.io.allow_http];
      if (zoneOverride == true) {
        return;
      }
      if (zoneOverride == false && uri.isScheme('http')) {
        // Going to _isLoopback check before throwing
      } else if (mayInsecurelyConnectToAllDomains || uri.isScheme('https')) {
        // In absence of zone override, if engine setting allows the connection
        // or if connection is to `https`, allow the connection.
        return;
      }
      // Loopback connections are always allowed
      // Check at last resort to avoid debug annoyance of try/on ArgumentError
      if (_isLoopback(uri.host)) {
        return;
      }
      throw UnsupportedError(
        'Non-https connection "$uri" is not supported by the platform. '
        'Refer to https://flutter.dev/docs/release/breaking-changes/network-policy-ios-android.');
    };
}

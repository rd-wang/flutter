// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'assertions.dart';
import 'constants.dart';
import 'diagnostics.dart';

const bool _kMemoryAllocations = bool.fromEnvironment('flutter.memory_allocations');

/// 如果为 true，Flutter 对象会分派内存分配事件。
///
/// 默认情况下，该常量对于调试模式为 true，对于配置文件和发布模式为 false。
/// 要启用发布模式的调度，请传递编译标志
/// `--dart-define=flutter.memory_allocations=true`.
const bool kFlutterMemoryAllocationsEnabled = _kMemoryAllocations || kDebugMode;

const String _dartUiLibrary = 'dart:ui';

class _FieldNames {
  static const String eventType = 'eventType';
  static const String libraryName = 'libraryName';
  static const String className = 'className';
}

/// A lifecycle event of an object.
abstract class ObjectEvent {
  /// Creates an instance of [ObjectEvent].
  ObjectEvent({
    required this.object,
  });

  /// Reference to the object.
  ///
  /// The reference should not be stored in any
  /// long living place as it will prevent garbage collection.
  final Object object;

  /// The representation of the event in a form, acceptable by a
  /// pure dart library, that cannot depend on Flutter.
  ///
  /// The method enables code like:
  /// ```dart
  /// void myDartMethod(Map<Object, Map<String, Object>> event) {}
  /// FlutterMemoryAllocations.instance
  ///   .addListener((ObjectEvent event) => myDartMethod(event.toMap()));
  /// ```
  Map<Object, Map<String, Object>> toMap();
}

/// A listener of [ObjectEvent].
typedef ObjectEventListener = void Function(ObjectEvent event);

/// An event that describes creation of an object.
class ObjectCreated extends ObjectEvent {
  /// Creates an instance of [ObjectCreated].
  ObjectCreated({
    required this.library,
    required this.className,
    required super.object,
  });

  /// Name of the instrumented library.
  ///
  /// The format of this parameter should be a library Uri.
  /// For example: `'package:flutter/rendering.dart'`.
  final String library;

  /// Name of the instrumented class.
  final String className;

  @override
  Map<Object, Map<String, Object>> toMap() {
    return <Object, Map<String, Object>>{
      object: <String, Object>{
        _FieldNames.libraryName: library,
        _FieldNames.className: className,
        _FieldNames.eventType: 'created',
      }
    };
  }
}

/// An event that describes disposal of an object.
class ObjectDisposed extends ObjectEvent {
  /// Creates an instance of [ObjectDisposed].
  ObjectDisposed({
    required super.object,
  });

  @override
  Map<Object, Map<String, Object>> toMap() {
    return <Object, Map<String, Object>>{
      object: <String, Object>{
        _FieldNames.eventType: 'disposed',
      }
    };
  }
}

/// An interface for listening to object lifecycle events.
@Deprecated('Use `FlutterMemoryAllocations` instead. '
    'The class `MemoryAllocations` will be introduced in a pure Dart library. '
    'This feature was deprecated after v3.18.0-18.0.pre.')
typedef MemoryAllocations = FlutterMemoryAllocations;

/// 用于监听对象生命周期事件的接口。
///
/// 如果 [kFlutterMemoryAllocationsEnabled] 为 true，
/// 则 [FlutterMemoryAllocations] 监听 Flutter Framework 中一次性对象的创建和处置事件。
/// 要调度其他事件对象，请调用 [FlutterMemoryAllocations.dispatchObjectEvent]。
///
/// 将此类与条件kFlutterMemoryAllocationsEnabled一起使用
/// 以确保在禁用内存分配的情况下不会通过类的代码增加应用程序的大小。
///
/// 该类针对大量事件流和少量添加或删除侦听器进行了优化。
class FlutterMemoryAllocations {
  FlutterMemoryAllocations._();

  /// [FlutterMemoryAllocations] 的共享实例。
  /// 仅当 [kFlutterMemoryAllocationsEnabled] 为 true 时才调用此函数。
  static final FlutterMemoryAllocations instance = FlutterMemoryAllocations._();

  /// List of listeners.
  ///
  /// The elements are nullable, because the listeners should be removable
  /// while iterating through the list.
  List<ObjectEventListener?>? _listeners;

  /// Register a listener that is called every time an object event is
  /// dispatched.
  ///
  /// Listeners can be removed with [removeListener].
  ///
  /// Only call this when [kFlutterMemoryAllocationsEnabled] is true.
  void addListener(ObjectEventListener listener) {
    if (!kFlutterMemoryAllocationsEnabled) {
      return;
    }
    if (_listeners == null) {
      _listeners = <ObjectEventListener?>[];
      _subscribeToSdkObjects();
    }
    _listeners!.add(listener);
  }

  /// 活动通知循环的数量。
  /// 当等于零时，我们可以从列表中删除监听器，否则应该将它们清空
  int _activeDispatchLoops = 0;

  /// If true, listeners were nulled by [removeListener].
  bool _listenersContainNulls = false;

  /// Stop calling the given listener every time an object event is
  /// dispatched.
  ///
  /// Listeners can be added with [addListener].
  ///
  /// Only call this when [kFlutterMemoryAllocationsEnabled] is true.
  void removeListener(ObjectEventListener listener) {
    if (!kFlutterMemoryAllocationsEnabled) {
      return;
    }
    final List<ObjectEventListener?>? listeners = _listeners;
    if (listeners == null) {
      return;
    }

    if (_activeDispatchLoops > 0) {
      // If there are active dispatch loops, listeners.remove
      // should not be invoked, as it will
      // break the dispatch loops correctness.
      for (int i = 0; i < listeners.length; i++) {
        if (listeners[i] == listener) {
          listeners[i] = null;
          _listenersContainNulls = true;
        }
      }
    } else {
      listeners.removeWhere((ObjectEventListener? l) => l == listener);
      _checkListenersForEmptiness();
    }
  }

  void _tryDefragmentListeners() {
    if (_activeDispatchLoops > 0 || !_listenersContainNulls) {
      return;
    }
    _listeners?.removeWhere((ObjectEventListener? e) => e == null);
    _listenersContainNulls = false;
    _checkListenersForEmptiness();
  }

  void _checkListenersForEmptiness() {
    if (_listeners?.isEmpty ?? false) {
      _listeners = null;
      _unSubscribeFromSdkObjects();
    }
  }

  /// Return true if there are listeners.
  ///
  /// If there is no listeners, the app can save on creating the event object.
  ///
  /// Only call this when [kFlutterMemoryAllocationsEnabled] is true.
  bool get hasListeners {
    if (!kFlutterMemoryAllocationsEnabled) {
      return false;
    }
    if (_listenersContainNulls) {
      return _listeners?.firstWhere((ObjectEventListener? l) => l != null) != null;
    }
    return _listeners?.isNotEmpty ?? false;
  }

  /// 向侦听器分派新对象事件。
  /// 监听器抛出的异常将被捕获并使用 [FlutterError.reportError]报告。
  /// 在事件分派期间添加的侦听器将开始为下一个事件调用，但对于此事件将被跳过。
  /// 在事件分派期间删除的侦听器在删除后将不会被调用。
  /// 仅当[kFlutterMemoryAllocationsEnabled]为 true 时才调用此函数
  void dispatchObjectEvent(ObjectEvent event) {
    if (!kFlutterMemoryAllocationsEnabled) {
      return;
    }
    final List<ObjectEventListener?>? listeners = _listeners;
    if (listeners == null || listeners.isEmpty) {
      return;
    }

    _activeDispatchLoops++;
    final int end = listeners.length;
    for (int i = 0; i < end; i++) {
      try {
        listeners[i]?.call(event);
      } catch (exception, stack) {
        final String type = event.object.runtimeType.toString();
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'foundation library',
          context: ErrorDescription('MemoryAllocations while '
              'dispatching notifications for $type'),
          informationCollector: () => <DiagnosticsNode>[
            DiagnosticsProperty<Object>(
              'The $type sending notification was',
              event.object,
              style: DiagnosticsTreeStyle.errorProperty,
            ),
          ],
        ));
      }
    }
    _activeDispatchLoops--;
    _tryDefragmentListeners();
  }

  /// 则创建 [ObjectCreated] 并在有侦听器的情况下调用 [dispatchObjectEvent]。
  /// 如果事件对象尚未创建，则此方法比 [dispatchObjectEvent] 更有效。
  void dispatchObjectCreated({
    required String library,
    required String className,
    required Object object,
  }) {
    if (!hasListeners) {
      return;
    }
    dispatchObjectEvent(ObjectCreated(
      library: library,
      className: className,
      object: object,
    ));
  }

  /// Create [ObjectDisposed] and invoke [dispatchObjectEvent] if there are listeners.
  ///
  /// This method is more efficient than [dispatchObjectEvent] if the event object is not created yet.
  void dispatchObjectDisposed({required Object object}) {
    if (!hasListeners) {
      return;
    }
    dispatchObjectEvent(ObjectDisposed(object: object));
  }

  void _subscribeToSdkObjects() {
    assert(ui.Image.onCreate == null);
    assert(ui.Image.onDispose == null);
    assert(ui.Picture.onCreate == null);
    assert(ui.Picture.onDispose == null);
    ui.Image.onCreate = _imageOnCreate;
    ui.Image.onDispose = _imageOnDispose;
    ui.Picture.onCreate = _pictureOnCreate;
    ui.Picture.onDispose = _pictureOnDispose;
  }

  void _unSubscribeFromSdkObjects() {
    assert(ui.Image.onCreate == _imageOnCreate);
    assert(ui.Image.onDispose == _imageOnDispose);
    assert(ui.Picture.onCreate == _pictureOnCreate);
    assert(ui.Picture.onDispose == _pictureOnDispose);
    ui.Image.onCreate = null;
    ui.Image.onDispose = null;
    ui.Picture.onCreate = null;
    ui.Picture.onDispose = null;
  }

  void _imageOnCreate(ui.Image image) {
    dispatchObjectEvent(ObjectCreated(
      library: _dartUiLibrary,
      className: '${ui.Image}',
      object: image,
    ));
  }

  void _pictureOnCreate(ui.Picture picture) {
    dispatchObjectEvent(ObjectCreated(
      library: _dartUiLibrary,
      className: '${ui.Picture}',
      object: picture,
    ));
  }

  void _imageOnDispose(ui.Image image) {
    dispatchObjectEvent(ObjectDisposed(
      object: image,
    ));
  }

  void _pictureOnDispose(ui.Picture picture) {
    dispatchObjectEvent(ObjectDisposed(
      object: picture,
    ));
  }
}

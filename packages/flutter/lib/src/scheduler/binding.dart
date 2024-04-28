// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:developer' show Flow, Timeline, TimelineTask;
import 'dart:ui'
    show AppLifecycleState, DartPerformanceMode, FramePhase, FrameTiming, PlatformDispatcher, TimingsCallback;

import 'package:collection/collection.dart' show HeapPriorityQueue, PriorityQueue;
import 'package:flutter/foundation.dart';

import 'debug.dart';
import 'priority.dart';
import 'service_extensions.dart';

export 'dart:ui' show AppLifecycleState, FrameTiming, TimingsCallback;

export 'priority.dart' show Priority;

/// Slows down animations by this factor to help in development.
double get timeDilation => _timeDilation;
double _timeDilation = 1.0;

/// If the [SchedulerBinding] has been initialized, setting the time dilation
/// automatically calls [SchedulerBinding.resetEpoch] to ensure that time stamps
/// seen by consumers of the scheduler binding are always increasing.
///
/// It is safe to set this before initializing the binding.
set timeDilation(double value) {
  assert(value > 0.0);
  if (_timeDilation == value) {
    return;
  }
  // If the binding has been created, we need to resetEpoch first so that we
  // capture start of the epoch with the current time dilation.
  SchedulerBinding._instance?.resetEpoch();
  _timeDilation = value;
}

/// Signature for frame-related callbacks from the scheduler.
///
/// The `timeStamp` is the number of milliseconds since the beginning of the
/// scheduler's epoch. Use timeStamp to determine how far to advance animation
/// timelines so that all the animations in the system are synchronized to a
/// common time base.
typedef FrameCallback = void Function(Duration timeStamp);

/// Signature for [SchedulerBinding.scheduleTask] callbacks.
///
/// The type argument `T` is the task's return value. Consider `void` if the
/// task does not return a value.
typedef TaskCallback<T> = FutureOr<T> Function();

/// Signature for the [SchedulerBinding.schedulingStrategy] callback. Called
/// whenever the system needs to decide whether a task at a given
/// priority needs to be run.
///
/// Return true if a task with the given priority should be executed at this
/// time, false otherwise.
///
/// See also:
///
///  * [defaultSchedulingStrategy], the default [SchedulingStrategy] for [SchedulerBinding.schedulingStrategy].
typedef SchedulingStrategy = bool Function({required int priority, required SchedulerBinding scheduler});

class _TaskEntry<T> {
  _TaskEntry(this.task, this.priority, this.debugLabel, this.flow) {
    assert(() {
      debugStack = StackTrace.current;
      return true;
    }());
  }
  final TaskCallback<T> task;
  final int priority;
  final String? debugLabel;
  final Flow? flow;

  late StackTrace debugStack;
  final Completer<T> completer = Completer<T>();

  void run() {
    if (!kReleaseMode) {
      Timeline.timeSync(
        debugLabel ?? 'Scheduled Task',
        () {
          completer.complete(task());
        },
        flow: flow != null ? Flow.step(flow!.id) : null,
      );
    } else {
      completer.complete(task());
    }
  }
}

class _FrameCallbackEntry {
  _FrameCallbackEntry(this.callback, {bool rescheduling = false}) {
    assert(() {
      if (rescheduling) {
        assert(() {
          if (debugCurrentCallbackStack == null) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('scheduleFrameCallback called with rescheduling true, but no callback is in scope.'),
              ErrorDescription(
                'The "rescheduling" argument should only be set to true if the '
                'callback is being reregistered from within the callback itself, '
                'and only then if the callback itself is entirely synchronous.',
              ),
              ErrorHint(
                'If this is the initial registration of the callback, or if the '
                'callback is asynchronous, then do not use the "rescheduling" '
                'argument.',
              ),
            ]);
          }
          return true;
        }());
        debugStack = debugCurrentCallbackStack;
      } else {
        // TODO(ianh): trim the frames from this library, so that the call to scheduleFrameCallback is the top one
        debugStack = StackTrace.current;
      }
      return true;
    }());
  }

  final FrameCallback callback;

  static StackTrace? debugCurrentCallbackStack;
  StackTrace? debugStack;
}

/// The various phases that a [SchedulerBinding] goes through during
/// [SchedulerBinding.handleBeginFrame].
///
/// This is exposed by [SchedulerBinding.schedulerPhase].
///
/// The values of this enum are ordered in the same order as the phases occur,
/// so their relative index values can be compared to each other.
///
/// See also:
///
///  * [WidgetsBinding.drawFrame], which pumps the build and rendering pipeline
///    to generate a frame.
enum SchedulerPhase {
  /// No frame is being processed. Tasks (scheduled by
  /// [SchedulerBinding.scheduleTask]), microtasks (scheduled by
  /// [scheduleMicrotask]), [Timer] callbacks, event handlers (e.g. from user
  /// input), and other callbacks (e.g. from [Future]s, [Stream]s, and the like)
  /// may be executing.
  idle,

  /// The transient callbacks (scheduled by
  /// [SchedulerBinding.scheduleFrameCallback]) are currently executing.
  ///
  /// Typically, these callbacks handle updating objects to new animation
  /// states.
  ///
  /// See [SchedulerBinding.handleBeginFrame].
  transientCallbacks,

  /// Microtasks scheduled during the processing of transient callbacks are
  /// current executing.
  ///
  /// This may include, for instance, callbacks from futures resolved during the
  /// [transientCallbacks] phase.
  midFrameMicrotasks,

  /// The persistent callbacks (scheduled by
  /// [SchedulerBinding.addPersistentFrameCallback]) are currently executing.
  ///
  /// Typically, this is the build/layout/paint pipeline. See
  /// [WidgetsBinding.drawFrame] and [SchedulerBinding.handleDrawFrame].
  persistentCallbacks,

  /// The post-frame callbacks (scheduled by
  /// [SchedulerBinding.addPostFrameCallback]) are currently executing.
  ///
  /// Typically, these callbacks handle cleanup and scheduling of work for the
  /// next frame.
  ///
  /// See [SchedulerBinding.handleDrawFrame].
  postFrameCallbacks,
}

/// This callback is invoked when a request for [DartPerformanceMode] is disposed.
///
/// See also:
///
/// * [PerformanceModeRequestHandle] for more information on the lifecycle of the handle.
typedef _PerformanceModeCleanupCallback = VoidCallback;

/// An opaque handle that keeps a request for [DartPerformanceMode] active until
/// disposed.
///
/// To create a [PerformanceModeRequestHandle], use [SchedulerBinding.requestPerformanceMode].
/// The component that makes the request is responsible for disposing the handle.
class PerformanceModeRequestHandle {
  PerformanceModeRequestHandle._(_PerformanceModeCleanupCallback this._cleanup) {
    // TODO(polina-c): stop duplicating code across disposables
    // https://github.com/flutter/flutter/issues/137435
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectCreated(
        library: 'package:flutter/scheduler.dart',
        className: '$PerformanceModeRequestHandle',
        object: this,
      );
    }
  }

  _PerformanceModeCleanupCallback? _cleanup;

  /// Call this method to signal to [SchedulerBinding] that a request for a [DartPerformanceMode]
  /// is no longer needed.
  ///
  /// This method must only be called once per object.
  void dispose() {
    assert(_cleanup != null);
    // TODO(polina-c): stop duplicating code across disposables
    // https://github.com/flutter/flutter/issues/137435
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectDisposed(object: this);
    }
    _cleanup!();
    _cleanup = null;
  }
}

/// 用于运行以下任务的调度程序：
///
/// * _Transient callbacks_, _瞬态回调_，
/// 由系统的 [dart:ui.PlatformDispatcher.onBeginFrame] 回调触发，
/// 用于将应用程序的行为同步到系统的显示。例如，[Ticker] 和 [AnimationController] 从中触发。
///
/// * _Persistent callbacks_, _持久回调_，
/// 由系统的 [dart:ui.PlatformDispatcher.onDrawFrame] 回调触发，
/// 用于在执行瞬时回调后更新系统的显示。例如，渲染层使用它来驱动其渲染管道。
///
/// * _Post-frame callbacks_, _帧后回调_，
/// 在持久回调之后、从 [dart:ui.PlatformDispatcher.onDrawFrame] 回调返回之前运行。
///
/// * Non-rendering tasks, 非渲染任务，
/// 在帧之间运行。
/// 这些被赋予优先级并根据[schedulingStrategy]按优先级顺序执行。
mixin SchedulerBinding on BindingBase {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    //debug编译模式时统计绘制流程时长，开始、运行、构建、光栅化。
    if (!kReleaseMode) {
      addTimingsCallback((List<FrameTiming> timings) {
        timings.forEach(_profileFramePostEvent);
      });
    }
  }

  /// The current [SchedulerBinding], if one has been created.
  ///
  /// Provides access to the features exposed by this mixin. The binding must
  /// be initialized before using this getter; this is typically done by calling
  /// [runApp] or [WidgetsFlutterBinding.ensureInitialized].
  static SchedulerBinding get instance => BindingBase.checkInstance(_instance);
  static SchedulerBinding? _instance;

  final List<TimingsCallback> _timingsCallbacks = <TimingsCallback>[];

  /// Add a [TimingsCallback] that receives [FrameTiming] sent from
  /// the engine.
  ///
  /// This API enables applications to monitor their graphics
  /// performance. Data from the engine is batched into lists of
  /// [FrameTiming] objects which are reported approximately once a
  /// second in release mode and approximately once every 100ms in
  /// debug and profile builds. The list is sorted in ascending
  /// chronological order (earliest frame first). The timing of the
  /// first frame is sent immediately without batching.
  ///
  /// The data returned can be used to catch missed frames (by seeing
  /// if [FrameTiming.buildDuration] or [FrameTiming.rasterDuration]
  /// exceed the frame budget, e.g. 16ms at 60Hz), and to catch high
  /// latency (by seeing if [FrameTiming.totalSpan] exceeds the frame
  /// budget). It is possible for no frames to be missed but for the
  /// latency to be more than one frame in the case where the Flutter
  /// engine is pipelining the graphics updates, e.g. because the sum
  /// of the [FrameTiming.buildDuration] and the
  /// [FrameTiming.rasterDuration] together exceed the frame budget.
  /// In those cases, animations will be smooth but touch input will
  /// feel more sluggish.
  ///
  /// Using [addTimingsCallback] is preferred over using
  /// [dart:ui.PlatformDispatcher.onReportTimings] directly because the
  /// [dart:ui.PlatformDispatcher.onReportTimings] API only allows one callback,
  /// which prevents multiple libraries from registering listeners
  /// simultaneously, while this API allows multiple callbacks to be registered
  /// independently.
  ///
  /// This API is implemented in terms of
  /// [dart:ui.PlatformDispatcher.onReportTimings]. In release builds, when no
  /// libraries have registered with this API, the
  /// [dart:ui.PlatformDispatcher.onReportTimings] callback is not set, which
  /// disables the performance tracking and reduces the runtime overhead to
  /// approximately zero. The performance overhead of the performance tracking
  /// when one or more callbacks are registered (i.e. when it is enabled) is
  /// very approximately 0.01% CPU usage per second (measured on an iPhone 6s).
  ///
  /// In debug and profile builds, the [SchedulerBinding] itself
  /// registers a timings callback to update the [Timeline].
  ///
  /// If the same callback is added twice, it will be executed twice.
  ///
  /// See also:
  ///
  ///  * [removeTimingsCallback], which can be used to remove a callback
  ///    added using this method.
  void addTimingsCallback(TimingsCallback callback) {
    _timingsCallbacks.add(callback);
    if (_timingsCallbacks.length == 1) {
      assert(platformDispatcher.onReportTimings == null);
      platformDispatcher.onReportTimings = _executeTimingsCallbacks;
    }
    assert(platformDispatcher.onReportTimings == _executeTimingsCallbacks);
  }

  /// Removes a callback that was earlier added by [addTimingsCallback].
  void removeTimingsCallback(TimingsCallback callback) {
    assert(_timingsCallbacks.contains(callback));
    _timingsCallbacks.remove(callback);
    if (_timingsCallbacks.isEmpty) {
      platformDispatcher.onReportTimings = null;
    }
  }

  @pragma('vm:notify-debugger-on-exception')
  void _executeTimingsCallbacks(List<FrameTiming> timings) {
    final List<TimingsCallback> clonedCallbacks = List<TimingsCallback>.of(_timingsCallbacks);
    for (final TimingsCallback callback in clonedCallbacks) {
      try {
        if (_timingsCallbacks.contains(callback)) {
          callback(timings);
        }
      } catch (exception, stack) {
        InformationCollector? collector;
        assert(() {
          collector = () => <DiagnosticsNode>[
                DiagnosticsProperty<TimingsCallback>(
                  'The TimingsCallback that gets executed was',
                  callback,
                  style: DiagnosticsTreeStyle.errorProperty,
                ),
              ];
          return true;
        }());
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          context: ErrorDescription('while executing callbacks for FrameTiming'),
          informationCollector: collector,
        ));
      }
    }
  }

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();

    if (!kReleaseMode) {
      registerNumericServiceExtension(
        name: SchedulerServiceExtensions.timeDilation.name,
        getter: () async => timeDilation,
        setter: (double value) async {
          timeDilation = value;
        },
      );
    }
  }

  /// Whether the application is visible, and if so, whether it is currently
  /// interactive.
  ///
  /// This is set by [handleAppLifecycleStateChanged] when the
  /// [SystemChannels.lifecycle] notification is dispatched.
  ///
  /// The preferred ways to watch for changes to this value are using
  /// [WidgetsBindingObserver.didChangeAppLifecycleState], or through an
  /// [AppLifecycleListener] object.
  AppLifecycleState? get lifecycleState => _lifecycleState;
  AppLifecycleState? _lifecycleState;

  /// Allows the test framework to reset the lifecycle state back to its
  /// initial value.
  @visibleForTesting
  void resetLifecycleState() {
    _lifecycleState = null;
  }

  /// Called when the application lifecycle state changes.
  ///
  /// Notifies all the observers using
  /// [WidgetsBindingObserver.didChangeAppLifecycleState].
  ///
  /// This method exposes notifications from [SystemChannels.lifecycle].
  @protected
  @mustCallSuper
  void handleAppLifecycleStateChanged(AppLifecycleState state) {
    if (lifecycleState == state) {
      return;
    }
    _lifecycleState = state;
    switch (state) {
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
        _setFramesEnabledState(true);
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _setFramesEnabledState(false);
    }
  }

  /// The strategy to use when deciding whether to run a task or not.
  ///
  /// Defaults to [defaultSchedulingStrategy].
  SchedulingStrategy schedulingStrategy = defaultSchedulingStrategy;

  static int _taskSorter(_TaskEntry<dynamic> e1, _TaskEntry<dynamic> e2) {
    return -e1.priority.compareTo(e2.priority);
  }

  final PriorityQueue<_TaskEntry<dynamic>> _taskQueue = HeapPriorityQueue<_TaskEntry<dynamic>>(_taskSorter);

  /// Schedules the given `task` with the given `priority`.
  ///
  /// If `task` returns a future, the future returned by [scheduleTask] will
  /// complete after the former future has been scheduled to completion.
  /// Otherwise, the returned future for [scheduleTask] will complete with the
  /// same value returned by `task` after it has been scheduled.
  ///
  /// The `debugLabel` and `flow` are used to report the task to the [Timeline],
  /// for use when profiling.
  ///
  /// ## Processing model
  ///
  /// Tasks will be executed between frames, in priority order,
  /// excluding tasks that are skipped by the current
  /// [schedulingStrategy]. Tasks should be short (as in, up to a
  /// millisecond), so as to not cause the regular frame callbacks to
  /// get delayed.
  ///
  /// If an animation is running, including, for instance, a [ProgressIndicator]
  /// indicating that there are pending tasks, then tasks with a priority below
  /// [Priority.animation] won't run (at least, not with the
  /// [defaultSchedulingStrategy]; this can be configured using
  /// [schedulingStrategy]).
  Future<T> scheduleTask<T>(
    TaskCallback<T> task,
    Priority priority, {
    String? debugLabel,
    Flow? flow,
  }) {
    final bool isFirstTask = _taskQueue.isEmpty;
    final _TaskEntry<T> entry = _TaskEntry<T>(
      task,
      priority.value,
      debugLabel,
      flow,
    );
    _taskQueue.add(entry);
    if (isFirstTask && !locked) {
      _ensureEventLoopCallback();
    }
    return entry.completer.future;
  }

  @override
  void unlocked() {
    super.unlocked();
    if (_taskQueue.isNotEmpty) {
      _ensureEventLoopCallback();
    }
  }

  // Whether this scheduler already requested to be called from the event loop.
  bool _hasRequestedAnEventLoopCallback = false;

  // Ensures that the scheduler services a task scheduled by
  // [SchedulerBinding.scheduleTask].
  void _ensureEventLoopCallback() {
    assert(!locked);
    assert(_taskQueue.isNotEmpty);
    if (_hasRequestedAnEventLoopCallback) {
      return;
    }
    _hasRequestedAnEventLoopCallback = true;
    Timer.run(_runTasks);
  }

  // Scheduled by _ensureEventLoopCallback.
  void _runTasks() {
    _hasRequestedAnEventLoopCallback = false;
    if (handleEventLoopCallback()) {
      _ensureEventLoopCallback();
    } // runs next task when there's time
  }

  /// Execute the highest-priority task, if it is of a high enough priority.
  ///
  /// Returns true if a task was executed and there are other tasks remaining
  /// (even if they are not high-enough priority).
  ///
  /// Returns false if no task was executed, which can occur if there are no
  /// tasks scheduled, if the scheduler is [locked], or if the highest-priority
  /// task is of too low a priority given the current [schedulingStrategy].
  ///
  /// Also returns false if there are no tasks remaining.
  @visibleForTesting
  @pragma('vm:notify-debugger-on-exception')
  bool handleEventLoopCallback() {
    if (_taskQueue.isEmpty || locked) {
      return false;
    }
    final _TaskEntry<dynamic> entry = _taskQueue.first;
    if (schedulingStrategy(priority: entry.priority, scheduler: this)) {
      try {
        _taskQueue.removeFirst();
        entry.run();
      } catch (exception, exceptionStack) {
        StackTrace? callbackStack;
        assert(() {
          callbackStack = entry.debugStack;
          return true;
        }());
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: exceptionStack,
          library: 'scheduler library',
          context: ErrorDescription('during a task callback'),
          informationCollector: (callbackStack == null)
              ? null
              : () {
                  return <DiagnosticsNode>[
                    DiagnosticsStackTrace(
                      '\nThis exception was thrown in the context of a scheduler callback. '
                      'When the scheduler callback was _registered_ (as opposed to when the '
                      'exception was thrown), this was the stack',
                      callbackStack,
                    ),
                  ];
                },
        ));
      }
      return _taskQueue.isNotEmpty;
    }
    return false;
  }

  int _nextFrameCallbackId = 0; // positive
  Map<int, _FrameCallbackEntry> _transientCallbacks = <int, _FrameCallbackEntry>{};
  final Set<int> _removedIds = HashSet<int>();

  /// The current number of transient frame callbacks scheduled.
  ///
  /// This is reset to zero just before all the currently scheduled
  /// transient callbacks are called, at the start of a frame.
  ///
  /// This number is primarily exposed so that tests can verify that
  /// there are no unexpected transient callbacks still registered
  /// after a test's resources have been gracefully disposed.
  int get transientCallbackCount => _transientCallbacks.length;

  /// Schedules the given transient frame callback.
  ///
  /// Adds the given callback to the list of frame callbacks and ensures that a
  /// frame is scheduled.
  ///
  /// If this is called during the frame's animation phase (when transient frame
  /// callbacks are still being invoked), a new frame will be scheduled, and
  /// `callback` will be called in the newly scheduled frame, not in the current
  /// frame.
  ///
  /// If this is a one-off registration, ignore the `rescheduling` argument.
  ///
  /// If this is a callback that will be re-registered each time it fires, then
  /// when you re-register the callback, set the `rescheduling` argument to
  /// true. This has no effect in release builds, but in debug builds, it
  /// ensures that the stack trace that is stored for this callback is the
  /// original stack trace for when the callback was _first_ registered, rather
  /// than the stack trace for when the callback is re-registered. This makes it
  /// easier to track down the original reason that a particular callback was
  /// called. If `rescheduling` is true, the call must be in the context of a
  /// frame callback.
  ///
  /// Callbacks registered with this method can be canceled using
  /// [cancelFrameCallbackWithId].
  ///
  /// See also:
  ///
  ///  * [WidgetsBinding.drawFrame], which explains the phases of each frame
  ///    for those apps that use Flutter widgets (and where transient frame
  ///    callbacks fit into those phases).
  int scheduleFrameCallback(FrameCallback callback, {bool rescheduling = false}) {
    scheduleFrame();
    _nextFrameCallbackId += 1;
    _transientCallbacks[_nextFrameCallbackId] = _FrameCallbackEntry(callback, rescheduling: rescheduling);
    return _nextFrameCallbackId;
  }

  /// Cancels the transient frame callback with the given [id].
  ///
  /// Removes the given callback from the list of frame callbacks. If a frame
  /// has been requested, this does not also cancel that request.
  ///
  /// Transient frame callbacks are those registered using
  /// [scheduleFrameCallback].
  void cancelFrameCallbackWithId(int id) {
    assert(id > 0);
    _transientCallbacks.remove(id);
    _removedIds.add(id);
  }

  /// Asserts that there are no registered transient callbacks; if
  /// there are, prints their locations and throws an exception.
  ///
  /// A transient frame callback is one that was registered with
  /// [scheduleFrameCallback].
  ///
  /// This is expected to be called at the end of tests (the
  /// flutter_test framework does it automatically in normal cases).
  ///
  /// Call this method when you expect there to be no transient
  /// callbacks registered, in an assert statement with a message that
  /// you want printed when a transient callback is registered:
  ///
  /// ```dart
  /// assert(SchedulerBinding.instance.debugAssertNoTransientCallbacks(
  ///   'A leak of transient callbacks was detected while doing foo.'
  /// ));
  /// ```
  ///
  /// Does nothing if asserts are disabled. Always returns true.
  bool debugAssertNoTransientCallbacks(String reason) {
    assert(() {
      if (transientCallbackCount > 0) {
        // We cache the values so that we can produce them later
        // even if the information collector is called after
        // the problem has been resolved.
        final int count = transientCallbackCount;
        final Map<int, _FrameCallbackEntry> callbacks = Map<int, _FrameCallbackEntry>.of(_transientCallbacks);
        FlutterError.reportError(FlutterErrorDetails(
          exception: reason,
          library: 'scheduler library',
          informationCollector: () => <DiagnosticsNode>[
            if (count == 1)
              // TODO(jacobr): I have added an extra line break in this case.
              ErrorDescription(
                'There was one transient callback left. '
                'The stack trace for when it was registered is as follows:',
              )
            else
              ErrorDescription(
                'There were $count transient callbacks left. '
                'The stack traces for when they were registered are as follows:',
              ),
            for (final int id in callbacks.keys)
              DiagnosticsStackTrace('── callback $id ──', callbacks[id]!.debugStack, showSeparator: false),
          ],
        ));
      }
      return true;
    }());
    return true;
  }

  /// Asserts that there are no pending performance mode requests in debug mode.
  ///
  /// Throws a [FlutterError] if there are pending performance mode requests,
  /// as this indicates a potential memory leak.
  bool debugAssertNoPendingPerformanceModeRequests(String reason) {
    assert(() {
      if (_performanceMode != null) {
        throw FlutterError(reason);
      }
      return true;
    }());
    return true;
  }

  /// Asserts that there is no artificial time dilation in debug mode.
  ///
  /// Throws a [FlutterError] if there are such dilation, as this will make
  /// subsequent tests see dilation and thus flaky.
  bool debugAssertNoTimeDilation(String reason) {
    assert(() {
      if (timeDilation != 1.0) {
        throw FlutterError(reason);
      }
      return true;
    }());
    return true;
  }

  /// Prints the stack for where the current transient callback was registered.
  ///
  /// A transient frame callback is one that was registered with
  /// [scheduleFrameCallback].
  ///
  /// When called in debug more and in the context of a transient callback, this
  /// function prints the stack trace from where the current transient callback
  /// was registered (i.e. where it first called [scheduleFrameCallback]).
  ///
  /// When called in debug mode in other contexts, it prints a message saying
  /// that this function was not called in the context a transient callback.
  ///
  /// In release mode, this function does nothing.
  ///
  /// To call this function, use the following code:
  ///
  /// ```dart
  /// SchedulerBinding.debugPrintTransientCallbackRegistrationStack();
  /// ```
  static void debugPrintTransientCallbackRegistrationStack() {
    assert(() {
      if (_FrameCallbackEntry.debugCurrentCallbackStack != null) {
        debugPrint('When the current transient callback was registered, this was the stack:');
        debugPrint(
          FlutterError.defaultStackFilter(
            FlutterError.demangleStackTrace(
              _FrameCallbackEntry.debugCurrentCallbackStack!,
            ).toString().trimRight().split('\n'),
          ).join('\n'),
        );
      } else {
        debugPrint('No transient callback is currently executing.');
      }
      return true;
    }());
  }

  final List<FrameCallback> _persistentCallbacks = <FrameCallback>[];

  /// 添加持久帧回调。Persistent callbacks
  ///
  /// Persistent callbacks are called after transient
  /// (non-persistent) frame callbacks.
  ///
  /// Does *not* request a new frame. Conceptually, persistent frame
  /// callbacks are observers of "begin frame" events. Since they are
  /// executed after the transient frame callbacks they can drive the
  /// rendering pipeline.
  ///
  /// Persistent frame callbacks cannot be unregistered. Once registered, they
  /// are called for every frame for the lifetime of the application.
  ///
  /// See also:
  ///
  ///  * [WidgetsBinding.drawFrame], which explains the phases of each frame
  ///    for those apps that use Flutter widgets (and where persistent frame
  ///    callbacks fit into those phases).
  void addPersistentFrameCallback(FrameCallback callback) {
    _persistentCallbacks.add(callback);
  }

  final List<FrameCallback> _postFrameCallbacks = <FrameCallback>[];

  /// Schedule a callback for the end of this frame.
  ///
  /// The provided callback is run immediately after a frame, just after the
  /// persistent frame callbacks (which is when the main rendering pipeline has
  /// been flushed).
  ///
  /// This method does *not* request a new frame. If a frame is already in
  /// progress and the execution of post-frame callbacks has not yet begun, then
  /// the registered callback is executed at the end of the current frame.
  /// Otherwise, the registered callback is executed after the next frame
  /// (whenever that may be, if ever).
  ///
  /// The callbacks are executed in the order in which they have been
  /// added.
  ///
  /// Post-frame callbacks cannot be unregistered. They are called exactly once.
  ///
  /// In debug mode, if [debugTracePostFrameCallbacks] is set to true, then the
  /// registered callback will show up in the timeline events chart, which can
  /// be viewed in [DevTools](https://docs.flutter.dev/tools/devtools/overview).
  /// In that case, the `debugLabel` argument specifies the name of the callback
  /// as it will appear in the timeline. In profile and release builds,
  /// post-frame are never traced, and the `debugLabel` argument is ignored.
  ///
  /// See also:
  ///
  ///  * [scheduleFrameCallback], which registers a callback for the start of
  ///    the next frame.
  ///  * [WidgetsBinding.drawFrame], which explains the phases of each frame
  ///    for those apps that use Flutter widgets (and where post frame
  ///    callbacks fit into those phases).
  void addPostFrameCallback(FrameCallback callback, {String debugLabel = 'callback'}) {
    assert(() {
      if (debugTracePostFrameCallbacks) {
        final FrameCallback originalCallback = callback;
        callback = (Duration timeStamp) {
          Timeline.startSync(debugLabel);
          try {
            originalCallback(timeStamp);
          } finally {
            Timeline.finishSync();
          }
        };
      }
      return true;
    }());
    _postFrameCallbacks.add(callback);
  }

  Completer<void>? _nextFrameCompleter;

  /// Returns a Future that completes after the frame completes.
  ///
  /// If this is called between frames, a frame is immediately scheduled if
  /// necessary. If this is called during a frame, the Future completes after
  /// the current frame.
  ///
  /// If the device's screen is currently turned off, this may wait a very long
  /// time, since frames are not scheduled while the device's screen is turned
  /// off.
  Future<void> get endOfFrame {
    if (_nextFrameCompleter == null) {
      if (schedulerPhase == SchedulerPhase.idle) {
        scheduleFrame();
      }
      _nextFrameCompleter = Completer<void>();
      addPostFrameCallback((Duration timeStamp) {
        _nextFrameCompleter!.complete();
        _nextFrameCompleter = null;
      }, debugLabel: 'SchedulerBinding.completeFrame');
    }
    return _nextFrameCompleter!.future;
  }

  /// Whether this scheduler has requested that [handleBeginFrame] be called soon.
  bool get hasScheduledFrame => _hasScheduledFrame;
  bool _hasScheduledFrame = false;

  /// The phase that the scheduler is currently operating under.
  SchedulerPhase get schedulerPhase => _schedulerPhase;
  SchedulerPhase _schedulerPhase = SchedulerPhase.idle;

  /// Whether frames are currently being scheduled when [scheduleFrame] is called.
  ///
  /// This value depends on the value of the [lifecycleState].
  bool get framesEnabled => _framesEnabled;

  bool _framesEnabled = true;
  void _setFramesEnabledState(bool enabled) {
    if (_framesEnabled == enabled) {
      return;
    }
    _framesEnabled = enabled;
    if (enabled) {
      scheduleFrame();
    }
  }

  /// Ensures callbacks for [PlatformDispatcher.onBeginFrame] and
  /// [PlatformDispatcher.onDrawFrame] are registered.
  @protected
  void ensureFrameCallbacksRegistered() {
    platformDispatcher.onBeginFrame ??= _handleBeginFrame;
    platformDispatcher.onDrawFrame ??= _handleDrawFrame;
  }

  /// 如果该对象当前未生成帧，则使用 [scheduleFrame] 安排新帧。
  ///
  /// 调用此方法可确保最终调用 [handleDrawFrame]，除非它已经在进行中。
  ///
  /// 如果 [schedulerPhase] 是 [SchedulerPhase.transientCallbacks]
  /// 或 [SchedulerPhase.midFrameMicrotasks]，则此设置无效
  /// (因为在这种情况下已经准备好了frame), 或者
  /// [SchedulerPhase.persistentCallbacks]（因为在这种情况下正在主动渲染帧）
  /// 如果 [schedulerPhase] 是 [SchedulerPhase.idle]（在帧之间）
  /// 或 [SchedulerPhase.postFrameCallbacks]（在帧之后），它将调度一个帧。
  void ensureVisualUpdate() {
    switch (schedulerPhase) {
      case SchedulerPhase.idle:
      case SchedulerPhase.postFrameCallbacks:
        scheduleFrame();
        return;
      case SchedulerPhase.transientCallbacks:
      case SchedulerPhase.midFrameMicrotasks:
      case SchedulerPhase.persistentCallbacks:
        return;
    }
  }

  /// If necessary, schedules a new frame by calling
  /// [dart:ui.PlatformDispatcher.scheduleFrame].
  ///
  /// After this is called, the engine will (eventually) call
  /// [handleBeginFrame]. (This call might be delayed, e.g. if the device's
  /// screen is turned off it will typically be delayed until the screen is on
  /// and the application is visible.) Calling this during a frame forces
  /// another frame to be scheduled, even if the current frame has not yet
  /// completed.
  ///
  /// Scheduled frames are serviced when triggered by a "Vsync" signal provided
  /// by the operating system. The "Vsync" signal, or vertical synchronization
  /// signal, was historically related to the display refresh, at a time when
  /// hardware physically moved a beam of electrons vertically between updates
  /// of the display. The operation of contemporary hardware is somewhat more
  /// subtle and complicated, but the conceptual "Vsync" refresh signal continue
  /// to be used to indicate when applications should update their rendering.
  ///
  /// To have a stack trace printed to the console any time this function
  /// schedules a frame, set [debugPrintScheduleFrameStacks] to true.
  ///
  /// See also:
  ///
  ///  * [scheduleForcedFrame], which ignores the [lifecycleState] when
  ///    scheduling a frame.
  ///  * [scheduleWarmUpFrame], which ignores the "Vsync" signal entirely and
  ///    triggers a frame immediately.
  void scheduleFrame() {
    if (_hasScheduledFrame || !framesEnabled) {
      return;
    }
    assert(() {
      if (debugPrintScheduleFrameStacks) {
        debugPrintStack(label: 'scheduleFrame() called. Current phase is $schedulerPhase.');
      }
      return true;
    }());
    ensureFrameCallbacksRegistered();
    platformDispatcher.scheduleFrame();
    _hasScheduledFrame = true;
  }

  /// Schedules a new frame by calling
  /// [dart:ui.PlatformDispatcher.scheduleFrame].
  ///
  /// After this is called, the engine will call [handleBeginFrame], even if
  /// frames would normally not be scheduled by [scheduleFrame] (e.g. even if
  /// the device's screen is turned off).
  ///
  /// The framework uses this to force a frame to be rendered at the correct
  /// size when the phone is rotated, so that a correctly-sized rendering is
  /// available when the screen is turned back on.
  ///
  /// To have a stack trace printed to the console any time this function
  /// schedules a frame, set [debugPrintScheduleFrameStacks] to true.
  ///
  /// Prefer using [scheduleFrame] unless it is imperative that a frame be
  /// scheduled immediately, since using [scheduleForcedFrame] will cause
  /// significantly higher battery usage when the device should be idle.
  ///
  /// Consider using [scheduleWarmUpFrame] instead if the goal is to update the
  /// rendering as soon as possible (e.g. at application startup).
  void scheduleForcedFrame() {
    if (_hasScheduledFrame) {
      return;
    }
    assert(() {
      if (debugPrintScheduleFrameStacks) {
        debugPrintStack(label: 'scheduleForcedFrame() called. Current phase is $schedulerPhase.');
      }
      return true;
    }());
    ensureFrameCallbacksRegistered();
    platformDispatcher.scheduleFrame();
    _hasScheduledFrame = true;
  }

  bool _warmUpFrame = false;

  /// 安排帧尽快运行，而不是等待引擎请求帧以响应系统“Vsync”信号。
  /// 这在应用程序启动期间使用，以便第一帧（可能非常昂贵）获得额外的几毫秒运行时间。
  ///
  /// 锁定事件分发，直到计划的帧完成。
  /// 如果已经使用 [scheduleFrame] 或 [scheduleForcedFrame] 调度了一个帧，则此调用可能会延迟该帧。
  /// 如果任何预定帧已经开始或者另一个 [scheduleWarmUpFrame] 已经被调用，则该调用将被忽略。
  /// 最好选 [scheduleFrame] 在正常操作中更新显示。
  ///
  /// ## 设计讨论
  ///
  /// 当 Flutter 引擎收到来自操作系统的请求时（由于历史原因称为 vsync），它会提示框架生成帧。
  /// 但是，在应用程序启动后（或热重新加载后）几毫秒内，这种情况可能不会发生。
  /// 利用首次配置 widget tree 和引擎请求更新之间的时间，框架安排一个_预热帧_。
  ///
  /// 预热帧可能永远不会真正渲染（因为引擎没有请求它，因此没有有效的上下文来绘制），
  /// 但它会导致框架经历构建、布局和绘制的步骤，这些步骤总共可能需要几毫秒。
  /// 因此，当引擎请求真实帧时，大部分工作已经完成，并且框架可以以最少的额外工作生成帧。
  ///
  /// 预热帧在启动时由 [runApp] 安排，在热重载期间由 [RendererBinding.performReassemble] 安排。
  ///
  /// 当框架通过调用 [RendererBinding.allowFirstFrame] 解除阻塞时，也会安排预热帧
  /// (对应于对阻止渲染的 [RendererBinding.deferFirstFrame] 的调用)
  void scheduleWarmUpFrame() {
    if (_warmUpFrame || schedulerPhase != SchedulerPhase.idle) {
      return;
    }

    _warmUpFrame = true;
    TimelineTask? debugTimelineTask;
    if (!kReleaseMode) {
      debugTimelineTask = TimelineTask()..start('Warm-up frame');
    }
    final bool hadScheduledFrame = _hasScheduledFrame;
    // 我们在这里使用timers来确保微任务在两者之间刷新。
    // Timer任务会加入到event queue,遵循 dart的事件循环规则
    // 在执行handleBeginFrame()前先处理完 microtask queue 中的任务
    Timer.run(() {
      assert(_warmUpFrame);
      // 绘制Frame前工作，主要是处理Animate动画
      handleBeginFrame(null);
    });
    Timer.run(() {
      assert(_warmUpFrame);
      // 开始Frame绘制
      handleDrawFrame();
      // 我们在此帧之后调用resetEpoch，以便在热重载情况下，下一帧假装在此预热帧之后立即发生。
      // 预热帧的时间戳通常是很久以前的事（最后一个真实帧的时间）， 所以如果我们不重置纪元
      // 我们会看到从热身帧中的旧时间突然跳到“真实”帧中的新时间。
      // 最大的问题是隐式动画最终会在旧时间触发，然后跳过每一帧并在新时间完成。
      // 即:在预热帧绘制结束后调用resetEpoch()来重置时间戳，
      // 避免热重载情况从预热帧到热重载帧的时间差，导致隐式动画的跳帧情况。
      resetEpoch();
      _warmUpFrame = false;
      if (hadScheduledFrame) {
        scheduleFrame();
      }
    });

    // 锁定事件，以便触摸事件等在预定帧完成之前不会自行插入。
    // 在热身帧绘制结束前通过加锁来屏蔽期间的屏幕指针事件处理及_taskQueue中的回调，
    // 保证在绘制过程中不会再触发新的重绘。
    lockEvents(() async {
      await endOfFrame;
      if (!kReleaseMode) {
        debugTimelineTask!.finish();
      }
    });
  }

  Duration? _firstRawTimeStampInEpoch;
  Duration _epochStart = Duration.zero;
  Duration _lastRawTimeStamp = Duration.zero;

  /// Prepares the scheduler for a non-monotonic change to how time stamps are
  /// calculated.
  ///
  /// Callbacks received from the scheduler assume that their time stamps are
  /// monotonically increasing. The raw time stamp passed to [handleBeginFrame]
  /// is monotonic, but the scheduler might adjust those time stamps to provide
  /// [timeDilation]. Without careful handling, these adjusts could cause time
  /// to appear to run backwards.
  ///
  /// The [resetEpoch] function ensures that the time stamps are monotonic by
  /// resetting the base time stamp used for future time stamp adjustments to the
  /// current value. For example, if the [timeDilation] decreases, rather than
  /// scaling down the [Duration] since the beginning of time, [resetEpoch] will
  /// ensure that we only scale down the duration since [resetEpoch] was called.
  ///
  /// Setting [timeDilation] calls [resetEpoch] automatically. You don't need to
  /// call [resetEpoch] yourself.
  void resetEpoch() {
    _epochStart = _adjustForEpoch(_lastRawTimeStamp);
    _firstRawTimeStampInEpoch = null;
  }

  /// 将给定时间戳调整为当前纪元。
  ///
  /// This both offsets the time stamp to account for when the epoch started
  /// (both in raw time and in the epoch's own time line) and scales the time
  /// stamp to reflect the time dilation in the current epoch.
  ///
  /// These mechanisms together combine to ensure that the durations we give
  /// during frame callbacks are monotonically increasing.
  Duration _adjustForEpoch(Duration rawTimeStamp) {
    final Duration rawDurationSinceEpoch =
        _firstRawTimeStampInEpoch == null ? Duration.zero : rawTimeStamp - _firstRawTimeStampInEpoch!;
    return Duration(
        microseconds: (rawDurationSinceEpoch.inMicroseconds / timeDilation).round() + _epochStart.inMicroseconds);
  }

  /// The time stamp for the frame currently being processed.
  ///
  /// This is only valid while between the start of [handleBeginFrame] and the
  /// end of the corresponding [handleDrawFrame], i.e. while a frame is being
  /// produced.
  Duration get currentFrameTimeStamp {
    assert(_currentFrameTimeStamp != null);
    return _currentFrameTimeStamp!;
  }

  Duration? _currentFrameTimeStamp;

  /// The raw time stamp as provided by the engine to
  /// [dart:ui.PlatformDispatcher.onBeginFrame] for the frame currently being
  /// processed.
  ///
  /// Unlike [currentFrameTimeStamp], this time stamp is neither adjusted to
  /// offset when the epoch started nor scaled to reflect the [timeDilation] in
  /// the current epoch.
  ///
  /// On most platforms, this is a more or less arbitrary value, and should
  /// generally be ignored. On Fuchsia, this corresponds to the system-provided
  /// presentation time, and can be used to ensure that animations running in
  /// different processes are synchronized.
  Duration get currentSystemFrameTimeStamp {
    return _lastRawTimeStamp;
  }

  int _debugFrameNumber = 0;
  String? _debugBanner;

  // Whether the current engine frame needs to be postponed till after the
  // warm-up frame.
  //
  // Engine may begin a frame in the middle of the warm-up frame because the
  // warm-up frame is scheduled by timers while the engine frame is scheduled
  // by platform specific frame scheduler (e.g. `requestAnimationFrame` on the
  // web). When this happens, we let the warm-up frame finish, and postpone the
  // engine frame.
  bool _rescheduleAfterWarmUpFrame = false;

  void _handleBeginFrame(Duration rawTimeStamp) {
    if (_warmUpFrame) {
      // "begin frame" and "draw frame" must strictly alternate. Therefore
      // _rescheduleAfterWarmUpFrame cannot possibly be true here as it is
      // reset by _handleDrawFrame.
      assert(!_rescheduleAfterWarmUpFrame);
      _rescheduleAfterWarmUpFrame = true;
      return;
    }
    handleBeginFrame(rawTimeStamp);
  }

  void _handleDrawFrame() {
    if (_rescheduleAfterWarmUpFrame) {
      _rescheduleAfterWarmUpFrame = false;
      // Reschedule in a post-frame callback to allow the draw-frame phase of
      // the warm-up frame to finish.
      addPostFrameCallback((Duration timeStamp) {
        // Force an engine frame.
        //
        // We need to reset _hasScheduledFrame here because we cancelled the
        // original engine frame, and therefore did not run handleBeginFrame
        // who is responsible for resetting it. So if a frame callback set this
        // to true in the "begin frame" part of the warm-up frame, it will
        // still be true here and cause us to skip scheduling an engine frame.
        _hasScheduledFrame = false;
        scheduleFrame();
      }, debugLabel: 'SchedulerBinding.scheduleFrame');
      return;
    }
    handleDrawFrame();
  }

  final TimelineTask? _frameTimelineTask = kReleaseMode ? null : TimelineTask();

  /// 由引擎调用以准备框架以生成新frame.
  ///
  /// 该函数调用[scheduleFrameCallback]注册的所有瞬态帧回调
  /// 然后返回，运行任何计划的微任务microtasks
  /// (例如由瞬态帧回调解析的任何 [Future] 的处理程序),
  /// 并调用 [handleDrawFrame] 来继续该帧。
  ///
  /// 如果给定的时间戳为空，则重新使用最后一帧的时间戳。
  ///
  /// 要在调试模式下在每个帧的开头显示banner，将 [debugPrintBeginFrameBanner] 设置为 true。
  /// banner将使用 [debugPrint] 打印到控制台，并将包含帧编号（每帧递增 1）,以及帧的时间戳。
  /// 如果给定的时间戳为空，则显示字符串“预热帧”而不是时间戳。
  /// 这使得框架急切推送的帧能够与引擎响应来自操作系统的“Vsync”信号而请求的帧区分开来。
  ///
  /// 您还可以通过将 [debugPrintEndFrameBanner] 设置为 true 在每帧末尾显示banner。
  /// 这允许您区分帧期间打印的日志语句和帧之间打印的日志语句（例如响应事件或Timers）。
  void handleBeginFrame(Duration? rawTimeStamp) {
    _frameTimelineTask?.start('Frame');
    _firstRawTimeStampInEpoch ??= rawTimeStamp;
    _currentFrameTimeStamp = _adjustForEpoch(rawTimeStamp ?? _lastRawTimeStamp);
    if (rawTimeStamp != null) {
      _lastRawTimeStamp = rawTimeStamp;
    }

    assert(() {
      _debugFrameNumber += 1;

      if (debugPrintBeginFrameBanner || debugPrintEndFrameBanner) {
        final StringBuffer frameTimeStampDescription = StringBuffer();
        if (rawTimeStamp != null) {
          _debugDescribeTimeStamp(_currentFrameTimeStamp!, frameTimeStampDescription);
        } else {
          frameTimeStampDescription.write('(warm-up frame)');
        }
        _debugBanner =
            '▄▄▄▄▄▄▄▄ Frame ${_debugFrameNumber.toString().padRight(7)}   ${frameTimeStampDescription.toString().padLeft(18)} ▄▄▄▄▄▄▄▄';
        if (debugPrintBeginFrameBanner) {
          debugPrint(_debugBanner);
        }
      }
      return true;
    }());

    assert(schedulerPhase == SchedulerPhase.idle);
    _hasScheduledFrame = false;
    try {
      // TRANSIENT FRAME CALLBACKS  处理回调前设置为瞬态
      _frameTimelineTask?.start('Animate');
      _schedulerPhase = SchedulerPhase.transientCallbacks;
      final Map<int, _FrameCallbackEntry> callbacks = _transientCallbacks;
      _transientCallbacks = <int, _FrameCallbackEntry>{};
      //处理Animation回调
      callbacks.forEach((int id, _FrameCallbackEntry callbackEntry) {
        if (!_removedIds.contains(id)) {
          //使用 [timestamp] 作为参数调用给定的 [callback]。
          _invokeFrameCallback(callbackEntry.callback, _currentFrameTimeStamp!, callbackEntry.debugStack);
        }
      });
      _removedIds.clear();
    } finally {
      //回调处理完，设置为中间态，即先处理microTask任务队列
      _schedulerPhase = SchedulerPhase.midFrameMicrotasks;
    }
  }

  DartPerformanceMode? _performanceMode;
  int _numPerformanceModeRequests = 0;

  /// Request a specific [DartPerformanceMode].
  ///
  /// Returns `null` if the request was not successful due to conflicting performance mode requests.
  /// Two requests are said to be in conflict if they are not of the same [DartPerformanceMode] type,
  /// and an explicit request for a performance mode has been made prior.
  ///
  /// Requestor is responsible for calling [PerformanceModeRequestHandle.dispose] when it no longer
  /// requires the performance mode.
  PerformanceModeRequestHandle? requestPerformanceMode(DartPerformanceMode mode) {
    // conflicting requests are not allowed.
    if (_performanceMode != null && _performanceMode != mode) {
      return null;
    }

    if (_performanceMode == mode) {
      assert(_numPerformanceModeRequests > 0);
      _numPerformanceModeRequests++;
    } else if (_performanceMode == null) {
      assert(_numPerformanceModeRequests == 0);
      _performanceMode = mode;
      _numPerformanceModeRequests = 1;
    }

    return PerformanceModeRequestHandle._(_disposePerformanceModeRequest);
  }

  /// Remove a request for a specific [DartPerformanceMode].
  ///
  /// If all the pending requests have been disposed, the engine will revert to the
  /// [DartPerformanceMode.balanced] performance mode.
  void _disposePerformanceModeRequest() {
    _numPerformanceModeRequests--;
    if (_numPerformanceModeRequests == 0) {
      _performanceMode = null;
      PlatformDispatcher.instance.requestDartPerformanceMode(DartPerformanceMode.balanced);
    }
  }

  /// Returns the current [DartPerformanceMode] requested or `null` if no requests have
  /// been made.
  ///
  /// This is only supported in debug and profile modes, returns `null` in release mode.
  DartPerformanceMode? debugGetRequestedPerformanceMode() {
    if (!(kDebugMode || kProfileMode)) {
      return null;
    } else {
      return _performanceMode;
    }
  }

  /// 由引擎调用以产生新的frame.
  ///
  /// 该方法在[handleBeginFrame]之后立即调用。 它调用 [addPersistentFrameCallback] 注册的所有回调
  /// , 通常驱动rendering pipeline 然后调用[addPostFrameCallback]注册的回调。
  ///
  /// 有关debug hooks的讨论，请参阅 [handleBeginFrame]，这些讨论在使用帧回调时可能很有用。
  void handleDrawFrame() {
    assert(_schedulerPhase == SchedulerPhase.midFrameMicrotasks);
    _frameTimelineTask?.finish(); // end the "Animate" phase
    try {
      // PERSISTENT FRAME CALLBACKS
      _schedulerPhase = SchedulerPhase.persistentCallbacks;
      // 处理Persistent类型回调,主要包括build\layout\draw流程
      for (final FrameCallback callback in List<FrameCallback>.of(_persistentCallbacks)) {
        _invokeFrameCallback(callback, _currentFrameTimeStamp!);
      }

      // POST-FRAME CALLBACKS
      _schedulerPhase = SchedulerPhase.postFrameCallbacks;
      // 处理Post-Frame回调，主要是状态清理，准备调度下一帧绘制请求
      final List<FrameCallback> localPostFrameCallbacks = List<FrameCallback>.of(_postFrameCallbacks);
      _postFrameCallbacks.clear();
      Timeline.startSync('POST_FRAME');
      try {
        for (final FrameCallback callback in localPostFrameCallbacks) {
          _invokeFrameCallback(callback, _currentFrameTimeStamp!);
        }
      } finally {
        Timeline.finishSync();
      }
    } finally {
      //处理完成，设置为idle状态
      _schedulerPhase = SchedulerPhase.idle;
      _frameTimelineTask?.finish(); // end the Frame
      assert(() {
        if (debugPrintEndFrameBanner) {
          debugPrint('▀' * _debugBanner!.length);
        }
        _debugBanner = null;
        return true;
      }());
      _currentFrameTimeStamp = null;
    }
  }

  void _profileFramePostEvent(FrameTiming frameTiming) {
    postEvent('Flutter.Frame', <String, dynamic>{
      'number': frameTiming.frameNumber,
      'startTime': frameTiming.timestampInMicroseconds(FramePhase.buildStart),
      'elapsed': frameTiming.totalSpan.inMicroseconds,
      'build': frameTiming.buildDuration.inMicroseconds,
      'raster': frameTiming.rasterDuration.inMicroseconds,
      'vsyncOverhead': frameTiming.vsyncOverhead.inMicroseconds,
    });
  }

  static void _debugDescribeTimeStamp(Duration timeStamp, StringBuffer buffer) {
    if (timeStamp.inDays > 0) {
      buffer.write('${timeStamp.inDays}d ');
    }
    if (timeStamp.inHours > 0) {
      buffer.write('${timeStamp.inHours - timeStamp.inDays * Duration.hoursPerDay}h ');
    }
    if (timeStamp.inMinutes > 0) {
      buffer.write('${timeStamp.inMinutes - timeStamp.inHours * Duration.minutesPerHour}m ');
    }
    if (timeStamp.inSeconds > 0) {
      buffer.write('${timeStamp.inSeconds - timeStamp.inMinutes * Duration.secondsPerMinute}s ');
    }
    buffer.write('${timeStamp.inMilliseconds - timeStamp.inSeconds * Duration.millisecondsPerSecond}');
    final int microseconds = timeStamp.inMicroseconds - timeStamp.inMilliseconds * Duration.microsecondsPerMillisecond;
    if (microseconds > 0) {
      buffer.write('.${microseconds.toString().padLeft(3, "0")}');
    }
    buffer.write('ms');
  }

  // 使用 [timestamp] 作为参数调用给定的 [callback]。
  //
  // 将回调包装在 try/catch 中，并将任何错误转发到 [debugSchedulerExceptionHandler]（如果设置）。
  // 如果未设置，则打印错误。
  @pragma('vm:notify-debugger-on-exception')
  void _invokeFrameCallback(FrameCallback callback, Duration timeStamp, [StackTrace? callbackStack]) {
    assert(_FrameCallbackEntry.debugCurrentCallbackStack == null);
    assert(() {
      _FrameCallbackEntry.debugCurrentCallbackStack = callbackStack;
      return true;
    }());
    try {
      callback(timeStamp);
    } catch (exception, exceptionStack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: exceptionStack,
        library: 'scheduler library',
        context: ErrorDescription('during a scheduler callback'),
        informationCollector: (callbackStack == null)
            ? null
            : () {
                return <DiagnosticsNode>[
                  DiagnosticsStackTrace(
                    '\nThis exception was thrown in the context of a scheduler callback. '
                    'When the scheduler callback was _registered_ (as opposed to when the '
                    'exception was thrown), this was the stack',
                    callbackStack,
                  ),
                ];
              },
      ));
    }
    assert(() {
      _FrameCallbackEntry.debugCurrentCallbackStack = null;
      return true;
    }());
  }
}

/// The default [SchedulingStrategy] for [SchedulerBinding.schedulingStrategy].
///
/// If there are any frame callbacks registered, only runs tasks with
/// a [Priority] of [Priority.animation] or higher. Otherwise, runs
/// all tasks.
bool defaultSchedulingStrategy({required int priority, required SchedulerBinding scheduler}) {
  if (scheduler.transientCallbackCount > 0) {
    return priority >= Priority.animation.value;
  }
  return true;
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '_timeline_io.dart' if (dart.library.js_util) '_timeline_web.dart' as impl;
import 'constants.dart';

/// Measures how long blocks of code take to run.
///
/// This class can be used as a drop-in replacement for [Timeline] as it
/// provides methods compatible with [Timeline] signature-wise, and it has
/// minimal overhead.
///
/// Provides [debugReset] and [debugCollect] methods that make it convenient to use in
/// frame-oriented environment where collected metrics can be attributed to a
/// frame, then aggregated into frame statistics, e.g. frame averages.
///
/// Forwards measurements to [Timeline] so they appear in Flutter DevTools.
abstract final class FlutterTimeline {
  static _BlockBuffer _buffer = _BlockBuffer();

  /// Whether block timings are collected and can be retrieved using the
  /// [debugCollect] method.
  ///
  /// This is always false in release mode.
  static bool get debugCollectionEnabled => _collectionEnabled;

  /// Enables metric collection.
  ///
  /// Metric collection can only be enabled in non-release modes. It is most
  /// useful in profile mode where application performance is representative
  /// of a deployed application.
  ///
  /// When disabled, resets collected data by calling [debugReset].
  ///
  /// Throws a [StateError] if invoked in release mode.
  static set debugCollectionEnabled(bool value) {
    if (kReleaseMode) {
      throw _createReleaseModeNotSupportedError();
    }
    if (value == _collectionEnabled) {
      return;
    }
    _collectionEnabled = value;
    debugReset();
  }

  static StateError _createReleaseModeNotSupportedError() {
    return StateError('FlutterTimeline metric collection not supported in release mode.');
  }

  static bool _collectionEnabled = false;

  /// Start a synchronous operation labeled `name`.
  ///
  /// Optionally takes a map of `arguments`. This slice may also optionally be
  /// associated with a [Flow] event. This operation must be finished by calling
  /// [finishSync] before returning to the event queue.
  ///
  /// This is a drop-in replacement for [Timeline.startSync].
  static void startSync(String name, {Map<String, Object?>? arguments, Flow? flow}) {
    Timeline.startSync(name, arguments: arguments, flow: flow);
    if (!kReleaseMode && _collectionEnabled) {
      _buffer.startSync(name, arguments: arguments, flow: flow);
    }
  }

  /// Finish the last synchronous operation that was started.
  ///
  /// This is a drop-in replacement for [Timeline.finishSync].
  static void finishSync() {
    Timeline.finishSync();
    if (!kReleaseMode && _collectionEnabled) {
      _buffer.finishSync();
    }
  }

  /// Emit an instant event.
  ///
  /// This is a drop-in replacement for [Timeline.instantSync].
  static void instantSync(String name, {Map<String, Object?>? arguments}) {
    Timeline.instantSync(name, arguments: arguments);
  }

  /// A utility method to time a synchronous `function`. Internally calls
  /// `function` bracketed by calls to [startSync] and [finishSync].
  ///
  /// This is a drop-in replacement for [Timeline.timeSync].
  static T timeSync<T>(String name, TimelineSyncFunction<T> function, {Map<String, Object?>? arguments, Flow? flow}) {
    startSync(name, arguments: arguments, flow: flow);
    try {
      return function();
    } finally {
      finishSync();
    }
  }

  /// The current time stamp from the clock used by the timeline in
  /// microseconds.
  ///
  /// When run on the Dart VM, uses the same monotonic clock as the embedding
  /// API's `Dart_TimelineGetMicros`.
  ///
  /// When run on the web, uses `window.performance.now`.
  ///
  /// This is a drop-in replacement for [Timeline.now].
  static int get now => impl.performanceTimestamp.toInt();

  /// Returns timings collected since [debugCollectionEnabled] was set to true,
  /// since the previous [debugCollect], or since the previous [debugReset],
  /// whichever was last.
  ///
  /// Resets the collected timings.
  ///
  /// This is only meant to be used in non-release modes, typically in profile
  /// mode that provides timings close to release mode timings.
  static AggregatedTimings debugCollect() {
    if (kReleaseMode) {
      throw _createReleaseModeNotSupportedError();
    }
    if (!_collectionEnabled) {
      throw StateError('Timeline metric collection not enabled.');
    }
    final AggregatedTimings result = AggregatedTimings(_buffer.computeTimings());
    debugReset();
    return result;
  }

  /// Forgets all previously collected timing data.
  ///
  /// Use this method to scope metrics to a frame, a pointer event, or any
  /// other event. To do that, call [debugReset] at the start of the event, then
  /// call [debugCollect] at the end of the event.
  ///
  /// This is only meant to be used in non-release modes.
  static void debugReset() {
    if (kReleaseMode) {
      throw _createReleaseModeNotSupportedError();
    }
    _buffer = _BlockBuffer();
  }
}

/// Provides [start], [end], and [duration] of a named block of code, timed by
/// [FlutterTimeline].
@immutable
final class TimedBlock {
  /// Creates a timed block of code from a [name], [start], and [end].
  ///
  /// The [name] should be sufficiently unique and descriptive for someone to
  /// easily tell which part of code was measured.
  const TimedBlock({
    required this.name,
    required this.start,
    required this.end,
  }) : assert(end >= start, 'The start timestamp must not be greater than the end timestamp.');

  /// A readable label for a block of code that was measured.
  ///
  /// This field should be sufficiently unique and descriptive for someone to
  /// easily tell which part of code was measured.
  final String name;

  /// The timestamp in microseconds that marks the beginning of the measured
  /// block of code.
  final double start;

  /// The timestamp in microseconds that marks the end of the measured block of
  /// code.
  final double end;

  /// How long the measured block of code took to execute in microseconds.
  double get duration => end - start;

  @override
  String toString() {
    return 'TimedBlock($name, $start, $end, $duration)';
  }
}

/// Provides aggregated results for timings collected by [FlutterTimeline].
@immutable
final class AggregatedTimings {
  /// Creates aggregated timings for the provided timed blocks.
  AggregatedTimings(this.timedBlocks);

  /// All timed blocks collected between the last reset and [FlutterTimeline.debugCollect].
  final List<TimedBlock> timedBlocks;

  /// Aggregated timed blocks collected between the last reset and [FlutterTimeline.debugCollect].
  ///
  /// Does not guarantee that all code blocks will be reported. Only those that
  /// executed since the last reset are listed here. Use [getAggregated] for
  /// graceful handling of missing code blocks.
  late final List<AggregatedTimedBlock> aggregatedBlocks = _computeAggregatedBlocks();

  List<AggregatedTimedBlock> _computeAggregatedBlocks() {
    final Map<String, (double, int)> aggregate = <String, (double, int)>{};
    for (final TimedBlock block in timedBlocks) {
      final (double, int) previousValue = aggregate.putIfAbsent(block.name, () => (0, 0));
      aggregate[block.name] = (previousValue.$1 + block.duration, previousValue.$2 + 1);
    }
    return aggregate.entries.map<AggregatedTimedBlock>((MapEntry<String, (double, int)> entry) {
      return AggregatedTimedBlock(name: entry.key, duration: entry.value.$1, count: entry.value.$2);
    }).toList();
  }

  /// Returns aggregated numbers for a named block of code.
  ///
  /// If the block in question never executed since the last reset, returns an
  /// aggregation with zero duration and count.
  AggregatedTimedBlock getAggregated(String name) {
    return aggregatedBlocks.singleWhere(
      (AggregatedTimedBlock block) => block.name == name,
      // Handle the case where there are no recorded blocks of the specified
      // type. In this case, the aggregated duration is simply zero, and so is
      // the number of occurrences (i.e. count).
      orElse: () => AggregatedTimedBlock(name: name, duration: 0, count: 0),
    );
  }
}

/// Aggregates multiple [TimedBlock] objects that share a [name].
///
/// It is common for the same block of code to be executed multiple times within
/// a frame. It is useful to combine multiple executions and report the total
/// amount of time attributed to that block of code.
@immutable
final class AggregatedTimedBlock {
  /// Creates a timed block of code from a [name] and [duration].
  ///
  /// The [name] should be sufficiently unique and descriptive for someone to
  /// easily tell which part of code was measured.
  const AggregatedTimedBlock({
    required this.name,
    required this.duration,
    required this.count,
  }) : assert(duration >= 0);

  /// A readable label for a block of code that was measured.
  ///
  /// This field should be sufficiently unique and descriptive for someone to
  /// easily tell which part of code was measured.
  final String name;

  /// The sum of [TimedBlock.duration] values of aggretaged blocks.
  final double duration;

  /// The number of [TimedBlock] objects aggregated.
  final int count;

  @override
  String toString() {
    return 'AggregatedTimedBlock($name, $duration, $count)';
  }
}

const int _kSliceSize = 500;

/// 具有可预测add性能的可增长的 float64 值列表。
/// 该列表被组织成[Float64List]的“链”。
/// 该对象以[Float64List] “切片”开始。
/// 调用[add]时，该值将添加到切片中。一旦切片满了，它就会被移动到链中，并分配一个新的切片。
/// 切片大小是静态的，因此其分配具有可预测的成本。
/// 这与默认的[List]实现不同，后者在满时将其缓冲区大小加倍，并将所有旧元素复制到新缓冲区中，
/// 从而导致性能不可预测。这使得它成为记录性能的糟糕选择，因为缓冲区重新分配会影响运行时间。
/// 权衡是，与[List]相比，从链读回值的成本更高，因为它需要迭代多个切片。
/// 对于性能指标来说，这是一个合理的权衡，
/// 因为在记录指标时最大限度地减少开销比读取指标时更重要。
final class _Float64ListChain {
  _Float64ListChain();

  final List<Float64List> _chain = <Float64List>[];
  Float64List _slice = Float64List(_kSliceSize);
  int _pointer = 0;

  int get length => _length;
  int _length = 0;

  /// Adds and [element] to this chain.
  void add(double element) {
    _slice[_pointer] = element;
    _pointer += 1;
    _length += 1;
    if (_pointer >= _kSliceSize) {
      _chain.add(_slice);
      _slice = Float64List(_kSliceSize);
      _pointer = 0;
    }
  }

  /// Returns all elements added to this chain.
  /// 返回添加到此链的所有元素。
  /// 此 getter 并未针对快速进行优化。
  /// 假设读回指标时，它们不会影响正在进行基准测试的工作的时间安排。
  List<double> extractElements() {
    final List<double> result = <double>[];
    _chain.forEach(result.addAll);
    for (int i = 0; i < _pointer; i++) {
      result.add(_slice[i]);
    }
    return result;
  }
}

/// 与 [_Float64ListChain] 相同，但用于记录字符串值。
final class _StringListChain {
  _StringListChain();

  final List<List<String?>> _chain = <List<String?>>[];
  List<String?> _slice = List<String?>.filled(_kSliceSize, null);
  int _pointer = 0;

  int get length => _length;
  int _length = 0;

  /// Adds and [element] to this chain.
  void add(String element) {
    _slice[_pointer] = element;
    _pointer += 1;
    _length += 1;
    if (_pointer >= _kSliceSize) {
      _chain.add(_slice);
      _slice = List<String?>.filled(_kSliceSize, null);
      _pointer = 0;
    }
  }

  /// Returns all elements added to this chain.
  ///
  /// This getter is not optimized to be fast. It is assumed that when metrics
  /// are read back, they do not affect the timings of the work being
  /// benchmarked.
  List<String> extractElements() {
    final List<String> result = <String>[];
    for (final List<String?> slice in _chain) {
      for (final String? element in slice) {
        result.add(element!);
      }
    }
    for (int i = 0; i < _pointer; i++) {
      result.add(_slice[i]!);
    }
    return result;
  }
}

/// 记录代码块的开始和结束及其名称的缓冲区
final class _BlockBuffer {
  // 开始-结束块可以嵌套。通过堆叠来跟踪这种嵌套
  // 开始时间戳。完成时间戳将从堆栈中弹出计时并
  // 将 (start, finish) 元组添加到 _block 中
  static const int _stackDepth = 1000;
  static final Float64List _startStack = Float64List(_stackDepth);
  static final List<String?> _nameStack = List<String?>.filled(_stackDepth, null);
  static int _stackPointer = 0;

  final _Float64ListChain _starts = _Float64ListChain();
  final _Float64ListChain _finishes = _Float64ListChain();
  final _StringListChain _names = _StringListChain();

  List<TimedBlock> computeTimings() {
    assert(
        _stackPointer == 0,
        '`startSync` 和 `finishSync` 的序列无效。\n'
        '操作栈不为空。以下操作仍等待通过“finishSync”方法完成:\n'
        '${List<String>.generate(_stackPointer, (int i) => _nameStack[i]!).join(', ')}');

    final List<TimedBlock> result = <TimedBlock>[];
    final int length = _finishes.length;
    final List<double> starts = _starts.extractElements();
    final List<double> finishes = _finishes.extractElements();
    final List<String> names = _names.extractElements();

    assert(starts.length == length);
    assert(finishes.length == length);
    assert(names.length == length);

    for (int i = 0; i < length; i++) {
      result.add(TimedBlock(
        start: starts[i],
        end: finishes[i],
        name: names[i],
      ));
    }

    return result;
  }

  void startSync(String name, {Map<String, Object?>? arguments, Flow? flow}) {
    _startStack[_stackPointer] = impl.performanceTimestamp;
    _nameStack[_stackPointer] = name;
    _stackPointer += 1;
  }

  void finishSync() {
    assert(
        _stackPointer > 0,
        '`startSync` 和 `finishSync` 的序列无效。\n'
        '尝试完成代码块的计时，但没有挂起的“startSync”调用');

    final double finishTime = impl.performanceTimestamp;
    final double startTime = _startStack[_stackPointer - 1];
    final String name = _nameStack[_stackPointer - 1]!;
    _stackPointer -= 1;

    _starts.add(startTime);
    _finishes.add(finishTime);
    _names.add(name);
  }
}

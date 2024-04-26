// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show PointerChange, PointerData, PointerSignalKind;

import 'events.dart';

export 'dart:ui' show PointerData;

export 'events.dart' show PointerEvent;

// 当某些设备的指针按下时，将 `kPrimaryButton` 添加到 [buttons]。
//
// TODO(tongmu): This patch is supposed to be done by embedders. Patching it
// in framework is a workaround before [PointerEventConverter] is moved to embedders.
// https://github.com/flutter/flutter/issues/30454
int _synthesiseDownButtons(int buttons, PointerDeviceKind kind) {
  switch (kind) {
    case PointerDeviceKind.mouse:
    case PointerDeviceKind.trackpad:
      return buttons;
    case PointerDeviceKind.touch:
    case PointerDeviceKind.stylus:
    case PointerDeviceKind.invertedStylus:
      return buttons == 0 ? kPrimaryButton : buttons;
    case PointerDeviceKind.unknown:
      // We have no information about the device but we know we never want
      // buttons to be 0 when the pointer is down.
      return buttons == 0 ? kPrimaryButton : buttons;
  }
}

/// 回调的签名，该回调返回由提供的viewId标识的[FlutterView]的设备像素比。
/// 如果不存在具有提供的 ID 的视图，则返回 null。
/// 由[PointerEventConverter.expand]使用。
typedef DevicePixelRatioGetter = double? Function(int viewId);

/// 将 引擎指针数据 转换为 框架指针事件。
///
/// 这需要通过 [dart:ui.PlatformDispatcher.onPointerDataPacket]
/// 从引擎接收的 [PointerDataPacket] 对象，并将它们转换为 [PointerEvent] 对象。
abstract final class PointerEventConverter {
  /// 将给定的指针数据包扩展为一系列框架指针事件。
  /// devicePixelRatioForView 用于获取发生特定事件的视图的设备像素比率，
  /// 以将其数据从物理坐标转换为逻辑像素。有关 [PointerEvent] 坐标空间的更多详细信息，请参阅 [PointerEvent] 中的讨论。
  static Iterable<PointerEvent> expand(Iterable<ui.PointerData> data, DevicePixelRatioGetter devicePixelRatioForView) {
    return data
        .where((ui.PointerData datum) => datum.signalKind != ui.PointerSignalKind.unknown)
        .map<PointerEvent?>((ui.PointerData datum) {
      final double? devicePixelRatio = devicePixelRatioForView(datum.viewId);
      if (devicePixelRatio == null) {
        // View doesn't exist anymore.
        return null;
      }
      final Offset position = Offset(datum.physicalX, datum.physicalY) / devicePixelRatio;
      final Offset delta = Offset(datum.physicalDeltaX, datum.physicalDeltaY) / devicePixelRatio;
      final double radiusMinor = _toLogicalPixels(datum.radiusMinor, devicePixelRatio);
      final double radiusMajor = _toLogicalPixels(datum.radiusMajor, devicePixelRatio);
      final double radiusMin = _toLogicalPixels(datum.radiusMin, devicePixelRatio);
      final double radiusMax = _toLogicalPixels(datum.radiusMax, devicePixelRatio);
      final Duration timeStamp = datum.timeStamp;
      final PointerDeviceKind kind = datum.kind;
      switch (datum.signalKind ?? ui.PointerSignalKind.none) {
        case ui.PointerSignalKind.none:
          switch (datum.change) {
            case ui.PointerChange.add:
              return PointerAddedEvent(
                viewId: datum.viewId,
                timeStamp: timeStamp,
                kind: kind,
                device: datum.device,
                position: position,
                obscured: datum.obscured,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distance: datum.distance,
                distanceMax: datum.distanceMax,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
                embedderId: datum.embedderId,
              );
            case ui.PointerChange.hover:
              return PointerHoverEvent(
                viewId: datum.viewId,
                timeStamp: timeStamp,
                kind: kind,
                device: datum.device,
                position: position,
                delta: delta,
                buttons: datum.buttons,
                obscured: datum.obscured,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distance: datum.distance,
                distanceMax: datum.distanceMax,
                size: datum.size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
                synthesized: datum.synthesized,
                embedderId: datum.embedderId,
              );
            case ui.PointerChange.down:
              return PointerDownEvent(
                viewId: datum.viewId,
                timeStamp: timeStamp,
                pointer: datum.pointerIdentifier,
                kind: kind,
                device: datum.device,
                position: position,
                buttons: _synthesiseDownButtons(datum.buttons, kind),
                obscured: datum.obscured,
                pressure: datum.pressure,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distanceMax: datum.distanceMax,
                size: datum.size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
                embedderId: datum.embedderId,
              );
            case ui.PointerChange.move:
              return PointerMoveEvent(
                viewId: datum.viewId,
                timeStamp: timeStamp,
                pointer: datum.pointerIdentifier,
                kind: kind,
                device: datum.device,
                position: position,
                delta: delta,
                buttons: _synthesiseDownButtons(datum.buttons, kind),
                obscured: datum.obscured,
                pressure: datum.pressure,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distanceMax: datum.distanceMax,
                size: datum.size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
                platformData: datum.platformData,
                synthesized: datum.synthesized,
                embedderId: datum.embedderId,
              );
            case ui.PointerChange.up:
              return PointerUpEvent(
                viewId: datum.viewId,
                timeStamp: timeStamp,
                pointer: datum.pointerIdentifier,
                kind: kind,
                device: datum.device,
                position: position,
                buttons: datum.buttons,
                obscured: datum.obscured,
                pressure: datum.pressure,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distance: datum.distance,
                distanceMax: datum.distanceMax,
                size: datum.size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
                embedderId: datum.embedderId,
              );
            case ui.PointerChange.cancel:
              return PointerCancelEvent(
                viewId: datum.viewId,
                timeStamp: timeStamp,
                pointer: datum.pointerIdentifier,
                kind: kind,
                device: datum.device,
                position: position,
                buttons: datum.buttons,
                obscured: datum.obscured,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distance: datum.distance,
                distanceMax: datum.distanceMax,
                size: datum.size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
                embedderId: datum.embedderId,
              );
            case ui.PointerChange.remove:
              return PointerRemovedEvent(
                viewId: datum.viewId,
                timeStamp: timeStamp,
                kind: kind,
                device: datum.device,
                position: position,
                obscured: datum.obscured,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distanceMax: datum.distanceMax,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                embedderId: datum.embedderId,
              );
            case ui.PointerChange.panZoomStart:
              return PointerPanZoomStartEvent(
                viewId: datum.viewId,
                timeStamp: timeStamp,
                pointer: datum.pointerIdentifier,
                device: datum.device,
                position: position,
                embedderId: datum.embedderId,
                synthesized: datum.synthesized,
              );
            case ui.PointerChange.panZoomUpdate:
              final Offset pan = Offset(datum.panX, datum.panY) / devicePixelRatio;
              final Offset panDelta = Offset(datum.panDeltaX, datum.panDeltaY) / devicePixelRatio;
              return PointerPanZoomUpdateEvent(
                viewId: datum.viewId,
                timeStamp: timeStamp,
                pointer: datum.pointerIdentifier,
                device: datum.device,
                position: position,
                pan: pan,
                panDelta: panDelta,
                scale: datum.scale,
                rotation: datum.rotation,
                embedderId: datum.embedderId,
                synthesized: datum.synthesized,
              );
            case ui.PointerChange.panZoomEnd:
              return PointerPanZoomEndEvent(
                viewId: datum.viewId,
                timeStamp: timeStamp,
                pointer: datum.pointerIdentifier,
                device: datum.device,
                position: position,
                embedderId: datum.embedderId,
                synthesized: datum.synthesized,
              );
          }
        case ui.PointerSignalKind.scroll:
          if (!datum.scrollDeltaX.isFinite || !datum.scrollDeltaY.isFinite || devicePixelRatio <= 0) {
            return null;
          }
          final Offset scrollDelta = Offset(datum.scrollDeltaX, datum.scrollDeltaY) / devicePixelRatio;
          return PointerScrollEvent(
            viewId: datum.viewId,
            timeStamp: timeStamp,
            kind: kind,
            device: datum.device,
            position: position,
            scrollDelta: scrollDelta,
            embedderId: datum.embedderId,
          );
        case ui.PointerSignalKind.scrollInertiaCancel:
          return PointerScrollInertiaCancelEvent(
            viewId: datum.viewId,
            timeStamp: timeStamp,
            kind: kind,
            device: datum.device,
            position: position,
            embedderId: datum.embedderId,
          );
        case ui.PointerSignalKind.scale:
          return PointerScaleEvent(
            viewId: datum.viewId,
            timeStamp: timeStamp,
            kind: kind,
            device: datum.device,
            position: position,
            embedderId: datum.embedderId,
            scale: datum.scale,
          );
        case ui.PointerSignalKind.unknown:
          throw StateError('Unreachable');
      }
    }).whereType<PointerEvent>();
  }

  static double _toLogicalPixels(double physicalPixels, double devicePixelRatio) => physicalPixels / devicePixelRatio;
}

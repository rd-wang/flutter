// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:developer' as developer;
import 'dart:io' show exit;
import 'dart:ui' as ui
    show Brightness, PlatformDispatcher, SingletonFlutterWindow, window; // ignore: deprecated_member_use

// Before adding any more dart:ui imports, please read the README.

import 'package:meta/meta.dart';

import 'assertions.dart';
import 'basic_types.dart';
import 'constants.dart';
import 'debug.dart';
import 'object.dart';
import 'platform.dart';
import 'print.dart';
import 'service_extensions.dart';
import 'timeline.dart';

export 'dart:ui' show PlatformDispatcher, SingletonFlutterWindow, clampDouble; // ignore: deprecated_member_use

export 'basic_types.dart' show AsyncCallback, AsyncValueGetter, AsyncValueSetter;

// Examples can assume:
// mixin BarBinding on BindingBase { }

/// Signature for service extensions.
///
/// The returned map must not contain the keys "type" or "method", as
/// they will be replaced before the value is sent to the client. The
/// "type" key will be set to the string `_extensionType` to indicate
/// that this is a return value from a service extension, and the
/// "method" key will be set to the full name of the method.
typedef ServiceExtensionCallback = Future<Map<String, dynamic>> Function(Map<String, String> parameters);

/// 提供单例服务的 mixin 的基类。
///
/// Flutter 引擎 ([dart:ui]) 公开了一些底层服务，但这些服务通常不适合直接使用，
/// 例如，因为它们仅提供单个回调，应用程序可能希望复用该回调以允许多个侦听器。
/// 绑定在这些底层 API 和高级框架 API 之间提供了粘合剂。他们将两者结合在一起，因此得名。
///
/// 库通常会创建一个新的BindingMixin来公开dart:ui中的某个功能。
/// 一般来说，这种情况很少见，但这是替代框架可以做到的事情，
/// 例如如果框架要用替代 API 替换 [widgets] 库，但仍希望利用 [services] 和 [foundation] 库。
///
/// ## 实现BindingMixin:
/// 通过on关键字在[BindingBase]类上声明一个mixin，
/// 并实现initInstances方法和instance静态getter，可以创建BindingMixin。
/// [initInstances]方法必须调用super.initInstances 保证在应用程序的生命周期内仅构造一次；
/// 并设置一个_instance静态字段为this，
/// instance静态getter必须使用[checkInstance]返回该字段。
/// ### 设计建议
/// 尽量减少绑定中的内容:
///   这建议在设计 API 时，最好将较少的功能直接放在绑定（bindings）中。绑定通常指的是代码中不同部分之间的接口或连接。
///   更倾向于设计那些接受对象作为参数的 API，而不是直接引用全局的单例对象。这样的设计更有模块性，使代码更易于维护和测试。
/// 限制绑定只暴露独特的特性:
///   "绑定"在这里通常指的是不同编程语言或库之间的接口。
///   该建议表明应该尽量保持代码接口的简洁性，只公开那些真正只存在一次的、不容易在其他地方复制的功能。
///   举例来说，可以在 [dart:ui] 中找到的 API 可能是唯一存在的、不易在其他地方复制的功能。
/// 鼓励采用模块化、面向对象的 API 设计。重点是将功能封装在对象中，
/// 并通过绑定仅公开那些真正独特和必要的全局特性。这样设计可以使代码更易于维护和测试。
///
/// ## 实现Binding Class:
///
/// 最顶层用于编写应用程序 (e.g. [widgets] library)
/// 将有一个继承自 [BindingBase] 的具体类，
/// 并使用所有各种 [BindingBase] mixin（例如 [ServicesBinding]）.
/// Flutter 中的 [widgets] 库引入了一个名为 [WidgetsFlutterBinding] 的绑定
///
/// Binding class应该从每个层次结构中mixin它希望公开绑定，
/// 并应该有一个 ensureInitialized 方法，如果该层次结构中混入的 _instance 字段为null，则构造该类。
/// 这允许具有更具体需求的开发人员覆盖绑定，同时仍然允许其他代码在需要绑定时调用“ensureInitialized”。
///
/// ```dart
///mixin FooBinding on BindingBase, BarBinding {
///   @override
///   void initInstances() {
///     super.initInstances();
///     _instance = this;
///     // ...binding initialization...
///   }
///
///   static FooBinding get instance => BindingBase.checkInstance(_instance);
///   static FooBinding? _instance;
///
///   // ...binding features...
/// }
///
/// class FooLibraryBinding extends BindingBase with BarBinding, FooBinding {
///   static FooBinding ensureInitialized() {
///     if (FooBinding._instance == null) {
///       FooLibraryBinding();
///     }
///     return FooBinding.instance;
///   }
/// }
/// ```
abstract class BindingBase {
  /// Default abstract constructor for bindings.
  ///
  /// First calls [initInstances] to have bindings initialize their
  /// instance pointers and other state, then calls
  /// [initServiceExtensions] to have bindings initialize their
  /// VM service extensions, if any.
  BindingBase() {
    if (!kReleaseMode) {
      FlutterTimeline.startSync('Framework initialization');
    }
    assert(() {
      _debugConstructed = true;
      return true;
    }());

    assert(_debugInitializedType == null, 'Binding is already initialized to $_debugInitializedType');
    initInstances();
    assert(_debugInitializedType != null);

    assert(!_debugServiceExtensionsRegistered);
    initServiceExtensions();
    assert(_debugServiceExtensionsRegistered);

    if (!kReleaseMode) {
      developer.postEvent('Flutter.FrameworkInitialization', <String, String>{});
      FlutterTimeline.finishSync();
    }
  }

  bool _debugConstructed = false;
  static Type? _debugInitializedType;
  static bool _debugServiceExtensionsRegistered = false;

  /// 该属性已被标记为废弃，以便为 Flutter 未来版本中的多视图和多窗口支持做准备。
  ///
  /// 属性说明： window 属性表示应用程序的主视图，
  /// 在只有一个视图的应用程序中有用，比如为单显示移动设备设计的应用程序。
  /// 如果嵌入程序支持多视图，它指向创建的第一个视图，假设它是主视图。
  /// 如果尚未创建任何视图或第一个视图已被删除，则会引发异常。
  ///
  /// 迁移选项：
  /// 如果有 [BuildContext] 可用，
  /// 可以通过 [View.of] 查找与该上下文关联的当前 [FlutterView]。
  /// 这提供了与[window]相同的功能。然而，平台特定的功能已移至 [platformDispatcher]，
  /// 可以通过 [View.of] 返回的视图的 [FlutterView.platformDispatcher] 来访问。
  /// 使用带有 [BuildContext]  的  [View.of] 是迁移离开这个已弃用的 window 属性的首选选项。
  ///
  /// 如果没有[context]可用来查找 [FlutterView]，
  /// 则可以直接使用此绑定公开的 [platformDispatcher] 进行平台特定的功能。
  /// 它还在 [PlatformDispatcher.views] 中维护了所有可用 [FlutterView] 的列表，
  /// 以便在没有上下文的情况下访问特定于视图的功能。
  ///
  /// 相关链接：
  /// * [View.of] 通过提供的 [BuildContext] 访问与 [FlutterView] 关联的视图特定功能。
  /// * [FlutterView.platformDispatcher] 从给定的 [FlutterView]  访问平台特定功能。
  /// * [platformDispatcher] 访问[PlatformDispatcher]，提供平台特定功能。
  @Deprecated(
      'Look up the current FlutterView from the context via View.of(context) or consult the PlatformDispatcher directly instead. '
      'Deprecated to prepare for the upcoming multi-window support. '
      'This feature was deprecated after v3.7.0-32.0.pre.')
  ui.SingletonFlutterWindow get window => ui.window;

  /// 此绑定绑定到的[ui.PlatformDispatcher] 。是一个与Flutter绑定关联的平台调度
  /// 扩展自[BindingBase]的其他绑定，例如[ServicesBinding]、[RendererBinding]和[WidgetsBinding]。
  /// 每个绑定都定义了与[ui.PlatformDispatcher]进行交互的行为，
  /// 例如，[ServicesBinding]使用[ChannelBuffers]注册侦听器，
  /// [RendererBinding]注册[ui.PlatformDispatcher.onMetricsChanged]、[ui.PlatformDispatcher.onTextScaleFactorChanged]
  /// [SemanticsBinding]注册[ui.PlatformDispatcher.onSemanticsEnabledChanged]、
  /// [ui.PlatformDispatcher.onSemanticsActionEvent]和
  /// [ui.PlatformDispatcher.onAccessibilityFeaturesChanged]处理程序。
  ///
  /// 这些绑定中的每一个都可以静态地单独访问[ui.PlatformDispatcher]，
  /// 但这将排除使用虚假平台调度程序测试这些行为以进行验证的能力。因此，[BindingBase] 公开此 [ui.PlatformDispatcher] 供其他绑定使用。
  /// [BindingBase] 的子类（例如 [TestWidgetsFlutterBinding]）可以重写此访问器以返回不同的 [ui.PlatformDispatcher] 实现。
  ui.PlatformDispatcher get platformDispatcher => ui.PlatformDispatcher.instance;

  /// The initialization method. Subclasses override this method to hook into
  /// the platform and otherwise configure their services. Subclasses must call
  /// "super.initInstances()".
  ///
  /// The binding is not fully initialized when this method runs (for
  /// example, other binding mixins may not yet have run their
  /// [initInstances] method). For this reason, code in this method
  /// should avoid invoking callbacks or synchronously triggering any
  /// code that would normally assume that the bindings are ready.
  ///
  /// {@tool snippet}
  ///
  /// By convention, if the service is to be provided as a singleton,
  /// it should be exposed as `MixinClassName.instance`, a static
  /// getter with a non-nullable return type that returns
  /// `MixinClassName._instance`, a static field that is set by
  /// `initInstances()`. To improve the developer experience, the
  /// return value should actually be
  /// `BindingBase.checkInstance(_instance)` (see [checkInstance]), as
  /// in the example below.
  ///
  /// ```dart
  /// mixin BazBinding on BindingBase {
  ///   @override
  ///   void initInstances() {
  ///     super.initInstances();
  ///     _instance = this;
  ///     // ...binding initialization...
  ///   }
  ///
  ///   static BazBinding get instance => BindingBase.checkInstance(_instance);
  ///   static BazBinding? _instance;
  ///
  ///   // ...binding features...
  /// }
  /// ```
  /// {@end-tool}
  @protected
  @mustCallSuper
  void initInstances() {
    assert(_debugInitializedType == null);
    assert(() {
      _debugInitializedType = runtimeType;
      _debugBindingZone = Zone.current;
      return true;
    }());
  }

  /// A method that shows a useful error message if the given binding
  /// instance is not initialized.
  ///
  /// See [initInstances] for advice on using this method.
  ///
  /// This method either returns the argument or throws an exception.
  /// In release mode it always returns the argument.
  ///
  /// The type argument `T` should be the kind of binding mixin (e.g.
  /// `SchedulerBinding`) that is calling the method. It is used in
  /// error messages.
  @protected
  static T checkInstance<T extends BindingBase>(T? instance) {
    assert(() {
      if (_debugInitializedType == null && instance == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('Binding has not yet been initialized.'),
          ErrorDescription(
              'The "instance" getter on the $T binding mixin is only available once that binding has been initialized.'),
          ErrorHint(
            'Typically, this is done by calling "WidgetsFlutterBinding.ensureInitialized()" or "runApp()" (the '
            'latter calls the former). Typically this call is done in the "void main()" method. The "ensureInitialized" method '
            'is idempotent; calling it multiple times is not harmful. After calling that method, the "instance" getter will '
            'return the binding.',
          ),
          ErrorHint(
            'In a test, one can call "TestWidgetsFlutterBinding.ensureInitialized()" as the first line in the test\'s "main()" method '
            'to initialize the binding.',
          ),
          ErrorHint(
            'If $T is a custom binding mixin, there must also be a custom binding class, like WidgetsFlutterBinding, '
            'but that mixes in the selected binding, and that is the class that must be constructed before using the "instance" getter.',
          ),
        ]);
      }
      if (instance == null) {
        assert(_debugInitializedType == null);
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('Binding mixin instance is null but bindings are already initialized.'),
          ErrorDescription(
            'The "instance" property of the $T binding mixin was accessed, but that binding was not initialized when '
            'the "initInstances()" method was called.',
          ),
          ErrorHint(
            'This probably indicates that the $T mixin was not mixed into the class that was used to initialize the binding. '
            'If this is a custom binding mixin, there must also be a custom binding class, like WidgetsFlutterBinding, '
            'but that mixes in the selected binding. If this is a test binding, check that the binding being initialized '
            'is the same as the one into which the test binding is mixed.',
          ),
          ErrorHint(
            'It is also possible that $T does not implement "initInstances()" to assign a value to "instance". See the '
            'documentation of the BindingBase class for more details.',
          ),
          ErrorHint('The binding that was initialized was of the type "$_debugInitializedType". '),
        ]);
      }
      try {
        if (instance._debugConstructed && _debugInitializedType == null) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('Binding initialized without calling initInstances.'),
            ErrorDescription('An instance of $T is non-null, but BindingBase.initInstances() has not yet been called.'),
            ErrorHint(
              'This could happen because a binding mixin was somehow used outside of the normal binding mechanisms, or because '
              'the binding\'s initInstances() method did not call "super.initInstances()".',
            ),
            ErrorHint(
              'This could also happen if some code was invoked that used the binding while the binding was initializing, '
              'for example if the "initInstances" method invokes a callback. Bindings should not invoke callbacks before '
              '"initInstances" has completed.',
            ),
          ]);
        }
        if (!instance._debugConstructed) {
          // The state of _debugInitializedType doesn't matter in this failure mode.
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('Binding did not complete initialization.'),
            ErrorDescription(
                'An instance of $T is non-null, but the BindingBase() constructor has not yet been called.'),
            ErrorHint(
              'This could also happen if some code was invoked that used the binding while the binding was initializing, '
              "for example if the binding's constructor itself invokes a callback. Bindings should not invoke callbacks "
              'before "initInstances" has completed.',
            ),
          ]);
        }
      } on NoSuchMethodError {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('Binding does not extend BindingBase'),
          ErrorDescription('An instance of $T was created but the BindingBase constructor was not called.'),
          ErrorHint(
            'This could happen because the binding was implemented using "implements" rather than "extends" or "with". '
            'Concrete binding classes must extend or mix in BindingBase.',
          ),
        ]);
      }
      return true;
    }());
    return instance!;
  }

  /// In debug builds, the type of the current binding, if any, or else null.
  ///
  /// This may be useful in asserts to verify that the binding has not been initialized
  /// before the point in the application code that wants to initialize the binding, or
  /// to verify that the binding is the one that is expected.
  ///
  /// For example, if an application uses [Zone]s to report uncaught exceptions, it may
  /// need to ensure that `ensureInitialized()` has not yet been invoked on any binding
  /// at the point where it configures the zone and initializes the binding.
  ///
  /// If this returns null, the binding has not been initialized.
  ///
  /// If this returns a non-null value, it returns the type of the binding instance.
  ///
  /// To obtain the binding itself, consider the `instance` getter on the [BindingBase]
  /// subclass or mixin.
  ///
  /// This method only returns a useful value in debug builds. In release builds, the
  /// return value is always null; to improve startup performance, the type of the
  /// binding is not tracked in release builds.
  ///
  /// See also:
  ///
  ///  * [BindingBase], whose class documentation describes the conventions for dealing
  ///    with bindings.
  ///  * [initInstances], whose documentation details how to create a binding mixin.
  static Type? debugBindingType() {
    return _debugInitializedType;
  }

  Zone? _debugBindingZone;

  /// Whether [debugCheckZone] should throw (true) or just report the error (false).
  ///
  /// Setting this to true makes it easier to catch cases where the zones are
  /// misconfigured, by allowing debuggers to stop at the point of error.
  ///
  /// Currently this defaults to false, to avoid suddenly breaking applications
  /// that are affected by this check but appear to be working today. Applications
  /// are encouraged to resolve any issues that cause the [debugCheckZone] message
  /// to appear, as even if they appear to be working today, they are likely to be
  /// hiding hard-to-find bugs, and are more brittle (likely to collect bugs in
  /// the future).
  ///
  /// To silence the message displayed by [debugCheckZone], ensure that the same
  /// zone is used when calling `ensureInitialized()` as when calling the framework
  /// in any other context (e.g. via [runApp]).
  static bool debugZoneErrorsAreFatal = false;

  /// Checks that the current [Zone] is the same as that which was used
  /// to initialize the binding.
  ///
  /// If the current zone ([Zone.current]) is not the zone that was active when
  /// the binding was initialized, then this method generates a [FlutterError]
  /// exception with detailed information. The exception is either thrown
  /// directly, or reported via [FlutterError.reportError], depending on the
  /// value of [BindingBase.debugZoneErrorsAreFatal].
  ///
  /// To silence the message displayed by [debugCheckZone], ensure that the same
  /// zone is used when calling `ensureInitialized()` as when calling the
  /// framework in any other context (e.g. via [runApp]). For example, consider
  /// keeping a reference to the zone used to initialize the binding, and using
  /// [Zone.run] to use it again when calling into the framework.
  ///
  /// ## Usage
  ///
  /// The binding is considered initialized once [BindingBase.initInstances] has
  /// run; if this is called before then, it will throw an [AssertionError].
  ///
  /// The `entryPoint` parameter is the name of the API that is checking the
  /// zones are consistent, for example, `'runApp'`.
  ///
  /// This function always returns true (if it does not throw). It is expected
  /// to be invoked via the binding instance, e.g.:
  ///
  /// ```dart
  /// void startup() {
  ///   WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  ///   assert(binding.debugCheckZone('startup'));
  ///   // ...
  /// }
  /// ```
  ///
  /// If the binding expects to be used with multiple zones, it should override
  /// this method to return true always without throwing. (For example, the
  /// bindings used with [flutter_test] do this as they make heavy use of zones
  /// to drive the framework with an artificial clock and to catch errors and
  /// report them as test failures.)
  bool debugCheckZone(String entryPoint) {
    assert(() {
      assert(_debugBindingZone != null, 'debugCheckZone can only be used after the binding is fully initialized.');
      if (Zone.current != _debugBindingZone) {
        final Error message = FlutterError(
          'Zone mismatch.\n'
          'The Flutter bindings were initialized in a different zone than is now being used. '
          'This will likely cause confusion and bugs as any zone-specific configuration will '
          'inconsistently use the configuration of the original binding initialization zone '
          'or this zone based on hard-to-predict factors such as which zone was active when '
          'a particular callback was set.\n'
          'It is important to use the same zone when calling `ensureInitialized` on the binding '
          'as when calling `$entryPoint` later.\n'
          'To make this ${debugZoneErrorsAreFatal ? 'error non-fatal' : 'warning fatal'}, '
          'set BindingBase.debugZoneErrorsAreFatal to ${!debugZoneErrorsAreFatal} before the '
          'bindings are initialized (i.e. as the first statement in `void main() { }`).',
        );
        if (debugZoneErrorsAreFatal) {
          throw message;
        }
        FlutterError.reportError(FlutterErrorDetails(
          exception: message,
          stack: StackTrace.current,
          context: ErrorDescription('during $entryPoint'),
        ));
      }
      return true;
    }());
    return true;
  }

  /// Called when the binding is initialized, to register service
  /// extensions.
  ///
  /// Bindings that want to expose service extensions should overload
  /// this method to register them using calls to
  /// [registerSignalServiceExtension],
  /// [registerBoolServiceExtension],
  /// [registerNumericServiceExtension], and
  /// [registerServiceExtension] (in increasing order of complexity).
  ///
  /// Implementations of this method must call their superclass
  /// implementation.
  ///
  /// {@macro flutter.foundation.BindingBase.registerServiceExtension}
  ///
  /// See also:
  ///
  ///  * <https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md#rpcs-requests-and-responses>
  @protected
  @mustCallSuper
  void initServiceExtensions() {
    assert(!_debugServiceExtensionsRegistered);

    assert(() {
      registerSignalServiceExtension(
        name: FoundationServiceExtensions.reassemble.name,
        callback: reassembleApplication,
      );
      return true;
    }());

    if (!kReleaseMode) {
      if (!kIsWeb) {
        registerSignalServiceExtension(
          name: FoundationServiceExtensions.exit.name,
          callback: _exitApplication,
        );
      }
      // These service extensions are used in profile mode applications.
      registerStringServiceExtension(
        name: FoundationServiceExtensions.connectedVmServiceUri.name,
        getter: () async => connectedVmServiceUri ?? '',
        setter: (String uri) async {
          connectedVmServiceUri = uri;
        },
      );
      registerStringServiceExtension(
        name: FoundationServiceExtensions.activeDevToolsServerAddress.name,
        getter: () async => activeDevToolsServerAddress ?? '',
        setter: (String serverAddress) async {
          activeDevToolsServerAddress = serverAddress;
        },
      );
    }

    assert(() {
      registerServiceExtension(
        name: FoundationServiceExtensions.platformOverride.name,
        callback: (Map<String, String> parameters) async {
          if (parameters.containsKey('value')) {
            final String value = parameters['value']!;
            debugDefaultTargetPlatformOverride = null;
            for (final TargetPlatform candidate in TargetPlatform.values) {
              if (candidate.name == value) {
                debugDefaultTargetPlatformOverride = candidate;
                break;
              }
            }
            _postExtensionStateChangedEvent(
              FoundationServiceExtensions.platformOverride.name,
              defaultTargetPlatform.name,
            );
            await reassembleApplication();
          }
          return <String, dynamic>{
            'value': defaultTargetPlatform.name,
          };
        },
      );

      registerServiceExtension(
        name: FoundationServiceExtensions.brightnessOverride.name,
        callback: (Map<String, String> parameters) async {
          if (parameters.containsKey('value')) {
            switch (parameters['value']) {
              case 'Brightness.light':
                debugBrightnessOverride = ui.Brightness.light;
              case 'Brightness.dark':
                debugBrightnessOverride = ui.Brightness.dark;
              default:
                debugBrightnessOverride = null;
            }
            _postExtensionStateChangedEvent(
              FoundationServiceExtensions.brightnessOverride.name,
              (debugBrightnessOverride ?? platformDispatcher.platformBrightness).toString(),
            );
            await reassembleApplication();
          }
          return <String, dynamic>{
            'value': (debugBrightnessOverride ?? platformDispatcher.platformBrightness).toString(),
          };
        },
      );
      return true;
    }());
    assert(() {
      _debugServiceExtensionsRegistered = true;
      return true;
    }());
  }

  /// [lockEvents]当前是否正在锁定事件。
  /// 绑定触发事件的子类应该首先检查它，如果设置了，则对事件进行排队而不是触发它们。
  /// 调用 [unlocked] 时应刷新事件。
  @protected
  bool get locked => _lockCount > 0;
  int _lockCount = 0;

  /// ### 锁定异步事件和回调的调度，直到回调的 future 完成。
  /// 这会导致输入滞后，因此应尽可能避免。它主要用于非用户交互时间，
  /// 例如允许 [reassembleApplication] 在遍历树时阻止输入（部分是异步执行的）。
  /// ###`callback` 参数返回的 [Future] 由 [lockEvents] 返回。
  ///
  /// [gestures] 绑定将 [PlatformDispatcher.onPointerDataPacket]
  /// 包装在遵循此事件锁定机制的逻辑中。
  /// 同样，使用 [SchedulerBinding.scheduleTask] 排队的任务仅在事件未[locked]时启动。
  @protected
  Future<void> lockEvents(Future<void> Function() callback) {
    developer.TimelineTask? debugTimelineTask;
    if (!kReleaseMode) {
      debugTimelineTask = developer.TimelineTask()..start('Lock events');
    }

    _lockCount += 1;
    final Future<void> future = callback();
    future.whenComplete(() {
      _lockCount -= 1;
      if (!locked) {
        if (!kReleaseMode) {
          debugTimelineTask!.finish();
        }
        try {
          unlocked();
        } catch (error, stack) {
          FlutterError.reportError(FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'foundation',
            context: ErrorDescription('while handling pending events'),
          ));
        }
      }
    });
    return future;
  }

  /// 当事件解锁时由[lockEvents]调用。
  /// 这应该刷新 [locked] 为 true 时排队的所有事件。
  @protected
  @mustCallSuper
  void unlocked() {
    assert(!locked);
  }

  /// Cause the entire application to redraw, e.g. after a hot reload.
  ///
  /// This is used by development tools when the application code has changed,
  /// to cause the application to pick up any changed code. It can be triggered
  /// manually by sending the `ext.flutter.reassemble` service extension signal.
  ///
  /// This method is very computationally expensive and should not be used in
  /// production code. There is never a valid reason to cause the entire
  /// application to repaint in production. All aspects of the Flutter framework
  /// know how to redraw when necessary. It is only necessary in development
  /// when the code is literally changed on the fly (e.g. in hot reload) or when
  /// debug flags are being toggled.
  ///
  /// While this method runs, events are locked (e.g. pointer events are not
  /// dispatched).
  ///
  /// Subclasses (binding classes) should override [performReassemble] to react
  /// to this method being called. This method itself should not be overridden.
  Future<void> reassembleApplication() {
    return lockEvents(performReassemble);
  }

  /// This method is called by [reassembleApplication] to actually cause the
  /// application to reassemble, e.g. after a hot reload.
  ///
  /// Bindings are expected to use this method to re-register anything that uses
  /// closures, so that they do not keep pointing to old code, and to flush any
  /// caches of previously computed values, in case the new code would compute
  /// them differently. For example, the rendering layer triggers the entire
  /// application to repaint when this is called.
  ///
  /// Do not call this method directly. Instead, use [reassembleApplication].
  @mustCallSuper
  @protected
  Future<void> performReassemble() {
    FlutterError.resetErrorCount();
    return Future<void>.value();
  }

  /// Registers a service extension method with the given name (full
  /// name "ext.flutter.name"), which takes no arguments and returns
  /// no value.
  ///
  /// Calls the `callback` callback when the service extension is called.
  ///
  /// {@macro flutter.foundation.BindingBase.registerServiceExtension}
  @protected
  void registerSignalServiceExtension({
    required String name,
    required AsyncCallback callback,
  }) {
    registerServiceExtension(
      name: name,
      callback: (Map<String, String> parameters) async {
        await callback();
        return <String, dynamic>{};
      },
    );
  }

  /// Registers a service extension method with the given name (full
  /// name "ext.flutter.name"), which takes a single argument
  /// "enabled" which can have the value "true" or the value "false"
  /// or can be omitted to read the current value. (Any value other
  /// than "true" is considered equivalent to "false". Other arguments
  /// are ignored.)
  ///
  /// Calls the `getter` callback to obtain the value when
  /// responding to the service extension method being called.
  ///
  /// Calls the `setter` callback with the new value when the
  /// service extension method is called with a new value.
  ///
  /// {@macro flutter.foundation.BindingBase.registerServiceExtension}
  @protected
  void registerBoolServiceExtension({
    required String name,
    required AsyncValueGetter<bool> getter,
    required AsyncValueSetter<bool> setter,
  }) {
    registerServiceExtension(
      name: name,
      callback: (Map<String, String> parameters) async {
        if (parameters.containsKey('enabled')) {
          await setter(parameters['enabled'] == 'true');
          _postExtensionStateChangedEvent(name, await getter() ? 'true' : 'false');
        }
        return <String, dynamic>{'enabled': await getter() ? 'true' : 'false'};
      },
    );
  }

  /// Registers a service extension method with the given name (full
  /// name "ext.flutter.name"), which takes a single argument with the
  /// same name as the method which, if present, must have a value
  /// that can be parsed by [double.parse], and can be omitted to read
  /// the current value. (Other arguments are ignored.)
  ///
  /// Calls the `getter` callback to obtain the value when
  /// responding to the service extension method being called.
  ///
  /// Calls the `setter` callback with the new value when the
  /// service extension method is called with a new value.
  ///
  /// {@macro flutter.foundation.BindingBase.registerServiceExtension}
  @protected
  void registerNumericServiceExtension({
    required String name,
    required AsyncValueGetter<double> getter,
    required AsyncValueSetter<double> setter,
  }) {
    registerServiceExtension(
      name: name,
      callback: (Map<String, String> parameters) async {
        if (parameters.containsKey(name)) {
          await setter(double.parse(parameters[name]!));
          _postExtensionStateChangedEvent(name, (await getter()).toString());
        }
        return <String, dynamic>{name: (await getter()).toString()};
      },
    );
  }

  /// Sends an event when a service extension's state is changed.
  ///
  /// Clients should listen for this event to stay aware of the current service
  /// extension state. Any service extension that manages a state should call
  /// this method on state change.
  ///
  /// `value` reflects the newly updated service extension value.
  ///
  /// This will be called automatically for service extensions registered via
  /// [registerBoolServiceExtension], [registerNumericServiceExtension], or
  /// [registerStringServiceExtension].
  void _postExtensionStateChangedEvent(String name, dynamic value) {
    postEvent(
      'Flutter.ServiceExtensionStateChanged',
      <String, dynamic>{
        'extension': 'ext.flutter.$name',
        'value': value,
      },
    );
  }

  /// All events dispatched by a [BindingBase] use this method instead of
  /// calling [developer.postEvent] directly so that tests for [BindingBase]
  /// can track which events were dispatched by overriding this method.
  ///
  /// This is unrelated to the events managed by [lockEvents].
  @protected
  void postEvent(String eventKind, Map<String, dynamic> eventData) {
    developer.postEvent(eventKind, eventData);
  }

  /// Registers a service extension method with the given name (full name
  /// "ext.flutter.name"), which optionally takes a single argument with the
  /// name "value". If the argument is omitted, the value is to be read,
  /// otherwise it is to be set. Returns the current value.
  ///
  /// Calls the `getter` callback to obtain the value when
  /// responding to the service extension method being called.
  ///
  /// Calls the `setter` callback with the new value when the
  /// service extension method is called with a new value.
  ///
  /// {@macro flutter.foundation.BindingBase.registerServiceExtension}
  @protected
  void registerStringServiceExtension({
    required String name,
    required AsyncValueGetter<String> getter,
    required AsyncValueSetter<String> setter,
  }) {
    registerServiceExtension(
      name: name,
      callback: (Map<String, String> parameters) async {
        if (parameters.containsKey('value')) {
          await setter(parameters['value']!);
          _postExtensionStateChangedEvent(name, await getter());
        }
        return <String, dynamic>{'value': await getter()};
      },
    );
  }

  /// Registers a service extension method with the given name (full name
  /// "ext.flutter.name").
  ///
  /// The given callback is called when the extension method is called. The
  /// callback must return a [Future] that either eventually completes to a
  /// return value in the form of a name/value map where the values can all be
  /// converted to JSON using `json.encode()` (see [JsonEncoder]), or fails. In
  /// case of failure, the failure is reported to the remote caller and is
  /// dumped to the logs.
  ///
  /// The returned map will be mutated.
  ///
  /// {@template flutter.foundation.BindingBase.registerServiceExtension}
  /// A registered service extension can only be activated if the vm-service
  /// is included in the build, which only happens in debug and profile mode.
  /// Although a service extension cannot be used in release mode its code may
  /// still be included in the Dart snapshot and blow up binary size if it is
  /// not wrapped in a guard that allows the tree shaker to remove it (see
  /// sample code below).
  ///
  /// {@tool snippet}
  /// The following code registers a service extension that is only included in
  /// debug builds.
  ///
  /// ```dart
  /// void myRegistrationFunction() {
  ///   assert(() {
  ///     // Register your service extension here.
  ///     return true;
  ///   }());
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// {@tool snippet}
  /// A service extension registered with the following code snippet is
  /// available in debug and profile mode.
  ///
  /// ```dart
  /// void myOtherRegistrationFunction() {
  ///   // kReleaseMode is defined in the 'flutter/foundation.dart' package.
  ///   if (!kReleaseMode) {
  ///     // Register your service extension here.
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// Both guards ensure that Dart's tree shaker can remove the code for the
  /// service extension in release builds.
  /// {@endtemplate}
  @protected
  void registerServiceExtension({
    required String name,
    required ServiceExtensionCallback callback,
  }) {
    final String methodName = 'ext.flutter.$name';
    developer.registerExtension(methodName, (String method, Map<String, String> parameters) async {
      assert(method == methodName);
      assert(() {
        if (debugInstrumentationEnabled) {
          debugPrint('service extension method received: $method($parameters)');
        }
        return true;
      }());

      // VM service extensions are handled as "out of band" messages by the VM,
      // which means they are handled at various times, generally ASAP.
      // Notably, this includes being handled in the middle of microtask loops.
      // While this makes sense for some service extensions (e.g. "dump current
      // stack trace", which explicitly doesn't want to wait for a loop to
      // complete), Flutter extensions need not be handled with such high
      // priority. Further, handling them with such high priority exposes us to
      // the possibility that they're handled in the middle of a frame, which
      // breaks many assertions. As such, we ensure they we run the callbacks
      // on the outer event loop here.
      await debugInstrumentAction<void>('Wait for outer event loop', () {
        return Future<void>.delayed(Duration.zero);
      });

      late Map<String, dynamic> result;
      try {
        result = await callback(parameters);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          context: ErrorDescription('during a service extension callback for "$method"'),
        ));
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.extensionError,
          json.encode(<String, String>{
            'exception': exception.toString(),
            'stack': stack.toString(),
            'method': method,
          }),
        );
      }
      result['type'] = '_extensionType';
      result['method'] = method;
      return developer.ServiceExtensionResponse.result(json.encode(result));
    });
  }

  @override
  String toString() => '<${objectRuntimeType(this, 'BindingBase')}>';
}

/// Terminate the Flutter application.
Future<void> _exitApplication() async {
  exit(0);
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


// KEEP THIS SYNCHRONIZED WITH ../web_ui/lib/channel_buffers.dart
part of dart.ui;

/// Deprecated. Migrate to [ChannelCallback] instead.
///
/// Signature for [ChannelBuffers.drain]'s `callback` argument.
///
/// The first argument is the data sent by the plugin.
///
/// The second argument is a closure that, when called, will send messages
/// back to the plugin.
@Deprecated(
  'Migrate to ChannelCallback instead. '
  'This feature was deprecated after v3.11.0-20.0.pre.',
)
typedef DrainChannelCallback = Future<void> Function(ByteData? data, PlatformMessageResponseCallback callback);

/// [ChannelBuffers.setListener] 的 `callback` 参数的签名。
///
///   第一个参数是插件发送的数据。
///   第二个参数是一个闭包，调用时会将消息发送回插件。
/// See also:
///  * [PlatformMessageResponseCallback], 用于回复的类型。
typedef ChannelCallback = void Function(ByteData? data, PlatformMessageResponseCallback callback);

/// 存储和调用回调所需的数据和逻辑。
/// 这会跟踪（并应用）[Zone]。
class _ChannelCallbackRecord {
  _ChannelCallbackRecord(this._callback) : _zone = Zone.current;
  final ChannelCallback _callback;
  final Zone _zone;

  /// 使用给定的参数在 [zone] 中调用 [callback]。
  void invoke(ByteData? dataArg, PlatformMessageResponseCallback callbackArg) {
    _invoke2<ByteData?, PlatformMessageResponseCallback>(_callback, _zone, dataArg, callbackArg);
  }
}

/// 为通道保存的平台消息及其回调。
class _StoredMessage {
  /// 将平台消息的数据和回调包装到 [_StoredMessage] 实例中。
  ///
  /// 第一个参数是[ByteData]，表示消息的有效负载（payload），
  /// 第二个参数是[PlatformMessageResponseCallback]，表示在处理消息时将调用的回调函数。
  _StoredMessage(this.data, this._callback) : _zone = Zone.current;

  /// 消息有效负载的表示。
  final ByteData? data;

  /// 回复消息时使用的回调。
  final PlatformMessageResponseCallback _callback;

  final Zone _zone;

  void invoke(ByteData? dataArg) {
    _invoke1(_callback, _zone, dataArg);
  }
}

/// 平台通道的内部存储。
///
/// 这由 [_StoredMessage] 的固定大小循环队列和通道的回调（如果已注册）组成。
class _Channel {
  _Channel([ this._capacity = ChannelBuffers.kDefaultBufferSize ])
    : _queue = collection.ListQueue<_StoredMessage>(_capacity);

  /// 缓冲消息的基础数据。
  final collection.ListQueue<_StoredMessage> _queue;

  /// [_Channel] 中当前的消息数。小于等于[capacity].
  int get length => _queue.length;

  /// 当消息因通道溢出而被丢弃时，是否将消息转储到控制台。对发布版本没有影响。
  bool debugEnableDiscardWarnings = true;

  ///[_Channel]_可以_存储的消息数量。
  /// 当存储附加消息时，较早的消息将以先进先出的方式被丢弃。
  int get capacity => _capacity;
  int _capacity;
  /// 将通道的[capacity]设置为给定的大小
  /// 如果新的大小小于[length]，则最旧的消息将被丢弃，直到达到容量。
  /// 无论 [debugEnableDiscardWarnings] 的值如何，在溢出的情况下都不会显示任何消息。
  set capacity(int newSize) {
    _capacity = newSize;
    _dropOverflowMessages(newSize);
  }

  /// 微任务是否排队等待调用 [_drainStep]。
  ///
  /// 这用于对排出时收到的消息进行排队，而不是乱序发送它们。这通常不会在生产中发生，但在测试场景中是可能的。
  ///
  /// 这对于避免同时调用多个排出的情况也是必要的。
  /// 例如，如果设置了一个侦听器（对排出进行排队），
  /// 然后取消设置，
  /// 然后再次设置（这将再次对排出进行排队），
  /// 所有这些都在一个堆栈帧中（不允许排出本身有机会检查侦听器是否已设置）
  bool _draining = false;

  /// 向频道添加消息
  ///
  /// 如果通道溢出，较早的消息将按照先进先出的方式被丢弃。参见[capacity].
  /// 如果 [debugEnableDiscardWarnings] 为 true，则此方法在溢出时返回 true。
  /// 调用者有责任显示警告消息。
  bool push(_StoredMessage message) {
    if (!_draining && _channelCallbackRecord != null) {
      assert(_queue.isEmpty);
      _channelCallbackRecord!.invoke(message.data, message.invoke);
      return false;
    }
    if (_capacity <= 0) {
      return debugEnableDiscardWarnings;
    }
    final bool result = _dropOverflowMessages(_capacity - 1);
    _queue.addLast(message);
    return result;
  }

  /// 返回通道中的第一条消息并将其删除。Throws when empty.
  _StoredMessage pop() => _queue.removeFirst();

  /// 删除消息，直到 [length] 达到“lengthLimit”。
  /// 每条已删除消息的回调均以 null 作为参数进行调用。
  /// 如果删除任何消息，并且 [debugEnableDiscardWarnings] 为 true，
  /// 则返回 true。在这种情况下，调用者负责显示警告消息。
  bool _dropOverflowMessages(int lengthLimit) {
    bool result = false;
    while (_queue.length > lengthLimit) {
      final _StoredMessage message = _queue.removeFirst();
      message.invoke(null); // send empty reply to the plugin side
      result = true;
    }
    return result;
  }

  _ChannelCallbackRecord? _channelCallbackRecord;

  /// 设置该通道的监听器。
  /// 当有监听者时，消息会立即发送。
  /// 如果在添加侦听器之前有任何消息已排队，则在此方法返回后它们将被异步排出。
  /// （参见[_drain]。）
  /// 一次只能设置一个侦听器。设置新的侦听器会清除前一个侦听器。
  /// 回调在其自己的堆栈帧中调用，并使用注册回调时当前的区域。
  void setListener(ChannelCallback callback) {
    final bool needDrain = _channelCallbackRecord == null;
    _channelCallbackRecord = _ChannelCallbackRecord(callback);
    if (needDrain && !_draining) {
      _drain();
    }
  }

  /// 清除该通道的侦听器。
  /// 当没有侦听器时，消息将排队，直至达到 [capacity] ，然后以先进先出的方式丢弃。
  void clearListener() {
    _channelCallbackRecord = null;
  }

  /// 耗尽通道中的所有消息（为每条消息调用当前注册的侦听器）。
  ///
  /// 每条消息都在其自己的微任务中处理。当队列被清空时，
  /// 插件不能将消息放入队列, 但处理程序本身排队的任何微任务都将在处理下一条消息之前得到处理。
  ///
  /// 如果监听器被移除，耗尽就会停止。
  /// See also:
  ///  * [setListener],用于注册回调。
  ///  * [clearListener], 将其删除。
  void _drain() {
    assert(!_draining);
    _draining = true;
    scheduleMicrotask(_drainStep);
  }

  /// 处理一条消息，然后异步 重新调用 自身。
  /// 有关更多详细信息，请参阅 [_drain]。
  void _drainStep() {
    assert(_draining);
    if (_queue.isNotEmpty && _channelCallbackRecord != null) {
      final _StoredMessage message = pop();
      _channelCallbackRecord!.invoke(message.data, message.invoke);
      scheduleMicrotask(_drainStep);
    } else {
      _draining = false;
    }
  }
}

/// 引擎端插件发送到框架端相应插件代码的消息的缓冲和调度机制。
///
/// 通道的消息将被存储，直到使用 [setListener] 为该通道提供侦听器。每个通道只能配置一个侦听器。
///
/// 通常，一旦在 Flutter 框架中的 [BinaryMessenger] 上设置回调，
/// 这些缓冲区就会被排干。(参见[setListener]。)
///
/// ## channel名称
///
/// 按照惯例，通道通常使用反向 DNS 前缀、斜杠，然后是特定于域的名称来命名。例如，`com.example/demo`.
///
/// 通道名称不能包含 U+0000 NULL 字符，因为它们是通过使用 null 终止字符串的 API 传递的。
///
/// ## 缓冲区容量和溢出
///
/// 每个通道都有有限的缓冲区容量，如果超出容量，消息将以先进先出（FIFO）的方式删除。
///
/// 默认情况下，缓冲区每个通道存储一条消息，当消息溢出时，在调试模式下，一条消息将打印到控制台。该消息如下所示：
///
/// > A message on the com.example channel was discarded before it could be handled.
/// > This happens when a plugin sends messages to the framework side before the
/// > framework has had an opportunity to register a listener. See the
/// > ChannelBuffers API documentation for details on how to configure the channel
/// > to expect more messages, or to expect messages to get discarded:
/// >   https://api.flutter.dev/flutter/dart-ui/ChannelBuffers-class.html
///
/// 任何规模都需要权衡。应根据通道的语义选择正确的大小。要更改大小，插件可以使用控制通道发送消息，如下所述。
///
/// 大小 0 在引擎和框架准备好之前发送的channel 应该被忽略.
/// 例如 每当辐射传感器检测到电离事件时通知框架的插件可能会将其大小设置为零，
/// 因为过去的电离事件通常并不有趣，只有瞬时读数才值得跟踪。
///
/// 大小 1 适合关卡触发(level-triggered)的插件。
/// For example, 向框架通知压力传感器当前值的插件可能会将其大小保留为 1（默认值），同时不断发送消息；
/// 一旦插件的框架端向通道注册，它将立即接收最新的值，并且早期的消息将被丢弃。
///
/// 大于 1 适合每条消息都很重要的插件。
/// For example, 如果插件本身向另一个正在缓冲事件的系统注册，并立即转发所有先前缓冲的事件，
/// 则可能希望避免任何消息掉落在地板上。
/// 在这种情况下，选择避免溢出的尺寸非常重要。考虑框架端永远不会完全初始化的可能性也很重要
/// (e.g. 如果用户启动应用程序，但随后很快终止它，则为插件的平台端运行留下时间，而不是框架端运行).
///
/// ## 控制 channel
///
/// 插件可以通过向控制通道发送消息来配置其通道的缓冲区，
/// `dev.flutter/channel-buffers` (see [kControlChannelName]).
///
/// 有两条消息可以发送到该控制通道，以调整缓冲区大小并禁用溢出警告。有关这些消息的详细信息，请参阅 [handleMessage]。
class ChannelBuffers {
  /// 为平台消息创建缓冲池。
  ///
  /// 一般不需要创建该类的实例；全局 [channelBuffers] 实例是引擎使用的实例。
  ChannelBuffers();

  /// 通道缓冲区默认存储的消息数。
  static const int kDefaultBufferSize = 1;

  /// 插件可用于与通道缓冲区系统通信的通道名称。
  ///
  /// 这些消息由[handleMessage]处理。
  static const String kControlChannelName = 'dev.flutter/channel-buffers';

  /// 通道名称与其关联的 [_Channel] 之间的映射。
  final Map<String, _Channel> _channels = <String, _Channel>{};

  /// 将消息（`data`）添加到命名通道缓冲区（`name`）。
  /// “callback”参数是一个闭包，当调用时，会将消息发送回插件。
  ///
  /// 如果消息溢出通道，并且通道尚未配置为预期溢出，则在调试模式下，将向控制台打印一条有关溢出的消息警告。
  /// 通道名称不能包含 U+0000 NULL 字符，因为它们是通过使用 null 终止字符串的 API 传递的
  void push(String name, ByteData? data, PlatformMessageResponseCallback callback) {
    assert(!name.contains('\u0000'), 'Channel names must not contain U+0000 NULL characters.');
    final _Channel channel = _channels.putIfAbsent(name, () => _Channel());
    if (channel.push(_StoredMessage(data, callback))) {
      _printDebug(
        'A message on the $name channel was discarded before it could be handled.\n'
        'This happens when a plugin sends messages to the framework side before the '
        'framework has had an opportunity to register a listener. See the ChannelBuffers '
        'API documentation for details on how to configure the channel to expect more '
        'messages, or to expect messages to get discarded:\n'
        '  https://api.flutter.dev/flutter/dart-ui/ChannelBuffers-class.html\n'
        'The capacity of the $name channel is ${channel._capacity} message${channel._capacity != 1 ? 's' : ''}.',
      );
    }
  }

  /// 设置指定通道的监听器。
  ///
  /// 当有监听者时，消息会立即发送。
  ///
  /// 每个通道一次最多可以设置一个侦听器。
  /// 在具有现有侦听器的通道上设置新侦听器会清除前一个侦听器。
  ///
  /// 回调在其自己的堆栈帧中调用，并使用注册回调时当前的区域。
  ///
  /// ## Draining 排水
  ///
  /// 如果在添加侦听器之前有任何消息已排队，则在此方法返回后它们将被异步排出。
  ///
  /// 每条消息都在其自己的微任务中处理。当队列被清空时，插件不能将任何消息排队，
  /// 但处理程序本身排队的任何微任务都将在处理下一条消息之前得到处理。
  ///
  /// 如果监听器被移除，draining就会停止。
  void setListener(String name, ChannelCallback callback) {
    assert(!name.contains('\u0000'), 'Channel names must not contain U+0000 NULL characters.');
    final _Channel channel = _channels.putIfAbsent(name, () => _Channel());
    channel.setListener(callback);
    sendChannelUpdate(name, listening: true);
  }

  /// 清除指定通道的侦听器。
  ///
  /// 当没有侦听器时，该通道上的消息将排队，最多可达 [kDefaultBufferSize]
  /// （或通过控制通道配置的大小），然后以先进先出的方式丢弃。
  void clearListener(String name) {
    final _Channel? channel = _channels[name];
    if (channel != null) {
      channel.clearListener();
      sendChannelUpdate(name, listening: false);
    }
  }

  @Native<Void Function(Handle, Bool)>(symbol: 'PlatformConfigurationNativeApi::SendChannelUpdate')
  external static void _sendChannelUpdate(String name, bool listening);

  void sendChannelUpdate(String name, {required bool listening}) => _sendChannelUpdate(name, listening);

  /// Deprecated. Migrate to [setListener] instead.
  ///
  /// Remove and process all stored messages for a given channel.
  ///
  /// This should be called once a channel is prepared to handle messages
  /// (i.e. when a message handler is set up in the framework).
  ///
  /// The messages are processed by calling the given `callback`. Each message
  /// is processed in its own microtask.
  @Deprecated(
    'Migrate to setListener instead. '
    'This feature was deprecated after v3.11.0-20.0.pre.',
  )
  Future<void> drain(String name, DrainChannelCallback callback) async {
    final _Channel? channel = _channels[name];
    while (channel != null && !channel._queue.isEmpty) {
      final _StoredMessage message = channel.pop();
      await callback(message.data, message.invoke);
    }
  }

  /// 处理控制消息。
  ///
  /// 这旨在由平台消息调度程序调用，将消息从插件转发到 [kControlChannelName] 通道。
  ///
  /// 消息使用 [StandardMethodCodec] 格式。
  /// 支持两种方法：“resize”和“overflow”。 `resize` 方法更改缓冲区的大小，而 `overflow` 方法控制是否预期溢出。
  ///
  /// ## `resize`
  ///
  /// `resize` 方法将一个包含两个值的列表作为其参数，
  /// 第一个是通道名称（长度小于 254 字节且不包含任何空字节的 UTF-8 字符串），
  /// 第二个是通道缓冲区允许的大小（一个整数） 0 到 2147483647 之间）。
  ///
  /// 收到消息后，将调整通道缓冲区的大小。如有必要，消息将被静默丢弃，以确保缓冲区不大于指定大小。
  ///
  /// 由于历史原因，此消息也可以使用由 UTF-8 编码字符串组成的定制格式发送，
  /// 该字符串由三个部分组成，三个部分之间用 U+000D 回车 (CR) 字符分隔，
  /// 这三个部分是字符串“resize” ，给出通道名称的字符串，然后给出新通道缓冲区大小的十进制序列化的字符串。
  /// For example: `resize\rchannel\r1`
  ///
  /// ## `overflow`
  ///
  /// “overflow”方法将一个包含两个值的列表作为其参数，
  /// 第一个是通道名称（长度小于 254 字节且不包含任何空字节的 UTF-8 字符串），
  /// 第二个是布尔值，如果预期溢出则为 true，并且如果不是则为 false。
  ///
  /// 这会在debug下的通道上设置一个标志。在release下，该消息将被默默忽略。
  /// 该标志指示该通道是否会发生溢出。
  /// 设置该标志后，消息将被静默丢弃。
  /// 当该标志被清除（默认）时，通道上的任何溢出都会导致一条消息打印到控制台，警告消息丢失。
  void handleMessage(ByteData data) {
    // 因为 StandardMethodCodec 类 我们在这里对反序列化进行硬编码，
    // 是框架的一部分，而不是 dart:ui。
    final Uint8List bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    if (bytes[0] == 0x07) { // 7 = value code for string
      final int methodNameLength = bytes[1];
      if (methodNameLength >= 254) { // 长度大于 253 有更复杂的编码
        throw Exception('Unrecognized message sent to $kControlChannelName (method name too long)');
      }
      int index = 2; // 我们正在读取字节的位置
      final String methodName = utf8.decode(bytes.sublist(index, index + methodNameLength));
      index += methodNameLength;
      switch (methodName) {
        case 'resize':
          if (bytes[index] != 0x0C) { // 12 = value code for list
            throw Exception("Invalid arguments for 'resize' method sent to $kControlChannelName (arguments must be a two-element list, channel name and new capacity)");
          }
          index += 1;
          if (bytes[index] < 0x02) { // 我们忽略额外的参数，以防将来需要支持它们，因此 <2 而不是 !=2。
            throw Exception("Invalid arguments for 'resize' method sent to $kControlChannelName (arguments must be a two-element list, channel name and new capacity)");
          }
          index += 1;
          if (bytes[index] != 0x07) { // 7 = value code for string
            throw Exception("Invalid arguments for 'resize' method sent to $kControlChannelName (first argument must be a string)");
          }
          index += 1;
          final int channelNameLength = bytes[index];
          if (channelNameLength >= 254) { // 长度大于 253 有更复杂的编码
            throw Exception("Invalid arguments for 'resize' method sent to $kControlChannelName (channel name must be less than 254 characters long)");
          }
          index += 1;
          final String channelName = utf8.decode(bytes.sublist(index, index + channelNameLength));
          if (channelName.contains('\u0000')) {
            throw Exception("Invalid arguments for 'resize' method sent to $kControlChannelName (channel name must not contain any null bytes)");
          }
          index += channelNameLength;
          if (bytes[index] != 0x03) { // 3 = value code for uint32
            throw Exception("Invalid arguments for 'resize' method sent to $kControlChannelName (second argument must be an integer in the range 0 to 2147483647)");
          }
          index += 1;
          resize(channelName, data.getUint32(index, Endian.host));
        case 'overflow':
          if (bytes[index] != 0x0C) { // 12 = value code for list
            throw Exception("Invalid arguments for 'overflow' method sent to $kControlChannelName (arguments must be a two-element list, channel name and flag state)");
          }
          index += 1;
          if (bytes[index] < 0x02) { // 我们忽略额外的参数，以防将来需要支持它们，因此 <2 而不是 !=2。
            throw Exception("Invalid arguments for 'overflow' method sent to $kControlChannelName (arguments must be a two-element list, channel name and flag state)");
          }
          index += 1;
          if (bytes[index] != 0x07) { // 7 = value code for string
            throw Exception("Invalid arguments for 'overflow' method sent to $kControlChannelName (first argument must be a string)");
          }
          index += 1;
          final int channelNameLength = bytes[index];
          if (channelNameLength >= 254) { // 长度大于 253 有更复杂的编码
            throw Exception("Invalid arguments for 'overflow' method sent to $kControlChannelName (channel name must be less than 254 characters long)");
          }
          index += 1;
          final String channelName = utf8.decode(bytes.sublist(index, index + channelNameLength));
          index += channelNameLength;
          if (bytes[index] != 0x01 && bytes[index] != 0x02) { // 1 = value code for true, 2 = value code for false
            throw Exception("Invalid arguments for 'overflow' method sent to $kControlChannelName (second argument must be a boolean)");
          }
          allowOverflow(channelName, bytes[index] == 0x01);
        default:
          throw Exception("Unrecognized method '$methodName' sent to $kControlChannelName");
      }
    } else {
      final List<String> parts = utf8.decode(bytes).split('\r');
      if (parts.length == 1 + /*arity=*/2 && parts[0] == 'resize') {
        resize(parts[1], int.parse(parts[2]));
      } else {
        // 如果消息无法解码为 UTF-8，上面的 utf8.decode() 将抛出 FormatException。
        throw Exception('Unrecognized message $parts sent to $kControlChannelName.');
      }
    }
  }

  /// 更改与给定通道关联的队列的容量。
  ///
  /// 如果 newSize 小于队列的当前长度，这可能会导致消息被丢弃。
  ///
  /// 这预计将由特定于平台的插件代码（间接通过控制通道）调用，而不是由框架端的代码调用。请参阅[处理消息]。
  ///
  /// 从框架代码中调用此方法是多余的，因为当框架代码可以运行时，它只需订阅相关频道即可，因此不需要任何缓冲。
  void resize(String name, int newSize) {
    _Channel? channel = _channels[name];
    if (channel == null) {
      assert(!name.contains('\u0000'), 'Channel names must not contain U+0000 NULL characters.');
      channel = _Channel(newSize);
      _channels[name] = channel;
    } else {
      channel.capacity = newSize;
    }
  }

  /// 切换通道在因溢出而丢弃消息时是否应显示警告消息。
  ///
  /// 这预计将由特定于平台的插件代码（间接通过控制通道）调用，而不是由框架端的代码调用。请参阅[处理消息]。
  ///
  /// 从框架代码中调用此方法是多余的，因为当框架代码可以运行时，它只需订阅相关频道，因此不需要任何消息溢出。
  ///
  /// 此方法对发布版本没有影响。
  void allowOverflow(String name, bool allowed) {
    assert(() {
      _Channel? channel = _channels[name];
      if (channel == null && allowed) {
        assert(!name.contains('\u0000'), 'Channel names must not contain U+0000 NULL characters.');
        channel = _Channel();
        _channels[name] = channel;
      }
      channel?.debugEnableDiscardWarnings = !allowed;
      return true;
    }());
  }
}

/// [ChannelBuffers] 允许在引擎和框架之间存储消息。通常，无法传递的消息会存储在这里，直到框架能够处理它们。
///
/// See also:
/// * [BinaryMessenger]，通常读取 [ChannelBuffers]。
final ChannelBuffers channelBuffers = ChannelBuffers();

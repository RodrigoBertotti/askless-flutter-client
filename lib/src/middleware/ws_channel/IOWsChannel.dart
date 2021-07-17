import 'dart:convert';

import 'package:askless/askless.dart';
import 'package:askless/src/dependency_injection/index.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/data/Mappable.dart';
import 'package:askless/src/middleware/data/request/AbstractRequestCli.dart';
import 'package:askless/src/middleware/receivements/ClientReceived.dart';
import 'package:injectable/injectable.dart';
import 'package:web_socket_channel/io.dart';
import 'AbstractIOWsChannel.dart';
import 'FakeIOWsChannel.dart';
import 'package:meta/meta.dart';



@Injectable(as: AbstractIOWsChannel, env: ['dev', 'prod'])
class IOWsChannel extends AbstractIOWsChannel {
  IOWebSocketChannel? _channel;

  IOWsChannel(@factoryParam String? serverUrl) : super(serverUrl ?? '');

  @override
  void wsConnect() {
    _channel = IOWebSocketChannel.connect(serverUrl);
  }

  @override
  void wsListen(void Function(dynamic event) onData, {void Function(dynamic error)? onError, void Function()? onDone}) {
    _channel!.stream.listen(onData, onError: onError, onDone: onDone);
  }

  @override
  void sinkAdd({Mappable? map, String? data}) {
    super.sinkAdd(map: map, data: data);

    if(map != null) {
      _channel?.sink.add(jsonEncode(map.toMap()));
    }
    if(data!=null){
      _channel?.sink.add(data);
    }
  }

  @override
  void wsHandleError(void Function(dynamic error)? handleError) {
    _channel!.stream.handleError(handleError ?? (_){});
  }

  @override
  void wsClose() => _channel?.sink.close();

  @override
  bool get isReady => _channel != null;

}
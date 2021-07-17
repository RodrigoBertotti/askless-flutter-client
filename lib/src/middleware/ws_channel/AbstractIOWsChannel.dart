
import 'dart:convert';

import 'package:askless/askless.dart';
import 'package:askless/src/dependency_injection/index.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/data/Mappable.dart';
import 'package:askless/src/middleware/data/request/AbstractRequestCli.dart';
import 'package:askless/src/middleware/receivements/ClientReceived.dart';
import 'package:injectable/injectable.dart';
import 'package:web_socket_channel/io.dart';
import 'FakeIOWsChannel.dart';
import 'package:meta/meta.dart';

abstract class AbstractIOWsChannel {
  final String serverUrl;
  IOWebSocketChannel? _channel;
  int? _lastPongFromServer;

  AbstractIOWsChannel (this.serverUrl){
    assert(this.serverUrl.isNotEmpty);
  }

  void sinkAdd({Mappable? map, String? data}){
    assert(map!=null||data!=null);
    assert(map==null||data==null);
  }

  int? get lastPongFromServer => _lastPongFromServer;

  bool get isReady;

  @protected
  void wsConnect();

  @protected
  void wsClose();

  @protected
  void wsHandleError(void Function(dynamic error)? handleError);

  @protected
  void wsListen(void Function(dynamic data) param0, {void Function(dynamic err) onError, void Function() onDone});

  void start(){
    wsConnect();

    wsListen((data) {
      _lastPongFromServer = DateTime.now().millisecondsSinceEpoch;

      ClientReceived.from(data).handle();

    }, onError: (err) {
      Internal.instance.logger(message: "middleware: channel.stream.listen onError", level: Level.error, additionalData: err.toString());
    }, onDone: () =>  _handleConnectionClosed());

    wsHandleError((err) {
      Internal.instance.logger(message: "channel handleError", additionalData: err, level: Level.error);
    });
  }

  void _handleConnectionClosed([Duration delay=const Duration(seconds: 2)]) {
    Internal.instance.logger(message: "channel.stream.listen onDone");

    Future.delayed(delay, () {
      Internal.instance.middleware!.disconnectAndClearOnDone();
      Internal.instance.middleware!.disconnectAndClearOnDone = () {};

      if (Internal.instance.disconnectionReason != DisconnectionReason.TOKEN_INVALID &&
          Internal.instance.disconnectionReason != DisconnectionReason.DISCONNECTED_BY_CLIENT &&
          Internal.instance.disconnectionReason != DisconnectionReason.VERSION_CODE_NOT_SUPPORTED &&
          Internal.instance.disconnectionReason != DisconnectionReason.WRONG_PROJECT_NAME
      ) {
        if (Internal.instance.disconnectionReason == null) {
          Internal.instance.disconnectionReason = DisconnectionReason.UNDEFINED;
        }

        if(AsklessClient.instance.connection == Connection.DISCONNECTED){
          AsklessClient.instance.reconnect();
        }
      }
    });
  }

  void close() {
    Internal.instance.logger(message: 'close');
    _lastPongFromServer = null;
    wsClose();
    _channel = null;
  }

}




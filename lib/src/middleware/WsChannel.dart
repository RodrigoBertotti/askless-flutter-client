

import 'package:askless/askless.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/receivements/ClientReceived.dart';
import 'package:web_socket_channel/io.dart';

class WsChannel  {
  IOWebSocketChannel _channel;
  final String serverUrl;
  int _lastPongFromServer;

  WsChannel(this.serverUrl);

  int get lastPongFromServer => _lastPongFromServer;

  bool get isReady => _channel != null;

  void sinkAdd (data) => _channel?.sink?.add(data);

  connect(){
    _channel = IOWebSocketChannel.connect(serverUrl);

    _channel.stream.listen((data) {
      _lastPongFromServer = DateTime.now().millisecondsSinceEpoch;

      ClientReceived.from(data).handle();

    }, onError: (err) {
      Internal.instance.logger(message: "middleware: channel.stream.listen onError", level: Level.error, additionalData: err.toString());
    }, onDone: () =>  _handleConnectionClosed(Duration(seconds: 2))
    );

    _channel.stream.handleError((err) {
      Internal.instance.logger(message: "channel handleError", additionalData: err, level: Level.error);
    });
  }

  void close() {
    Internal.instance.logger(message: 'close');

    if (_channel != null)
      _channel.sink.close();

    _lastPongFromServer = null;
    _channel = null;
  }

  void _handleConnectionClosed(Duration delay) {
    Internal.instance.logger(message: "channel.stream.listen onDone");

    Future.delayed(delay, () {
      Internal.instance.middleware.disconnectAndClearOnDone();
      Internal.instance.middleware.disconnectAndClearOnDone = () {};

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

}
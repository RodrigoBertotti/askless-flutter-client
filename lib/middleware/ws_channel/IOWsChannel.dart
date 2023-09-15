import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../../../injection_container.dart';
import '../../domain/services/connection_service.dart';
import '../../domain/utils/logger.dart';
import '../data/Mappable.dart';
import 'AbstractIOWsChannel.dart';


class IOWsChannel extends AbstractIOWsChannel {
  WebSocketChannel? _channel;

  @override
  Future<bool> wsConnect() async {
    logger("wsConnect", level: Level.debug);
    try {
      final uri = Uri.parse(getIt.get<ConnectionService>().serverUrl);
      await HttpClient().get(uri.host, uri.port, uri.path);
      _channel = WebSocketChannel.connect(uri);
      return true;
    }catch (error) {
      if (!error.toString().contains("SocketException: Connection")) {
        logger(error.toString(), level: Level.error);
        _channel = WebSocketChannel.connect(Uri.parse(getIt.get<ConnectionService>().serverUrl));
        return true;
      } else {
        logger("Server is not online or App is disconnected from the internet", level: Level.debug);
        return false;
      }
    }
  }

  @override
  void wsListen(void Function(dynamic event) onData, {void Function(dynamic error)? onError, void Function()? onDone}) {
    _channel?.stream.listen(onData, onError: onError, onDone: onDone);
  }

  // static final List<String> _lastClientRequestIds = [];

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
    _channel?.stream.handleError(handleError ?? (_){});
  }

  @override
  void wsClose() {
    _channel?.sink.close();
    _channel = null;
  }

  @override
  bool get isReady => _channel != null;

}

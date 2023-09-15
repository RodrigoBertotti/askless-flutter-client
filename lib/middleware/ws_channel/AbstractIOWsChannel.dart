import 'dart:async';
import 'package:meta/meta.dart';
import '../../../../../../injection_container.dart';
import '../../index.dart';
import '../../middleware/data/request/AbstractRequestCli.dart';
import '../../domain/services/connection_service.dart';
import '../../domain/utils/logger.dart';
import '../data/Mappable.dart';
import '../receivements/ClientReceived.dart';

abstract class AbstractIOWsChannel {
  int? _lastPongFromServer;

  AbstractIOWsChannel ();

  void sinkAdd({Mappable? map, String? data}){
    assert(map!=null||data!=null);
    assert(map==null||data==null);
  }

  int? get lastPongFromServer => _lastPongFromServer;

  bool get isReady;

  @protected
  Future<bool> wsConnect();

  @protected
  void wsClose();

  @protected
  void wsHandleError(void Function(dynamic error)? handleError);

  @protected
  void wsListen(void Function(dynamic data) param0, {void Function(dynamic err) onError, void Function() onDone});

  Future<bool> start() async {
    final success = await wsConnect();
    if(!success) {
      return false;
    }

    final completer = Completer<bool>();

    Future.delayed(const Duration(seconds: 10), () { // timeout
      print ("completer.isCompleted #3: ${completer.isCompleted}");
      if (!completer.isCompleted) {
        logger("Could not connect the websocket, because of the timeout of 10 seconds");
        completer.complete(false);
      }
    });

    print ("completer.isCompleted #1: ${completer.isCompleted}");

    wsListen((data) {
      _lastPongFromServer = DateTime.now().millisecondsSinceEpoch;

      if (!completer.isCompleted) {
        completer.complete(true);
      }

      ClientReceived.from(data).handle();

    }, onError: (err) {
      logger("middleware: channel.stream.listen onError", level: Level.error, additionalData: err.toString());
    }, onDone: () {
      _handleConnectionClosed();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    wsHandleError((err) {
      logger("channel handleError", additionalData: err, level: Level.error);
    });

    return completer.future;
  }

  void _handleConnectionClosed([Duration delay=const Duration(seconds: 2)]) {
    logger("channel.stream.listen onDone");

    Future.delayed(delay, () {
      getIt.get<ConnectionService>().disconnectAndClearOnDone?.call();
      getIt.get<ConnectionService>().disconnectAndClearOnDone = null;

      if (getIt.get<ConnectionService>().disconnectionReason != DisconnectionReason.unsupportedVersionCode) {
        getIt.get<ConnectionService>().disconnectionReason ??= DisconnectionReason.other;

        if(AsklessClient.instance.connection.status == ConnectionStatus.disconnected){
          getIt.get<ConnectionService>().reconnect();
        }
        logger("${AsklessClient.instance.connection}");
      }
    });
  }

  void close() {
    logger('close');
    _lastPongFromServer = null;
    wsClose();
  }

}




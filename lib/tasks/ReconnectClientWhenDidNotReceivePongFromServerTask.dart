import '../../../../../injection_container.dart';
import '../domain/services/connection_service.dart';
import '../domain/utils/logger.dart';
import '../index.dart';
import '../middleware/data/receivements/ConfigureConnectionResponseCli.dart';
import '../middleware/ws_channel/AbstractIOWsChannel.dart';
import 'TimedTask.dart';

class ReconnectWhenDidNotReceivePongFromServerTask extends TimedTask{
//  OnChangeConnectionWithServerListener onConnectionChange;
  late bool _lastPongFromServerBeforeWasNull = false;
  bool _isFirst = true;

  ReconnectWhenDidNotReceivePongFromServerTask() : super('ReconnectWhenDidNotReceivePongFromServerTask', ConnectionConfiguration().reconnectClientAfterMillisecondsWithoutServerPong);

  @override
  onStop() {
//    Future.delayed(Duration(seconds: 3), (){
//      removeOnChangeConnectionWithServer(onConnectionChange);
//    });
  }

  @override
  onStart() {
    _lastPongFromServerBeforeWasNull = false;
  }


  @override
  void run() {
    if(_isFirst) {
      _isFirst = false;
      return;
    }
    final ws = getIt.get<AbstractIOWsChannel>();
    final lastPongFromServer = ws.lastPongFromServer;
    if((lastPongFromServer == null && _lastPongFromServerBeforeWasNull)
        || (lastPongFromServer != null && (lastPongFromServer + intervalInMs) < DateTime.now().millisecondsSinceEpoch)) {
      logger('reconnectWhenDidNotReceivePongFromServerTask reconnecting', level: Level.debug);
      getIt.get<ConnectionService>().reconnect();
    }
    _lastPongFromServerBeforeWasNull = lastPongFromServer == null;
  }

}

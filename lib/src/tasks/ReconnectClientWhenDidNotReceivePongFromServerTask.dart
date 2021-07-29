

import 'package:askless/src/middleware/data/receivements/ConfigureConnectionResponseCli.dart';


import '../index.dart';
import 'TimedTask.dart';

class ReconnectWhenDidNotReceivePongFromServerTask extends TimedTask{
//  OnChangeConnectionWithServerListener onConnectionChange;
  late bool _lastPongFromServerBeforeWasNull = false;
  bool _isFirst = true;

  ReconnectWhenDidNotReceivePongFromServerTask() : super('ReconnectWhenDidNotReceivePongFromServerTask', new ConnectionConfiguration().reconnectClientAfterSecondsWithoutServerPong);

  @override
  onStop() {
//    Future.delayed(Duration(seconds: 3), (){
//      Internal.instance.removeOnChangeConnectionWithServer(onConnectionChange);
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

    if(Internal.instance.middleware==null) {
      logger(message: 'reconnectWhenDidNotReceivePongFromServerTask: Dove.instance.middleware==null', level: Level.error);
      return;
    }

    final lastPongFromServer = Internal.instance.middleware?.ws?.lastPongFromServer;
    if(Internal.instance.disconnectionReason!=DisconnectionReason.TOKEN_INVALID && ((lastPongFromServer == null && Internal.instance.middleware!.ws!=null && _lastPongFromServerBeforeWasNull) || (lastPongFromServer != null && lastPongFromServer + intervalInSeconds * 1000 < DateTime.now().millisecondsSinceEpoch))) {
      logger(message: 'reconnectWhenDidNotReceivePongFromServerTask reconnecting', level: Level.debug);
      AsklessClient.instance.reconnect();
    }
    _lastPongFromServerBeforeWasNull = lastPongFromServer == null;
  }

}



import 'package:askless/src/middleware/data/receivements/ConfigureConnectionResponseCli.dart';


import '../index.dart';
import 'TimedTask.dart';

class ReconnectWhenDidNotReceivePongFromServerTask extends TimedTask{
//  OnChangeConnectionWithServerListener onConnectionChange;
  bool _lastPongFromServerBeforeWasNull;
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
    assert(_lastPongFromServerBeforeWasNull!=null);

    if(Internal.instance==null) {
      Internal.instance.logger(message: 'reconnectWhenDidNotReceivePongFromServerTask: Dove.instance==null', level: Level.error);
      return;
    }
    if(Internal.instance.middleware==null) {
      Internal.instance.logger(message: 'reconnectWhenDidNotReceivePongFromServerTask: Dove.instance.middleware==null', level: Level.error);
      return;
    }

    final lastPongFromServer = Internal.instance.middleware.lastPongFromServer;
    if(Internal.instance.disconnectionReason!=DisconnectionReason.TOKEN_INVALID && ((lastPongFromServer == null && Internal.instance.middleware.channel!=null && _lastPongFromServerBeforeWasNull) || (lastPongFromServer != null && lastPongFromServer + intervalInSeconds * 1000 < DateTime.now().millisecondsSinceEpoch))) {
      Internal.instance.logger(message: 'reconnectWhenDidNotReceivePongFromServerTask reconnecting', level: Level.debug);
      AsklessClient.instance.reconnect();
    }
    _lastPongFromServerBeforeWasNull = lastPongFromServer == null;
  }

}

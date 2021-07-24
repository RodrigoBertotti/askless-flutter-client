import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:askless/src/middleware/data/receivements/ConfigureConnectionResponseCli.dart';

import '../index.dart';

class ReconnectWhenOffline{
  final Connectivity _connectivityManager = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  int secondsToDisconnectWithoutPingFromClient = new ConnectionConfiguration().reconnectClientAfterSecondsWithoutServerPong;
  ConnectivityResult? _connectivity;
  bool _isFirstTime = true;

  ConnectivityResult? get connectivity => _connectivity;

  start(){
    if(noTasks){
      logger(message: "Not starting ReconnectWhenOffline, because noTasks == true");
      return;
    }

    stop();
    Future.delayed(Duration(seconds: 1), (){
      _connectivitySubscription =
          _connectivityManager.onConnectivityChanged.listen((ConnectivityResult conn) {
            if(_isFirstTime){
              _isFirstTime = false;
              return;
            }
            _connectivity = conn;

            if (conn == ConnectivityResult.none) {
              Internal.instance.notifyConnectionChanged(Connection.DISCONNECTED);
              logger(message: 'Lost internet connection', level: Level.debug);
            } else {
              logger(message: 'Got internet connection, reconnecting...', level: Level.debug);
              try{
                AsklessClient.instance.reconnect();
              }catch(e){
                 logger(message: 'ReconnectWhenOffline', level:  Level.error, additionalData: e);
              }
            }
          });
    });
  }

  stop(){
    _connectivitySubscription?.cancel();
  }
}

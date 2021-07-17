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
              Internal.instance.logger(message: 'Lost internet connection', level: Level.debug);
            } else {
              Internal.instance.logger(message: 'Got internet connection, reconnecting...', level: Level.debug);
              try{
                AsklessClient.instance.reconnect();
              }catch(e){
                 Internal.instance.logger(message: 'ReconnectWhenOffline', level:  Level.error, additionalData: e);
              }
            }
          });
    });
  }

  stop(){
    _connectivitySubscription?.cancel();
  }
}

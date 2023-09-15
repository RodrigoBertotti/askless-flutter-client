import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../../injection_container.dart';
import '../domain/services/connection_service.dart';
import '../domain/utils/logger.dart';
import '../index.dart';
import '../middleware/data/receivements/ConfigureConnectionResponseCli.dart';

class ReconnectWhenOffline{
  final Connectivity _connectivityManager = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  int secondsToDisconnectWithoutPingFromClient = ConnectionConfiguration().reconnectClientAfterMillisecondsWithoutServerPong;
  ConnectivityResult? _connectivity;
  bool _isFirstTime = true;

  ConnectivityResult? get connectivity => _connectivity;

  start(){
    stop();
    Future.delayed(const Duration(seconds: 1), (){
      _connectivitySubscription =
          _connectivityManager.onConnectivityChanged.listen((ConnectivityResult conn) {
            if(_isFirstTime){
              _isFirstTime = false;
              return;
            }
            _connectivity = conn;

            if (conn == ConnectivityResult.none) {
              getIt.get<ConnectionService>().notifyConnectionChanged(ConnectionStatus.disconnected);
              logger('Lost internet connection',);
            } else {
              logger('Got internet connection, reconnecting...', level: Level.debug);
              try {
                getIt.get<ConnectionService>().reconnect();
              } catch(e) {
                 logger('ReconnectWhenOffline', level:  Level.error, additionalData: e);
              }
            }
          });
    });
  }

  stop(){
    _connectivitySubscription?.cancel();
  }
}

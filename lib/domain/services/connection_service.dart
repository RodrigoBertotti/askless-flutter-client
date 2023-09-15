import 'dart:async';
import 'package:random_string/random_string.dart';
import '../../../../../../injection_container.dart';
import '../../constants.dart';
import '../../index.dart';
import '../../middleware/data/receivements/ConfigureConnectionResponseCli.dart';
import '../../middleware/data/request/ConfigureConnectionRequestCli.dart';
import '../../middleware/ws_channel/AbstractIOWsChannel.dart';
import '../../tasks/ReconnectClientWhenDidNotReceivePongFromServerTask.dart';
import '../../tasks/SendMessageToServerAgainTask.dart';
import '../../tasks/SendPingTask.dart';
import '../utils/logger.dart';
import '../services/requests_service.dart';


class ConnectionService {
  static final String clientIdInternalApp = randomAlphaNumeric(28);
  String? _serverUrl;
  void Function()? disconnectAndClearOnDone;
  AbstractIOWsChannel? ws;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  bool _initialized = false;
  final List<OnConnectionChange> _onConnectionWithServerChangeListeners = [];
  final List<OnConnectionChange> _onConnectionWithServerChangeListenersBeforeOthersListeners = [];
  final StreamController<ConnectionDetails> _connectionWithServerChangesStreamController = StreamController.broadcast();
  DisconnectionReason? disconnectionReason;
  bool _connectHasBeenCalledAtLeastOneTime = false;
  ConnectionConfiguration connectionConfiguration = ConnectionConfiguration();

  String get serverUrl { assert(_initialized, "should initialize first"); return _serverUrl!; }
  ConnectionDetails get connection => ConnectionDetails(_connectionStatus, disconnectionReason);
  bool get connectHasBeenCalledAtLeastOneTime => _connectHasBeenCalledAtLeastOneTime;

  void start({required String serverUrl}) {
    assert(serverUrl.startsWith('ws:') || serverUrl.startsWith('wss:'));
    if(serverUrl.contains('192.168.') && !serverUrl.contains(':')) {
      throw 'Please, inform the port on the serverUrl, default is 3000, example: ws://192.168.0.8:3000';
    }
    _serverUrl = serverUrl;
    _initialized = true;
    _connect();
  }

  Future<void> reconnect() async {
    if(!_connectHasBeenCalledAtLeastOneTime) {
      throw "'reconnect' only can be called after a 'start'";
    }

    logger("reconnect", level: Level.debug);
    await _connect();
  }

  _checkIfIsNeededToStopConnectionFromBeingEstablished(ConnectionConfiguration connectionConfiguration) {
    if (connectionConfiguration.incompatibleVersion) {
      disconnectAndClear();
      disconnectionReason = DisconnectionReason.unsupportedVersionCode;
      throw "Check if you server and client are updated! Your Askless version on server is ${connectionConfiguration.serverVersion}. Your Askless client version is $CLIENT_LIBRARY_VERSION_NAME";
    }

    // if (connectionConfiguration.differentProjectId) {
    //   disconnectAndClear();
    //   disconnectionReason = DisconnectionReason.incorrectProjectId;
    //   throw "Looks like you are not running the right server (${connectionConfiguration.projectId ?? 'null'}) to your Flutter Client project (${AsklessClient.instance.projectId ?? 'null'})";
    // }
  }

  Future<void> _connect() async {
    //TODO???: if the credentials are the same and it is already connected, return ConfigureConnectionAsklessResponse instantaneously
    logger("connecting...", level: Level.debug);

    getIt.get<ConnectionService>().notifyConnectionChanged(ConnectionStatus.disconnected);

    if(_connectHasBeenCalledAtLeastOneTime){
      disconnectAndClear();
      ws?.close();
      ws = null;
      disconnectionReason = null;
    }
    _connectHasBeenCalledAtLeastOneTime = true;

    notifyConnectionChanged(ConnectionStatus.inProgress);
    connectionConfiguration = ConnectionConfiguration(); //restaurando isFromServer para false, pois quando se perde  é mantido o connectionConfiguration da conexão atual

    logger("middleware: connect");

    ws = getIt.get<AbstractIOWsChannel>();
    final wsSuccess = await ws!.start();
    if (wsSuccess) {
      await _configureConnection();
    } else if (getIt.get<ConnectionService>().connection.status == ConnectionStatus.inProgress){
      getIt.get<ConnectionService>().notifyConnectionChanged(ConnectionStatus.disconnected);
    }
  }

  Future<void> _configureConnection () async {
    final response = ConfigureConnectionAsklessResponse.fromResponse(
        await getIt.get<RequestsService>().runOperationInServer(
          data: ConfigureConnectionRequestCli(clientIdInternalApp,),
          neverTimeout: true,
          isPersevere: () => false,
        )
    );
    if (response.error != null) {
      logger("Data could not be sent, got an error", level: Level.error, additionalData: '${response.error?.code??''} ${response.error?.description??''}');
      notifyConnectionChanged(ConnectionStatus.disconnected);

      Future.delayed(const Duration(seconds: 1), () {_connect();});
      return;
    } else {
      connectionConfiguration = response.connectionConfiguration!;
      _checkIfIsNeededToStopConnectionFromBeingEstablished(connectionConfiguration);

      getIt.get<SendPingTask>().changeInterval(connectionConfiguration.intervalInMsClientPing);
      getIt.get<ReconnectWhenDidNotReceivePongFromServerTask>().changeInterval(connectionConfiguration.reconnectClientAfterMillisecondsWithoutServerPong);

      print ("------------------- _configureConnection ------------------");
      notifyConnectionChanged(ConnectionStatus.connected);

      Future.delayed(const Duration(seconds: 1), (){
        getIt.get<SendMessageToServerAgainTask>().changeInterval(connectionConfiguration.intervalInMsClientSendSameMessage);
      });
    }
  }


  bool get isInitialized => _initialized;

  Future<void> waitForConnection () async {
    await _waitForConnectionImp(timeout: null);
  }
  Future<bool> waitForConnectionOrTimeout ({Duration? timeout}) {
    return _waitForConnectionImp(timeout: timeout);
  }
  Future<bool> _waitForConnectionImp({Duration? timeout}) async {
    if (!_initialized) {
      throw 'Ops! Looks like you forgot to call "AsklessClient.instance.start()"';
    }
    if (_connectionStatus == ConnectionStatus.connected){
      return true;
    }
    late final OnConnectionChange onConnectionChange;
    final completer = Completer<bool>();
    if (timeout != null && timeout.inMilliseconds > 0) {
      Future.delayed(timeout).then((_) {
        if (!completer.isCompleted){
          removeOnConnectionChange(onConnectionChange);
          completer.complete(false);
        }
      });
    }
    // ignore: prefer_function_declarations_over_variables
    onConnectionChange = (ConnectionDetails connection, [DisconnectionReason? disconnectionReason]) {
      if (connection.status == ConnectionStatus.connected && !completer.isCompleted) {
        completer.complete(true);
        removeOnConnectionChange(onConnectionChange);
      }
    };
    addOnConnectionChangeListener(onConnectionChange, immediately: true);
    return completer.future;
  }


  void disconnectAndClear({void Function() ? onDone}) {
    logger('disconnectAndClear');
    if (onDone != null) { disconnectAndClearOnDone = onDone; }

    notifyConnectionChanged(ConnectionStatus.disconnected);

    ws?.close();
    ws = null;
    connectionConfiguration = ConnectionConfiguration();
  }

  Stream<ConnectionDetails> streamConnectionChanges({bool immediately = false}) {
      if (immediately) {
      Future.delayed(const Duration(milliseconds: 50), () {
        _connectionWithServerChangesStreamController.add(
            ConnectionDetails(_connectionStatus, disconnectionReason));
      });
    }
    return _connectionWithServerChangesStreamController.stream;
  }

  //Não pode ser acessado de fora do package:
  void notifyConnectionChanged(ConnectionStatus conn, {DisconnectionReason ? disconnectionReason}) async {
    if (conn == _connectionStatus) {
      return;
    }
    _connectionStatus = conn;

    for (final OnConnectionChange listener in List.from(_onConnectionWithServerChangeListenersBeforeOthersListeners)) {
      await listener(ConnectionDetails(conn, disconnectionReason));
    }

    for (final OnConnectionChange listener in List.from(_onConnectionWithServerChangeListeners)) {
      listener(ConnectionDetails(conn, disconnectionReason));
    }
    _connectionWithServerChangesStreamController.add(ConnectionDetails(conn, disconnectionReason));
    if (conn==ConnectionStatus.disconnected) {
      this.disconnectionReason = disconnectionReason ?? DisconnectionReason.other;
    }
  }

  void addOnConnectionChangeListener(OnConnectionChange listener, {bool immediately=true, bool beforeOthersListeners = false}) {
    if (beforeOthersListeners) {
      _onConnectionWithServerChangeListenersBeforeOthersListeners.add(listener);
    } else {
      _onConnectionWithServerChangeListeners.add(listener);
    }

    if(immediately) {
      listener(ConnectionDetails(_connectionStatus, disconnectionReason));
    }
  }

  void removeOnConnectionChange(OnConnectionChange listener) {
    _onConnectionWithServerChangeListeners.remove(listener);
    _onConnectionWithServerChangeListenersBeforeOthersListeners.remove(listener);
  }

}

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:askless/src/tasks/ReconnectClientWhenDidNotReceivePongFromServerTask.dart';
import 'package:askless/src/middleware/data/request/OperationRequestCli.dart';
import 'package:askless/src/middleware/data/receivements/NewRealtimeData.dart';
import 'package:askless/src/middleware/data/receivements/ResponseCli.dart';
import 'package:askless/src/tasks/SendMessageToServerAgainTask.dart';
import 'package:askless/src/tasks/SendPingTask.dart';
import '../askless.dart';
import 'constants.dart';
import 'dependency_injection/index.dart';
import 'middleware/index.dart';
import 'tasks/ReconnectWhenOffline.dart';

enum DisconnectionReason{
  TOKEN_INVALID,
  UNDEFINED,
  DISCONNECTED_BY_CLIENT,
  VERSION_CODE_NOT_SUPPORTED,
  WRONG_PROJECT_NAME
}
enum Connection{
  CONNECTED_WITH_SUCCESS,
  CONNECTION_IN_PROGRESS,
  DISCONNECTED,
}
typedef OnConnectionChange(Connection connection);
enum Level{info, debug, error, warning}
typedef LoggerFunction (String message, Level level, {additionalData});

LoggerFunction _getDefaultLogger() => (String message, Level level, {additionalData})  {
  //if(level==Level.debug) //Logger padrão mostra apenas erros
  //  return;

  final prefix = "> askless ["
//      (showDateTime ? (
//          NOW.year.toString()+"-"+
//              NOW.month.toString()+"-"+
//              NOW.day.toString()+" "+
//              NOW.hour.toString()+':'+
//              NOW.minute.toString()+':'+
//              NOW.second.toString()+" "
//      ) : "")
      +level.toString().toUpperCase().substring(6)
      +"]: ";
  print(prefix+message);
  if(additionalData!=null) {
    print(additionalData.toString());
//    try{
//      print(additionalData.toMap());
//    }catch(e){onError
//
//    }
  }
};
class Logger{
  late final LoggerFunction doLog;

  /// Allow to customize the behavior of internal logs and enable/disable the default logger (optional).
  ///
  /// [useDefaultLogger] If [true]: the default logger will be used (optional). Default: `false`
  ///
  /// [customLogger]  Allows the implementation of a custom logger (optional).
  ///
  /// Example:
  ///
  /// ```
  ///     AsklessClient.instance.init(
  ///        projectName: 'MyApp',
  ///        serverUrl: "ws://192.168.2.1:3000",
  ///        logger: Logger(
  ///            useDefaultLogger: false,
  ///            customLogger: (String message, Level level, {additionalData}) {
  ///                final prefix = "> askless ["+level.toString().toUpperCase().substring(6)+"]: ";
  ///                print(prefix+message);
  ///                if(additionalData!=null)
  ///                  print(additionalData.toString());
  ///           }
  ///        )
  ///    );
  /// ```
  Logger({LoggerFunction ? customLogger, bool ? useDefaultLogger}){
    final defaultLogger = useDefaultLogger == true || (useDefaultLogger != false && environment == 'test') ? _getDefaultLogger() : null;

    doLog = (String message, Level level, {additionalData})  {
      if(defaultLogger!=null)
        defaultLogger(message, level, additionalData: additionalData);
      if(customLogger!=null)
        customLogger(message, level, additionalData: additionalData);
    };
  }
}

class Internal {
  static Internal ? _instance;
  bool tasksStarted = false;
  final ReconnectWhenDidNotReceivePongFromServerTask reconnectWhenDidNotReceivePongFromServerTask = new ReconnectWhenDidNotReceivePongFromServerTask();
  final SendMessageToServerAgainTask sendMessageToServerAgainTask = new SendMessageToServerAgainTask();
  final SendPingTask sendPingTask = new SendPingTask();
  final ReconnectWhenOffline reconnectWhenOffline = new ReconnectWhenOffline();
  String ? serverUrl;
  Middleware ? middleware;
  final List<OnConnectionChange> _onConnectionWithServerChangeListeners = [];
  Connection _connection = Connection.DISCONNECTED;
  DisconnectionReason ? disconnectionReason;
  Logger _logger = new Logger();

  Internal._(){
    if(!dependenciesHasBeenConfigured) {
      configureDependencies('prod');
    }
  }

  static Internal get instance {
    if (Internal._instance == null)
      _instance = new Internal._();
    return Internal._instance!;
  }


  //Não pode ser acessado de fora do package:
  void notifyConnectionChanged(Connection conn, {DisconnectionReason ? disconnectionReason}) {
    this._connection = conn;
    this._onConnectionWithServerChangeListeners.forEach((listener) => listener(conn));
    if(conn==Connection.DISCONNECTED)
      this.disconnectionReason = disconnectionReason ?? DisconnectionReason.UNDEFINED;
  }

  logger({required String message, Level level=Level.debug, additionalData}){
    return _logger.doLog(message, level, additionalData: additionalData);
  }

  void reset() {
    assert(environment=='test');
    AsklessClient._instance = _instance = null;
  }

  
}

// bool get allDelaysToZero => _allDelaysToZero;
// set allDelaysToZero(bool allDelaysToZero) {
//   if(environment == 'test') {
//     _allDelaysToZero = allDelaysToZero;
//   }
// }
// bool _allDelaysToZero = false;

bool get noTasks => _noTasks;
set noTasks(bool noTasks) {
  assert(environment == 'test');
  _noTasks = noTasks;
}
bool _noTasks = false;

class AsklessClient {
  String ? _projectName;

  set projectName(String ? projectName){
    this._projectName = projectName;
  }

  /// Name for this project (optional).
  /// If [!= null]: the field [projectName] on server side must have the same name (optional).
  String ? get projectName => _projectName;

  ///The URL of the server, must start with [ws://] or [wss://].
  String ? get serverUrl => Internal.instance.serverUrl;

  var _ownClientId;
  Map<String, dynamic> ? _headers;

  AsklessClient._();

  static AsklessClient ? _instance;

  ///Askless client
  static AsklessClient get instance {
    if (AsklessClient._instance == null)
      _instance = new AsklessClient._();
    return AsklessClient._instance!;
  }

  ///Get the status of the connection with the server.
  Connection get connection => Internal.instance._connection;

  ///May indicate the reason of no connection.
  DisconnectionReason ? get disconnectReason => Internal.instance.disconnectionReason;


  /// Try to perform a connection with the server.
  ///
  /// [ownClientId]: The ID of the user defined in your application.
  /// This field must NOT be [null] when the user is logging in,
  /// otherwise must be [null] (optional).
  ///
  /// [headers]: Allows informing the token of the respective [ownClientId] (and/or additional data)
  /// so that the server can be able to accept or recuse the connection attempt (optional).
  ///
  /// In the server side, you can implement [grantConnection](https://github.com/WiseTap/askless/blob/master/documentation/english_documentation.md#grantconnection)
  /// to accept or deny connections attempts from the client.
  ///
  /// Returns the result of the connection attempt.
  ///
  /// Example:
  /// ```
  ///     AsklessClient.instance.connect(ownClientId: 1, headers: {
  ///       'Authorization' : 'TOKEN HERE'
  ///     });
  /// ```
  Future<ResponseCli> connect({dynamic ownClientId , Map<String, dynamic> ? headers}) async {
    if(serverUrl == null)
      throw "You must call the method 'init' before 'connect'";

    if (ownClientId != null && ownClientId.toString().startsWith(CLIENT_GENERATED_ID_PREFIX)) //Vai que o usuário insira um id manualmente desse tipo
      throw "ownClientId invalid: "+ownClientId;

    logger(message: "connecting...", level: Level.debug);

    Internal.instance.disconnectionReason = null;

    if(Internal.instance.serverUrl != serverUrl)
      logger(message: "server: "+(serverUrl??'null'), level: Level.info);

    if(Internal.instance.middleware==null || Internal.instance.serverUrl!=serverUrl || this._ownClientId != ownClientId){
      _disconnectAndClearByClient();
      Internal.instance.middleware = new Middleware(serverUrl!);
    }else{
      Internal.instance.middleware!.ws?.close();
      Internal.instance.middleware!.ws = null;
    }
    this._ownClientId = ownClientId;
    this._headers = headers ?? {};

    return  (await Internal.instance.middleware!.performConnection(ownClientId: ownClientId, headers: headers));
  }


  ///Stop the connection with the server and clear the credentials [headers] and [ownClientId].
  void disconnect() {
    logger(message: "disconnect", level: Level.debug);

    _headers = null;
    _ownClientId = null;
    _disconnectAndClearByClient();
  }

  /// Adds a [listener] that will be triggered
  /// every time the status of connection with
  /// the server changes.
  ///
  /// [runListenerNow] Default: true. If [true]: the [listener] is called
  /// right after being added (optional).
  ///
  void addOnConnectionChange(OnConnectionChange listener, {bool runListenerNow=true}) {
    Internal.instance._onConnectionWithServerChangeListeners.add(listener);
    if(runListenerNow)
      listener(connection);
  }

  ///Removes the added [listener].
  void removeOnConnectionChange(OnConnectionChange listener) {
    Internal.instance._onConnectionWithServerChangeListeners.remove(listener);
  }

  /// Reconnects to the server using the same credentials
  /// as the previous informed in [connect].
  ///
  /// Returns the result of the connection attempt.
  Future<ResponseCli> reconnect() {
    if(_headers == null)
      throw "'reconnect' only can be called after a 'connect'";

    logger(message: "reconnect", level: Level.debug);

    return this.connect(headers: _headers, ownClientId: _ownClientId);
  }

  /// Creates data in the server.
  ///
  /// [body] The data that will be created.
  ///
  /// [route] The path of the route.
  ///
  /// [query] Additional data (optional).
  ///
  /// [neverTimeout] Default: [false] (optional). If [true]: the
  /// request will be performed as soon as possible,
  /// without timeout.
  /// If [false]: the field [requestTimeoutInSeconds] defined in the server side
  /// will be the timeout.
  ///
  Future<ResponseCli> create({required String route, required dynamic body, Map<String, dynamic> ? query, bool neverTimeout: false}) async {
    assert(body!=null);
    await _assertHasMadeConnection();

    return Internal.instance.middleware!.runOperationInServer(new CreateCli(
        route: route, body: body, query: query
    ), neverTimeout);
  }

  ///Updates data in the server.
  ///
  /// [body] The entire data or field(s) that will be updated.
  ///
  /// [route] The path of the route.
  ///
  /// [query] Additional data (optional).
  ///
  /// [neverTimeout] Default: [false] (optional). If [true]: the
  /// request will be performed as soon as possible,
  /// without timeout.
  /// If [false]: the field [requestTimeoutInSeconds] defined in the server side
  /// will be the timeout.
  ///
  Future<ResponseCli> update({required String route, required dynamic body, Map<String, dynamic> ? query, bool neverTimeout: false}) async {
    assert(body!=null);
    await _assertHasMadeConnection();

    return Internal.instance.middleware!.runOperationInServer(new UpdateCli(
        route: route, body: body, query: query), neverTimeout);
  }

  /// Removes data from server.
  ///
  /// [route] The path route.
  ///
  /// [query] Additional data, indicate here which data will be removed.
  ///
  /// [neverTimeout] Default: [false] (optional). If [true]: the
  /// request will be performed as soon as possible,
  /// without timeout.
  /// If [false]: the field [requestTimeoutInSeconds] defined in the server side
  /// will be the timeout.
  ///
  /// Example
  /// ```
  ///     AsklessClient.instance
  ///        .delete(
  ///            route: 'product',
  ///            query: {
  ///              'id': 1
  ///            },
  ///        ).then((res) => print(res.isSuccess ? 'Success' : res.error!.code));
  /// ```
  ///
  Future<ResponseCli> delete({required String route, required Map<String, dynamic> ? query, bool neverTimeout: false}) async {
    assert(query!=null);
    await _assertHasMadeConnection();

    return Internal.instance.middleware!.runOperationInServer(new DeleteCli(route: route, query: query), neverTimeout);
  }

  /// Read data once.
  ///
  /// [route] The path of the route.
  ///
  /// [query] Additional data (optional),
  /// here can be added a filter to indicate to the server
  /// which data this client will receive.
  ///
  /// [neverTimeout] Default: [false] (optional). If [true]: the
  /// request will be performed as soon as possible,
  /// without timeout.
  /// If [false]: the field [requestTimeoutInSeconds] defined in the server side
  /// will be the timeout.
  ///
  /// Example
  ///
  /// ```
  ///     AsklessClient.instance
  ///         .read(route: 'allProducts',
  ///             query: {
  ///                 'nameContains' : 'game'
  ///             },
  ///             neverTimeout: true
  ///         ).then((res) {
  ///             (res.result as List).forEach((product) {
  ///                 print(product['name']);
  ///             });
  ///         });
  /// ```
  ///
  Future<ResponseCli> read({required String route, Map<String, dynamic> ? query, bool neverTimeout: false}) async {
    await _assertHasMadeConnection();

    return Internal.instance.middleware!.runOperationInServer(new ReadCli(route: route, query: query), neverTimeout);
  }

  /// Get realtime data using [stream].
  ///
  /// Returns a [Listening].
  ///
  /// Is __necessary__ to call the method `Listening.close`
  /// to stop receiving data from server.
  ///
  /// Example: @override `dispose` of Scaffold that uses this stream.
  ///
  /// [route] The path of the route.
  ///
  /// [query] Additional data (optional),
  /// here can be added a filter to indicate to the server
  /// which data this client will receive.
  ///
  Listening listen({required String route,  Map<String, dynamic> ? query,}) {
    _assertHasMadeConnection();

    return Internal.instance.middleware!.listen(listenCli: new ListenCli(route: route, query: query, ));
  }


  /// Get data once and returns a
  /// [FutureBuilder](https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html)
  ///
  /// [route] The path route.
  ///
  /// [builder] [Official documentation](https://api.flutter.dev/flutter/widgets/FutureBuilder/builder.html)
  ///
  /// [query] Additional data (optional),
  /// here can be added a filter to indicate to the server
  /// which data this client will receive.
  ///
  /// [initialData] [Official documentation](https://api.flutter.dev/flutter/widgets/StreamBuilder/initialData.html) (optional).
  ///
  /// [key] [Official documentation](https://api.flutter.dev/flutter/foundation/Key-class.html) (optional).
  ///
  /// Example
  /// ```
  ///      AsklessClient.instance
  ///         .readAndBuild(
  ///           route: 'product',
  ///           query: {
  ///             'id': 1
  ///           },
  ///           builder: (context,  snapshot) {
  ///             if(!snapshot.hasData)
  ///               return Container();
  ///             return Text(snapshot.data.output['name']);
  ///           }
  ///         );
  /// ```
  FutureBuilder<ResponseCli> readAndBuild({required String route, required AsyncWidgetBuilder builder, Map<String, dynamic> ? query, dynamic initialData, Key ? key,}) {
    _assertHasMadeConnection();

    return FutureBuilder(
      builder: builder,
      future: this.read(route: route, query: query, neverTimeout: true),
      initialData: initialData == null || initialData is ResponseCli ? initialData : new ResponseCli(
        clientRequestId: 'none', //TODO: usar clientRequestId real
        output: initialData
      ),
      key: key ?? new GlobalKey(),
    );
  }

  /// Get realtime data through [StreamBuilder](https://api.flutter.dev/flutter/widgets/StreamBuilder-class.html).
  ///
  /// Unlike the [listen] method, in [listenAndBuild]
  /// the stream will be closed automatically
  /// when this widget [dispose].
  ///
  /// [route] The path route.
  ///
  /// [builder] [Official documentation](https://api.flutter.dev/flutter/widgets/StreamBuilder/builder.html)
  ///
  /// [query] Additional data (optional),
  /// here can be added a filter to indicate to the server
  /// which data this client will receive.
  ///
  /// [initialData] [Official documentation](https://api.flutter.dev/flutter/widgets/StreamBuilder/initialData.html) (optional).
  ///
  /// [key] [Official documentation](https://api.flutter.dev/flutter/foundation/Key-class.html) (optional).
  ///
  /// Example
  ///
  /// ```
  ///     //other widgets...
  ///     AsklessClient.instance
  ///        .listenAndBuild(
  ///          route: 'allProducts',
  ///          builder: (context,  snapshot) {
  ///              if(!snapshot.hasData)
  ///                return Container();
  ///
  ///              final listOfProductsNames =
  ///                  (snapshot.data.output as List)
  ///                  .map((product) => Text(product['name'])).toList();
  ///
  ///              return Column(
  ///                children: listOfProductsNames,
  ///              );
  ///            }
  ///          );
  ///      //other widgets...
  /// ```
  ///
  StreamBuilder<dynamic> listenAndBuild({required String route, required AsyncWidgetBuilder<dynamic> builder, dynamic initialData, Map<String, dynamic>? query, Key? key,}) {
    _assertHasMadeConnection();

    // ignore: close_sinks
    StreamController ctrlForStreamBuilder = new StreamController<dynamic>();

    // Se não fizer isso: quando é feito "stop" e depois "build" não dá problema
    // mas quando é dado "rebuild" dá problema
    // além disso: output já enviado diretamente (e não NewRealtimeData)
    Future.delayed(Duration(milliseconds: 100), () {
      final listen = this.listen(route: route, query: query, );
      listen.stream.listen((ev) {
        ctrlForStreamBuilder.add(ev.output);
      });
      ctrlForStreamBuilder.onCancel = (){
        listen.close();
      };
    });

    return StreamBuilder(
      builder: builder,
      key: key ?? new GlobalKey(),
      initialData: initialData,
      stream: ctrlForStreamBuilder.stream,
    );
  }

  Future<void> _assertHasMadeConnection() async {
    if(Internal.instance.middleware==null) {
      await this.connect();
      logger(message: 'You didn\'t call the method `connect` yet, so the connection will be made with null values for `ownClientId` and `headers` params', level: Level.warning);
    }
//        throw "You have not been connected yet, please, call the method connect before any operation in the server";
  }

  /// The client can be initialized with the method [init].
  ///
  /// It's recommended to call [init] in the [main] method of the application.
  ///
  /// [serverUrl] The URL of the server, must start with [ws://] or [wss://]. Example: [ws://192.168.2.1:3000].
  ///
  /// [logger]  Allow to customize the behavior of internal logs and enable/disable the default logger (optional).
  ///
  /// [projectName] Name for this project (optional).
  /// If [!= null]: the field [projectName] on server side must have the same name (optional).
  ///
  void init({required serverUrl, Logger? logger, String? projectName}) {
    assert(serverUrl.startsWith('ws:') || serverUrl.startsWith('wss:'));
    if(serverUrl.contains('192.168.') && !serverUrl.contains(':'))
      throw 'Please, inform the port on the serverUrl, default is 3000, example: ws://192.168.2.1:3000';
    Internal.instance.serverUrl = serverUrl;
    this._projectName = projectName;
    Internal.instance._logger = logger ?? new Logger();
  }

  void _disconnectAndClearByClient() {
    Internal.instance.middleware?.disconnectAndClear(onDone: () {
      Internal.instance.disconnectionReason = DisconnectionReason.DISCONNECTED_BY_CLIENT;
    });
  }
}

typedef OnDisconnect({RespondError error});

/// Listening for new data from the server after call the method [wsListen].
///
/// [stream] Get realtime data from server.
///
/// Is necessary to call the method [Listening.close]
/// so that the server can stop sending data.
/// Example: in [dispose] implementation of Scaffold
/// that uses this stream.
///
/// [close] Stop receiving realtime data from server using  [Listening.stream].
///
class Listening {
  /// Listening for new data from the server after call the method [wsListen].
  ///
  /// [stream] Get realtime data from server.
  ///
  /// Is necessary to call the method [Listening.close]
  /// so that the server can stop sending data.
  /// Example: in [dispose] implementation of Scaffold
  /// that uses this stream.
  ///
  /// [close] Stop receiving realtime data from server using  [Listening.stream].
  ///

  final String clientRequestId;
  //Um id gerado pelo cliente que representa
  //a troca de dados em tempo real entre o o cliente e uma sub-rota do servidor
  final String listenId;
  final VoidCallback _notifyMotherStreamThatChildStreamIsNotListeningAnymore;

  late final Stream<NewDataForListener> stream;
  final StreamController<NewDataForListener> _streamController = new StreamController();
  final Stream<NewDataForListener> _superStream;
  late final StreamSubscription<NewDataForListener> _subscription;
  bool _closeHasBeenCalled = false;

  Listening(this._superStream, this.clientRequestId, this.listenId, this._notifyMotherStreamThatChildStreamIsNotListeningAnymore){
    stream = _streamController.stream;
    _subscription = _superStream.listen((event) {
      _streamController.add(event);
    });
    _streamController.onCancel = () {
      this.close();
    };
  }

  /// Stop receiving realtime data from server using [stream]
  void close(){
    if(_closeHasBeenCalled)
      return;
    _closeHasBeenCalled = true;
    _subscription.cancel();
    _streamController.close();
    this._notifyMotherStreamThatChildStreamIsNotListeningAnymore();
  }
}

void logger({required String message, Level level=Level.debug, additionalData}) => Internal.instance.logger(message: message, level: level, additionalData: additionalData);

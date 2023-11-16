import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../../injection_container.dart';
import 'domain/entities/response_entity.dart';
import 'domain/services/authenticate_service.dart';
import 'domain/services/call_service.dart';
import 'domain/services/connection_service.dart';
import 'domain/services/requests_service.dart';
import 'domain/utils/logger.dart';
import 'middleware/ListeningHandler.dart';
import 'middleware/data/request/OperationRequestCli.dart';
import 'tasks/ReconnectWhenOffline.dart';
import 'injection_container.dart' as injection;
import 'tasks/SendPingTask.dart';
import 'tasks/ReconnectClientWhenDidNotReceivePongFromServerTask.dart';
import 'tasks/SendMessageToServerAgainTask.dart';

class AsklessClient<USER_ID> {
  final ReconnectWhenDidNotReceivePongFromServerTask reconnectWhenDidNotReceivePongFromServerTask = ReconnectWhenDidNotReceivePongFromServerTask();
  final SendMessageToServerAgainTask sendMessageToServerAgainTask = SendMessageToServerAgainTask();
  final SendPingTask sendPingTask = SendPingTask();
  final ReconnectWhenOffline reconnectWhenOffline = ReconnectWhenOffline();
  bool _tasksStarted = false;
  DateTime _startedAt = DateTime(1970,1,1);
  late final Future<WebRTCParams> Function(USER_ID userId) _getWebRTCParams;

  static final AsklessClient instance = AsklessClient._();

  AsklessClient._() {
    injection.init();
  }

  /// The server URL that Askless should be connected to
  String? get serverUrl => getIt.get<ConnectionService>().serverUrl;

  /// Current connection status to the server with details
  ConnectionDetails get connection => getIt.get<ConnectionService>().connection;

  /// Disconnection reason only in case where [connection] equals [Connection.disconnectedAt]
  DisconnectionReason? get disconnectReason => getIt.get<ConnectionService>().disconnectionReason;

  /// Adds a [listener] that will be triggered
  /// every time the status of the connection to
  /// the server changes.
  ///
  /// [immediately] Default [true]. If [true], emits the first event immediately with
  /// the current connection status, otherwise
  /// it will wait to emit until the connection status changes.
  void addOnConnectionChangeListener(OnConnectionChange listener, {bool immediately=false}) {
    return getIt.get<ConnectionService>().addOnConnectionChangeListener(listener, immediately: immediately);
  }

  /// Removes the listener which is triggered
  /// every time the status of the connection to
  /// the server changes.
  void removeOnConnectionChangeListener(OnConnectionChange listenerToRemove) {
    return getIt.get<ConnectionService>().removeOnConnectionChange(listenerToRemove);
  }

  /// Performs an authentication attempt to the server side. Useful for the login page or to authenticate
  /// with tokens automatically in the startup of your App.
  ///
  /// **Important:** `authenticate(..)` will be called automatically by using the same `credential` when
  /// the user loses the internet connection and connects again,
  /// but if it fails `onAutoReauthenticationFails(...)` will be triggered
  ///
  /// If [AuthenticateResponse.success] is true: the current user will be able to interact with routes
  /// on the server side created with [addRouteFor.authenticatedUsers]
  ///
  /// [credential] Customized data you will use in the backend side to validate the authentication
  /// request
  ///
  /// [neverTimeout] Default: [false] (optional). If [true]: the request attempt will live as long as possible.
  ///
  /// If [false]: if the request doesn't receive a response within the time limit, it will be canceled.
  /// The field `requestTimeoutInMs` defined on the server side will be the time limit.
  ///
  /// Example
  /// ```
  ///    final authenticateResponse = await AsklessClient.instance.authenticate(credential: { "accessToken": accessToken });
  ///     if (authenticateResponse.success) {
  ///       log("user has been authenticated successfully");
  ///     } else {
  ///       log("connectWithAccessToken error: ${authenticateResponse.errorCode}");
  ///       if (authenticateResponse.isCredentialError) {
  ///         log("got an error: access token is invalid");
  ///       } else {
  ///         log("got an error with code ${authenticateResponse.errorCode}: ${authenticateResponse.errorDescription}");
  ///       }
  ///     }
  /// ```
  Future<AuthenticateResponse> authenticate ({required Map<String, dynamic> credential, bool neverTimeout = false}) async {
    await getIt.get<AuthenticateService>().clearAuthentication();
    return getIt.get<AuthenticateService>().authenticate(credential, neverTimeout: neverTimeout);
  }

  /// Clears the authentication, you may want to call this in case the user clicks in a logout button for example.
  ///
  /// After calling [clearAuthentication] the user will NOT be able to
  /// interact anymore with routes created with [addRouteFor.authenticatedUsers] on the server side
  Future<void> clearAuthentication () {
    return getIt.get<AuthenticateService>().clearAuthentication();
  }



  /// Request a call to a remote user. Returns a [RequestCallToUserInstance]
  ///
  /// [localStream] The [MediaStream] for the local user, so the remote user will be able to receive video and/or audio.
  /// You can get it  with `navigator.mediaDevices.getUserMedia(...)`
  ///
  /// [userId] Refers to the remote user the local user want talk to.
  ///
  /// [additionalData] Add custom data here (optional)
  ///
  /// Example
  /// ```
  ///  final localVideoRenderer = RTCVideoRenderer();
  ///  final remoteVideoRenderer = RTCVideoRenderer();
  ///  RequestCallToUserInstance? callInstance;
  ///
  ///  requestCall() async {
  ///    navigator.mediaDevices.getUserMedia({
  ///      'audio': true,
  ///      'video': {
  ///        'facingMode': 'user',
  ///      },
  ///    }).then((localUserStream) {
  ///      setState(() {
  ///        localVideoRenderer.srcObject = localUserStream;
  ///        callInstance = AsklessClient.instance.requestCallToUser(
  ///          userId: 2,
  ///          localStream: localUserStream,
  ///          additionalData: {
  ///            "videoCall": true // add your custom data here, I'm sending whether is a video call or not
  ///          },
  ///        );
  ///        callInstance!.response().then((response) {
  ///          if (!response.callAccepted) {
  ///            print("Call has not been accepted");
  ///            return;
  ///          }
  ///
  ///          setState(() {
  ///            remoteVideoRenderer.srcObject = response.liveCall!.remoteStream;
  ///            liveCall!.addOnCallClosesListener(listener: () {
  ///              // to handle when the call has been closed
  ///            });
  ///          });
  ///        });
  ///      });
  ///    }, onError: (error) {
  ///      print("Could not get access to camera and/or microphone ${error.toString()}");
  ///    });
  ///  }
  ///
  ///  @override
  ///  Widget build(BuildContext context) {
  ///    return Stack(
  ///      children: [
  ///        RTCVideoView(remoteVideoRenderer),
  ///        Positioned(
  ///          bottom: 4,
  ///          right: 0,
  ///          child: SizedBox(
  ///            height: 125,
  ///            width: 75,
  ///            child: RTCVideoView(localVideoRenderer),
  ///          ),
  ///        ),
  ///      ],
  ///    );
  ///  }
  ///
  ///  @override
  ///  void dispose() {
  ///    callInstance?.dispose();
  ///    liveCall?.dispose();
  ///    super.dispose();
  ///  }
  /// ```
  RequestCallToUserInstance requestCallToUser({
    required MediaStream localStream,
    required USER_ID userId,
    Map<String,dynamic>? additionalData,
  }) {
    assert(additionalData == null || additionalData is Map);

    return CallService<USER_ID>(_getWebRTCParams).requestCallToUser(
      localStream: localStream,
      remoteUserId: userId,
      additionalData: Map.from(additionalData ?? {}),
    );
  }

  /// Adds a listener that handles call requests coming from any remote user.
  /// Returns a [ReceivingCallsInstance] object where you can call
  /// [ReceivingCallsInstance.cancel] to stop receiving new call requests
  ///
  /// Example
  /// ```
  ///     bool _receivingCallHasBeenConfigured = false;
  ///     final navigatorKey = GlobalKey<NavigatorState>();
  ///     class MyApp extends StatelessWidget {
  ///       const MyApp({super.key});
  ///
  ///       @override
  ///       Widget build(BuildContext context) {
  ///           if (!_receivingCallHasBeenConfigured) {
  ///            _receivingCallHasBeenConfigured = true;
  ///            AsklessClient.instance.addOnReceiveCallListener((ReceivingCall receivingCall) {
  ///               print("receiving call");
  ///               Navigator.of(navigatorKey.currentContext!).push(MaterialPageRoute(builder: (context) => AcceptOrRejectCallPage(receivingCall: receivingCall)));
  ///            });
  ///           }
  ///
  ///           return MaterialApp(
  ///              title: 'Flutter with Mysql',
  ///              navigatorKey: navigatorKey,
  ///              ...
  ///           );
  ///       }
  ///     }
  /// ```
  ReceivingCallsInstance addOnReceiveCallListener(OnReceiveVideoCallListener listener) {
    final StreamSubscription listeningToCallsSubscription = AsklessClient
        .instance
        .readStream(route: "askless-internal/call/receive", persevere: true)
        .listen((callRequest) {
      logger("askless-internal/call/receive");
      logger(Map.from(callRequest).toString());
      if (callRequest["hasCallRequest"] != true) {
        logger("hasCallRequest is ${callRequest["hasCallRequest"]}");
        return;
      }

      CallService<USER_ID>(_getWebRTCParams).onReceiveCallCallback(callRequest, listener);

    });

    return ReceivingCallsInstance(cancel: listeningToCallsSubscription.cancel);
  }


  /// Performs a request attempt for a `create` route added on the server side
  ///
  /// [body] The data that will be created.
  ///
  /// [route] The path of the route.
  ///
  /// [params] Additional data (optional).
  ///
  /// [neverTimeout] Default: [false] (optional). If [true]: the request attempt will live as long as possible.
  ///
  /// If [false]: if the request doesn't receive a response within the time limit, it will be canceled. The field [requestTimeoutInMs] defined on the server side will be the time limit.
  ///
  /// [persevere] Default: [false] (optional). If [persevere] is [true] and this route was created in the server with [addRouteFor.authenticatedUsers] (requires authentication)
  /// but [clearAuthentication()] is called, then this route **will wait for the authentication to come back.**
  /// In case of [false] the route will be canceled right after [clearAuthentication()] is called (only if this route requires authentication).
  /// This is no-op in case this route doesn't require authentication ([addRoute.forAllUsers]).
  ///
  /// Example
  /// ```
  ///     AsklessClient.instance
  ///       .create(route: 'product',
  ///         body: {
  ///            'name' : 'Video Game',
  ///            'price' : 500,
  ///            'discount' : 0.1
  ///         }
  ///       ).then((res) => print(res.success ? 'Success' : res.error!.code));
  /// ```
  Future<AsklessResponse> create({required String route, required dynamic body, Map<String, dynamic> ? params, bool neverTimeout = false, bool persevere = false}) async {
    assert(body!=null);
    await getIt.get<ConnectionService>().waitForConnectionOrTimeout(timeout: neverTimeout ? null : Duration(milliseconds: getIt.get<ConnectionService>().connectionConfiguration.requestTimeoutInMs));
    return getIt.get<RequestsService>().runOperationInServer(
      data: CreateCli(route: route, body: body, params: params),
      neverTimeout: neverTimeout,
      isPersevere: () => persevere,
    );
  }

  /// Performs a request attempt for a `update` route added on the server side
  ///
  /// [body] The entire data or field(s) that will be updated.
  ///
  /// [route] The path of the route.
  ///
  /// [params] Additional data (optional).
  ///
  /// [neverTimeout] Default: [false] (optional). If [true]: the request attempt will live as long as possible.
  ///
  /// If [false]: if the request doesn't receive a response within the time limit, it will be canceled. The field [requestTimeoutInMs] defined on the server side will be the time limit.
  ///
  /// [persevere] Default: [false] (optional). If [persevere] is [true] and this route was created in the server with [addRouteFor.authenticatedUsers] (requires authentication)
  /// but [clearAuthentication()] is called, then this route **will wait for the authentication to come back.**
  /// In case of [false] the route will be canceled right after [clearAuthentication()] is called (only if this route requires authentication).
  /// This is no-op in case this route doesn't require authentication ([addRoute.forAllUsers]).
  ///
  /// Example
  /// ```
  ///     AsklessClient.instance
  ///         .update(
  ///             route: 'allProducts',
  ///             params: {
  ///               'nameContains' : 'game'
  ///             },
  ///             body: {
  ///               'discount' : 0.8
  ///             }
  ///         ).then((res) => print(res.success ? 'Success' : res.error!.code));
  /// ```
  Future<AsklessResponse> update({required String route, required dynamic body, Map<String, dynamic>? params, bool neverTimeout = false, bool persevere = false}) async {
    assert(body!=null);
    await getIt.get<ConnectionService>().waitForConnectionOrTimeout(timeout: neverTimeout ? null : Duration(milliseconds: getIt.get<ConnectionService>().connectionConfiguration.requestTimeoutInMs));

    return getIt.get<RequestsService>().runOperationInServer(
      data: UpdateCli(route: route, body: body, params: params),
      neverTimeout: neverTimeout,
      isPersevere: () => persevere,
    );
  }

  void _checkStartTasks() {
    if (_tasksStarted == false) {
      _tasksStarted = true;
      sendMessageToServerAgainTask.start();
      sendPingTask.start();
      reconnectWhenDidNotReceivePongFromServerTask.start();
      reconnectWhenOffline.start();
    }
  }

  /// Performs a request attempt for a `delete` route added on the server side
  ///
  /// [route] The path of the route.
  ///
  /// [params] Additional data, indicate here which data will be removed.
  ///
  /// [neverTimeout] Default: [false] (optional). If [true]: the request attempt will live as long as possible.
  ///
  /// If [false]: if the request doesn't receive a response within the time limit, it will be canceled. The field [requestTimeoutInMs] defined on the server side will be the time limit.
  ///
  /// [persevere] Default: [false] (optional). If [persevere] is [true] and this route was created in the server with [addRouteFor.authenticatedUsers] (requires authentication)
  /// but [clearAuthentication()] is called, then this route **will wait for the authentication to come back.**
  /// In case of [false] the route will be canceled right after [clearAuthentication()] is called (only if this route requires authentication).
  /// This is no-op in case this route doesn't require authentication ([addRoute.forAllUsers]).
  ///
  /// Example
  /// ```
  ///     AsklessClient.instance
  ///        .delete(
  ///            route: 'product',
  ///            params: {
  ///              'id': 1
  ///            },
  ///        ).then((res) => print(res.success ? 'Success' : res.error!.code));
  /// ```
  ///
  Future<AsklessResponse> delete({required String route, Map<String, dynamic>? params, bool neverTimeout = false, bool persevere = false}) async {
    await getIt.get<ConnectionService>().waitForConnectionOrTimeout(timeout: neverTimeout ? null : Duration(milliseconds: getIt.get<ConnectionService>().connectionConfiguration.requestTimeoutInMs));
    return getIt.get<RequestsService>().runOperationInServer(data: DeleteCli(route: route, params: params), neverTimeout: neverTimeout, isPersevere: () => persevere,);
  }

  /// Performs a request attempt for a `read` route added on the server side
  ///
  /// Similar to [readStream], but doesn't stream changes.
  ///
  /// [route] The path of the route.
  ///
  /// [params] Additional data (optional),
  /// here can be added a filter to indicate to the server
  /// which data will be received.
  ///
  /// [neverTimeout] Default: [false] (optional). If [true]: the request attempt will live as long as possible.
  ///
  /// If [false]: if the request doesn't receive a response within the time limit, it will be canceled. The field [requestTimeoutInMs] defined on the server side will be the time limit.
  ///
  /// [persevere] Default: [false] (optional). If [persevere] is [true] and this route was created in the server with [addRouteFor.authenticatedUsers] (requires authentication)
  /// but [clearAuthentication()] is called, then this route **will wait for the authentication to come back.**
  /// In case of [false] the route will be canceled right after [clearAuthentication()] is called (only if this route requires authentication).
  /// This is no-op in case this route doesn't require authentication ([addRoute.forAllUsers]).
  ///
  /// Example
  /// ```
  ///      AsklessClient.instance.read(
  ///         route: 'allProducts',
  ///         params: {
  ///           'nameContains' : 'game'
  ///         },
  ///         neverTimeout: true
  ///      ).then((res) {
  ///         for (final product in List.from(res.output)) {
  ///           print(product['name']);
  ///         }
  ///      });
  /// ```
  ///
  Future<AsklessResponse> read({required String route, Map<String, dynamic>? params, bool neverTimeout = false, bool persevere = false}) async {
    await getIt.get<ConnectionService>().waitForConnectionOrTimeout(timeout: neverTimeout ? null : Duration(milliseconds: getIt.get<ConnectionService>().connectionConfiguration.requestTimeoutInMs));
    return getIt.get<RequestsService>().runOperationInServer(data: ReadCli(route: route, params: params), neverTimeout: neverTimeout, isPersevere: () => persevere,);
  }

  /// Read and stream data for a `read` route added on the server side
  ///
  /// Similar to [read] and it does stream changes.
  ///
  /// Returns a [Stream].
  ///
  /// [route] The path of the route.
  ///
  /// [params] Additional data (optional),
  /// here can be added a filter to indicate to the server
  /// which data will be received.
  ///
  /// [persevere] Default: **true** (optional). If [persevere] is [true] and this route was created in the server with [addRouteFor.authenticatedUsers] (requires authentication)
  /// but [clearAuthentication()] is called, then this route **will wait for the authentication to come back.**
  /// In case of [false] the route will be canceled right after [clearAuthentication()] is called (only if this route requires authentication).
  /// This is no-op in case this route doesn't require authentication ([addRoute.forAllUsers]).
  ///
  /// [source] (optional) Default: [StreamSource.remoteOnly].
  ///
  /// If [StreamSource.remoteOnly] shows only realtime events from the server (recommended).
  ///
  /// If [StreamSource.cacheAndRemote] Uses the last emitted event (from another stream with same [route] and [params]) as the first event,
  /// only in case it's available.
  ///
  /// Example
  /// ```
  ///      late StreamSubscription myTextMessagesSubscription;
  ///
  ///      @override
  ///      void initState() {
  ///        super.initState();
  ///        myTextMessagesSubscription = AsklessClient.instance.readStream(
  ///          route: "my-text-messages",
  ///          params: { "contains" : "thanks" },
  ///          source: StreamSource.remoteOnly,
  ///          persevere: true,
  ///        ).listen((event) {
  ///          print(event);
  ///        });
  ///      }
  ///
  ///      @override
  ///      void dispose() {
  ///        /// remember to cancel() on dispose()
  ///        myTextMessagesSubscription.cancel();
  ///        super.dispose();
  ///      }
  /// ```
  Stream readStream({required String route, Map<String, dynamic>? params, StreamSource source = StreamSource.remoteOnly, bool persevere = true}) {
    return getIt.get<ListeningHandler>().stream(
      listenCli: ListenCli(route: route, params: params),
      source: source,
      persevere: persevere,
    );
  }


  /// Init and start Askless. This method should be called before making any operations using Askless.
  ///
  /// [serverUrl] The server URL, must start with [ws://] or [wss://]. Example: [ws://192.168.0.8:3000].
  ///
  /// [debugLogs] Show Askless internal logs for debugging
  ///
  /// [onAutoReauthenticationFails] is a callback that is triggered once the automatic re-authentication attempt fails.
  /// This happens when the user loses the internet connection and Askless tries to reconnect, but the previous credential
  /// is no longer valid. This is a good place to handle the logic of refreshing the Access Token or moving
  /// the user to the logout page. [onAutoReauthenticationFails] **is NOT called** after `AsklessClient.instance.authenticate(..)` is finished.
  ///
  /// [getWebRTCParams] For video and audio calls only. (optional)
  ///
  /// ⚠️ **[Requires configuration, click here to proceed](https://github.com/RodrigoBertotti/askless-flutter-client/blob/dev/documentation.md#video-and-audio-calls)**
  ///
  /// A function that returns a future object of type `WebRTCParams` which allows you to
  /// set `configuration` and `constraints` Map objects from WebRTC,
  /// it's recommended to set your TURN servers in the `configuration` field.
  ///
  /// Example:
  ///
  /// ```
  ///    void main() {
  ///      AsklessClient.instance.start(
  ///          serverUrl: 'ws://192.168.0.8:3000',
  ///          debugLogs: false,
  ///          onAutoReauthenticationFails: (String credentialErrorCode, void Function() clearAuthentication) {
  ///            // Add your logic to handle when the user credential
  ///            // is no longer valid
  ///            if (credentialErrorCode == "EXPIRED_ACCESS_TOKEN") {
  ///              refreshTheAccessToken();
  ///            } else {
  ///              clearAuthentication();
  ///              goToLoginPage();
  ///            }
  ///          },
  ///          // Only in case you want to use video and/or audio calls:
  ///          getWebRTCParams: (userId) => Future.value(
  ///              WebRTCParams(
  ///                  configuration: {
  ///                    'iceServers': [
  ///                      {
  ///                        "urls": [
  ///                          'stun:stun1.l.google.com:19302',
  ///                          'stun:stun2.l.google.com:19302'
  ///                        ],
  ///                      },
  ///                      {
  ///                        // setting up TURN servers are important for Apps behind symmetric nat
  ///                        "urls": "turn:a.relay.metered.ca:80",
  ///                        "username": "turn.username",
  ///                        "credential": "turn.password",
  ///                      },
  ///                      {
  ///                        "urls": "turn:a.relay.metered.ca:80?transport=tcp",
  ///                        "username": "turn.username",
  ///                        "credential": "turn.password",
  ///                      }
  ///                    ]
  ///                  }
  ///              )
  ///          )
  ///      );
  ///
  ///      runApp(const MyApp());
  ///    }
  /// ```
  void start({
    required String serverUrl,
    bool debugLogs = false,
    OnAutoReauthenticationFails? onAutoReauthenticationFails,
    Future<WebRTCParams> Function(USER_ID userId)? getWebRTCParams,
  }) {
    _getWebRTCParams = getWebRTCParams ?? (userId) => Future.value(
        WebRTCParams(configuration: {
          'iceServers': [
            {
              "urls":   [
                'stun:stun1.l.google.com:19302',
                'stun:stun2.l.google.com:19302'
              ],
            }
          ]
        })
    );
    _startedAt = DateTime.now();
    setAsklessLogger(Logger(debugLogs: debugLogs));
    _checkStartTasks();
    getIt.get<ConnectionService>().start(serverUrl: serverUrl);
    getIt.get<AuthenticateService>().start(onAutoReauthenticationFails: onAutoReauthenticationFails);
  }

  /// Stream changes of the connection status to the server.
  ///
  /// [immediately] Default [true]. If [true], emits the first event immediately with
  /// the current connection status, otherwise
  /// it will wait to emit until the connection status changes.
  Stream<ConnectionDetails> streamConnectionChanges({bool immediately = true}) {
    return getIt.get<ConnectionService>().streamConnectionChanges(immediately: immediately);
  }
}

enum StreamSource {
  cacheAndRemote,
  remoteOnly,
}

typedef OnAutoReauthenticationFails = void Function(String credentialErrorCode, void Function() clearAuthentication);

enum DisconnectionReason {
  unsupportedVersionCode,
  other,
}
enum ConnectionStatus {
  connected,
  inProgress,
  disconnected,
}

/// Connection status to the server with details
class ConnectionDetails {
  /// The connection status to the server: [ConnectionStatus.connected], [ConnectionStatus.inProgress] or [ConnectionStatus.disconnected]
  final ConnectionStatus status;

  /// Disconnection reason only in case where [status] equals [ConnectionStatus.disconnected]
  final DisconnectionReason? disconnectionReason;

  ConnectionDetails(this.status, [this.disconnectionReason]);
}
typedef OnConnectionChange = dynamic Function(ConnectionDetails connectionDetails);

/// The result of the authentication attempt, if [success] is
/// [true]: the current user will be able to interact with routes
/// on the server side created with [addRouteFor.authenticatedUsers].
class AuthenticateResponse<USER_ID> {
  /// The authenticated user ID, or `null`
  final USER_ID? userId;

  /// The claims the authenticated user has, or `null`
  final List<String>? claims;

  /// Returns [true] if the authentication is a success
  bool get success => error == null;

  /// Authenticate error, is never null in cases where [success] == false
  final AsklessAuthenticateError? error;

  AuthenticateResponse(this.userId, this.claims, this.error);
}


class AsklessErrorCode {
  /// An unknown error occurred on the server side
  static const internalError = 'INTERNAL_ERROR';

  /// The App is disconnected from the internet or/and the server is offline
  static const noConnection = "NO_CONNECTION";

  /// The requested operation is already in progress
  static const conflict = "CONFLICT";

  /// The authenticated user doesn't have permission to modify or/and access the requested resource
  static const permissionDenied= 'PERMISSION_DENIED';


  /// `credential` wasn't accepted in the `authenticate` function on the server side
  ///
  /// Example: accessToken is invalid, invalid email, invalid password, etc.
  static const invalidCredential = 'INVALID_CREDENTIAL';

  /// The request could not proceed because the informed `route` requires authentication by the client.
  ///
  /// To fix this, choose to either:
  /// - call AsklessClient.instance.authenticate(...) in the client side before performing this request
  ///
  /// or
  ///
  /// - change the route on the server side from `addRouteFor.authenticatedUsers` to [addRoute.forAllUsers]
  static const pendingAuthentication = 'PENDING_AUTHENTICATION';

  /// The server didn't give a response to the `authentication(..)` function on the server side, to fix this, make sure to
  /// call either `accept.asAuthenticatedUser(..)`, `accept.asUnauthenticatedUser()` or `reject(..)` callbacks in the `authentication(..)` function on the server side.
  static const authorizeTimeout = 'AUTHORIZE_TIMEOUT';
}

/// Error details of a failed request attempt
class AsklessError {
  /// The error code, may be a field of [AsklessErrorCode],
  /// or a **custom error code** sent by the server
  final String code;
  /// The error description
  final String description;

  AsklessError({required this.code, required this.description});

  @override
  String toString() {
    return 'An error occurred with code "$code" and description "$description"';
  }
}

class AsklessAuthenticateError extends AsklessError {
  /// Returns [true] if the error is a credential error,
  /// which means that could not authenticate because of an error like: invalid email,
  /// invalid password, invalid access token, etc.
  ///
  /// Returns [false] in case the error is not related to credential,
  /// like no connection error.
  final bool isCredentialError;

  AsklessAuthenticateError({required this.isCredentialError, required super.code, required super.description});
}

typedef OnRemoteUserConnectionChangeListener = void Function (bool connected);


/// The response received from a request call
class RequestCallResult {

  /// Refers to a running video/audio call. Is null in case of error
  final LiveCall? liveCall;

  /// Indicates whether the call has been accepted or not
  final bool callAccepted;

  /// Error info, is null in cases where [success] is [true]
  final String? error;

  /// Custom data
  final Map<String,dynamic> additionalData;

  RequestCallResult({this.liveCall, required this.callAccepted, this.error, this.additionalData = const {}}) {
    assert(!callAccepted || liveCall != null);
  }
}

/// Refers to a running video/audio call
///
/// Call [dispose] once the widget showing the call disposes
class LiveCall {
  late final void Function({String? error, dynamic result}) _doDispose;

  /// Closes the running call
  final void Function() closeCall;

  late final List<OnRemoteUserConnectionChangeListener> _onRemoteUserConnectionChangeListeners;

  /// [MediaStream](https://github.com/flutter-webrtc/webrtc-interface/blob/main/lib/src/media_stream.dart)
  /// for the remote user from the [Flutter-WebRTC](https://github.com/flutter-webrtc/flutter-webrtc) library
  final MediaStream? remoteStream;

  late final List<void Function()> _onCallCloses;

  /// Adds a [listener] that will be triggered once the call closes
  void addOnCallClosesListener({required void Function() listener}) {
    _onCallCloses.add(listener);
  }

  /// Removes the [listener] previously added
  void removeOnCallClosesListener({required void Function() listener}) {
    _onCallCloses.remove(listener);
  }

  /// Adds a listener function that will be triggered when the connection of the remote user changes
  /// You may want to call [closeCall] if the remote user is disconnected for a long time
  void addOnRemoteUserConnectionChangeListener (OnRemoteUserConnectionChangeListener listener) { _onRemoteUserConnectionChangeListeners.add(listener); }

  /// Removes the listener previously added
  void removeOnRemoteUserConnectionChangeListener (OnRemoteUserConnectionChangeListener listener) { _onRemoteUserConnectionChangeListeners.remove(listener); }

  LiveCall({
    required this.remoteStream,
    required this.closeCall,
    required List<void Function()> onCallCloses,
    required void Function({String? error, dynamic result}) doDispose,
    required List<OnRemoteUserConnectionChangeListener> onRemoteUserConnectionChangeListeners,
  }) {
    _doDispose = doDispose;
    _onCallCloses = onCallCloses;
    _onRemoteUserConnectionChangeListeners = onRemoteUserConnectionChangeListeners;
  }

  /// Call [dispose] once the widget showing the call disposes
  void dispose() {
    closeCall();
    _onRemoteUserConnectionChangeListeners.clear();
    _onCallCloses.clear();
    _doDispose();
  }
}

/// A call request received from a remote user, the local user should choose between [acceptCall] or [rejectCall].
///
/// Call [dispose] once the widget showing the call (e.g. call page) disposes before user accepting/rejecting the call.
class ReceivingCall {

  /// Accepts the call request from the remote user
  /// [localStream] The [MediaStream] for the local user, so the remote user will be able to receive video and/or audio.
  /// You can get it  with `navigator.mediaDevices.getUserMedia(...)`
  final Future<AcceptingCallResult> Function({required MediaStream localStream, Map<String, dynamic>? additionalData}) acceptCall;

  /// Rejects the call request from the remote user
  final void Function({Map<String, dynamic>? additionalData}) rejectCall;

  /// Refers to the remote user that is requesting the call
  final dynamic remoteUserId;

  /// Custom data
  final Map<String,dynamic> additionalData;

  /// Adds a [listener] that will be triggered in case the call request is canceled
  void addOnCanceledListener (void Function() listener) { _disposeList.add(listener); }

  /// Removes the [listener] previously added
  void removeOnCanceledListener (void Function() listener) { _disposeList.remove(listener); }

  bool get answered => _isCallAnswered();

  late final List<void Function()> _disposeList;
  late final Function({String? error, dynamic result}) _doDispose;
  late bool Function() _isCallAnswered;

  ReceivingCall({required List<void Function()> disposeList, required this.acceptCall, required bool Function() isCallAnswered, required this.rejectCall, required this.remoteUserId, required this.additionalData, required Function({String? error, dynamic result}) doDispose}) {
    _isCallAnswered = isCallAnswered;
    _disposeList = disposeList;
    _doDispose = doDispose;
  }

  /// Call [dispose] once the widget showing the call (e.g. call page) disposes before user accepting/rejecting the call.
  void dispose() {
    if (!answered) {
      rejectCall();
    }
    _doDispose();
  }
}
typedef OnReceiveVideoCallListener = void Function (ReceivingCall receivingCall);

/// The return of requesting a call to a remote user,
/// call `dispose()` once the widget showing the call disposes.
class RequestCallToUserInstance {
  late Completer<RequestCallResult> _resultCompleter;

  /// Call [dispose] once the widget showing the call disposes
  final void Function() dispose;

  /// The response to the call request
  Future<RequestCallResult> response () => _resultCompleter.future;

  RequestCallToUserInstance({required Completer<RequestCallResult> resultCompleter, required this.dispose}) {
    _resultCompleter = resultCompleter;
  }
}

class ReceivingCallsInstance {
  /// Use [cancel] to stop receiving new call requests from remote users
  final void Function() cancel;

  ReceivingCallsInstance({required this.cancel});
}

/// Create an instance of this object to pass it on
/// AsklessClient.instance.start(...),
/// you can add your TURN servers in the `configuration` field.
class WebRTCParams {
  final Map<String, dynamic> configuration;
  final Map<String, dynamic> constraints;

  List<dynamic> get iceServers {
    if (configuration['iceServers'] == null) {
      return [
        {
          "urls": [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ];
    }
    return List.from(configuration['iceServers']).map((ice) => Map.from(ice)).toList();
  }

  WebRTCParams({required this.configuration, this.constraints = const {}});
}

/// The result of accepting the call
class AcceptingCallResult {
  /// Error info, is null in cases where [success] is [true]
  String? error;

  /// Refers to a running video/audio call
  ///
  /// Call [liveCall.dispose] once the widget showing the call disposes
  LiveCall? liveCall;

  /// Indicates whether the call started successfully
  bool get success => liveCall != null && error == null;

  AcceptingCallResult({this.liveCall, this.error});
}

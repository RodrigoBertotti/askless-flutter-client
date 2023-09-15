import 'dart:async';
import 'package:collection/collection.dart';
import 'package:random_string/random_string.dart';
import '../../../../../../injection_container.dart';
import '../../constants.dart';
import '../../index.dart';
import '../../middleware/data/receivements/ConfigureConnectionResponseCli.dart';
import '../../middleware/data/request/AbstractRequestCli.dart';
import '../../middleware/data/request/OperationRequestCli.dart';
import '../../middleware/ws_channel/AbstractIOWsChannel.dart';
import '../entities/internal_response_cli_entity.dart';
import '../utils/logger.dart';
import 'authenticate_service.dart';
import 'connection_service.dart';

typedef OnResponseCallback = void Function(InternalAsklessResponseEntity response);

class _Request {
  final AbstractRequestCli data;
  final OnResponseCallback onResponse;
  bool serverReceived = false;
  final createdAt = DateTime.now();

  _Request(this.data, this.onResponse);
}

class RequestsService {
  late final RequestsService sendClientData;
  final List<_Request> _pendingRequestsList = [];

  RequestsService();

  _removePendingRequests({RequestType? whereRequestType}){
    List.from(_pendingRequestsList.where((req) => whereRequestType?.toString().isNotEmpty != true || req.data.requestType == whereRequestType))
        .forEach((req) {
      // _lockPendingRequestsList.synchronized(() async {
        _pendingRequestsList.remove(req);
      // });
    });
  }

  void clear() {
    _pendingRequestsList.clear();
    _removePendingRequests();
  }

  void notifyThatHasBeenReceivedServerResponse(InternalAsklessResponseEntity response) {
    // _lockPendingRequestsList.synchronized(() async {
      final req = _pendingRequestsList.firstWhereOrNull((p) => p.data.clientRequestId == response.clientRequestId,);
      if (req != null) {
        logger("${req.data.getRoute() ?? ''}: response received!: ${response.success} ${response.error?.code}");
        req.onResponse(response);
        _pendingRequestsList.remove(req);
      } else {
        logger(response.clientRequestId.toString());
        logger("Response received, but did nothing, probably because the request timed out before. clientRequestId: ${response.clientRequestId}", level: Level.debug);
      }
    // });
  }

  void setAsReceivedPendingMessageThatServerShouldReceive(String clientRequestId) {
    // _lockPendingRequestsList.synchronized(() async {
      final pending = _pendingRequestsList.firstWhereOrNull((p) => p.data.clientRequestId == clientRequestId,);
      pending?.serverReceived = true;
    // });
  }

  Future<void> sendMessagesToServerAgain(int milliseconds) async {
    for (final pendingRequest in [..._pendingRequestsList]
        .where((element) => !element.serverReceived)
        .where((element) => element.createdAt.millisecondsSinceEpoch - 10 < DateTime.now().millisecondsSinceEpoch - milliseconds)
    ) {
      ws.sinkAdd(map: pendingRequest.data);
    }
  }

  AbstractIOWsChannel get ws => getIt.get<AbstractIOWsChannel>();
  ConnectionConfiguration get connectionConfiguration => getIt.get<ConnectionService>().connectionConfiguration;
  String get serverUrl => getIt.get<ConnectionService>().serverUrl;

  /// Does NOT wait for connection
  Future<InternalAsklessResponseEntity> runOperationInServer({required AbstractRequestCli data, bool neverTimeout = false, bool ifRequiresAuthenticationWaitForIt = true, required bool Function() isPersevere}) async {
    bool isAfterAuthentication = getIt.get<AuthenticateService>().authStatus == AuthStatus.authenticated;
    final completer = Completer<InternalAsklessResponseEntity>();
    data.clientRequestId ??= '${REQUEST_PREFIX}_${randomAlphaNumeric(28)}';

    // ignore: prefer_function_declarations_over_variables
    final sendAgainWhenConnected = (ConnectionDetails connection) async {
      if (connection.status == ConnectionStatus.connected) {
        if (isAfterAuthentication) {
          await getIt.get<AuthenticateService>().waitForAuthentication(neverTimeout: false, isPersevere: () => false);
        }
        logger("sending AGAIN because is connected");
        ws.sinkAdd(map: data);
      }
    };

    final _Request request = _Request(data, (response) {
      if (!completer.isCompleted){
        getIt.get<ConnectionService>().removeOnConnectionChange(sendAgainWhenConnected);
        completer.complete(response);
      }
    });

    getIt.get<ConnectionService>().addOnConnectionChangeListener(sendAgainWhenConnected, immediately: false);

    if (neverTimeout == false && connectionConfiguration.requestTimeoutInMs > 0) {
      Future.delayed(Duration(milliseconds: connectionConfiguration.requestTimeoutInMs), () {
        // _lockPendingRequestsList.synchronized(() async {
          final remove = _pendingRequestsList.firstWhereOrNull((p) => p.data.clientRequestId == request.data.clientRequestId,);
          if (remove != null) {
            _pendingRequestsList.remove(remove);
            request.onResponse(InternalAsklessResponseEntity(
                clientRequestId: data.clientRequestId!,
                error: AsklessError(code: AsklessErrorCode.noConnection, description: 'Request timed out')
            ));
            logger('Your request (${data.requestType}) \"${data.getRoute() ?? ''}\" timed out, check if: \n\t1) Your server configuration is serving on ${serverUrl}\n\t2) Your device has connection with internet\n\t3) Your API route implementation calls context.success or context.error methods', level: Level.error);
          }
        });
      // });
    }


    // await _lockPendingRequestsList.synchronized(() async {
      if (ws.isReady == true){
        await _addAsPending(request);
      } else {
        if (data.waitUntilGetServerConnection) {
          await _addAsPending(request);
          logger('Waiting connection to send message', level: Level.debug);
        } else {
          logger('You can\'t send this message while not connected', level: Level.debug);
          request.onResponse(InternalAsklessResponseEntity(
              clientRequestId: data.clientRequestId!,
              error: AsklessError(description: 'Maybe de device has no internet or the server is offline', code: 'AsklessErrorCode.noConnection')
            )
          );
        }
      }
    // });
    //In the end:
    logger('Sending data to server...', level: Level.debug,);
    ws.sinkAdd(map: data);

    final response = await completer.future;
    if (ifRequiresAuthenticationWaitForIt && response.error?.code == AsklessErrorCode.pendingAuthentication) {
      logger("${request.data.getRoute() ?? ''}: requires authentication, waiting for it, OLD clientRequestId WAS ${request.data.clientRequestId}");
      request.data.clientRequestId = '${REQUEST_PREFIX}_${randomAlphaNumeric(28)}';
      logger("${request.data.getRoute() ?? ''}: NEW clientRequestId IS ${request.data.clientRequestId}, now it will wait for the authentication to finished...");
      isAfterAuthentication = true;
      final authenticated = await getIt.get<AuthenticateService>().waitForAuthentication(
          neverTimeout: neverTimeout,
          isPersevere: isPersevere,
          requestType: request.data.requestType,
          route: request.data.getRoute()
      );
      logger("...${request.data.getRoute() ?? ''}: finished waiting for authentication");

      if (authenticated) {
        logger("${request.data.getRoute() ?? ''}: performing operation AGAIN after authenticated");
        return runOperationInServer(data: data, neverTimeout: neverTimeout, isPersevere: isPersevere);
      } else {
        logger("${request.data.getRoute() ?? ''}: authentication failed, so the request failed as well");
      }
    }

    final remove = _pendingRequestsList.firstWhereOrNull((p) => p.data.clientRequestId == request.data.clientRequestId,);
    if (remove != null) {
      _pendingRequestsList.remove(remove);
    }

    return response;
  }

  //A RESPOSTA ESTÁ VINDO ANTES DO addAsPending

  Future<void> _addAsPending (_Request request) async {
    //Se for um listening, deve ficar no final, do contrário
    //corre o risco de receber 2 dados iguais por conta do método onClientListen na Server
    // await _lockPendingRequestsList.synchronized(() {
      _pendingRequestsList.add(request);
      _pendingRequestsList.sort((a,b) {
        if (a.data.requestType == RequestType.CONFIGURE_CONNECTION) {
          return -2;
        }
        if (b.data.requestType == RequestType.CONFIGURE_CONNECTION) {
          return 2;
        }
        if (a.data.requestType == RequestType.AUTHENTICATE) {
          return -1;
        }
        if (b.data.requestType == RequestType.AUTHENTICATE) {
          return 1;
        }
        return 0;
      });
    // });
  }
}

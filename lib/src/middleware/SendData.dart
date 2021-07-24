import 'dart:async';
import 'dart:convert';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/index.dart';
import 'package:askless/src/middleware/data/receivements/RespondError.dart';
import '../constants.dart';
import 'data/request/AbstractRequestCli.dart';
import 'data/request/OperationRequestCli.dart';
import 'data/receivements/ResponseCli.dart';
import 'package:collection/collection.dart';

typedef void OnResponseCallback(ResponseCli response);

class _Request {
  final AbstractRequestCli data;
  final OnResponseCallback onResponse;
  bool serverReceived = false;

  _Request(this.data, this.onResponse);
}

_Request newTestRequest(AbstractRequestCli data, OnResponseCallback onResponse) => _Request(data, onResponse);

class SendClientData {
  final List<_Request> _pendingRequestsList = [];
  // final Lock _lockPendingRequestsList = new Lock();
  final Middleware middleware;

  SendClientData(this.middleware);

  removePendingRequests({RequestType? whereRequestType}){
    List.from(_pendingRequestsList.where((req) => whereRequestType?.toString().isNotEmpty != true || req.data.requestType == whereRequestType))
        .forEach((req) {
      // _lockPendingRequestsList.synchronized(() async {
        _pendingRequestsList.remove(req);
      // });
    });
  }

  List<_Request> get testGetPendingRequestsList => _pendingRequestsList;

  void testAddPendingRequests(_Request request) => _pendingRequestsList.add(request);

  void clear() {
    this._pendingRequestsList.clear();
    this.removePendingRequests();
  }

  void notifyThatHasBeenReceivedServerResponse(ResponseCli response) {
    // _lockPendingRequestsList.synchronized(() async {
      final req = _pendingRequestsList.firstWhereOrNull((p) => p.data.clientRequestId == response.clientRequestId,);
      if (req != null) {
        _pendingRequestsList.remove(req);
        req.onResponse(response);
      } else {
        logger(message: "Response received, but did nothing, probably because the request timed out before", level: Level.debug);
      }
    // });
  }

  void setAsReceivedPendingMessageThatServerShouldReceive(String clientRequestId) {
    // _lockPendingRequestsList.synchronized(() async {
      final pending = _pendingRequestsList.firstWhereOrNull((p) => p.data.clientRequestId == clientRequestId,);
      pending?.serverReceived = true;
    // });
  }



  Future<void> sendMessagesToServerAgain() async {
    // TODO? fazer como na web, parando o método caso if Internal.instance.connection == "DISCONNECTED"
    late List<_Request> copy;
    // await _lockPendingRequestsList.synchronized(() async {
      copy = []..addAll(this._pendingRequestsList);
    // });
    for (final pendingRequest in copy) {
      if (!pendingRequest.serverReceived) {
        Internal.instance.middleware!.sinkAdd(map: pendingRequest.data); //TODO: remover do lado web o que foi adicionado aqui?
      }
    }
  }

  Future<ResponseCli> runOperationInServer({required AbstractRequestCli data, bool? neverTimeout}) async {
    if(neverTimeout==null){
      neverTimeout = false;
    }
    final completer = new Completer<ResponseCli>();

    final _Request request = new _Request(data, (response) {
      completer.complete(response);
    });
    if (neverTimeout == false && Internal.instance.middleware!.connectionConfiguration.requestTimeoutInSeconds > 0) {
      Future.delayed(Duration(seconds: Internal.instance.middleware!.connectionConfiguration.requestTimeoutInSeconds), () {
        // _lockPendingRequestsList.synchronized(() async {
          final remove = _pendingRequestsList.firstWhereOrNull((p) => p.data.clientRequestId == request.data.clientRequestId,);
          if (remove != null) {
            _pendingRequestsList.remove(remove);
            request.onResponse(new ResponseCli(
                clientRequestId: data.clientRequestId,
                error: RespondError(ReqErrorCode.TIMEOUT, 'Request timed out')
            ));
            logger(message: 'Your request '+data.clientRequestId+'  '+data.requestType.toString()+' timed out, check if: \n\t1) Your server configuration is serving on ${Internal.instance.serverUrl}\n\t2) Your device has connection with internet\n\t3) Your API route implementation calls context.respondWithSuccess or context.respondWithError methods', level: Level.error);
          }
        });
      // });
    }


    // await _lockPendingRequestsList.synchronized(() async {
      if (Internal.instance.middleware!.ws?.isReady == true){  //TODO analisar no lado do cliente JS
        await addAsPending(request);
      } else {
        if (data.waitUntilGetServerConnection) {
          await addAsPending(request);
          logger(message: 'Waiting connection to send message', level: Level.debug);
        } else {
          logger(message: 'You can\'t send this message while not connected', level: Level.debug);
          request.onResponse(new ResponseCli(
              clientRequestId: data.clientRequestId,
              error: RespondError(ReqErrorCode.NO_CONNECTION, 'Maybe de device has no internet or the server is offline')
            )
          );
        }
      }
    // });
    //In the end:
    logger(message: 'Sending to Server...', level: Level.debug, additionalData: json);
    Internal.instance.middleware!.sinkAdd(map: data); //TODO? fazer tal como o lado web, verificando se o usuário NÃO está DESCONECTADO

    return completer.future;
  }

  //A RESPOSTA ESTÁ VINDO ANTES DO addAsPending

  Future<void> addAsPending (_Request request) async {
    //Se for um listening, deve ficar no final, do contrário
    //corre o risco de receber 2 dados iguais por conta do método onClientListen na Server
    // await _lockPendingRequestsList.synchronized(() {
      this._pendingRequestsList.add(request);
      final firsts = this._pendingRequestsList.where((r) => !(r.data is ListenCli)).toList();
      final lasts = this._pendingRequestsList.where((r) => r.data is ListenCli).toList();
      this._pendingRequestsList.clear();
      this._pendingRequestsList.addAll(firsts);
      this._pendingRequestsList.addAll(lasts);
    // });
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:synchronized/synchronized.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/Middleware.dart';
import 'package:askless/src/middleware/data/response/RespondError.dart';
import 'data/request/AbstractRequestCli.dart';
import 'data/request/ConfigureConnectionRequestCli.dart';
import 'data/request/OperationRequestCli.dart';
import 'data/response/ResponseCli.dart';
import 'data/response/ServerConfirmReceiptCli.dart';

typedef void OnResponseCallback(ResponseCli response);

class _Request {
  final AbstractRequestCli data;
  final OnResponseCallback onResponse;
  bool serverReceived = false;

  _Request(this.data, this.onResponse);
}


class SendClientData {
  final List<_Request> _pendingRequestsList = [];
  final Lock _lockPendingRequestsList = new Lock();
  final Middleware middleware;

  SendClientData(this.middleware);


  void clear() {
    this._pendingRequestsList.clear();
  }

  void notifyServerResponse(ResponseCli response) {
    _lockPendingRequestsList.synchronized(() async {
      final req = _pendingRequestsList.firstWhere(
          (p) => p.data.clientRequestId == response.clientRequestId,
          orElse: () => null);
      if (req != null) {
        req.onResponse(response);
        _pendingRequestsList.remove(req);
      } else {
        Internal.instance.logger(message: "Response received, but did nothing, probably because the request timed out before", level: Level.debug);
      }
    });
  }

  void setAsReceivedPendingMessageThatServerShouldReceive(String clientRequestId) {
    _lockPendingRequestsList.synchronized(() async {
      final pending = _pendingRequestsList.firstWhere(
          (p) => p.data.clientRequestId == clientRequestId,
          orElse: () => null);
      pending?.serverReceived = true;
    });
  }



  Future<void> sendMessagesToServerAgain() async {
    // TODO? fazer como na web, parando o método caso if Internal.instance.connection == "DISCONNECTED"

    List<_Request> copy;
    await _lockPendingRequestsList.synchronized(() async {
      copy = []..addAll(this._pendingRequestsList);
    });
    for (final pendingRequest in copy) {
      if (!pendingRequest.serverReceived) {
        final json = jsonEncode(pendingRequest.data.toMap());
        this.middleware.channel?.sink?.add(json); //TODO? fazer tal como o lado web, verificando se o usuário NÃO está DESCONECTADO
      }
    }
  }

  Future<ResponseCli> send({@required AbstractRequestCli data, bool neverTimeout=false}) {

    final json = jsonEncode(data.toMap());
    Internal.instance.logger(message: 'Sending to Server...', level: Level.debug, additionalData: json);
    this.middleware.channel?.sink?.add(json); //TODO? fazer tal como o lado web, verificando se o usuário NÃO está DESCONECTADO

    final completer = new Completer<ResponseCli>();

    final _Request request = new _Request(data, (response) {
      completer.complete(response);
    });
    if (neverTimeout == false && Internal.instance.middleware.connectionConfiguration.requestTimeoutInSeconds > 0) {
      Future.delayed(Duration(seconds: Internal.instance.middleware.connectionConfiguration.requestTimeoutInSeconds), () {
        _lockPendingRequestsList.synchronized(() async {
          final remove = _pendingRequestsList.firstWhere(
              (p) => p.data.clientRequestId == request.data.clientRequestId,
              orElse: () => null);
          if (remove != null) {
            _pendingRequestsList.remove(remove);
            request.onResponse(new ResponseCli(
                clientRequestId: data.clientRequestId,
                error: RespondError(ReqErrorCode.TIMEOUT, 'Request timed out')
            ));
            Internal.instance.logger(message: 'Your request timed out, check if: \n\t1) Your server configuration is serving on ${Internal.instance.serverUrl}\n\t2) Your device has connection with internet\n\t3) Your API route implementation calls context.respondWithSuccess or context.respondWithError methods', level: Level.error);
          }
        });
      });
    }

    final addAsPending = (){
      //Se for um listening, deve ficar no final, do contrário
      //corre o risco de receber 2 dados iguais por conta do método onClientListen na Server
      _lockPendingRequestsList.synchronized(() {
        this._pendingRequestsList.add(request);
        final firsts = this._pendingRequestsList.where((r) => !(r.data is ListenCli)).toList();
        final lasts = this._pendingRequestsList.where((r) => r.data is ListenCli).toList();
        this._pendingRequestsList.clear();
        this._pendingRequestsList.addAll(firsts);
        this._pendingRequestsList.addAll(lasts);
      });
    };

    _lockPendingRequestsList.synchronized(() async {
      if (this.middleware.isConnected) {  //TODO? Internal.instance.connection != "DISCONNECTED"
        addAsPending();
      } else {
        if (data.waitUntilGetServerConnection) {
          addAsPending();
          Internal.instance.logger(message: 'Waiting connection to send message', level: Level.debug);
        } else {
          Internal.instance.logger(message: 'You can\'t send this message while not connected', level: Level.debug);
          request.onResponse(new ResponseCli(
              clientRequestId: data.clientRequestId,
              error: RespondError(
                  ReqErrorCode.NO_CONNECTION,
                  'Maybe de device has no internet or the server is offline'
              )
            )
          );
        }
      }
    });

    return completer.future;
  }
}

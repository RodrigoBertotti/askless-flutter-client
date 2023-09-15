import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:random_string/random_string.dart';
import '../../../../../injection_container.dart';
import '../constants.dart';
import '../domain/services/authenticate_service.dart';
import '../domain/services/requests_service.dart';
import '../domain/utils/logger.dart';
import '../index.dart';
import 'data/receivements/NewDataForListener.dart';
import 'data/request/OperationRequestCli.dart';
import 'receivements/ClientReceivedNewDataForListener.dart';



class ListeningHandler {
  static const _kStreamAddDelayMs = 1500;
  final List<ClientListeningToRoute> listeningTo = [];
  final Map unfoundData = Map();

  Stream stream<O>({required ListenCli listenCli, required StreamSource source, required bool persevere}) {
    logger('> stream (ListeningHandler) -> ${listenCli.route}');

    final listener = _getExistingListener(hash: listenCli.hash, source: source) ?? _getNewListener(listenCli);

    // TODO: in the future, change this so if there's 3 streams identical, but only one is persevere
    // and the persevere stream stops listening, so persevere will change to false
    listener.persevere = persevere || listener.isPersevere();

    // Important: the logic of converting the stream events
    // should be always bellow _getAlreadyListening(..) and _getNewListening(..)

    return listener.stream.map((value) => value.output);
  }

  void Function() _getCallbackNotifyParentStreamThatChildStreamIsNotListeningAnymore (String listenId) => () {
    logger("notifyParentStreamThatChildStreamIsNotListeningAnymore");
    _stopListening(listenId: listenId);
  };


  void _stopListening({required String listenId}) {
    Future.delayed(const Duration(milliseconds: _kStreamAddDelayMs * 3), () {
      logger("stopListening started $listenId");
      final sub = listeningTo.firstWhereOrNull((s) => s.listenId == listenId);
      if (sub != null) {
        sub.counter--;
        assert(sub.counter >= 0 || !kDebugMode);
        logger("${sub.route} ($listenId) stopListening counter IS NOW ${sub.counter}");
        if (sub.counter <= 0) {
          sub.streamBroadcastController.close();
          listeningTo.remove(sub);
        }
      }
    });
  }

  Listening? _getExistingListener({required String hash, required StreamSource source}) {
    logger('alreadyListening');
    final ClientListeningToRoute? alreadyListening = listeningTo.firstWhereOrNull((listenId) => listenId.hash == hash);

    if(alreadyListening == null) {
      logger('alreadyListening: nothing found for hash = $hash');
      return null;
    }

    final childStreamController = StreamController<NewDataForListener>();
    alreadyListening.addOnDoneParentControllerListener(childStreamController.close);

    void streamAdd() {
      logger("COUNTER NOW IS ${alreadyListening.counter}");
      try {
        alreadyListening.counter++;
        if (alreadyListening.lastReceivementFromServer != null && source != StreamSource.remoteOnly) {
          alreadyListening.streamBroadcastController.add(alreadyListening.lastReceivementFromServer!);
        }
      } catch (e) {
        if (!e.toString().contains('Bad state: Cannot add new events after calling close')) {
          rethrow;
        }else{
          logger(e.toString(), level: Level.debug);
        }
      }
    }

    // if(environment == 'test'){
    //   streamAdd();
    // } else {
      Future.delayed(const Duration(milliseconds: _kStreamAddDelayMs), streamAdd);
    // }

    return Listening(
      alreadyListening.streamBroadcastController.stream,
      childStreamController,
      alreadyListening.listenId,
      _getCallbackNotifyParentStreamThatChildStreamIsNotListeningAnymore(alreadyListening.listenId),
    );
  }

  Listening _getNewListener(ListenCli listenCli) {
    logger("_getNewListener");
    final String listenId = LISTEN_PREFIX + randomAlphaNumeric(28);
    final parentStreamController = StreamController<NewDataForListener>.broadcast(); // ignore: close_sinks

    listenCli.listenId = listenId;
    ClientListeningToRoute listen = ClientListeningToRoute(
      route: listenCli.route,
      params: listenCli.params,
      streamBroadcastController: parentStreamController,
      hash: listenCli.hash,
      listenId: listenId,
    );
    listeningTo.add(listen);
    final childStreamController = StreamController<NewDataForListener>();
    listen.addOnDoneParentControllerListener(childStreamController.close);

    final res = Listening(
      parentStreamController.stream,
      childStreamController,
      listenId,
      _getCallbackNotifyParentStreamThatChildStreamIsNotListeningAnymore(listenId),
    );
    parentStreamController.done.then((_) => _onDoneParentStreamController(listen));
    ready(String clientRequestId) {
      logger("ready");
      listen.clientRequestId = listenCli.clientRequestId = clientRequestId;
      listen.ready = true;

      if (getIt.get<ListeningHandler>().unfoundData[listenId] != null) {
        ClientReceivedNewDataForListener(getIt.get<ListeningHandler>().unfoundData[listenId]).implementation();
        getIt.get<ListeningHandler>().unfoundData.removeWhere((key, _) => listenId == key);
      }
    }
    listenCli.clientRequestId = '${LISTEN_PREFIX}_${randomAlphaNumeric(28)}';
    getIt.get<RequestsService>().runOperationInServer(data: listenCli, isPersevere: res.isPersevere, neverTimeout: true, ifRequiresAuthenticationWaitForIt: false).then((firstResponse) {
      if (firstResponse.error?.code == AsklessErrorCode.pendingAuthentication) {
        getIt.get<AuthenticateService>().waitForAuthentication(neverTimeout: true, isPersevere: res.isPersevere, requestType: RequestType.LISTEN, route: listenCli.route).then((authenticated) {
          if (!authenticated){
            logger('waitForAuthentication failed', level: Level.error);
            parentStreamController.sink.addError(firstResponse.error!);
            return;
          }
          listenCli.clientRequestId = '${LISTEN_PREFIX}_${randomAlphaNumeric(28)}';
          getIt.get<RequestsService>().runOperationInServer(data: listenCli, isPersevere: res.isPersevere, neverTimeout: true).then((secondResponse) {
            if (secondResponse.error != null) {
              parentStreamController.sink.addError(secondResponse.error!);
              logger('could not listen (after authentication)', level: Level.error);
            } else {
              logger('now is listening to $listenId! (after authenticated)');
              ready(secondResponse.clientRequestId);
            }
          });
        }, onError: (e) {
          logger('WAIT FOR AUTH ERROR: ${e.toString()}', level: Level.error);
        });
      } else if (firstResponse.error != null) {
        parentStreamController.sink.addError(firstResponse.error!);
        logger('could not listen', level: Level.error);
      } else {
        logger('now is listening to $listenId!');
        ready(firstResponse.clientRequestId);
      }
    });

    return res;
  }

  void clear() {
    logger("clear() called");
    for (final s in listeningTo) {
      s.streamBroadcastController.close();
    }
    listeningTo.clear();
  }


  FutureOr _onDoneParentStreamController(ClientListeningToRoute parent) {
    for (final listener in parent.onDoneParentControllerListeners) {
      listener();
    }
  }
}


class ClientListeningToRoute {
  final String route;
  final dynamic params;
  StreamController<NewDataForListener> streamBroadcastController;
  final String hash;
  String listenId;
  NewDataForListener? lastReceivementFromServer;
  int counter = 1;
  String? clientRequestId;
  bool _ready = false;
  final List<void Function()> onReadList = [];
  final List<void Function()> onDoneParentControllerListeners = [];

  set ready (bool value) {
    _ready = value;
    for (final onReady in onReadList) {
      onReady();
    }
    onReadList.clear();
  }
  bool get ready => _ready;

  void onReady(void Function() onReady) {
    if (_ready) {
      onReady();
    } else {
      onReadList.add(onReady);
    }
  }

  ClientListeningToRoute(
      {required this.route,
        required this.params,
        required this.streamBroadcastController,
        required this.hash,
        required this.listenId,
        this.clientRequestId,
      }
  );

  void addOnDoneParentControllerListener(void Function() listener) {
    onDoneParentControllerListeners.add(listener);
  }
}

class Listening {
  //Um id gerado pelo cliente que representa
  //a troca de dados em tempo real entre o o cliente e uma sub-rota do servidor
  final String listenId;
  final void Function() _notifyParentStreamThatChildStreamIsNotListeningAnymore;

  late final Stream<NewDataForListener> stream;
  final StreamController<NewDataForListener> childStreamController;
  final Stream<NewDataForListener> _parentStream;
  late final StreamSubscription<NewDataForListener> _subscription;
  bool _closeHasBeenCalled = false;

  bool _persevere = false;
  set persevere (bool value) { _persevere |= value; }

  bool isPersevere () => _persevere;

  Listening(this._parentStream, this.childStreamController, this.listenId, this._notifyParentStreamThatChildStreamIsNotListeningAnymore){
    stream = childStreamController.stream;
    _subscription = _parentStream.listen(childStreamController.add);
    childStreamController.onCancel = close;
  }

  /// Stop receiving realtime data from server using [Listening.stream].
  void close(){
    logger("CLOSE HAS BEEN SUCCESSFULLY CALLED!! $_closeHasBeenCalled");
    if(_closeHasBeenCalled) {
      return;
    }
    _closeHasBeenCalled = true;
    _subscription.cancel();
    childStreamController.close();
    _notifyParentStreamThatChildStreamIsNotListeningAnymore();
  }
}

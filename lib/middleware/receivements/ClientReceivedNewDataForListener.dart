
import 'package:collection/collection.dart';
import '../../../../../../injection_container.dart';
import '../ListeningHandler.dart';
import '../data/receivements/NewDataForListener.dart';
import 'ClientReceived.dart';
import '../../index.dart';
import '../../domain/utils/logger.dart';

class ClientReceivedNewDataForListener extends ClientReceived{
  ClientReceivedNewDataForListener(messageMap)
      : super(messageMap, true);

  @override
  void implementation() {
    final message = NewDataForListener.fromMap(messageMap);

    final sub = getIt.get<ListeningHandler>()
        .listeningTo
        .firstWhereOrNull((s) => s.listenId == message.listenId);
    if (sub != null) {
      logger("found ${message.listenId}!!");
      sub.onReady(() {
        logger("running onReady ${message.listenId}!!");
        sub.streamBroadcastController.add(message);
        sub.lastReceivementFromServer = message;
      });
    } else {
      logger ("Not found ${message.listenId}!! ${getIt.get<ListeningHandler>().listeningTo.map((e) => "${e.listenId} ")}");
      getIt.get<ListeningHandler>().unfoundData[message.listenId] = messageMap;
      Future.delayed(const Duration(seconds: 15), () {
        getIt.get<ListeningHandler>().unfoundData.removeWhere((key, _) => message.listenId == key);
      });
    }
  }


}
import 'package:collection/collection.dart';
import '../../injection_container.dart';
import '../ListeningHandler.dart';
import '../data/receivements/StopListeningEvent.dart';
import 'ClientReceived.dart';
import 'package:collection/collection.dart';

class ClientReceivedStopListeningEvent extends ClientReceived{
  late final StopListeningEventEvent event;

  ClientReceivedStopListeningEvent(Map<String,dynamic> messageMap):super({}, false) {
    event = StopListeningEventEvent.fromMap(messageMap);
  }
  
  @override
  void implementation() async {
    final listening = getIt.get<ListeningHandler>().listeningTo.firstWhereOrNull((element) => element.listenId == event.listenId);
    if (listening != null) {
      getIt.get<ListeningHandler>().listeningTo.remove(listening);
      listening.streamBroadcastController.close();
    }
  }
  
}
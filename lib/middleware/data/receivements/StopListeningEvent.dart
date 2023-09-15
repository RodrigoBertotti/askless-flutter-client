
class StopListeningEventEvent {
  static const type = '_class_type_stoplistening';

  late final String listenId;

  StopListeningEventEvent({required this.listenId});

  @override
  StopListeningEventEvent.fromMap(messageMap) {
    listenId = messageMap['listenId'];
  }

}

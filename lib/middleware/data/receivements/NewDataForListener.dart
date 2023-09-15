
class NewDataForListener {
  static const type = '_class_type_newDataForListener';

  late final dynamic output;
  late final String listenId;

  NewDataForListener({required this.output, required this.listenId});

  @override
  NewDataForListener.fromMap(messageMap) {
    output = messageMap['output'];
    listenId = messageMap['listenId'];
  }

}

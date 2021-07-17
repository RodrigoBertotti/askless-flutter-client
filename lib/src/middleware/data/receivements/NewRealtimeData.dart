
import 'AbstractServerData.dart';

class NewDataForListener extends AbstractServerData{
  static const type = '_class_type_newDataForListener';
  final _class_type_newDataForListener = '_';

  late final dynamic output;
  late final String listenId;

  NewDataForListener({required this.output, required this.listenId});

  @override
  NewDataForListener.fromMap(messageMap) {
    super.fromMap(messageMap);
    output = messageMap['output'];
    listenId = messageMap['listenId'];
  }

}

import 'package:flutter/widgets.dart';
import 'package:askless/src/middleware/data/response/RespondError.dart';

import 'AbstractServerData.dart';

class NewDataForListener extends AbstractServerData{
  static final type = '_class_type_newDataForListener';
  final _class_type_newDataForListener = '_';

  dynamic output;
  String listenId;

  NewDataForListener({this.output, this.listenId});

  NewDataForListener.fromMap(messageMap) {
    super.fromMap(messageMap);
    output = messageMap['output'];
    listenId = messageMap['listenId'];
  }

}

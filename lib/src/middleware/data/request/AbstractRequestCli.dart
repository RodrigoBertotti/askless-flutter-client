import 'package:random_string/random_string.dart';

import '../../../constants.dart';

abstract class AbstractRequestCli {
  static int _counter = 1;
  static String jsonClientRequestId = 'clientRequestId';
  final String requestType;
  String clientRequestId = REQUEST_PREFIX+(_counter++).toString()+'_'+randomAlphaNumeric(7);
  bool waitUntilGetServerConnection;

  AbstractRequestCli(this.requestType, {this.waitUntilGetServerConnection=true});

  Map<String, dynamic> toMap(){
    final map = new Map<String, dynamic>();
    map[jsonClientRequestId] = clientRequestId;
    map['requestType'] = requestType;
    return map;
  }
}

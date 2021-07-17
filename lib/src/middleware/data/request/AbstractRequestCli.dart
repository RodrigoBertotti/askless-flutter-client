import 'package:askless/src/middleware/data/Mappable.dart';
import 'package:random_string/random_string.dart';
import '../../../constants.dart';

abstract class AbstractRequestCli implements Mappable {
  static const String fieldClientRequestId = 'clientRequestId';
  static const String fieldRequestType = 'requestType';

  static int _counter = 1;
  late RequestType requestType;
  String clientRequestId = REQUEST_PREFIX+(_counter++).toString()+'_'+randomAlphaNumeric(7);
  bool waitUntilGetServerConnection;

  AbstractRequestCli(this.requestType, {this.waitUntilGetServerConnection=true});

  @override
  Map<String, dynamic> toMap(){
    final map = new Map<String, dynamic>();
    map[fieldClientRequestId] = clientRequestId;
    map[fieldRequestType] = requestType.toString().split('.').last;
    return map;
  }
}

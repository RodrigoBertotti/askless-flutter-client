import '../../../constants.dart';
import '../Mappable.dart';

abstract class AbstractRequestCli implements Mappable {
  static const String fieldClientRequestId = 'clientRequestId';
  static const String fieldRequestType = 'requestType';

  late RequestType requestType;
  String? clientRequestId;
  bool waitUntilGetServerConnection;

  AbstractRequestCli(this.requestType, {this.waitUntilGetServerConnection=true, this.clientRequestId});

  @override
  Map<String, dynamic> toMap(){
    final map = <String, dynamic>{};
    map[fieldClientRequestId] = clientRequestId;
    map[fieldRequestType] = requestType.toString().split('.').last;
    return map;
  }

  String? getRoute();

}

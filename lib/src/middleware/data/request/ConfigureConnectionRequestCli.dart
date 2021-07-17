import 'package:askless/src/middleware/data/request/AbstractRequestCli.dart';

import '../../../constants.dart';




class ConfigureConnectionRequestCli extends AbstractRequestCli{
  static const fieldType = '_class_type_configureconnectionrequest';
  static const fieldHeaders = 'headers';
  static const fieldClientId = 'clientId';
  static const fieldClientType = 'clientType';

  Map<String,dynamic> headers;
  String clientId;
  String clientType = 'flutter';

  ConfigureConnectionRequestCli(this.clientId, this.headers) : super(RequestType.CONFIGURE_CONNECTION);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map[fieldType] = '_';
    map[fieldHeaders] = headers;
    map[fieldClientId] = clientId;
    map[fieldClientType] = clientType;
    return map;
  }
}

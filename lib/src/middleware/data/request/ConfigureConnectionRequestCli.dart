import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/data/request/AbstractRequestCli.dart';

import '../../../index.dart';
import '../../../constants.dart';




class ConfigureConnectionRequestCli extends AbstractRequestCli{
  static final type = '_class_type_configureconnectionrequest';
  final _class_type_configureconnectionrequest = '_';

  Map<String,dynamic> headers;
  final clientId;
  final clientType = 'flutter';

  ConfigureConnectionRequestCli(this.clientId, this.headers) : super(RequestType.CONFIGURE_CONNECTION);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map[type] = '_';
    map['headers'] = headers;
    map['clientId'] = clientId;
    map['clientType'] = clientType;
    return map;
  }
}

import 'package:askless/src/middleware/data/request/AbstractRequestCli.dart';

import '../../../constants.dart';




class ClientConfirmReceiptCli extends AbstractRequestCli{
  static const fieldType = '_class_type_clientconfirmreceipt';
  static const fieldServerId = 'serverId';

  String serverId;

  ClientConfirmReceiptCli(this.serverId) : super(RequestType.CONFIRM_RECEIPT);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map[fieldType] = '_';
    map[fieldServerId] = serverId;
    return map;
  }

}

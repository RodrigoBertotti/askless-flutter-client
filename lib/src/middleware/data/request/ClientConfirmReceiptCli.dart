import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/data/request/AbstractRequestCli.dart';

import '../../../index.dart';
import '../../../constants.dart';




class ClientConfirmReceiptCli extends AbstractRequestCli{
  static final type = '_class_type_clientconfirmreceipt';
  final _class_type_clientconfirmreceipt = '_';

  final String serverId;

  ClientConfirmReceiptCli(this.serverId) : super(RequestType.CONFIRM_RECEIPT);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map[type] = '_';
    map['serverId'] = serverId;
    return map;
  }


}

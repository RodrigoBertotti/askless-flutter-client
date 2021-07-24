import 'package:askless/src/middleware/data/receivements/ResponseCli.dart';

class ServerConfirmReceiptCli extends ResponseCli{
  static const typeResponse = '_class_type_serverconfirmreceipt';

  @override
  ServerConfirmReceiptCli.fromMap(messageMap) : super.fromMap(messageMap);

}




import 'package:askless/src/middleware/receivements/ClientReceived.dart';

class ClientReceivedIgnore extends ClientReceived{


  ClientReceivedIgnore():super(null, false);
  
  @override
  void implementation() async {}
  
}
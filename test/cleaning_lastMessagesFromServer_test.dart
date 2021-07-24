import 'dart:math';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/index.dart';
import 'package:askless/src/middleware/receivements/ClientReceived.dart';
import 'package:test/test.dart';


class _ClientReceivedTest extends ClientReceived {

  _ClientReceivedTest() : super({}, true);

  @override
  void implementation() {

  }

}

void setLastMessagesFromServer(int shouldKeep, int shouldRemove){
  assert(shouldRemove >=0 && shouldKeep >= 0);

  assert(
    shouldRemove == 0 || shouldKeep + shouldRemove > ClientReceived.startCheckingLastMessagesFromServerAfterSize,
    'checkCleanOldMessagesFromServer will run only when lastMessagesFromServer.length is >= than '+ClientReceived.startCheckingLastMessagesFromServerAfterSize.toString()
  );

  Internal.instance.middleware!.lastMessagesFromServer.clear();

  while(true){
    final lastServerMessage = new LastServerMessage('server_id'+(shouldKeep + shouldRemove).toString());
    if(shouldKeep > 0){
      shouldKeep--;
      lastServerMessage.messageReceivedAtSinceEpoch = (DateTime.now().millisecondsSinceEpoch - keepLastMessagesFromServerWithinMs * new Random().nextInt(100)/100).toInt();
    }else if(shouldRemove > 0){
      shouldRemove--;
      lastServerMessage.messageReceivedAtSinceEpoch = (DateTime.now().millisecondsSinceEpoch - keepLastMessagesFromServerWithinMs * (1.1 + new Random().nextInt(100)/100)).toInt();
    }else{
      break;
    }
    Internal.instance.middleware!.lastMessagesFromServer.add(lastServerMessage);
  }
}

void main() {

  Internal.instance.middleware = new Middleware('test');


  test('checkCleanOldMessagesFromServer: lastMessagesFromServer.length should be 60 + 70 = 130', () {
    setLastMessagesFromServer(60, 70);
    expect(Internal.instance.middleware!.lastMessagesFromServer.length, equals(130));

    expect(Internal.instance.middleware!.lastMessagesFromServer.length, equals(130));
  });


  test('checkCleanOldMessagesFromServer lastMessagesFromServer.length should be 118', () {
    setLastMessagesFromServer(60, 70);
    expect(Internal.instance.middleware!.lastMessagesFromServer.length, equals(130));

    new _ClientReceivedTest().checkCleanOldMessagesFromServer(removeCount: 12);

    expect(Internal.instance.middleware!.lastMessagesFromServer.length, equals(118));
  });

  test('checkCleanOldMessagesFromServer lastMessagesFromServer.length should be 180', () {
    setLastMessagesFromServer(178, 12);
    expect(Internal.instance.middleware!.lastMessagesFromServer.length, equals(190));

    new _ClientReceivedTest().checkCleanOldMessagesFromServer(removeCount: 10);

    expect(Internal.instance.middleware!.lastMessagesFromServer.length, equals(180));
  });
}
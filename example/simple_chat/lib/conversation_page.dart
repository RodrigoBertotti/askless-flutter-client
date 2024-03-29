import 'dart:async';
import 'package:flutter/material.dart';
import 'package:askless/index.dart';
import 'MessageWidget.dart';

class Test extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: GestureDetector(
            child: Text("TAP"),
            onTap: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (c) => ConversationsPage(myName: 'blue',)));
            },
          ),
        ),
      ),
    );
  }
}


class ConversationsPage extends StatefulWidget {
  late final bool _iAmGreen;
  late final Color _myColor;
  final String myName;

  ConversationsPage({super.key, required this.myName}){
    _iAmGreen = myName == 'green';
    _myColor = _iAmGreen ? Colors.green : Colors.blue;
  }

  @override
  _ConversationsPageState createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> with TickerProviderStateMixin {
  late ConnectionDetails _connection; // ignore: unused_field
  bool _hasTextToSend = false;
  final TextEditingController messageController = TextEditingController(text: '');
  final animatedListKey = GlobalKey<AnimatedListState>();
  late ScrollController controller;
  List messages = [];
  late StreamSubscription<dynamic> messagesSubscription;

  _ConversationsPageState();


  @override
  void initState() {
    super.initState();
    _connection = AsklessClient.instance.connection;
    AsklessClient.instance.addOnConnectionChangeListener((connection) {
      _connection=connection;
    });
    
    messageController.addListener(() {
      final hasTextToSendNew = messageController.text.isNotEmpty;
      if(hasTextToSendNew!=_hasTextToSend){
        setState((){ _hasTextToSend = hasTextToSendNew;});
      }else{
        _hasTextToSend = hasTextToSendNew;
      }
    });
    controller = ScrollController();

    messagesSubscription = AsklessClient.instance.readStream(route: 'message')
        .listen((output) {
          final serverMessages = List.from(output);
          for (final message in serverMessages) {
            messages.add(message);
            animatedListKey.currentState?.insertItem(messages.length - 1);

            Future.delayed(const Duration(milliseconds: 200), () {
              controller.jumpTo(controller.position.maxScrollExtent);
            });
          }
        }
      );
  }

  keyboardIsClosed(BuildContext context) => MediaQuery.of(context).viewInsets.bottom == 0.0;

  @override
  void dispose() {
    messagesSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const inputStyle = TextStyle(color: Colors.black);

    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(13)),
      borderSide: BorderSide(color: Colors.greenAccent, width: 0.0),
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Container(color: widget._myColor, width: MediaQuery.of(context).size.width, height: MediaQuery.of(context).size.height,),
            Column(
              children: <Widget>[
                Expanded(
                  flex: keyboardIsClosed(context) ? 17 : 11,
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: AnimatedList(
                            key: animatedListKey,
                            controller: controller,
                            initialItemCount: messages.length,
                            itemBuilder: ((context2, position, animation){
                              final message = messages[position];
                              return SlideTransition(
                                position: animation.drive(
                                    Tween(
                                        begin: Offset(message['origin'] == widget.myName ? 1.0 : -1.0, 0),
                                        end: Offset.zero
                                    )
                                        .chain(
                                        CurveTween(
                                            curve: Curves.linear
                                        )
                                    )
                                ),
                                child: message['origin'] == widget.myName
                                    ? MessageWidgetOfMyself(text:message['text'])
                                    : MessageWidgetOfTheir(text:message['text']),
                              );
                            }),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
//                            GestureDetector(
//                              child: Text("TAP"),
//                              onTap: () {
//                                Navigator.of(context).pushReplacement(new MaterialPageRoute(builder: (c) => Test()));
//                              },
//                            ),
                            Container(
                                width: MediaQuery.of(context).size.width - 100,
                                child: TextFormField(
                                  controller: messageController,
                                  decoration: InputDecoration(
                                    hintStyle: TextStyle(color: Colors.grey),
                                    hintText: 'Type your message here...',
                                    fillColor: Colors.white,
                                    focusedBorder: border,
                                    enabledBorder: border,
                                    errorBorder: border,
                                    disabledBorder: border,
                                    border: border,
                                    focusedErrorBorder: border,
                                    filled: true,
                                  ),
                                  style: inputStyle,
                                )
                            ),
                            Container(width: 5,),
                            GestureDetector(
                              child: Opacity(opacity: _hasTextToSend ? 1 : 0, child: Icon(Icons.send, color: Colors.white, size: 27,),),
                              onTap: !_hasTextToSend ? null : (){
                                AsklessClient.instance.create(
                                    route: 'message',
                                    body: {
                                      'text' : messageController.text
                                    },
                                    neverTimeout: true
                                );
                                messageController.clear();
                              },
                            )
                          ],
                        ),
                      ),
                    )
                )
              ],
            ),
          ],
        ),
      ),
    );
  }


}


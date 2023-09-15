import 'package:flutter/material.dart';
import 'package:askless/index.dart';
import 'conversation_page.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  String? _tapped;
  final Duration _containerAnimationDuration = Duration(seconds: 1);
  final Duration _titleAnimationDuration = Duration(milliseconds: 500);
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:  <Widget>[
          AnimatedSwitcher(duration: _titleAnimationDuration, child: _tapped!=null ? Container() : RichText(text: const TextSpan(
              children: <TextSpan>[
                TextSpan(text: 'What co',
                    style: TextStyle(fontSize: 22, color: Colors.blue)),
                TextSpan(text: 'lor am I?',
                    style: TextStyle(fontSize: 22, color: Colors.green)),
              ]
          ),),),
          AnimatedContainer(height: _tapped==null?40:0, duration: _containerAnimationDuration,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              item(color: Colors.blue, myColor: 'blue', isTapped: _tapped == 'blue'),
              AnimatedContainer(width: _tapped==null?10:0, duration: _containerAnimationDuration,),
              item(color: Colors.green, myColor: 'green', isTapped: _tapped == 'green'),
            ],
          ),
        ],
      ),
    );
  }

  item({required Color color, required String myColor, required isTapped}) {
    final size = _getSizeContainer(name: myColor);
    return Row(
      children: <Widget>[
        GestureDetector(
            onTap: () {
              setState(() {
                _tapped = myColor;
                _loading = true;
                AsklessClient.instance.clearAuthentication();
                AsklessClient.instance.authenticate(credential: { "myColor": myColor }, neverTimeout: true).then((value){
                  Future.delayed(_containerAnimationDuration, () {
                    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => ConversationsPage(myName: _tapped!,)), (route) => false);
                  });
                });
              });
            },
            child: AnimatedContainer(
              duration: _containerAnimationDuration,
              width: size['width'],
              color: color,
              height: size['height'],
              alignment: Alignment.bottomCenter,
              child: _loading && isTapped ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),),
                  SizedBox(height: 20,),
                  Text('Disconnecting and connecting again\nto server as ownClientId: '+myColor, style: TextStyle(color: Colors.white, fontSize: 18,), textAlign: TextAlign.center,)
                ],
              ) : Container(),
            )
        )
      ],
    );
  }

  _getSizeContainer({required name}) {
    if(_tapped==null) {
      return {
        'width': MediaQuery.of(context).size.width / 2 - 10,
        'height':  MediaQuery.of(context).size.height / 2
      };
    }
    if(_tapped==name) {
      return {
        'width': MediaQuery.of(context).size.width,
        'height':  MediaQuery.of(context).size.height
      };
    }
    return {
      'width': 0.0,
      'height':  0.0
    };
  }

}

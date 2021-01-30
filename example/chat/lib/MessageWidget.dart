import 'package:flutter/material.dart';
import 'package:askless/askless.dart';

class MessageWidgetOfMyself extends StatelessWidget {
  final String text;

  MessageWidgetOfMyself({@required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _buildBox(text: text, context: context),
      ],
      mainAxisAlignment: MainAxisAlignment.end,
    );
  }
}

class MessageWidgetOfTheir extends StatelessWidget {
  final String text;

  MessageWidgetOfTheir({@required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _buildBox(text: text, context: context),
      ],
      mainAxisAlignment: MainAxisAlignment.start,
    );
  }
}

_buildBox({@required BuildContext context, @required String text}){
  return Padding(
    child: Container(
      decoration: BoxDecoration(
          borderRadius: new BorderRadius.circular(10.0),
          color: Colors.white
      ),
      child: Padding(
        padding: EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
        child: Text(text),
      ),
    ),
    padding: EdgeInsets.only(bottom: 5),
  );
}

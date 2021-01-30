import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:askless/askless.dart';

import 'main.dart';

class TrackingApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tracking',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final _textStyle = TextStyle(fontSize: 22);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Tracking"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              //Show the status of the tracking in realtime
              AsklessClient.instance
                  .listenAndBuild(
                  route: 'product/tracking-ts',
                  builder: (context,  snapshot) {
                    if(!snapshot.hasData)
                      return Container();
                    return Text(snapshot.data, style: _textStyle);
                  }
              ),

              SizedBox(height: 100,),

              RaisedButton(
                child: Text("I'm waiting", style: _textStyle,),
                onPressed: (){
                  AsklessClient.instance
                      .create(route: 'product/customerSaid', body: 'I\'m waiting')
                      .then((res) => print(res.isSuccess ? 'Success' : res.error.code));
                },
              )],
          ),
        )
    );
  }

  @override
  void initState() {
    super.initState();
  }
}

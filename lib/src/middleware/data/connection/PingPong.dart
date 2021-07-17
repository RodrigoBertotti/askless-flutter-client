import 'package:flutter/cupertino.dart';
import 'package:askless/src/middleware/data/request/OperationRequestCli.dart';

import '../Mappable.dart';

class ListeningTo extends ListenCli{
  String listenId;

  ListeningTo({required this.listenId, required String route, query, String ? clientRequestId}) : super(route: route, query: query){
    if(clientRequestId!=null)
      super.clientRequestId = clientRequestId;
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['listenId'] = listenId;
    return map;
  }

  static List toMapList(List<ListeningTo> list){
    List<dynamic> res = [];
    list.forEach((v) => res.add(v.toMap()));
    return res;
  }
}

class PingPong implements Mappable{
  static const type = '_class_type_pingpong';
  final _class_type_pingpong = '_';

  List<ListeningTo> listeningToRoutes;

  PingPong({required this.listeningToRoutes});

  @override
  toMap() {
    final map = {
      type: '_',
      'listeningToRoutes': ListeningTo.toMapList(listeningToRoutes),
    };
    return map;
  }



}

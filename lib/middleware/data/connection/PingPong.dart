import '../Mappable.dart';
import '../request/OperationRequestCli.dart';

class ListeningTo extends ListenCli {
  final String listenId;

  ListeningTo({required this.listenId, required String route, params, required String clientRequestId})
      : super(route: route, params: params, clientRequestId: clientRequestId,);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['listenId'] = listenId;
    return map;
  }

  static List toMapList(List<ListeningTo> list){
    List<dynamic> res = [];
    for (final v in list) {
      res.add(v.toMap());
    }
    return res;
  }
}

class PingPong implements Mappable {
  static const type = '_class_type_pingpong';

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

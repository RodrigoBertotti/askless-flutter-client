import 'dart:convert';
import '../../../constants.dart';
import 'AbstractRequestCli.dart';

abstract class ModifyCli extends AbstractRequestCli{
  static const fieldType = '_class_type_modify';
  static const fieldRoute = 'route';
  static const fieldBody = 'body';
  static const fieldQuery = 'params';

  String  route;
  dynamic body;
  Map<String,dynamic> ? params;

  ModifyCli(
    this.route,
    RequestType requestType,
    this.body,
    this.params
  ) : super(requestType, waitUntilGetServerConnection: false){
    assert(this.requestType == RequestType.CREATE || this.requestType == RequestType.UPDATE || this.requestType == RequestType.DELETE);
  }

  @override
  String? getRoute() {
    return route;
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map[fieldType] = '_';
    map[fieldRoute] = route;
    map[fieldBody] = body;
    map[fieldQuery] = params;
    return map;
  }
}

class CreateCli extends ModifyCli{
  CreateCli({
    required String route,
    required body,
    Map<String, dynamic> ? params
  }) : super(route, RequestType.CREATE, body, params);
}

class UpdateCli extends ModifyCli{
  UpdateCli({
    required String route,
    required dynamic body,
    Map<String, dynamic> ? params
  }) : super(route, RequestType.UPDATE, body, params);

}

class DeleteCli extends ModifyCli{
  DeleteCli({
    required String route,
    Map<String, dynamic> ? params
  }) : super(route, RequestType.DELETE, {}, params);
}

class ReadCli extends AbstractRequestCli {
  static const fieldType = '_class_type_read';
  static const fieldRoute = 'route';
  static const fieldQuery = 'params';

  String  route;
  Map<String, dynamic> ? params;

  ReadCli({
    required this.route,
    this.params
  }) : super(RequestType.READ, waitUntilGetServerConnection: false);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map[fieldType] = '_';
    map[fieldRoute] = route;
    map[fieldQuery] = params;
    return map;
  }

  @override
  String? getRoute() { return route; }
}

class ListenCli extends AbstractRequestCli {
  static const String fieldType = '_class_type_listen';
  static const String fieldListenId = 'listenId';
  static const String fieldRoute = 'route';
  static const String fieldQuery = 'params';

  String route;
  Map<String, dynamic>? params;
  late String listenId;

  ListenCli({
    required this.route,
    this.params,
    String? clientRequestId,
  }) : super(RequestType.LISTEN, clientRequestId: clientRequestId);

  @override
  Map<String, dynamic> toMap(){
    final map = super.toMap();
    map[fieldType] = '_';
    map[fieldRoute] = route;
    map[fieldQuery] = params;
    map[fieldListenId] = listenId;
    return map;
  }

  @override
  String? getRoute() {
    return route;
  }

  String get hash {
    String hashMap(Map map) {
      final List<String> orderedKeyValues = [];
      map.forEach((key, value) { orderedKeyValues.add("$key|$value"); });
      orderedKeyValues.sort((a,b) => a.compareTo(b));
      return jsonEncode(orderedKeyValues);
    }

    return hashMap({
      fieldRoute: route,
      fieldQuery: params == null ? null : hashMap(params!),
      AbstractRequestCli.fieldRequestType: requestType.toString().split('.').last,
    });
  }

}

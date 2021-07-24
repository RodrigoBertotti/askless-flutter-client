import 'dart:convert';
import 'package:askless/src/middleware/data/request/AbstractRequestCli.dart';
import '../../../constants.dart';

abstract class ModifyCli extends AbstractRequestCli{
  static const fieldType = '_class_type_modify';
  static const fieldRoute = 'route';
  static const fieldBody = 'body';
  static const fieldQuery = 'query';

  String  route;
  dynamic body;
  Map<String,dynamic> ? query;

  ModifyCli(
    this.route,
    RequestType requestType,
    this.body,
    this.query
  ) : super(requestType, waitUntilGetServerConnection: false){
    assert(this.requestType == RequestType.CREATE || this.requestType == RequestType.UPDATE || this.requestType == RequestType.DELETE);
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map[fieldType] = '_';
    map[fieldRoute] = route;
    map[fieldBody] = body;
    map[fieldQuery] = query;
    return map;
  }
}

class CreateCli extends ModifyCli{
  CreateCli({
    required String route,
    required body,
    Map<String, dynamic> ? query
  }) : super(route, RequestType.CREATE, body, query);
}

class UpdateCli extends ModifyCli{
  UpdateCli({
    required String route,
    required dynamic body,
    Map<String, dynamic> ? query
  }) : super(route, RequestType.UPDATE, body, query);

}

class DeleteCli extends ModifyCli{
  DeleteCli({
    required String route,
    Map<String, dynamic> ? query
  }) : super(route, RequestType.DELETE, {}, query);
}

class ReadCli extends AbstractRequestCli{
  static const fieldType = '_class_type_read';
  static const fieldRoute = 'route';
  static const fieldQuery = 'query';

  String  route;
  Map<String, dynamic> ? query;

  ReadCli({
    required this.route,
    this.query
  }) : super(RequestType.READ, waitUntilGetServerConnection: false);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map[fieldType] = '_';
    map[fieldRoute] = route;
    map[fieldQuery] = query;
    return map;
  }

  // @override
  // ReadCli.fromMap(map) : super.fromMap(map) {
  //   route = map[fieldRoute];
  //   query = map[fieldQuery];
  // }
}

class ListenCli extends AbstractRequestCli{
  static const String fieldType = '_class_type_listen';
  static const String fieldListenId = 'listenId';
  static const String fieldRoute = 'route';
  static const String fieldQuery = 'query';

  String  route;
  dynamic query;
  late String listenId;

  ListenCli({
    required this.route,
    this.query
  }) : super(RequestType.LISTEN);

  @override
  Map<String, dynamic> toMap(){
    final map = super.toMap();
    map[fieldType] = '_';
    map[fieldRoute] = route;
    map[fieldQuery] = query;
    map[fieldListenId] = listenId;
    return map;
  }

  String get hash => jsonEncode({
    fieldRoute: route,
    fieldQuery: query,
    AbstractRequestCli.fieldRequestType: requestType.toString().split('.').last,
  });

}

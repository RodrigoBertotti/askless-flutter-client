


import 'package:flutter/widgets.dart';
import 'package:askless/src/middleware/data/request/AbstractRequestCli.dart';

import '../../../constants.dart';

abstract class _ModifyCli extends AbstractRequestCli{
  final _class_type_modify = '_';

  final String  route;
  final dynamic body;
  final Map<String,dynamic> query;

  _ModifyCli(
    this.route,
    String requestType,
    this.body,
    this.query
  ) : super(requestType, waitUntilGetServerConnection: false){
    assert(this.requestType == RequestType.CREATE || this.requestType == RequestType.UPDATE || this.requestType == RequestType.DELETE);
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['route'] = route;
    map['body'] = body;
    map['query'] = query;
    map['_class_type_modify'] = '_';
    return map;
  }
}

class CreateCli extends _ModifyCli{
  CreateCli({
    @required String route,

    @required body,
    Map<String, dynamic> query
  }) : super(route, RequestType.CREATE, body, query);
}

class UpdateCli extends _ModifyCli{
  UpdateCli({
    @required String route,

    @required Map<String, dynamic> body,
    query
  }) : super(route, RequestType.UPDATE, body, query);
}

class DeleteCli extends _ModifyCli{
  DeleteCli({
    @required String route,

    Map<String, dynamic> query
  }) : super(route, RequestType.DELETE, null, query);
}

class ReadCli extends AbstractRequestCli{
  final _class_type_read = '_';

  final String  route;
  final dynamic query;

  ReadCli({
    @required this.route,
    this.query
  }) : super(RequestType.READ, waitUntilGetServerConnection: false);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['_class_type_read'] = '_';
    map['route'] = route;
    map['query'] = query;
    return map;
  }
}

class ListenCli extends AbstractRequestCli{
  static final String type = '_class_type_listen';
  final _class_type_listen = '_';
  static final String jsonListenId = 'listenId';

  final String  route;
  final dynamic query;
  String listenId;

  ListenCli({
    @required this.route,
    this.query
  }) : super(RequestType.LISTEN);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map[type] = '_';
    map['route'] = route;
    map['query'] = query;
    map[jsonListenId] = listenId;
    return map;
  }
}

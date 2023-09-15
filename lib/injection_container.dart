import 'package:get_it/get_it.dart';
import 'domain/services/authenticate_service.dart';
import 'domain/services/call_service.dart';
import 'domain/services/connection_service.dart';
import 'domain/services/requests_service.dart';
import 'middleware/ListeningHandler.dart';
import 'middleware/ws_channel/AbstractIOWsChannel.dart';
import 'middleware/ws_channel/IOWsChannel.dart';
import 'tasks/SendPingTask.dart';
import 'tasks/SendMessageToServerAgainTask.dart';
import 'tasks/ReconnectClientWhenDidNotReceivePongFromServerTask.dart';
import 'tasks/ReconnectWhenOffline.dart';
import 'tasks/TimedTask.dart';

/// Service locator
final getIt = GetIt.instance;

void init () {
  getIt.registerLazySingleton(() => SendPingTask());
  getIt.registerLazySingleton(() => SendMessageToServerAgainTask());
  getIt.registerLazySingleton(() => ReconnectWhenDidNotReceivePongFromServerTask());
  getIt.registerLazySingleton(() => ConnectionService());
  getIt.registerLazySingleton(() => AuthenticateService());
  getIt.registerLazySingleton(() => RequestsService());
  getIt.registerLazySingleton<AbstractIOWsChannel>(() => IOWsChannel());
  getIt.registerLazySingleton(() => ListeningHandler());
}


import 'dart:async';
import '../../../../../../injection_container.dart';
import '../../constants.dart';
import '../../index.dart';
import '../../middleware/ListeningHandler.dart';
import '../../middleware/data/receivements/AuthenticateResponseCli.dart';
import '../../middleware/data/request/AuthenticateRequestCli.dart';
import '../utils/logger.dart';
import 'connection_service.dart';
import '../services/requests_service.dart';
import '../../middleware/data/request/AbstractRequestCli.dart';

enum AuthStatus {
  inProgress,
  authenticated,
  notAuthenticated,
}

class WaitingForAuthenticationItem {
  final Completer<bool> completer;
  final bool Function() isPersevere;

  WaitingForAuthenticationItem({required this.completer, required this.isPersevere});
}

class AuthenticateService<USER_ID> {
  dynamic _credential;
  AuthStatus _authStatus = AuthStatus.notAuthenticated;
  final List<WaitingForAuthenticationItem> _waitingForAuthentication = [];
  USER_ID? _userId;
  List<String>? _claims;
  bool _shouldBeAuthenticated = false;

  USER_ID? get userId => _userId;

  AuthStatus get authStatus => _authStatus;

  Future<bool> waitForAuthentication(
      {required bool neverTimeout, required bool Function() isPersevere, RequestType? requestType, String? route}) {
    if (_authStatus == AuthStatus.authenticated) {
      return Future.value(true);
    }
    final completer = Completer<bool>();
    Future.delayed(
        Duration(
            milliseconds: getIt
                .get<ConnectionService>()
                .connectionConfiguration
                .waitForAuthenticationTimeoutInMs), () {
      if (neverTimeout) {
        if (!completer.isCompleted) {
          logger(
              "Askless is still waiting for authentication to complete so it can perform \"(${requestType?.toString() ?? ''}) ${route ?? '(null route)'}\", please make sure to call AsklessClient.instance.authenticate(..) so the operation will continue",
              level: Level.warning);
        }
      } else {
        if (!completer.isCompleted) {
          logger(
              "Askless could not \"(${requestType?.toString() ?? ''}) ${route ?? 'null'}\" because it requires authentication, please, call AsklessClient.instance.authenticate(..) and try again",
              level: Level.warning);

          completer.complete(false);
          _waitingForAuthentication.removeWhere((item) => item.completer == completer);
        }
      }
    });
    _waitingForAuthentication.add(WaitingForAuthenticationItem(completer: completer, isPersevere: isPersevere));
    return completer.future;
  }

  /// throws [AuthenticationIsAlreadyInProgress]
  Future<AuthenticateResponse> authenticateAgainWithPreviousCredential(
      {bool ignoreConnectionStatus = false}) {
    return authenticate(_credential,
        neverTimeout: false, ignoreConnectionStatus: ignoreConnectionStatus);
  }

  Future<AuthenticateResponse> authenticate(credential, {bool neverTimeout = false, bool ignoreConnectionStatus = false}) async {
    if (_authStatus == AuthStatus.inProgress) {
      return AuthenticateResponse<USER_ID>(
          null,
          null,
          AsklessAuthenticateError(
              code: AsklessErrorCode.conflict,
              isCredentialError: false,
              description: "There's already a authentication in progress"
          )
      );
    }
    _authStatus = AuthStatus.inProgress;
    if (!ignoreConnectionStatus) {
      final connected = await getIt
          .get<ConnectionService>()
          .waitForConnectionOrTimeout(timeout: neverTimeout ? null : const Duration(seconds: 3));
      if (!connected) {
        return AuthenticateResponse(
            null,
            null,
            AsklessAuthenticateError(
                code: AsklessErrorCode.noConnection,
                isCredentialError: false,
                description: "No connection"
            )
        );
      }
    }
    final res = AuthenticateResponseCli.fromResponse(await getIt
        .get<RequestsService>()
        .runOperationInServer(
            data: AuthenticateRequestCli(
                clientIdInternalApp: ConnectionService.clientIdInternalApp,
                credential: credential
            ),
            neverTimeout: neverTimeout,
            isPersevere: () => false,
        )
    );
    if (res.success && res.userId != null) { // Checking the res.userId in case the user is switching back to not authenticated, like in the catalog example.
      _shouldBeAuthenticated = true;
      _credential = credential;
      _userId = res.userId;
      _claims = res.claims;
      _authStatus = AuthStatus.authenticated;
      _completeAuthentication();
    } else {
      _authStatus = AuthStatus.notAuthenticated;
    }
    return AuthenticateResponse(
        res.userId,
        res.claims,
        res.success
            ? null
            : AsklessAuthenticateError(
                isCredentialError: res.isCredentialError,
                code: res.error!.code,
                description: res.error!.description
            ));
  }

  Future<void> clearAuthentication() async {
    logger("clearAuthentication() called");
    if (_authStatus == AuthStatus.authenticated) {
      await AsklessClient.instance.delete(route: "askless-internal/authentication");
    }
    _shouldBeAuthenticated = false;
    _credential = null;
    _claims = null;
    _userId = null;
    _authStatus = AuthStatus.notAuthenticated;
    _invalidateWaitForAuthentication();
    getIt.get<RequestsService>().clear();
  }

  start({OnAutoReauthenticationFails? onAutoReauthenticationFails}) {
    if (onAutoReauthenticationFails != null) {
      _onAutoReauthenticationFailsListener = onAutoReauthenticationFails;
    }

    getIt
        .get<ConnectionService>()
        .addOnConnectionChangeListener(_onConnectionChange, immediately: true, beforeOthersListeners: true);
  }

  OnAutoReauthenticationFails _onAutoReauthenticationFailsListener =
      ([String? credentialErrorCode, void Function()? clearAuthentication]) {
    logger(
        "Askless could not reconnect automatically using the current credential! (credentialErrorCode: \"${credentialErrorCode ?? "null"}\") "
        "Please add onAutoReauthenticationFails on init(serverUrl: '..', onAutoReauthenticationFails: (credentialErrorCode) {/* impl */}) so you can handle this behavior (for example: move the user to the login page or refresh the accessToken with a refreshToken)",
        level: Level.warning);
  };

  void _invalidateWaitForAuthentication() {
    logger("_invalidateWaitForAuthentication");
    final remove = [];
    for (final item in _waitingForAuthentication.where((element) => !element.isPersevere()).toList()) {
      item.completer.complete(false);
      remove.add(item);
    }
    for (final removeItem in remove) {
      _waitingForAuthentication.remove(removeItem);
    }
  }

  void _completeAuthentication() {
    for (final item in _waitingForAuthentication) {
      item.completer.complete(true);
    }
    _waitingForAuthentication.clear();
  }

  bool get shouldBeAuthenticated => _shouldBeAuthenticated;

  Future<bool> _handleConnected() async {
    if (!_shouldBeAuthenticated) {
      return true;
    }

    bool repeat;
    bool onAutoReauthenticationFailsHasBeenCalled = false;
    do {
      repeat = false;
      final authenticateResponse =
          await authenticateAgainWithPreviousCredential(
              ignoreConnectionStatus: true);
      if (!authenticateResponse.success) {
        logger("Could not reauthenticate automatically: ${authenticateResponse.error!.code}", level: Level.error);
        if (authenticateResponse.error!.isCredentialError == true) {
          onAutoReauthenticationFailsHasBeenCalled = true;
          _onAutoReauthenticationFailsListener(authenticateResponse.error!.code!, clearAuthentication);
        } else if (authenticateResponse.error!.code !=
            AsklessErrorCode.conflict) {
          await Future.delayed(const Duration(seconds: 1));
          repeat = _authStatus == AuthStatus.notAuthenticated;
        }
      }
    } while (repeat);

    if (!onAutoReauthenticationFailsHasBeenCalled) {
      return _authStatus == AuthStatus.authenticated;
    }
    return (await waitForAuthentication(neverTimeout: false, isPersevere: () => false));
  }

  Future<void> _onConnectionChange(ConnectionDetails connection) async {
    _authStatus = AuthStatus.notAuthenticated;
    if (connection.status == ConnectionStatus.connected &&
        getIt.get<AuthenticateService>().shouldBeAuthenticated) {
      await _handleConnected();
    }
  }
}

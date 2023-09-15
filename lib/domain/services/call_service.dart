import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:safe_device/safe_device.dart';
import '../../index.dart';
import '../../injection_container.dart';
import '../utils/logger.dart';
import 'authenticate_service.dart';

class CallService<USER_ID> {
  USER_ID? remoteUserId;
  late MediaStream localStream;
  late Map<String, dynamic> additionalData;
  late final Future<WebRTCParams> getWebRTCParams;
  final List<void Function(bool)> onRemoteUserConnectionChangeListeners = [];
  late RTCPeerConnection rtcPeerConnection;
  bool disposed = false;
  final List<void Function()> onCallCloses = [];
  final List<void Function()> disposeList = [];
  final List<RTCIceCandidate> rtcIceCandidateList = [];
  bool _sdpHasAlreadyBeenSet = false;
  bool _callServiceExpired = false;

  Completer<AcceptingCallResult>? resultCompleterForAcceptingCall;
  Completer<RequestCallResult>? resultCompleterForRequestingCall;

  bool _functionCalled = false;

  LiveCall? liveCall;
  ReceivingCall? receivingCall;
  RequestCallToUserInstance? requestCallInstance;
  final candidatesByPort = {};
  Map<String,dynamic> remoteUserAdditionalData = {};

  CallService(Future<WebRTCParams> Function(USER_ID userId) getWebRTCParams) {
    this.getWebRTCParams = getWebRTCParams(getIt.get<AuthenticateService>().userId);
    Future.delayed(const Duration(seconds: 1), () {_callServiceExpired = true;});
  }

  doDisposeCallback ({String? error, dynamic result}) {
    if (disposed) {
      logger("doDisposeCallback already called before", level: Level.debug);
      return;
    }
    logger("doDisposeCallback");
    assert(result == null || result is RequestCallResult || result is AcceptingCallResult);
    disposed = true;

    for (final disposeCallback in disposeList) {
      try {
        disposeCallback();
      }catch(e) {
        logger(e.toString());
      }
    }
    for (final listener in onCallCloses) {
      listener();
    }

    if (error != null || result != null) {
      if (resultCompleterForAcceptingCall != null &&
          !resultCompleterForAcceptingCall!.isCompleted) {
        if (error != null) {
          resultCompleterForAcceptingCall!.complete(
              AcceptingCallResult(error: error));
        } else {
          resultCompleterForAcceptingCall!.complete(result);
        }
      }
      if (resultCompleterForRequestingCall != null &&
          !resultCompleterForRequestingCall!.isCompleted) {
        if (error != null) {
          resultCompleterForRequestingCall!.complete(RequestCallResult(callAccepted: false, error: error));
        } else {
          resultCompleterForRequestingCall!.complete(result);
        }
      }
    }

    if (resultCompleterForRequestingCall?.isCompleted == false) {
      resultCompleterForRequestingCall!.complete(RequestCallResult(callAccepted: false, error: "Interrupted"));
    }
    if (resultCompleterForAcceptingCall?.isCompleted == false) {
      resultCompleterForAcceptingCall!.complete(AcceptingCallResult(liveCall: null, error: "Interrupted"));
    }

    receivingCall?.dispose();
    requestCallInstance?.dispose();
    liveCall?.dispose();
  }

  addToOnDisposeList (void Function() disposeCallback) {
    if (disposed) { disposeCallback(); }
    else { disposeList.add(disposeCallback); }
  }

  RequestCallToUserInstance requestCallToUser ({
    required localStream,
    required remoteUserId,
    Map<String,dynamic>? additionalData,
  }) {
    assert(!_functionCalled, "Please, create another instance of this class, this one is already in use");
    assert(!_callServiceExpired, "Please, create another instance of this class and use it right away, because of getWebRTCParams");
    _callServiceExpired = _functionCalled = true;
    resultCompleterForRequestingCall = Completer();

    this.remoteUserId = remoteUserId;
    this.localStream = localStream;
    this.additionalData = additionalData ?? <String, dynamic>{};

    _listenToCallToClose(
      onCallAnswered: (event) async {
        logger("Uhull! Call has been answered! Accepted: ${event["callAccepted"]}");

        if (disposed) {
          logger("success, but it was canceled");
          return;
        }
        if (event["callAccepted"] != true) {
          logger("callAccepted field is ${(event["callAccepted"] ?? 'null')}");
          doDisposeCallback(result: RequestCallResult(callAccepted: false, additionalData: remoteUserAdditionalData));
          return;
        }
        assert(event["sdp"]["type"] == "answer");

        logger (">> 2 - Setting remote description from answer! ${event["sdp"]["type"]} and ${event["sdp"]["sdp"]}");

        // call accepted..
        await rtcPeerConnection.setRemoteDescription(
            RTCSessionDescription(
                event["sdp"]["sdp"],
                event["sdp"]["type"]
            )
        );

        logger("--->");
        logger(Map.from(candidatesByPort).toString());

        final iceCandidateListWebsocketResponse = await AsklessClient.instance.create(
            route: "askless-internal/call/ice-candidate-list",
            body: {
              "remoteUserId": remoteUserId,
              "iceCandidateList": rtcIceCandidateList.map((iceCandidate) {
                return {
                  "candidate": iceCandidate.candidate,
                  "id": iceCandidate.sdpMid,
                  "label": iceCandidate.sdpMLineIndex,
                };
              }).toList()
            }
        );
        if (!iceCandidateListWebsocketResponse.success) {
          final errorMessage = "could not inform the iceCandidateList: \"${iceCandidateListWebsocketResponse.error!.code}: ${iceCandidateListWebsocketResponse.error!.description}\"";
          logger(errorMessage, level: Level.error);
          doDisposeCallback(error: errorMessage);
          return;
        }
      }
    );

    _setup(
      impl: () async {
        if (disposed) {
          doDisposeCallback(error: 'disposing...');
          return;
        }
        final sdpOffer = await rtcPeerConnection.createOffer({'offerToReceiveVideo': 1, 'offerToReceiveAudio': 1});
        await rtcPeerConnection.setLocalDescription(sdpOffer);

        logger(">> 1 - SDP OFFER GENERATED AND SET LOCAL DESCRIPTION LOCALLY sdpOffer");

        rtcPeerConnection.onIceCandidate = (RTCIceCandidate candidate) {
          logger("rtcPeerConnection -> onIceCandidate #1");
          rtcIceCandidateList.add(candidate);
          logger(json.encode({
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMlineIndex': candidate.sdpMLineIndex
          }));

          if (candidate.candidate != null && candidate.candidate!.contains('srflx')) {
            final cand = parseCandidate(candidate.candidate!);
            if (candidatesByPort[cand["relatedPort"]] == null) {
              candidatesByPort[cand["relatedPort"]] = [];
            }
            logger('adding --> '+Map.from(cand).toString());
            candidatesByPort[cand["relatedPort"]].add(cand["port"]);
          } else if (candidate.candidate == null) {
            if (candidatesByPort.keys.length == 1) {
              final ports = candidatesByPort[candidatesByPort.keys.first];
              logger(ports.length == 1 ? 'cool nat' : 'symmetric nat');
            }
          }

        };

        logger("askless-internal/call/request: requesting call...");
        final res = await AsklessClient.instance.create(
            route: "askless-internal/call/request",
            neverTimeout: false,
            /** TODO: add controller to let the user be able to cancel the request */
            /** TODO: custom timeout? */
            body: {
              "remoteUserId": remoteUserId,
              "sdp": sdpOffer.toMap(),
              "additionalData": additionalData,
            }
        );
        logger("askless-internal/call/request: requesting call: Call request response is ${res.success} ${res.error?.code ?? ''} ${res.error?.description ?? ''} ");
        if (!res.success) {
          doDisposeCallback(error: res.error!.description);
        }
      }
    );

    return requestCallInstance = RequestCallToUserInstance(
      resultCompleter: resultCompleterForRequestingCall!,
      dispose: doDisposeCallback,
    );
  }

  closeCallAndNotify() {
    print("closeCallAndNotify dispose (!2)");
    AsklessClient.instance.create(
        route: "askless-internal/call/close",
        body: {
          "remoteUserId": remoteUserId,
          "callClosed": true,
        }
    ).then((res) {
      print("askless-internal/call/close response: "+res.success.toString() + ' ' + (res.error?.code ?? '') + ' ' + (res.error?.description ?? ''));
    });
    doDisposeCallback();
  }

  void _setup({required void Function() impl}) {
    getWebRTCParams.then((webRTCParams){
      _checkWebRTC(webRTCParams);

      createPeerConnection(webRTCParams.configuration, webRTCParams.constraints).then((rtcPeerConnection) async {
        this.rtcPeerConnection = rtcPeerConnection;
        addToOnDisposeList(() => rtcPeerConnection.dispose());

        localStream.getTracks().forEach((track) {
          print ("ADDING TRACKS!!");
          rtcPeerConnection.addTrack(track, localStream);
        });

        rtcPeerConnection.onIceConnectionState = (e) {
          logger("rtcPeerConnection -> onIceConnectionState:");
          logger(e.toString());
        };


        MediaStream? prev;
        onAddStreamHandler (remoteStream) {
          assert(prev == null || prev == remoteStream);
          prev = remoteStream;

          // assert(!localStream.getTracks().contains(track), "onAddTrack(..) is calling with the local track");

          if (resultCompleterForAcceptingCall?.isCompleted == true || resultCompleterForRequestingCall?.isCompleted == true) {
            logger("already completed");
            return;
          }

          logger("rtcPeerConnection -> onAddTrack");
          addToOnDisposeList(() => remoteStream.dispose());

          liveCall = LiveCall(
              doDispose: doDisposeCallback,
              onCallCloses: onCallCloses,
              remoteStream: remoteStream,
              closeCall: closeCallAndNotify,
              onRemoteUserConnectionChangeListeners: onRemoteUserConnectionChangeListeners
          );

          if (resultCompleterForRequestingCall != null) {
            resultCompleterForRequestingCall!.complete(RequestCallResult(callAccepted: true, liveCall: liveCall, additionalData: remoteUserAdditionalData));
          } else {
            resultCompleterForAcceptingCall!.complete(AcceptingCallResult(liveCall: liveCall));
          }
        }

        rtcPeerConnection.onAddStream = onAddStreamHandler;
        rtcPeerConnection.onAddTrack = (remoteStream, track) { onAddStreamHandler(remoteStream); };

        rtcPeerConnection.onIceCandidate = (RTCIceCandidate candidate) {
          logger("rtcPeerConnection -> onIceCandidate #2");
          logger(json.encode({
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMlineIndex': candidate.sdpMLineIndex
          }));
        };

        impl();


      }, onError: (err) {
        final errorMessage = "createPeerConnection failed: \"$err\"";
        logger(errorMessage, level: Level.error);
        doDisposeCallback(error: errorMessage);
      });
    }, onError: (err) {
      final errorMessage = "getWebRTCParams failed: \"$err\"";
      logger(errorMessage, level: Level.error);
      doDisposeCallback(error: errorMessage);
    });
  }

  void onReceiveCallCallback(dynamic callRequest, OnReceiveVideoCallListener listener) async {
    assert(!_functionCalled, "Please, create another instance of this class, this one is already in use");
    assert(!_callServiceExpired, "Please, create another instance of this class and use it right away, because of getWebRTCParams");

    _callServiceExpired = _functionCalled = true;
    resultCompleterForAcceptingCall = Completer();
    remoteUserId = callRequest["remoteUserId"];

    _listenToCallToClose();

    Future<AcceptingCallResult> acceptCall({required MediaStream localStream, Map<String,dynamic> additionalData = const {}}) {
      this.localStream = localStream;
      this.additionalData = additionalData;

      if (_sdpHasAlreadyBeenSet) {
        throw ("sdpHasAlreadyBeenSet is true");
      }
      _sdpHasAlreadyBeenSet = true;

      _setup(
          impl: () async {
            final iceCandidateSubscription = AsklessClient.instance.readStream(
                route: "askless-internal/call/ice-candidate-list",
                params: { "remoteUserId": remoteUserId }
            ).listen((event) {
              bool added = false;
              for (final iceCandidate in List.from(event["iceCandidateList"])) {
                added = true;
                rtcPeerConnection.addCandidate(
                    RTCIceCandidate(
                        iceCandidate["candidate"],
                        iceCandidate["id"],
                        iceCandidate["label"]
                    )
                );
                logger("---------------------------");
                logger(json.encode({
                  'candidate':  iceCandidate["candidate"],
                  'sdpMid': iceCandidate["id"],
                  'sdpMlineIndex': iceCandidate["label"]
                }));
                logger("---------------------------");
              }
              logger(added ? ">> 3 - ${List.from(event["iceCandidateList"]).length} ICE candidates added!" : "NO ICE candidates added");
            }, cancelOnError: true, onError: (err) {
              final errorMessage = "\"askless-internal/call/ice-candidate-list\" failed: \"${err.toString()}\"";
              logger(errorMessage, level: Level.error);
              doDisposeCallback(error: errorMessage);
            });
            addToOnDisposeList(() => iceCandidateSubscription.cancel());

            assert(callRequest["sdp"]["type"] == "offer");

            logger(">> setRemoteDescription from offer");
            await rtcPeerConnection.setRemoteDescription(
                RTCSessionDescription(
                    callRequest["sdp"]["sdp"],
                    callRequest["sdp"]["type"]
                )
            );
            final sdpAnswer = await rtcPeerConnection.createAnswer({'offerToReceiveVideo': 1, 'offerToReceiveAudio': 1});
            await rtcPeerConnection.setLocalDescription(sdpAnswer);

            AsklessClient.instance.create(
                route: "askless-internal/call/response",
                body: {
                  "callAccepted": true,
                  "remoteUserId": remoteUserId,
                  "sdp": sdpAnswer.toMap(),
                  "additionalData": additionalData ?? {},
                }
            ).then((result) {
              if (!result.success){
                final errorMessage = "\"askless-internal/call/response\" failed: \"${result.error!.code}: ${result.error!.description}\"";
                logger(errorMessage, level: Level.error);
                doDisposeCallback(error: errorMessage);
              }
            });
          }
      );
      return resultCompleterForAcceptingCall!.future;
    }

    AcceptingCallResult? acceptedCallAnswer;
    bool callAnswered = false;
    listener(
        receivingCall = ReceivingCall(
            doDispose: doDisposeCallback,
            disposeList: disposeList,
            isCallAnswered: () => callAnswered,
            acceptCall: ({required MediaStream localStream, Map<String,dynamic>? additionalData}) async {  /* accepting call */
              if (callAnswered) {
                if (acceptedCallAnswer != null) {
                  logger("Call already answered", level: Level.warning);
                  return acceptedCallAnswer!;
                }
                throw "Call already answered";
              }
              callAnswered = true;
              return (acceptedCallAnswer = await acceptCall(localStream: localStream, additionalData: additionalData ?? {},));
            },
            rejectCall: ({Map<String,dynamic>? additionalData}) { /* rejecting call */
              if (callAnswered) {
                logger("Call already answered", level: Level.warning);
                return;
              }
              callAnswered = true;
              AsklessClient.instance.create(
                  route: "askless-internal/call/response",
                  body: {
                    "remoteUserId": remoteUserId,
                    "callAccepted": false,
                    "additionalData": additionalData ?? {},
                  }
              );
            },
            remoteUserId: remoteUserId,
            additionalData: Map.from(callRequest["additionalData"] ?? {},)
        )
    );
  }


  _listenToCallToClose({void Function(dynamic event)? onCallAnswered}) {
    logger("askless-internal/call/listen-for-a-call: lets listen to when the user $remoteUserId closes the call");
    final listeningForCallItself = AsklessClient.instance.readStream(
        route: 'askless-internal/call/listen-for-a-call',
        params: {'remoteUserId': remoteUserId}
    ).listen((event) {
      if (event["remoteUserIsConnected"] != null) {
        logger("Remote user connection changed: ${(event["remoteUserIsConnected"] ? 'connected' : 'disconnected')}");
        for (final listener in onRemoteUserConnectionChangeListeners) {
          listener(event["remoteUserIsConnected"]);
        }
      }
      if (event["callAccepted"] != null && onCallAnswered != null) {
        logger("call has been answered!");
        if (_sdpHasAlreadyBeenSet) {
          logger("sdpHasAlreadyBeenSet is true");
          return;
        }
        _sdpHasAlreadyBeenSet = true;
        remoteUserAdditionalData = event["additionalData"] ?? {};
        onCallAnswered(event);
        return;
      }

      if (event["callClosed"] != true) {
        logger("callClosed is not true");
        logger(jsonEncode(Map.from(event)));
        return;
      }
      logger("askless-internal/call/listen-for-a-call: callClosed is true -> dispose");
      doDisposeCallback();
    }, cancelOnError: true, onError: (error) {
      logger('"askless-internal/call/listen-for-a-call" error: ${error.toString()}');
      doDisposeCallback(result: error);
    }, onDone: () {
      logger("askless-internal/call/listen-for-a-call -> listeningToCallResponse is DONE! #2");
      doDisposeCallback();
    });
    addToOnDisposeList(() {
      logger("askless-internal/call/listen-for-a-call -> disposed and canceled");
      listeningForCallItself.cancel();
    });
    addToOnDisposeList(onRemoteUserConnectionChangeListeners.clear);
  }

  parseCandidate(String line) {
    List<String> parts;
    // Parse both variants.
    if (line.indexOf('a=candidate:') == 0) {
      parts = line.substring(12).split(' ');
    } else {
      parts = line.substring(10).split(' ');
    }

    final candidate = {
      "foundation": parts[0],
      "component": parts[1],
      "protocol": parts[2].toLowerCase(),
      "priority": int.parse(parts[3], radix: 10),
      "ip": parts[4],
      "port": int.parse(parts[5], radix: 10),
      // skip parts[6] == 'typ'
      "type": parts[7]
    };

    for (var i = 8; i < parts.length; i += 2) {
      switch (parts[i]) {
        case 'raddr':
          candidate["relatedAddress"] = parts[i + 1];
          break;
        case 'rport':
          candidate["relatedPort"] = int.parse(parts[i + 1], radix: 10);
          break;
        case 'tcptype':
          candidate["tcpType"] = parts[i + 1];
          break;
        default: // Unknown extensions are silently ignored.
          break;
      }
    }
    return candidate;
  }


  void _checkWebRTC(WebRTCParams webRTC) {
    bool hasTurnServer = false;
    for (final element in webRTC.iceServers) {
      final urlAux = (element["urls"] ?? element["url"]);
      final List<String> urls;
      if (urlAux is String) {
        urls = [ urlAux ];
      } else {
        assert(urlAux is List, 'Please, check the iceServers');
        urls = urlAux;
      }
      if (urls.any((element) => element.startsWith('turn:'))) {
        hasTurnServer = true;
        break;
      }
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (!hasTurnServer) {
        Future.delayed(const Duration(seconds: 1), () {
          logger('No TURN server found! To avoid problems like https://stackoverflow.com/a/35862243/4508758 consider adding TURN servers along with STUN on AsklessClient.instance.start(webRTCParams: WebRTCParams(..))', level: Level.warning);
        });
      }

      if (!kIsWeb) {
        SafeDevice.isRealDevice.then((isRealDevice) {
          if (!isRealDevice) {
            logger("Not a real device! Emulator/Simulators doesn't work well when testing video/audio calls, please use a real device instead", level: Level.warning);
          }
        });
      }
    });
  }
}

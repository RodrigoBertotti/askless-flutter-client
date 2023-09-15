# Documentation

Documentation of the Flutter Client for Askless. 

[Click here](README.md#important-links)
to check examples and introduction to Askless or [here](https://github.com/RodrigoBertotti/askless) to access
the server side in Node.js.

## Index
- [Introduction](#introduction)
- [Starting Askless in the Flutter Client](#starting-askless-in-the-flutter-client)
- [Authentication](#authentication)
- [Interacting with the routes](#interacting-with-the-routes)
- [Connection](#connection)
- [Video and Audio Calls](#video-and-audio-calls)

## Introduction

This doc uses the following pattern for getting and passing values:

####  Getting values

What you can obtain is represented by **name** &#8594; **_type_**

#### Setting values

Functions that require params contain 3 dots between parenthesis,
like **functionName (___...___)**

Those params are described under the function name, they are 
represented by **___type___** **param**

## Starting Askless in the Flutter Client

### start(___...___) &#8594; ___void___

Init and start Askless. This method should be called before making any operations using Askless.

#### Example

    void main() {
       AsklessClient.instance.start(
          serverUrl: 'ws://192.168.0.8:3000',
          debugLogs: false,
          onAutoReauthenticationFails: (String credentialErrorCode, void Function() clearAuthentication) {
            // Add your logic to handle when the user credential
            // is no longer valid
            if (credentialErrorCode == "EXPIRED_ACCESS_TOKEN") {
              refreshTheAccessToken();
            } else {
              clearAuthentication();
              goToLoginPage();
            }
          },
          // Only in case you want to use video and/or audio calls:
          getWebRTCParams: (userId) => Future.value(
            WebRTCParams(
               configuration: {
                 'iceServers': [
                   {
                     "urls": [
                       'stun:stun1.l.google.com:19302',
                       'stun:stun2.l.google.com:19302'
                     ],
                   },
                   {
                     // setting up TURN servers are important for Apps behind symmetric nat
                     "urls": "turn:a.relay.metered.ca:80",
                     "username": "turn.username",
                     "credential": "turn.password",
                   },
                   {
                     "urls": "turn:a.relay.metered.ca:80?transport=tcp",
                     "username": "turn.username",
                     "credential": "turn.password",
                   }
                 ]
               }
           )
         )
       );

       runApp(const MyApp());
    }

#### 🔸 ___String___ serverUrl

The server URL, must start with `ws://` or `wss://`. Example: `ws://192.168.0.8:3000`.
You can also access the `myAsklessServer.localUrl` attribute on your server-side in node.js
to discover what the local URL of your server is.

#### 🔸 ___bool?___ debugLogs
Show Askless internal logs for debugging.

#### 🔸 ___void Function(String credentialErrorCode, void Function() clearAuthentication)___ onAutoReauthenticationFails
`onAutoReauthenticationFails` is a callback that is triggered once the automatic re-authentication attempt fails.
This happens when the user loses the internet connection and Askless tries to reconnect, but the previous credential
is no longer valid. This is a good place to handle the logic of refreshing the Access Token or moving
the user to the logout page.

`onAutoReauthenticationFails` **is NOT called** after `AsklessClient.instance.authenticate(..)` is finished.

#### 🔸 ___Future\<WebRTCParams\> Function(userId)___ getWebRTCParams 
For video and audio calls only. (optional)

⚠️ **[Requires configuration, click here to proceed](#video-and-audio-calls)**

A function that returns a future object of type `WebRTCParams` which allows you to 
set `configuration` and `constraints` Map objects from WebRTC,
it's recommended to set your TURN servers in the `configuration` field.

## Authentication

All routes that are added in the backend with `addRouteFor.authenticatedUsers` do require authentication.

### authenticate (___...___) &#8594;  ___Future\<[AuthenticateResponse](#AuthenticateResponse)\>___
Performs an authentication attempt to the server side. Useful for the login page or to authenticate
with tokens automatically in the startup of your App.

**Important:** `authenticate(..)` will be called automatically by using the same `credential` when
the user loses the internet connection and connects again,
but if it fails `onAutoReauthenticationFails(...)` will be triggered

If `AuthenticateResponse.success` is true: the current user will be able to interact
with routes on the server side created with `addRouteFor.authenticatedUsers`

#### 🔹 ___Map<String,dynamic>___ credential

Customized data you will use in the backend side to validate the authentication
request

#### 🔹 ___bool___ neverTimeout
Default: `false` (optional). If `true`: the request attempt will live as long as possible.

If `false`: if the request doesn't receive a response within the time limit, it will be canceled. The field `requestTimeoutInMs` defined on the server side will be the time limit.

#### Example

    final authenticateResponse = await AsklessClient.instance.authenticate(credential: { "accessToken": accessToken });
    if (authenticateResponse.success) {
      log("user has been authenticated successfully");
    } else {
      log("connectWithAccessToken error: ${authenticateResponse.errorCode}");
      if (authenticateResponse.isCredentialError) {
        log("got an error: access token is invalid");
      } else {
        log("got an error with code ${authenticateResponse.errorCode}: ${authenticateResponse.errorDescription}");
      }
    }

### AuthenticateResponse
The result of the authentication attempt, if `success` is 
true: the current user will be able to interact with routes
on the server side created with `addRouteFor.authenticatedUsers`.

#### 🔸 ___dynamic___ userId
The authenticated user ID, or `null`

#### 🔸 ___List\<String\>?___ claims
The claims the authenticated user has, or `null`

#### 🔸 ___bool___ success 
Returns `true` if the authentication is a success

#### 🔸 ___[AsklessAuthenticateError](#AsklessAuthenticateError)___ error
Authenticate error, is never null in cases where `success == false`

### clearAuthentication() &#8594; ___Future<void>___
Clears the authentication, you may want to call this in case the user clicks in a logout button for example.

After calling `clearAuthentication` the user will NOT be able to
interact anymore with routes created with `addRouteFor.authenticatedUsers` on the server side

    AsklessClient.instance.clearAuthentication();

## Interacting with the routes 

### read(___...___) &#8594; ___Future\<[AsklessResponse](#AsklessResponse)\>___
Performs a request attempt for a `read` route added on the server side

Similar to [readStream](#readstream---stream), but doesn't stream changes.

#### 🔹 route
The path of the route.

#### 🔹 params
Additional data (optional), 
here can be added a filter to indicate to the server
which data will be received.

#### 🔹 neverTimeout
Default: `false` (optional). If `true`: the request attempt will live as long as possible.

If `false`: if the request doesn't receive a response within the time limit, it will be canceled. The field `requestTimeoutInMs` defined on the server side will be the time limit.

#### 🔹 persevere
Default: `false` (optional). If `persevere` is `true` and this route was created in the server with `addRouteFor.authenticatedUsers` (requires authentication)
but `clearAuthentication()` is called, then this route **will wait for the authentication to come back.**

In case of `false` the route will be canceled right after `clearAuthentication()` is called (only if this route requires authentication).

This is no-op in case this route doesn't require authentication (`addRoute.forAllUsers`).

#### Example
 
    AsklessClient.instance
        .read(route: 'allProducts',
           params: {
             'nameContains' : 'game'
           },
           neverTimeout: true
        ).then((res) {
          for (final product in List.from(res.output)) {
            print(product['name']);
          }
        });

### readStream(___...___) &#8594; ___Stream___

 Get realtime data using `stream`.

 Similar to [read](#read---futureasklessresponseasklessresponse) and it does stream changes.

 Returns a `Stream`.

 #### 🔸 ___String___ route
 The path of the route.

 #### 🔸 ___Map<String, dynamic>___ params
 Additional data (optional),
 here can be added a filter to indicate to the server
 which data will be received.

 #### 🔸 persevere
 Default: **true** (optional). If `persevere` is `true` and this route was created in the server with `addRouteFor.authenticatedUsers` (requires authentication)
 but `clearAuthentication()` is called, then this route **will wait for the authentication to come back.**

 In case of `false` the route will be canceled right after `clearAuthentication()` is called (only if this route requires authentication).

 This is no-op in case this route doesn't require authentication (`addRoute.forAllUsers`).

 #### 🔸 ___StreamSource___ source (optional)
 
 Default: `StreamSource.remoteOnly`.

 If `StreamSource.remoteOnly` shows only realtime events from the server (recommended).

 If `StreamSource.cacheAndRemote` Uses the last emitted event
 (from another stream with same `route` and `params`) as the first event,
 only in case it's available.


#### Example

    late StreamSubscription myTextMessagesSubscription;
    
    @override
    void initState() {
        super.initState();
        myTextMessagesSubscription = AsklessClient.instance.readStream(
          route: "my-text-messages",
          params: { "contains" : "thanks" },
          source: StreamSource.remoteOnly,
          persevere: true,
        ).listen((event) {
          print(event);
        });
    }
    
    @override
    void dispose() {
        /// remember to cancel() on dispose()
        myTextMessagesSubscription.cancel();
        super.dispose();
    }

### create(___...___) &#8594; ___Future\<[AsklessResponse](#AsklessResponse)\>___

Performs a request attempt for a `create` route added on the server side

#### 🔹 body
The data that will be created.

#### 🔹 route
The path of the route.

#### 🔹 params
Additional data (optional).

#### 🔹 neverTimeout
Default: `false` (optional). If `true`: the request attempt will live as long as possible.

If `false`: if the request doesn't receive a response within the time limit, it will be canceled. The field `requestTimeoutInMs` defined on the server side will be the time limit.

#### 🔹 persevere
Default: `false` (optional). If `persevere` is `true` and this route was created in the server with `addRouteFor.authenticatedUsers` (requires authentication)
but `clearAuthentication()` is called, then this route **will wait for the authentication to come back.**

In case of `false` the route will be canceled right after `clearAuthentication()` is called (only if this route requires authentication).

This is no-op in case this route doesn't require authentication (`addRoute.forAllUsers`).

#### Example

    AsklessClient.instance
      .create(route: 'product',
        body: {
           'name' : 'Video Game',
           'price' : 500,
           'discount' : 0.1
        }
      ).then((res) => print(res.success ? 'Success' : res.error!.code));

### update(___...___) &#8594; ___Future\<[AsklessResponse](#AsklessResponse)\>___
Performs a request attempt for a `update` route added on the server side

#### 🔸 body
The entire data or field(s) that will be updated.

#### 🔸 route
The path of the route.

#### 🔸 params
Additional data (optional).

#### 🔸 neverTimeout
Default: `false` (optional). If `true`: the request attempt will live as long as possible.

If `false`: if the request doesn't receive a response within the time limit, it will be canceled. The field `requestTimeoutInMs` defined on the server side will be the time limit.

#### 🔸 persevere
Default: `false` (optional). If `persevere` is `true` and this route was created in the server with `addRouteFor.authenticatedUsers` (requires authentication)
but `clearAuthentication()` is called, then this route **will wait for the authentication to come back.**

In case of `false` the route will be canceled right after `clearAuthentication()` is called (only if this route requires authentication).

This is no-op in case this route doesn't require authentication (`addRoute.forAllUsers`).

#### Example

    AsklessClient.instance
        .update(
            route: 'allProducts',
            params: {
              'nameContains' : 'game'
            },
            body: {
              'discount' : 0.8
            }
        ).then((res) => print(res.success ? 'Success' : res.error!.code));

### delete(___...___) &#8594; ___Future\<[AsklessResponse](#AsklessResponse)\>___

Performs a request attempt for a `delete` route added on the server side.

#### 🔹 route
The path of the route.

#### 🔹 params
Additional data, indicate here which data will be removed.

#### 🔹 neverTimeout
Default: `false` (optional). If `true`: the request attempt will live as long as possible.
 
If `false`: if the request doesn't receive a response within the time limit, it will be canceled. The field `requestTimeoutInMs` defined on the server side will be the time limit.

#### 🔹 persevere
Default: `false` (optional). If `persevere` is `true` and this route was created in the server with `addRouteFor.authenticatedUsers` (requires authentication)
but `clearAuthentication()` is called, then this route **will wait for the authentication to come back.**

In case of `false` the route will be canceled right after `clearAuthentication()` is called (only if this route requires authentication).

This is no-op in case this route doesn't require authentication (`addRoute.forAllUsers`).

##### Example

    AsklessClient.instance
        .delete(
            route: 'product',
            params: { 'id': 1 },
        ).then((res) => print(res.success ? 'Success' : res.error!.code));


### AsklessResponse

Result of request attempt to the server.

#### 🔸 output  &#8594; ___dynamic___
The output the server sent, or null.

:warning: Do NOT use `output` to check if the operation 
failed (because it can be null even in case of success)

#### 🔸  success &#8594; ___bool___

Indicates whether the request attempt is a success

#### 🔸 error &#8594; [AsklessError?](#AsklessError)
Error details in case where [success](#-success---bool) == `false`

### AsklessError
Error details of a failed request attempt

#### 🔹 code &#8594; ___String___
The error code. Can be either a field of [AsklessErrorCode](#AsklessErrorCode),
or a **custom error code** sent by the server

#### 🔹 description &#8594; ___String___
The error description

### AsklessErrorCode

#### 🔸 INTERNAL_ERROR
An unknown error occurred on the server side

#### 🔸 NO_CONNECTION
The App is disconnected from the internet or/and the server is offline

#### 🔸 CONFLICT
The requested operation is already in progress

#### 🔸 PERMISSION_DENIED
The authenticated user doesn't have permission to modify or/and access the requested resource

#### 🔸 INVALID_CREDENTIAL
`credential` wasn't accepted in the `authenticate` function on the server side.
Example: accessToken is invalid, invalid email, invalid password, etc.

#### 🔸 PENDING_AUTHENTICATION
The request could not proceed because the informed `route` requires authentication by the client.

To fix this, choose to either:
- call `AsklessClient.instance.authenticate(...)` in the client side before performing this request

or

- change the route on the server side from `addRouteFor.authenticatedUsers` to `addRoute.forAllUsers`

#### 🔸 AUTHORIZE_TIMEOUT
The server didn't give a response to the `authentication(..)` function on the server side, to fix this, make sure to
call either `accept.asAuthenticatedUser(..)`, `accept.asUnauthenticatedUser()` or `reject(..)` callbacks in the `authentication(..)` function on the server side.

### AsklessAuthenticateError
Error details of a failed request attempt

#### 🔹 code &#8594; ___String___
The error code. Can be either a field of [AsklessErrorCode](#AsklessErrorCode),
or a **custom error code** sent by the server

#### 🔹 description &#8594; ___String___
The error description

#### 🔹 isCredentialError &#8594; ___bool___
Returns `true` if the error is a credential error,
which means that could not authenticate because of an error like: invalid email,
invalid password, invalid access token, etc.

Returns `false` in case the error is not related to credential,
like no connection error.

## Connection

### connection &#8594; ___[ConnectionDetails](#ConnectionDetails)___
Current connection status to the server with details

### streamConnectionChanges(___...___)
Stream changes of the connection status to the server.

#### 🔸  ___bool___ immediately
Default `true`. If true, emits the first event immediately with
the current connection status, otherwise
it will wait to emit until the connection status changes.

#### Example

    late StreamSubscription<ConnectionDetails> connectionChangesSubscription;
    
    @override
    void initState() {
    super.initState();
        connectionChangesSubscription = AsklessClient.instance
            .streamConnectionChanges(immediately: true)
            .listen((connectionDetails) {
              print("Connection status is ${connectionDetails.status} ${connectionDetails.disconnectionReason == null ? "" : " disconnected because ${connectionDetails.disconnectionReason}"}")
            });
    }    
    
    @override
    void dispose() {
       connectionChangesSubscription.cancel();
       super.dispose();
    }

### addOnConnectionChangeListener(___...___)
Adds a [listener](#-onconnectionchangeonconnectionchange-listener) that will be triggered
every time the status of the connection to
the server changes.

#### 🔹 ___[OnConnectionChange](#OnConnectionChange)___ listener
The listener that will be triggered
every time the status of the connection to
the server changes.

#### 🔹 ___bool___ immediately
Default `true`. If true, emits the first event immediately with
the current connection status, otherwise
it will wait to emit until the connection status changes.

#### Example

    connectionChanged(ConnectionDetails connectionDetails) {
        print("Connection status is ${connectionDetails.status} ${connectionDetails.disconnectionReason == null ? "" : " disconnected because ${connectionDetails.disconnectionReason}"}")
    }
    
    @override
    void initState() {
        super.initState();
        AsklessClient.instance.addOnConnectionChangeListener(connectionChanged, immediately: true);
    }

### removeOnConnectionChangeListener(___...___)
Removes the listener which is triggered
every time the status of the connection to
the server changes.

#### 🔸 ___[OnConnectionChange](#OnConnectionChange)___ listener
The listener previously added

#### Example

    connectionChanged(ConnectionDetails connectionDetails) {
        print("Connection status is ${connectionDetails.status} ${connectionDetails.disconnectionReason == null ? "" : " disconnected because ${connectionDetails.disconnectionReason}"}")
    }

    @override
    void dispose() {
        AsklessClient.instance.removeOnConnectionChangeListener(connectionChanged);
        super.dispose();
    }

### OnConnectionChange

**typedef OnConnectionChange = dynamic Function(ConnectionDetails connectionDetails);**

A function that will be triggered  every time the status of the connection to the server changes.

#### 🔹 connectionDetails &#8594; [ConnectionDetails](#ConnectionDetails)
Connection status to the server with details

### ConnectionDetails
Connection status to the server with details

#### 🔸 ___ConnectionStatus___ status;
The connection status to the server:
`ConnectionStatus.connected`, `ConnectionStatus.inProgress` or `ConnectionStatus.disconnected`

#### 🔸 ___DisconnectionReason?___ disconnectionReason
Disconnection reason only in case where [status](#-connectionstatus-status)
equals `Connection.disconnected`

## Video and Audio Calls
You can skip this section if you don't want to use video and audio calls.

Askless imports the [Flutter-WebRTC](https://github.com/flutter-webrtc/flutter-webrtc) implementation to help you
easily implement your audio and video calls in Flutter with WebRTC and WebSockets.

### :warning: Configuration
**Requires configuration: [Follow the steps of Flutter-WebRTC](https://github.com/flutter-webrtc/flutter-webrtc#ios) 
to configure it on Android and iOS.**

### Testing
Avoid using Android emulator and iOS simulators when testing video and audio calls,
because WebRTC doesn't work well on them.

### Symmetric NAT
By default, everything should work well in most cases, 
but if some users are [behind symmetric NAT](https://stackoverflow.com/a/35862243/4508758) 
the video/audio calls won't work without setting up TURN servers,
so make sure to add TURN servers along with STUN before releasing your App to production.
*You can create your own TURN server and host it yourself, or choose an external service
like [metered.ca](https://www.metered.ca/pricing).*

### :arrow_up: Requesting Calls

#### requestCallToUser(...) &#8594; ___[RequestCallToUserInstance](#RequestCallToUserInstance-object)___
Request a call to a remote user. Returns a [RequestCallToUserInstance](#RequestCallToUserInstance-object).

#### 🔹 ___[MediaStream](https://github.com/flutter-webrtc/webrtc-interface/blob/main/lib/src/media_stream.dart)___ localStream
The [MediaStream](https://github.com/flutter-webrtc/webrtc-interface/blob/main/lib/src/media_stream.dart) for the local user,
so the remote user will be able to receive video and/or audio.  You can get it  with `navigator.mediaDevices.getUserMedia(...)`

#### 🔹 ___dynamic___ userId
Refers to the remote user the local user want talk to.

#### 🔹 ___Map<String,dynamic>___ additionalData
Add custom data here (optional)

#### RequestCallToUserInstance object
The return of requesting a call to a remote user, call `dispose()` once the widget showing the call disposes.

##### 🔸 dispose() &#8594; ___void___
Call `dispose()` once the widget showing the call disposes

##### 🔸 response() &#8594; [RequestCallResult](#RequestCallResult-object)
The response to the call request.

#### RequestCallResult object
The response received from a request call

##### 🔸🔹 liveCall &#8594; [LiveCall?](#-LiveCall-object)
Refers to a running video/audio call. Is null in case of error.
Call `liveCall.dispose()` once the widget showing the call disposes

##### 🔸🔹 callAccepted  &#8594; ___bool___
Indicates whether the call has been accepted or not

##### 🔸🔹 error &#8594; ___String___
Error info, is null in cases where `success` is `true`

##### 🔸🔹 additionalData &#8594; ___Map<String,dynamic>___
Custom data

##### Requesting Call Example

    final localVideoRenderer = RTCVideoRenderer();
    final remoteVideoRenderer = RTCVideoRenderer();
    RequestCallToUserInstance? callInstance;
  
    requestCall() async {
      navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
        },
      }).then((localUserStream) {
        setState(() {
          localVideoRenderer.srcObject = localUserStream;
          callInstance = AsklessClient.instance.requestCallToUser(
            userId: 2,
            localStream: localUserStream,
            additionalData: {
              "videoCall": true // add your custom data here, I'm sending whether is a video call or not
            },
          );
          callInstance!.response().then((response) {
            if (!response.callAccepted) {
              print("Call has not been accepted");
              return;
            }
  
            setState(() {
              remoteVideoRenderer.srcObject = response.liveCall!.remoteStream;
              liveCall!.addOnCallClosesListener(listener: () {
                // to handle when the call has been closed
              });
            });
          });
        });
      }, onError: (error) {
        print("Could not get access to camera and/or microphone ${error.toString()}");
      });
    }
  
    @override
    Widget build(BuildContext context) {
      return Stack(
        children: [
          RTCVideoView(remoteVideoRenderer),
          Positioned(
            bottom: 4,
            right: 0,
            child: SizedBox(
              height: 125,
              width: 75,
              child: RTCVideoView(localVideoRenderer),
            ),
          ),
        ],
      );
    }
  
    @override
    void dispose() {
      callInstance?.dispose();
      liveCall?.dispose();
      super.dispose();
    }

### :arrow_down: Receiving new call requests from remote users 

#### 🔸 addOnReceiveCallListener(___void Function ([ReceivingCall](#ReceivingCall-object) receivingCall)___) &#8594; ___[ReceivingCallsInstance](#ReceivingCallsInstance-object)___
Adds a listener that handles call requests coming from any remote user.
Returns a [ReceivingCall](#ReceivingCall-object) object where you can call
`cancel()` to stop receiving new call requests.

#### ReceivingCallsInstance object

##### 🔸🔹 ___void___ cancel()
Use `cancel()` to stop receiving new call requests from remote users

#### Receiving new call requests from remote users Example

    bool _receivingCallHasBeenConfigured = false;
    final navigatorKey = GlobalKey<NavigatorState>();
    class MyApp extends StatelessWidget {
      const MyApp({super.key});

      @override
      Widget build(BuildContext context) {
          if (!_receivingCallHasBeenConfigured) {
           _receivingCallHasBeenConfigured = true;
           AsklessClient.instance.addOnReceiveCallListener((ReceivingCall receivingCall) {
              print("receiving call");
              Navigator.of(navigatorKey.currentContext!).push(MaterialPageRoute(builder: (context) => AcceptOrRejectCallPage(receivingCall: receivingCall)));
           });
          }
    
          return MaterialApp(
             title: 'Flutter with Mysql',
             navigatorKey: navigatorKey,
             ...
          );
      }
    }

### ReceivingCall object
A call request received from a remote user, the local user should choose between `acceptCall(...)` or `rejectCall(...)`.
Call `dispose()` once the widget showing the call (e.g. call page) disposes before user accepting/rejecting the call.

#### 🔹 addOnCanceledListener(___void Function()___ listener) &#8594; ___void___
Adds a `listener` that will be triggered in case the call request is canceled

#### 🔹 removeOnCanceledListener(___void Function()___ listener) &#8594; ___void___
Removes the `listener` previously added

#### 🔹 acceptCall(...) &#8594; ___Future<[AcceptingCallResult](#AcceptingCallResult-object)>___
Accepts the call request from the remote user.

##### 🔹🔸 ___[MediaStream](https://github.com/flutter-webrtc/webrtc-interface/blob/main/lib/src/media_stream.dart)___ localStream
The [MediaStream](https://github.com/flutter-webrtc/webrtc-interface/blob/main/lib/src/media_stream.dart) for the local user,
so the remote user will be able to receive video and/or audio.  You can get it  with `navigator.mediaDevices.getUserMedia(...)`

##### 🔹🔸 ___Map<String, dynamic>?___ additionalData
Add custom data here (optional)

    receivingCall!.acceptCall(localStream: localUserStream!, additionalData: {})
        .then((AcceptingCallResult result) {
            print("call accepted by me: ${result.liveCall != null}");
            if (result.success){
                handleCallStarted(result.liveCall!);
            } else {
                handleCallFailed(error: result.error, message: "Ops, sorry, an error occurred when accepting the call, please try again later");
            }
        });

#### 🔹 rejectCall() &#8594; ___void___
Rejects the call request from the remote user

    receivingCall!.rejectCall();

### AcceptingCallResult object
The result of accepting the call

#### 🔸 success &#8594; ___bool___
Indicates whether the call started successfully

#### 🔸 error &#8594; ___String?___
Error info, is null in cases where `success` is `true`

#### 🔸 liveCall &#8594; [LiveCall](#-LiveCall-object)?
Refers to a running video/audio call. Is null in case of error.
Call `liveCall.dispose()` once the widget showing the call disposes

### 🔃 LiveCall object
Refers to a running video/audio call

#### 🔹 dispose() &#8594; ___void___
Call `dispose()` once the widget showing the call disposes

#### 🔹 closeCall() &#8594; ___void___
Closes the running call

#### 🔹 remoteStream &#8594; ___[MediaStream](https://github.com/flutter-webrtc/webrtc-interface/blob/main/lib/src/media_stream.dart)?___
[MediaStream](https://github.com/flutter-webrtc/webrtc-interface/blob/main/lib/src/media_stream.dart) for the remote user from the [Flutter-WebRTC](https://github.com/flutter-webrtc/flutter-webrtc) library

#### 🔹 addOnCallClosesListener(___void Function() listener___) &#8594; ___void___
Adds a listener that will be triggered once the call closes

#### 🔹 removeOnCallClosesListener(___void Function() listener___) &#8594; ___void___
Removes the listener previously added

#### 🔹 addOnConnectionChangedForRemoteUserListener(___void Function (bool connected) listener___) &#8594; ___void___
Adds a listener function that will be triggered when the connection of the remote user changes.
You may want to call `closeCall()` if the remote user is disconnected for a long time.

#### 🔹 removeOnConnectionChangedForRemoteUserListener(___listener___) &#8594; ___void___
Removes the listener previously added

# Askless for Flutter

Build Flutter Apps with PostgreSQL, MySQL, or any database, stream data changes through websockets effortlessly, handle websocket authentication like a pro and elevate your Flutter Chat App with video and audio calls!

🌟 If you want to build your Flutter App without Firebase and stream data from a database (like SQL) to the Flutter App,
Askless will save you a lot of time!

This is the Flutter side,
**[click here to access the Backend side in Node.js](https://github.com/RodrigoBertotti/Askless)**

## Built with Askless

Check the example of a Flutter Chat App with PostgreSQL / MySQL databases. Supports video and audio calls.

[//]: # (TODO VIDEO)

## Why Askless?

### :video_camera: Add Video and Audio calls to elevate your Flutter Chat App
Easily implement WebRTC live calls in your App, no third-party services are required *

<sup>* Some users may be [behind symmetric NAT](https://stackoverflow.com/a/35862243/4508758), so to avoid problems in this scenario
add your own or third-party TURN server, please check the [documentation](documentation.md#video-and-audio-calls) for more info </sup>

### :muscle: **Stream data from PostgreSQL, MySQL or other database** to your Flutter App through websockets

The Askless Framework (Backend in Node.js) is designed to make your Flutter App
stream data in without Firebase, create your own routes that interact with your database,
call `route.notifyChanges(..)` when something changes so the users will receive the changes!

### :airplane: Skip websocket details and focus in your application!

Askless Design is a result of thorough analysis to make websockets in Flutter easy and productive.
It can be tricky to build websockets to transport data from a database from scratch for your Flutter App:

<sup>:grey_exclamation:</sup> you need to add logic to handle different kinds of data that will move through the websockets

:grey_exclamation: **Authentication events come first**, so you don't want to your client receive data he doesn't have permission to.

:grey_exclamation: If the websockets disconnect, either because of the user device or because of the server, we need to 
**try to connect back again** as soon as possible

:grey_exclamation: Ops! The user was receiving data by websockets, but he lost connection for a second and connected again, 
now we need to **handle authentication BEFORE sending data again**

:grey_exclamation: We may want to know once the user started streaming data and when the user received data, so we can know
data was received, so an additional event like "message_received" needs to be added and handled in the App and backend, more work to
simply add a double-check icon in your chat app once the message is delivered

:white_check_mark: **You don't need to mull over implementing these details anymore** :grinning: **Askless is here to make your life easier!**


## Important links
*  [Askless Backend in Node.js](https://github.com/RodrigoBertotti/askless) the backend side of this Flutter client
*  [Documentation](documentation.md)
*  [Askless Node.js Server](https://github.com/RodrigoBertotti/Askless)

#### Examples
*  [Flutter Random Numbers Example](example/simple_chat): Random numbers are generated on the server.    <sup>  Level: :red_circle: :white_circle: :white_circle: :white_circle: :white_circle: </sup>
*  [Flutter Simple Chat Example](example/simple_chat): Simple chat between the colors blue and green.    <sup>  Level: :red_circle: :red_circle: :white_circle: :white_circle: :white_circle: </sup>
*  [Flutter Catalog Example](example/catalog): Users adding and removing products from a catalog. <sup>  Level: :red_circle: :red_circle: :red_circle: :white_circle: :white_circle: </sup>
*  [Flutter Chat App with MySQL or PostgreSQL + video and audio calls](example/simple_chat): A Flutter Chat App with MySQL, WebSockets, and Node.js,
   supports live video and audio calls streaming with WebRTC in Flutter. <sup> Level: :red_circle: :red_circle: :red_circle: :red_circle: :red_circle: </sup>

## Getting Started

The "Getting Started" is an example of the Flutter client,
an example is executed locally.
 
**1 -** First create the server, [click here](https://github.com/RodrigoBertotti/askless) and
follow the server instructions in the section "Getting Started"

**2 -** (Optional) To use an unencrypted connection in a **test environment** such as this example
(`ws://` connection instead of `wss://`) [follow these instructions](https://flutter.dev/docs/release/breaking-changes/network-policy-ios-android). **Do not apply this on a production environment.**

**3 -** (Optional) If you want to add video and audio calls for your Flutter App, [follow these instructions to set it up](documentation.md#video-and-audio-calls)

**4 -** Install

pubspec.yaml:

    dependencies:
      flutter:
        sdk: flutter
        
      # Add this line:
      askless: ^3.0.0

**5 -** Import the package

    import 'package:askless/askless.dart';

**6 -** Initialize
informing the server URL with port (default: 3000).
You can also access the `myAsklessServer.localUrl` attribute on your server-side in node.js
to discover what the local URL of your server is.

**7 -** Start Askless with `AsklessClient.instance.start()`
    
Example:

    void main() {
      AsklessClient.instance.start(serverUrl:"ws://192.168.0.8:3000"); // TODO: replace with the URL of your Askless Server
      runApp(MyApp());
    }    

**8 -** Here we go! Now you can start using building your Flutter App with Askless,
check the **[documentation](documentation.md)** and **[examples](#Examples)**!

## Issues

Feel free to open an issue about:

- :grey_question: questions

- :bulb: suggestions

- :page_facing_up: documentation improvements

- :ant: potential bugs

## Thanks
Thank you for using Askless!

Thanks also ALL the developers who developed the libraries that Askless
uses and the authors of these two very good articles! [A Comprehensive Guide to Flutter WebRTC](https://www.100ms.live/blog/flutter-webrtc) and [Flutter-WebRTC: A Complete Guide](https://www.videosdk.live/blog/flutter-webrtc).

## License

[MIT](LICENSE.txt)

## Contacting me

📧 rodrigo@wisetap.com

# Documentation

:checkered_flag: [Português (Portuguese)](portugues_documentacao.md)

Documentation of the Flutter Client. 
[Click here](https://github.com/WiseTap/askless) to access
the server side in Node.js.


 ## Important links
 *  [Getting Started](../README.md): Regarding to the client in Flutter.
 *  [Getting Started (server)](https://github.com/WiseTap/askless): Regarding to the server in Node.js.
 *  [chat (example)](../example/chat): Chat between the colors blue and green.
 *  [catalog (example)](../example/catalog): Users adding and removing products from a catalog.

## `init(...)` - Configuring the client

The client can be initialized with the method `init`.

It's recommended to call `init` in the `main` method of the application.

### Params

#### serverUrl

The URL of the server, must start with `ws://` or `wss://`. Example: `ws://192.168.2.3:3000`.

#### projectName
 Name for this project (optional). 
 If `!= null`: the field `projectName` on server side must have the same name (optional).

#### logger

 Allow customize the behavior of internal logs and enable/disable the default logger (optional).

#####  Params:
  
###### useDefaultLogger
 If `true`: the default logger will be used (optional). 
 Default: true.

###### customLogger

 Allows the implementation of a custom logger (optional).

##### Example

    Askless.instance.init(
        projectName: 'MyApp',
        serverUrl: "ws://192.168.2.1:3000",
        logger: Logger(
            useDefaultLogger: false,
            customLogger: (String message, Level level, {additionalData}) {
                final prefix = "> askless ["+level.toString().toUpperCase().substring(6)+"]: ";
                print(prefix+message);
                if(additionalData!=null)
                  print(additionalData.toString());
           }
        )
    );

## `connect(...)`- Connecting to the server

Try perform a connection with the server.

In the server side, you can implement [grantConnection](https://github.com/WiseTap/askless/blob/master/documentation/english_documentation.md#grantconnection)
to accept or deny connections attempts from the client.

Returns the result of the connection attempt.

### Params

#### `ownClientId`
The ID of the user defined in your application.
This field must NOT be `null` when the user is logging in, 
otherwise must be `null` (optional).

#### `headers`
Allows informing the token of the respective `ownClientId` (and/or additional data)
so that the server can be able to accept or recuse the connection attempt (optional).

### Example

    final connectionResponse = await Askless.instance.connect(
       ownClientId: 1,
       headers: {
           'Authorization': 'Bearer abcd'
       }
    );
    if(connectionResponse.isSuccess){
       print("Connected as me@example.com!");
    }else{
       print("Failed to connect, connecting again as unlogged user...");
       Askless.instance.connect();
    }

### Accepting or rejecting a connection attempt

On the server side, you can implement [grantConnection](https://github.com/WiseTap/askless/blob/master/documentation/english_documentation.md#grantconnection)
to accept or refuse connection attempts from the client.

#### Best practices

*Before reading this subsection, is necessary read the [create](#create) section.*

A simple way of authentication would be the client inform the email 
and password in the `header` field of the `connect` method:

    // Not recommended
    Askless.instance.connect(
        headers: {
          "email" : "me@example.com",
          "password": "123456"
        }
    ); 
 
But in this way the user would have to keep informing the e-mail and
password every time that he wants to access the application.

To avoid this, is **recommended** the creation of a route that allows 
to inform the e-mail and password in the body of a request and receive
the corresponding **ownClientId** and a **token** as response.
In this way, the token can be set in the `headers` field of the `connect` method.

#### Example

	// 'token' is an example of a route to
    // request a token on the server side
    // by informing the e-mail and password
    final loginResponse = await Askless.instance.create(
        route: 'token',
        body: {
          'email' : 'me@example.com',
          'password': '123456'
        }
    );
    if(loginResponse.isSuccess){
      // Save the token locally:
      myLocalRepository.saveToken(
          loginResponse.output['ownClientId'],
          loginResponse.output['Authorization']
      );

      // Reconnect informing the token and ownClientId
      // obtained in the last response
      final connectionResponse = await Askless.instance.connect(
        ownClientId: loginResponse.output['ownClientId'],
        headers: {
          'Authorization' : loginResponse.output['Authorization']
        }
      );
      if(connectionResponse.isSuccess){
        print("Connected as me@example.com!");
      }else{
        print("Failed to connect, connecting again as unlogged user...");
        Askless.instance.connect();
      }
    }

## `init` and `connect`
Where must you call `init` and `connect`? 

`init` must be called **only once**, preferably where the App starts,
therefore, is recommended that the initialization occur on `main.dart`.

`connect` can be called multiple times, 
since the user can do login and logout.

| Where                                                                                           |     `connect`      |       `init`       |
| ----------------------------------------------------------------------------------------------: |:------------------:|:------------------:|
| main.dart                                                                                       | :heavy_check_mark: | :heavy_check_mark: |
| When the user do login                                                                          | :heavy_check_mark: | :x:                |
| After a disconnect (example: user did logout) *                                                 | :heavy_check_mark: | :x:                |
| override `build` of a widget                                                                    | :x:                | :x:                |
| override `init` of a shared widget                                                             | :x:                | :x:                |
| override `init` of a widget that appears **once**, when the App starts                       | :heavy_check_mark: | :heavy_check_mark: |

\* After a logout, it may be necessary for the user to read data from server,
therefore, even after a logout can be done a `connect` with  
`ownClientId` being `null`.

## `reconnect()` - Reconnecting
Reconnects to the server using the same credentials
as the previous informed in `connect`.

Returns the result of the connection attempt.

## `disconnect()` - Disconnecting from the server
Stop the connection with the server and clear the credentials `headers` and `ownClientId`.

## `connection`
Get the status of the connection with the server.

## `disconnectReason`
May indicate the reason of no connection.

## `addOnConnectionChange(...)`

### Params

`listener` Adds a `listener` that will be triggered
every time the status of connection with 
the server changes.

`runListenerNow` Default: true. If `true`: the `listener` is called
right after being added (optional).

## `removeOnConnectionChange(listener)`
Removes the added `listener `.

## `create(...)`

 Creates data in the server.

#### Params

  `body` The data that will be created.

  `route` The path of the route.

  `query` Additional data (optional).

  `neverTimeout` Default: `false` (optional). If `true`: the
  request will be performed as soon as possible,
   without timeout.
  If `false`: the field `requestTimeoutInSeconds` defined in the server side
  will be the timeout.

#### Example
 
    Askless.instance
      .create(route: 'product',
        body: {
           'name' : 'Video Game',
           'price' : 500,
           'discount' : 0.1
        }
      ).then((res) => print(res.isSuccess ? 'Success' : res.error.code));
      

## `read(...)`
 Read data once.

#### Params

 `route` The path of the route.

 `query` Additional data (optional), 
 here can be added a filter to indicate to the server
 which data this client will receive.

 `neverTimeout` Default: `false` (optional). If `true`: the
 request will be performed as soon as possible,
 without timeout.
 If `false`: the field `requestTimeoutInSeconds` defined in the server side
 will be the timeout.

#### Example
 
    Askless.instance
        .read(route: 'allProducts',
            query: {
                'nameContains' : 'game'
            },
            neverTimeout: true
        ).then((res) {
            (res.output as List).forEach((product) {
                print(product['name']);
            });
        });
      

## `listen(...)`

 Get realtime data using `stream`.
 
 Returns a [Listening](#listening).

 Is necessary to call the method `Listening.close`
 to stop receiving data from server.
 Example: @override `dispose` of Scaffold that uses this stream.

### Params

 `route` The path of the route.

 `query` Additional data (optional), 
 here can be added a filter to indicate to the server
 which data this client will receive.

### Example

    Listening listeningForNewGamingProducts;
    
    @override
    void initState() {
      listeningForNewGamingProducts = Askless.instance
          .listen(route: 'allProducts',
            query: {
              'nameContains' : 'game'
            },
          );
      listeningForNewGamingProducts.stream.listen((newRealtimeData) {
        List products = newRealtimeData.output;
        products.forEach((singleProduct) {
          print("New gaming product created: "+singleProduct['name']);
        });
      });
      super.initState();
    }
      
    @override
    void dispose() {
    
      // IMPORTANT
      // don't forget to close the stream
      // to stop receiving data from the server
      listeningForNewGamingProducts.close();
      
      super.dispose();
    }

## `update(...)`
 Updates data in the server.

#### Params

 `body` The entire data or field(s) that will be updated.

 `route` The path route.

 `query` Additional data (optional).

  `neverTimeout` Default: `false` (optional). If `true`: the
  request will be performed as soon as possible,
   without timeout.
  If `false`: the field `requestTimeoutInSeconds` defined in the server side
  will be the timeout.

#### Example

    Askless.instance
        .update(
            route: 'allProducts',
            query: {
              'nameContains' : 'game'
            },
            body: {
              'discount' : 0.8
            }
        ).then((res) => print(res.isSuccess ? 'Success' : res.error.code));

## `readAndBuild(...)`
 Get data once and returns a 
 [FutureBuilder](https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html)

#### Params

 `route` The path route.

 `builder` [Official documentation](https://api.flutter.dev/flutter/widgets/FutureBuilder/builder.html)

 `query` Additional data (optional), 
 here can be added a filter to indicate to the server
 which data this client will receive.

 `initialData` [Official documentation](https://api.flutter.dev/flutter/widgets/StreamBuilder/initialData.html) (optional).

 `key` [Official documentation](https://api.flutter.dev/flutter/foundation/Key-class.html) (optional).

## Example

    //other widgets...
    Askless.instance
        .readAndBuild(
          route: 'product',
          query: {
            'id': 1
          },
          builder: (context,  snapshot) {
            if(!snapshot.hasData)
              return Container();
            return Text(snapshot.data['name']);
          }
        );
    //other widgets...    

## `listenAndBuild(...)`
 Get realtime data through [StreamBuilder](https://api.flutter.dev/flutter/widgets/StreamBuilder-class.html).

 
 Unlike the `listen` method, in `listenAndBuild`
 the stream will be closed automatically
 when this widget `dispose`.

### Params

 `route` The path route.

 `query` Additional data (optional), 
 here can be added a filter to indicate to the server
 which data this client will receive.

 `builder` [Official documentation](https://api.flutter.dev/flutter/widgets/StreamBuilder/builder.html)

 `initialData` [Official documentation](https://api.flutter.dev/flutter/widgets/StreamBuilder/initialData.html) (optional).

 `key` [Official documentation](https://api.flutter.dev/flutter/foundation/Key-class.html) (optional).

#### Example
   
    //other widgets...
    Askless.instance
        .listenAndBuild(
          route: 'allProducts',
          builder: (context,  snapshot) {
              if(!snapshot.hasData)
                return Container();
    
              final listOfProductsNames =
                  (snapshot.data as List)
                  .map((product) => Text(product['name'])).toList();
    
              return Column(
                children: listOfProductsNames,
              );
            }
          );
    //other widgets...
  
## `delete(...)`
 Removes data from server.

### Params

 `route` The path route.

 `query` Additional data, indicate here which data will be removed.

 `neverTimeout` Default: `false` (optional). If `true`: the
 request will be performed as soon as possible,
 without timeout.
 If `false`: the field `requestTimeoutInSeconds` defined in the server side
 will be the timeout.

#### Example

    Askless.instance
        .delete(
            route: 'product',
            query: {
              'id': 1
            },
        ).then((res) => print(res.isSuccess ? 'Success' : res.error.code));

## Classes

## `ResponseCli`
The response of an operation in the server.

### Fields

#### `clientRequestId`
 Request ID generated by the client. 

#### `output`
 Result of operation in the server.

 Do NOT use this field tho check if the operation
 failed (because it can be null even in case of success),
 instead use `isSuccess`.

#### `isSuccess`  
 Returns `true` if the response is a success.

#### `error`  
 Is the response error in case where `isSuccess == false`.
 
## `Listening`
Listening for new data from the server after call the method `listen`.

## Fields

### `stream`
Get realtime data from server.

Is necessary to call the method `Listening.close`
so that the server can stop sending data.
Example: in `dispose` implementation of Scaffold
that uses this stream.

### `close()`
 Stop receiving realtime data from server using `Listening.stream`.



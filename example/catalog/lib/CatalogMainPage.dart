import 'package:flutter/material.dart';
import 'package:askless/askless.dart';
import 'Product.dart';


class CatalogMainPage extends StatefulWidget {
  @override
  _CatalogMainPageState createState() => _CatalogMainPageState();
}

class _CatalogMainPageState extends State<CatalogMainPage> {
  TextEditingController _searchController = new TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  String search;
  final TextEditingController nameController = new TextEditingController();
  final TextEditingController priceController = new TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String selectedToken;
  Connection _connection = Connection.DISCONNECTED;
  OnConnectionChange _onConnectionChange;
  String name;
  int price;



  @override
  void initState() {
    super.initState();

    _onConnectionChange = (connection) {
      setState(() {
        _connection = connection;
      });
    };
    AsklessClient.instance.addOnConnectionChange(_onConnectionChange);

    _searchController.addListener(() {
      print("Searching for: " + _searchController.text);
      refreshProductsBySearch(search: _searchController.text);
    });

//    var run;
//    run = [
//      () {
//        Future.delayed(Duration(seconds: 3), () {
//          setState(() {
//            run[0]();
//          });
//        });
//      }
//    ];
//    run[0]();
  }

  refreshProductsBySearch({@required String search}) {
    setState(() {
      this.search = search;
    });
  }

  removeProduct({@required int id}) async {
    final response = await AsklessClient.instance.delete(route: 'product', query: {'id': id});

    if (response.isSuccess) {
      final Product product = Product.fromMap(response.output);
      this.showSnackBar(success: 'Product ${product.name} removed');
    }else {
      final err = response.error.code + ': ' + response.error.description;
      this.showSnackBar(err: err.length > 100 ? "Occurred an error" : err);
      print(err);
    }
  }

  addProduct({@required Product product}) async {
    final response = await AsklessClient.instance.create(route: 'product', body: product.toMap());

    if (response.isSuccess) {
      final Product product = Product.fromMap(response.output);
      this.showSnackBar(success: 'Product ${product.name} created with id=${product.id}');
    } else
      this.showSnackBar(err: response.error.code + ': ' + response.error.description);
  }

  showSnackBar({String success, String err, Duration duration}) {
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      content: Text(
        success ?? err,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: success != null ? Colors.green : Colors.red,
      duration: duration != null ? duration : Duration(milliseconds: 500),
    ));
  }

  connectAsViewer() {
    selectedToken = null;
    AsklessClient.instance.connect();
  }

  connectAsAdmin(
      {@required ownClientId, @required String token, @required onDisconnect}) {
    this.selectedToken = token;
    AsklessClient.instance.connect(
      ownClientId: ownClientId,
      headers: {'Authorization': token},
    ).then((connection) {
      if(connection.isSuccess) {
        this.showSnackBar(
            success: 'Connected',
            duration: Duration(seconds: 2)
        );
      }else{
        this.showSnackBar(
            err: 'Invalid credentials',
            duration: Duration(seconds: 3)
        );
      }
    });
  }


  @override
  void dispose() {
    AsklessClient.instance.removeOnConnectionChange(_onConnectionChange);
    super.dispose();
  }

  Widget buildListenToProducts({@required String route}) {
    return AsklessClient.instance.listenAndBuild(
      route: route,
      query: {'search': search},
      builder: (context, snapshots) {
        if (snapshots.error != null) {
          return Center(
            child: Text(
              'listenAndBuild error: ' + snapshots.error.toString(),
              style: TextStyle(color: Colors.red),
            ),
          );
        }
        final products = Product.fromMapList(snapshots.data);

        return FutureBuilder<Color>(
            initialData: Colors.black,
            key: new GlobalKey(),
            future: Future.delayed(Duration(milliseconds: 750,)).then((_) => Colors.black45),
            builder: (context, snapshot) {
              if (products.length == 0) {
                return Container(
                  height: 100,
                  child: Center(
                    child: _connection == Connection.DISCONNECTED && AsklessClient.instance.disconnectReason==DisconnectionReason.TOKEN_INVALID ? Text(
                      'Your token is invalid!',
                      style: TextStyle(color: Colors.red),
                    ) : Text(
                      'No registered products',
                      style: TextStyle(color: snapshot.data),
                    ),
                  ),
                );
              }

              return Column(
                children: products
                    .map((product) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      child: Icon(Icons.remove, color: snapshot.data,),
                      onTap: () => removeProduct(id: product.id),
                    ),
                    Container(
                      width: 300,
                      child: Center(
                        child: Text(
                          '\$${product.price} - ${product.name}',
                          style: TextStyle(color: snapshot.data),
                        ),
                      ),
                    )
                  ],
                ))
                    .toList(),
              );
            }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                new TextField(
                  controller: _searchController,
                  decoration: new InputDecoration(
                      prefixIcon: new Icon(Icons.search),
                      hintText: 'Search...'),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  width: 300,
                  child: ElevatedButton(
                    child: Text('Connect as viewer, no token on headers'),
                    onPressed: () {
                      setState(() {
                        this.connectAsViewer();
                      });
                    },
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            getConnectionColor(null, _connection)
                        )
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                _buildConnectAsAdmin(ownClientId: 1, token: 'Bearer abcd'),
                SizedBox(
                  height: 10,
                ),
                _buildConnectAsAdmin(ownClientId: 2, token: 'Bearer efgh'),
                SizedBox(
                  height: 10,
                ),
                _buildConnectAsAdmin(ownClientId: -1, token: 'Bearer wrong', wrongToken: true),




              Padding(
                child: buildListenToProducts(route: 'product/all'),
                padding: EdgeInsets.only(top: 10),
              ),

                Padding(
                  child: Column(
                    children: [
                      buildListenToProducts(route: 'product/all')
                    ],
                  ),
                  padding: EdgeInsets.only(top: 10),
                ),

                Padding(
                  child: buildListenToProducts(route: 'product/all/reversed'),
                  padding: EdgeInsets.only(top: 10),
                ),

                SizedBox(height: 20,),


                SizedBox(
                  height: 20,
                ),
                Center(
                  child: Container(
                    height: 1,
                    width: 300,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Center(
                  child: Text(
                    "New Product",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: Form(
                    key: _formKey,
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          child: TextFormField(
                            decoration: InputDecoration(hintText: 'Name'),
                            controller: nameController,
                            validator: (text) {
                              if (text.length == 0) {
                                return "Insert a name";
                              }
                              return null;
                            },
                            onSaved: (text) {
                              name = text;
                            },
                          ),
                          flex: 2,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Flexible(
                          flex: 1,
                          child: TextFormField(
                            keyboardType: TextInputType.numberWithOptions(
                                signed: false, decimal: false),
                            decoration: InputDecoration(hintText: 'Price'),
                            controller: priceController,
                            validator: (text) {
                              try {
                                int.parse(text);
                              } catch (e) {
                                return "Invalid";
                              }
                              return null;
                            },
                            onSaved: (text) {
                              price = int.parse(text);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        TextButton.icon(
                            icon: Icon(Icons.add),
                            label: Text('ADD'),
                            onPressed: () async {
                              if (_formKey.currentState.validate()) {
                                _formKey.currentState.save();

                                final response = await AsklessClient.instance.create(
                                  route: 'product',
                                  body: new Product(name: name, price: price).toMap(),
                                );
                                if (response.isSuccess) {
                                  this.showSnackBar(
                                      success: '$name created with success');
                                  _formKey.currentState.reset();
                                } else {
                                  this.showSnackBar(
                                      err: 'Failed to create $name (' +
                                          response.error.code +
                                          ': ' +
                                          response.error.description +
                                          ')',
                                      duration: Duration(seconds: 3));
                                }
                              }
                            })
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 100,
                )
              ],
            ),
          ),
        ));
  }

  //SET STATE PARECE SER A CAUSA DE NÃO MOSTRAR NOVOS DADOS NA TELA

  Container _buildList({@required AsyncSnapshot<dynamic> snapshots}) {
    Widget child;
    if (snapshots.error != null) {
      child = Center(
        child: Text(
          'listenAndBuild error: ' + snapshots.error.toString(),
          style: TextStyle(color: Colors.red),
        ),
      );
    } else if (!snapshots.hasData) {
      child = Center(
        child: Text(
          'No registered products',
          style: TextStyle(color: Colors.grey),
        ),
      );
    } else {
      final productsList = Product.fromMapList(snapshots.data);
      child = ListView.builder(
          itemCount: productsList.length,
          itemBuilder: (context, pos) {
            final product = productsList[pos];
            return ListTile(
              title: Text(product.name),
              trailing: GestureDetector(
                child: Icon(Icons.clear),
                onTap: () {
                  removeProduct(id: product.id);
                },
              ),
            );
          });
    }

    return new Container(
      child: child,
      height: 285,
    );
  }

  Widget _buildConnectAsAdmin(
      {@required String token, @required int ownClientId, bool wrongToken = false}) {

    return Container(
        width: 300,
        child: ElevatedButton(
          child: Text(
            (wrongToken ? 'WRONG token -' : 'Connect as admin,') + ' headers { Authorization: ' +
                token.toString() +
                ', ownClientId: ' +
                ownClientId.toString() +
                ' }',
            style: TextStyle(fontSize: 12, color: Colors.black),
          ),
          onPressed: () {
            setState(() {
              this.connectAsAdmin(ownClientId: ownClientId, token: token, onDisconnect: null);
            });
          },
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                  getConnectionColor(token, _connection)
              )
          ),
        )
    );
  }

  Color getConnectionColor(String token, Connection connection) {
    if (this.selectedToken != token)
      return Colors.grey;

    switch (connection) {
      case Connection.DISCONNECTED:
        return AsklessClient.instance.disconnectReason == DisconnectionReason.TOKEN_INVALID ? Colors.red : Colors.orange;
      case Connection.CONNECTION_IN_PROGRESS:
        return Colors.blue;
      case Connection.CONNECTED_WITH_SUCCESS:
        return Colors.green;
      default:
        throw "No color for ${connection.toString()}";
    }
  }
}

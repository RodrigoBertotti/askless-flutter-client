import 'package:flutter/material.dart';
import 'package:askless/index.dart';
import 'product.dart';


class CatalogMainPage extends StatefulWidget {
  @override
  _CatalogMainPageState createState() => _CatalogMainPageState();
}

class _CatalogMainPageState extends State<CatalogMainPage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String search = '';
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? selectedToken;
  ConnectionStatus _connection = ConnectionStatus.disconnected;
  late  OnConnectionChange _onConnectionChange;
  late String name;
  late int price;
  bool _invalidCredentials = false;


  @override
  void initState() {
    super.initState();

    _onConnectionChange = (connection) {
      setState(() {
        _connection = connection.status;
      });
    };
    AsklessClient.instance.addOnConnectionChangeListener(_onConnectionChange);

    _searchController.addListener(() {
      print("Searching for: ${_searchController.text}");
      refreshProductsBySearch(search: _searchController.text);
    });
  }

  refreshProductsBySearch({required String search}) {
    setState(() {
      this.search = search;
    });
  }

  removeProduct({required int id}) async {
    final response = await AsklessClient.instance.delete(route: 'product', params: {'id': id});

    if (response.success) {
      final Product product = Product.fromMap(response.output);
      showSnackBar(success: 'Product ${product.name} removed');
    }else {
      final err = '${response.error!.code}: ${response.error!.description}';
      showSnackBar(err: err.length > 300 ? "Occurred an error" : err, duration: Duration(seconds: 3));
      print(err);
    }
  }

  addProduct({required Product product}) async {
    final response = await AsklessClient.instance.create(route: 'product', body: product.toMap());

    if (response.success) {
      final Product product = Product.fromMap(response.output);
      showSnackBar(success: 'Product ${product.name} created with id=${product.id}');
    } else {
      showSnackBar(err: '${response.error!.code}: ${response.error!.description}');
    }
  }

  showSnackBar({String? success, String? err, Duration? duration}) {
    assert(success!=null || err != null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        success ?? err!,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: success != null ? Colors.green : Colors.red,
      duration: duration ?? const Duration(milliseconds: 500),
    ));
  }

  connectAsViewer() {
    selectedToken = null;
    AsklessClient.instance.clearAuthentication();
    AsklessClient.instance.authenticate(credential: {});
  }

  connectAsAdmin({required String token, required onDisconnect}) {
    selectedToken = token;
    AsklessClient.instance.authenticate(credential: {'Authorization': token}, neverTimeout: true);
  }


  @override
  void dispose() {
    AsklessClient.instance.removeOnConnectionChangeListener(_onConnectionChange);
    _searchController.dispose();
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Widget buildListenToProducts({required bool reversed}) {
    return StreamBuilder(
        stream: AsklessClient.instance.readStream(
          route: 'product-list',
          params: {
            'search': search,
            'reversed': reversed,
          },
        ),
        builder: (context, snapshots) {
          if (snapshots.error != null) {
            return Center(
              child: Text(
                'listenAndBuild error: ${snapshots.error!}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          final products = Product.fromMapList(snapshots.data);

          return FutureBuilder<Color>(
              initialData: Colors.black,
              key: GlobalKey(),
              future: Future.delayed(const Duration(milliseconds: 750,)).then((_) => Colors.black45),
              builder: (context, snapshot) {
                if (products.isEmpty) {
                  return SizedBox(
                    height: 100,
                    child: Center(
                      child: _connection == ConnectionStatus.disconnected && _invalidCredentials
                          ? const Text(
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
                        onTap: () => removeProduct(id: product.id!),
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
        }
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
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search...'
                  ),
                ),
                const SizedBox(height: 10,),
                Container(
                  width: 300,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        connectAsViewer();
                      });
                    },
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            getConnectionColor(null, _connection)
                        )
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(left: 20, right: 20),
                      child: const Text('Connect as unauthenticated, no token on headers', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(height: 10,),
                _buildConnectAsAdmin(token: 'Bearer abcd'),
                const SizedBox(height: 10,),
                _buildConnectAsAdmin(token: 'Bearer efgh'),
                const SizedBox(height: 10,),
                _buildConnectAsAdmin(token: 'Bearer wrong', wrongToken: true),
                const SizedBox(height: 10,),

                Text('remote product-list stream'),
                buildListenToProducts(reversed: false),

                const SizedBox(height: 20,),
                const Text('remote product-list stream (reversed)'),
                buildListenToProducts(reversed: true),

                const SizedBox(height: 10,),

                Center(
                  child: Container(
                    height: 1,
                    width: 300,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20,),
                const Center(
                  child: Text(
                    "New Product",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: Form(
                    key: _formKey,
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          flex: 2,
                          child: TextFormField(
                            decoration: const InputDecoration(hintText: 'Name'),
                            controller: nameController,
                            validator: (text) {
                              if (text?.isNotEmpty != true) {
                                return "Insert a name";
                              }
                              return null;
                            },
                            onSaved: (text) {
                              name = text!;
                            },
                          ),
                        ),
                        const SizedBox(width: 10,),
                        Flexible(
                          flex: 1,
                          child: TextFormField(
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: false, decimal: false),
                            decoration: const InputDecoration(hintText: 'Price'),
                            controller: priceController,
                            validator: (text) {
                              try {
                                int.parse(text!);
                              } catch (e) {
                                return "Invalid";
                              }
                              return null;
                            },
                            onSaved: (text) {
                              price = int.parse(text!);
                            },
                          ),
                        ),
                        const SizedBox(width: 10,),
                        TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('ADD'),
                            onPressed: () async {
                              if (_formKey.currentState?.validate() == true) {
                                _formKey.currentState?.save();

                                final response = await AsklessClient.instance.create(
                                  route: 'product',
                                  body: Product(name: name, price: price).toMap(),
                                );
                                if (response.success) {
                                  showSnackBar(success: '$name created with success');
                                  _formKey.currentState?.reset();
                                } else {
                                  showSnackBar(
                                      err: 'Failed to create product (${response.error!.code}: ${response.error!.description})',
                                      duration: const Duration(seconds: 3)
                                  );
                                }
                              }
                            })
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 100,)
              ],
            ),
          ),
        ));
  }

  Widget _buildConnectAsAdmin({required String token, bool wrongToken = false}) {

    return SizedBox(
        width: 300,
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              connectAsAdmin(token: token, onDisconnect: null);
            });
          },
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                  getConnectionColor(token, _connection)
              )
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 2),
            child: Column(
              children: [
                Text(
                  '${wrongToken ? 'WRONG token, ' : 'Connect as authenticated,'} headers { Authorization: $token }',
                  style: TextStyle(fontSize: wrongToken ? 10 : 12, color: Colors.black),
                ),
                if (wrongToken)
                  Text(
                    'Askless will consider as unauthenticated',
                    style: TextStyle(fontSize: 12, color: Colors.black),
                  )
              ],
            ),
          ),
        )
    );
  }

  Color getConnectionColor(String? token, ConnectionStatus connection) {
    if (selectedToken != token) {
      return Colors.grey;
    }

    switch (connection) {
      case ConnectionStatus.disconnected:
        return Colors.red;
      case ConnectionStatus.inProgress:
        return Colors.blue;
      case ConnectionStatus.connected:
        return Colors.green;
      default:
        throw "No color for ${connection.toString()}";
    }
  }
}

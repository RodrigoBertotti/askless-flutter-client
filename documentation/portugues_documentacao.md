# Documentação

:checkered_flag: [English (Inglês)](english_documentation.md)

Documentação do cliente em Flutter. 
[Clique aqui](https://github.com/WiseTap/askless/blob/master/README_PORTUGUES.md)
para acessar o lado servidor em Node.js

## Material para referência
*  [Começando](../README_PORTUGUES.md): Referente ao cliente em Flutter.
*  [Começando (servidor)](https://github.com/WiseTap/askless/blob/master/documentation/portugues_documentacao.md#create): Referente ao servidor em Node.js.
*  [chat (exemplo)](../example/chat): Troca de mensagens instantâneas entre as cores azul e verde.
*  [catalog (exemplo)](../example/catalog): Simulação de múltiplos usuários alterando e removendo produtos de um catálogo.

## `init(...)` - Configurando o cliente

O cliente pode ser inicializado com o método `init`.

É recomendado chamar `init` no `main` da aplicação.

### Parâmetros

#### serverUrl

A url do servidor, deve ser iniciada com `ws://` ou `wss://`. Exemplo: `ws://192.168.2.1:3000`.

#### projectName
Nome para esse projeto. Se `!= null`: o campo projectName no 
servidor deve conter o mesmo nome (opcional).

#### logger

Permite customizar a exibição de logs internos do Askless 
e habilitar e desabilitar o logger padrão (opcional). 

##### Parâmetros:

###### useDefaultLogger
Se true: será utilizado o log padrão. Padrão: `false`.

###### customLogger
Adicionar um novo logger, customizado.

##### Exemplo

    AsklessClient.instance.init(
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

## `connect(...)`- Se conectando com o servidor

Tenta realizar a conexão com o servidor.

Retorna o resultado da tentativa de conexão.

### Parâmetros

#### `ownClientId`
O ID do usuário definido na sua aplicação. Não deve ser `null` quando o usuário estiver realizando login,
do contrário, deve ser `null` (opcional).

#### `headers`
Permite informar o token do respectivo `ownClientId` (e/ou valores adicionais)
para que o servidor seja capaz de aceitar ou recusar a tentativa de conexão (opcional).

### Exemplo

    final connectionResponse = await AsklessClient.instance.connect(
        ownClientId: 1,
        headers: {
            'Authorization': 'Bearer abcd'
        }
    );
    if(connectionResponse.isSuccess){
        print("Connected as me@example.com!");
    }else{
        print("Failed to connect, connecting again as unlogged user...");
        AsklessClient.instance.connect();
    }

### Aceitando ou recusando uma tentativa de conexão

No lado do servidor, você pode implementar [grantConnection](https://github.com/WiseTap/askless/blob/master/documentation/portugues_documentacao.md#grantconnection)
para aceitar ou recusar tentativas de conexão provenientes do cliente.

#### Boa prática

*Antes de ler essa subseção, é necessário antes ler a seção [create](#create).*

Uma maneira simples de autenticar o usuário seria informando o e-mail
e senha no campo `header` do método `connect`, porém, dessa maneira
que o usuário precisaria ficar informando o e-mail e senha toda vez que 
acessar a aplicação.

    // Não recomendado 
    AsklessClient.instance.connect(
        headers: {
          "email" : "me@example.com",
          "password": "123456"
        }
    ); 
 
 
Para evitar isso é **recomendado** que seja criado uma rota 
que permita informar o e-mail e senha na requisição e
receber como resposta o respectivo **ownClientId** e um **token**.
Desta maneira, este token pode ser informado no campo `headers` de `connect`.

#### Exemplo
    
    // 'token' é um exemplo de uma rota no lado do servidor
    // que permite solicitar um token quando é informado um e-mail e senha
    final loginResponse = await AsklessClient.instance.create(
        route: 'token',
        body: {
          'email' : 'me@example.com',
          'password': '123456'
        }
    );
    if(loginResponse.isSuccess){
      // Salve o token localmente:
      myLocalRepository.saveToken(
          loginResponse.output['ownClientId'],
          loginResponse.output['Authorization']
      );

      // Reconecte informando o `token` e `ownClientId`
      // obtidos na última resposta
      final connectionResponse = await AsklessClient.instance.connect(
        ownClientId: loginResponse.output['ownClientId'],
        headers: {
          'Authorization' : loginResponse.output['Authorization']
        }
      );
      if(connectionResponse.isSuccess){
        print("Connected as me@example.com!");
      }else{
        print("Failed to connect, connecting again as unlogged user...");
        AsklessClient.instance.connect();
      }
    }

## `init` e `connect`
Onde pode ser chamado `init` e `connect`? 

`init` deve ser chamado *apenas uma vez* no início da aplicação.

`connect` 
 pode ser chamado várias vezes, visto que o usuário pode fazer login e logout.

| Local                                                                                                                                               |     `connect`      |       `init`       |
| --------------------------------------------------------------------------------------------------------------------------------------------------: |:------------------:|:------------------:|
| main.dart                                                                                                                                           | :heavy_check_mark: | :heavy_check_mark: |
| Quando o usuário faz login                                                                                                                          | :heavy_check_mark: | :x:                |
| Após um disconnect (exemplo: usuário fez logout) *                                                                                                  | :heavy_check_mark: | :x:                |
| override `build` de um widget                                                                                                                       | :x:                | :x:                |
| override `init` de um widget qualquer compartilhado                                                                                                 | :x:                | :x:                |
| override `init` de um widget que aparece apenas **uma única vez**, quando o App é aberto  (exemplo: em um arquivo `carregando_app.dart`)            | :heavy_check_mark: | :heavy_check_mark: |

\* Após um logout, pode ser necessário que o usuário leia dados do servidor,
por isso, mesmo após logout pode ser feito um `connect` com 
`ownClientId` sendo `null`.

## `reconnect()` - Reconectando
Reconecta com o servidor utilizando as mesmas credenciais da conexão
anteriores informadas em `connect`.

Retorna o resultado da tentativa de reconexão.
 
## `disconnect()` - Desconectando do servidor
Interrompe a conexão com o servidor e limpa as credenciais `headers` e `ownClientId`.

## `connection`
Obtém o status da conexão com o servidor.

## `disconnectReason`
Quando desconectado, indica o motivo da falta de conexão.

## `addOnConnectionChange(...)`

### Parâmetros

`listener` Adiciona um `listener` que será chamado toda vez que o status
da conexão com o servidor mudar.

`runListenerNow` Padrão: true. Se `true`: o `listener` é chamado
logo após ser adicionado (opcional).

## `removeOnConnectionChange(listener)`
Remove o `listener ` adicionado.

## `create(...)`
 Cria um dado no servidor.

#### Parâmetros

  `body` O dado a ser criado.

  `route` O caminho da rota.

  `query` Dados adicionais (opcional).

  `neverTimeout ` Padrão: `false` (opcional). Se `true`: a requisição será realizada quando possível,
 não havendo tempo limite. Se false: o campo `requestTimeoutInSeconds` definido no servidor
 será o tempo limite.

#### Exemplo
 
    AsklessClient.instance
      .create(route: 'product',
        body: {
           'name' : 'Video Game',
           'price' : 500,
           'discount' : 0.1
        }
      ).then((res) => print(res.isSuccess ? 'Success' : res.error!.code));
      

## `read(...)`
 Obtém dados apenas uma vez.

#### Parâmetros

 `route` O caminho da rota.

 `query` Dados adicionais (opcional), aqui pode ser adicionado um filtro para indicar ao
 o servidor quais dados esse cliente irá receber.

 `neverTimeout` Padrão: false (opcional). Se true: a requisição será realizada quando possível,
 não havendo tempo limite. Se false: o campo `requestTimeoutInSeconds` definido no servidor
 será o tempo limite.

#### Exemplo
 
    AsklessClient.instance
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
 Obtém dados em tempo real com `stream`. 

 Retorna um [Listening](#listening).

 É necessário chamar o método `Listening.close` para que o servidor pare de enviar os dados.
 Exemplo: no @override do `dispose` no Scaffold que usa essa stream.

### Parâmetros

 `route` O caminho da rota.

 `query` Dados adicionais (opcional), aqui pode ser adicionado um filtro para indicar ao
 o servidor quais dados esse cliente irá receber.

### Exemplo

    Listening listeningForNewGamingProducts;
    
    @override
    void initState() {
      super.initState();
      listeningForNewGamingProducts = AsklessClient.instance
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
    }
      
    @override
    void dispose() {
    
      // IMPORTANTE
      // Não esqueça de encerrar a stream para
      // parar de receber dados do servidor          
      listeningForNewGamingProducts.close();
      
      super.dispose();
    }

## `update(...)`
 Atualiza um dado no servidor.

#### Parâmetros

 `body` O dado inteiro ou seus respectivos campos que será(ão) atualizado(s).

 `route` O caminho da rota.

 `query` Dados adicionais (opcional).

 `neverTimeout` Padrão: false (opcional). Se true: a requisição será realizada quando possível,
 não havendo tempo limite. Se false: o campo `requestTimeoutInSeconds` definido no servidor
 será o tempo limite.

#### Exemplo

    AsklessClient.instance
        .update(
            route: 'allProducts',
            query: {
              'nameContains' : 'game'
            },
            body: {
              'discount' : 0.8
            }
        ).then((res) => print(res.isSuccess ? 'Success' : res.error!.code));

## `readAndBuild(...)`
 Obtém dados apenas uma vez e retorna um [FutureBuilder](https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html)

#### Parâmetros

 `route` O caminho da rota.

 `builder` [Documentação oficial](https://api.flutter.dev/flutter/widgets/FutureBuilder/builder.html)

 `query` Dados adicionais (opcional), aqui pode ser adicionado um filtro para indicar ao
 o servidor quais dados esse cliente irá receber.

 `initialData` [Documentação oficial](https://api.flutter.dev/flutter/widgets/FutureBuilder/initialData.html) (opcional).

 `key` [Documentação oficial](https://api.flutter.dev/flutter/foundation/Key-class.html) (opcional).

## Exemplo

    //other widgets...
    AsklessClient.instance
        .readAndBuild(
          route: 'product',
          query: {
            'id': 1
          },
          builder: (context,  snapshot) {
            if(!snapshot.hasData)
              return Container();
            return Text(snapshot.data.output['name']);
          }
        );
    //other widgets...

## `listenAndBuild(...)`
 Obtém dados em tempo real através de um [StreamBuilder](https://api.flutter.dev/flutter/widgets/StreamBuilder-class.html).

 Ao contrário do método `listen`, em `listenAndBuild` a stream irá se encerrar automaticamente
 quando este widget `dispose`.

### Parâmetros

 `route` O caminho da rota.

 `query` Dados adicionais (opcional), aqui pode ser adicionado um filtro para indicar ao
 o servidor quais dados esse cliente irá receber (opcional).

 `builder` [Documentação oficial](https://api.flutter.dev/flutter/widgets/StreamBuilder/builder.html)

 `initialData` [Documentação oficial](https://api.flutter.dev/flutter/widgets/StreamBuilder/initialData.html) (opcional).

 `key` [Documentação oficial](https://api.flutter.dev/flutter/foundation/Key-class.html) (opcional).

#### Exemplo

    //other widgets...
    AsklessClient.instance
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
 Remove um dado no servidor.

### Parâmetros

 `route` O caminho da rota.

 `query` Dados adicionais, indique por aqui qual dado será removido.

 `neverTimeout` Padrão: false (opcional). Se true: a requisição será realizada quando possível,
 não havendo tempo limite. Se false: o campo `requestTimeoutInSeconds` definido no servidor
 será o tempo limite.

#### Exemplo

    AsklessClient.instance
        .delete(
            route: 'product',
            query: {
              'id': 1
            },
        ).then((res) => print(res.isSuccess ? 'Success' : res.error!.code));

---

## Classes

## `ResponseCli`
A resposta para uma operação no servidor

### Campos

#### `clientRequestId`
 ID da requisição gerado pelo cliente

#### `output`
 Resultado da operação no servidor.

 Não use esse campo para verificar se houve um erro
 (pois pode ser null mesmo em caso de sucesso),
 em vez disso use `isSuccess `.
  
#### `isSuccess`  
Retorna `true` se a resposta é um sucesso

#### `error`  
 Se `isSuccess == false`: contém o erro da resposta
 
## `Listening`
Observando novos dados a serem recebidos do servidor.
É o retorno do método [listen](#listen).

## Campos
### `stream`
Obtém dados do servidor em tempo real.

É necessário chamar o método `Listening.close` para que o servidor pare de enviar dados. 
Exemplo: na implementação do `dispose` do Scaffold que usa essa stream.

### `close()`
Encerra o envio de dados do servidor com a `Listening.stream`


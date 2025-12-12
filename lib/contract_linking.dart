import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // Ajouter pour rootBundle
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart'; // Note: io.dart pour 2.x

class ContractLinking extends ChangeNotifier {
  final String _rpcUrl = "HTTP://127.0.0.1:7545";
  final String _wsUrl = "ws://localhost:7545/";
  final String _privateKey = "PRIVATE KEY"; // Remplacez!

  late Web3Client _client;
  bool isLoading = true;
  late String _abiCode;
  late EthereumAddress _contractAddress;
  late Credentials _credentials;
  late DeployedContract _contract;
  late ContractFunction _yourName;
  late ContractFunction _setName;
  late String deployedName;

  ContractLinking() {
    initialSetup();
  }

  initialSetup() async {
    _client = Web3Client(_rpcUrl, Client(), socketConnector: () {
      return WebSocketChannel.connect(Uri.parse(_wsUrl)).cast<String>();
    });
    await getAbi();
    await getCredentials();
    await getDeployedContract();
  }

  Future<void> getAbi() async {
    // rootBundle vient de 'package:flutter/services.dart'
    String abiStringFile = await rootBundle.loadString("src/artifacts/HelloWorld.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    _contractAddress = EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);
  }

  Future<void> getCredentials() async {
    // Méthode corrigée pour web3dart 3.x
    _credentials = EthPrivateKey.fromHex(_privateKey);
  }

  Future<void> getDeployedContract() async {
    _contract = DeployedContract(
      ContractAbi.fromJson(_abiCode, "HelloWorld"),
      _contractAddress,
    );
    _yourName = _contract.function("yourName");
    _setName = _contract.function("setName");
    getName();
  }

  getName() async {
    var currentName = await _client.call(
      contract: _contract,
      function: _yourName,
      params: [],
    );
    deployedName = currentName[0];
    isLoading = false;
    notifyListeners();
  }

  setName(String nameToSet) async {
    isLoading = true;
    notifyListeners();
    
    await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: _setName,
        parameters: [nameToSet],
      ),
    );
    
    getName();
  }
}

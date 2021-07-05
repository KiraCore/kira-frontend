import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kira_auth/models/transaction.dart';
import 'package:kira_auth/config.dart';
import 'package:kira_auth/services/export.dart';

class TransactionService {
  Future<Transaction> getTransaction({hash}) async {
    if (hash.length < 64) return null;

    Transaction transaction = Transaction();

    var apiUrl = await loadInterxURL();
    var response = await http.get(apiUrl[0] + "/cosmos/txs/$hash", headers: {'Access-Control-Allow-Origin': apiUrl[1]});
    var body = jsonDecode(response.body);
    if (body['message'] == "Internal error") return null;

    transaction.hash = "0x" + body['hash'];
    transaction.gas = body['gas_used'];
    transaction.status = "success";
    transaction.time = new DateTime.fromMillisecondsSinceEpoch(body[hash]['time'] * 1000);

    for (var events in body['tx_result']['events']) {
      for (var attribute in events['attributes']) {
        String key = attribute['key'];
        String value = attribute['value'];

        key = utf8.decode(base64Decode(key));
        value = utf8.decode(base64Decode(value));

        if (key == "action") transaction.action = value;
        if (key == "sender") transaction.sender = value;
        if (key == "recipient") transaction.recipient = value;
        if (key == "amount") {
          transaction.amount = value.split(new RegExp(r'[^0-9]+')).first;
          transaction.token = value.split(new RegExp(r'[^a-z]+')).last;
        }
        transaction.isNew = false;
      }
    }

    return transaction;
  }

  Future<List<Transaction>> getTransactions({account, max, isWithdrawal, pubKey}) async {
    List<Transaction> transactions = [];
    StatusService service = StatusService();

    await service.getNodeStatus();

    var apiUrl = await loadInterxURL();

    String url = isWithdrawal == true ? "withdraws" : "deposits";
    String bech32Address = account.bech32Address;

    var response = await http.get(apiUrl[0] + "/$url?account=$bech32Address&&type=all&&max=$max",
        headers: {'Access-Control-Allow-Origin': apiUrl[1]});

    Map<String, dynamic> body = jsonDecode(response.body);

    for (final hash in body.keys) {
      Transaction transaction = Transaction();

      transaction.hash = hash;
      transaction.status = "success";
      transaction.time = body[hash] != null && body[hash]['time'] > 0
          ? new DateTime.fromMillisecondsSinceEpoch(body[hash]['time'] * 1000)
          : new DateTime(0);

      var txs = body[hash]['txs'] ?? List.empty();
      if (txs.length == 0) continue;
      transaction.token = txs[0]['denom'];
      transaction.amount = txs[0]['amount'].toString();
      transaction.action = isWithdrawal == true ? 'Withdraw' : 'Deposit';

      if (isWithdrawal == true) {
        transaction.recipient = txs[0]['address'];
      } else {
        transaction.sender = txs[0]['address'];
      }

      transactions.add(transaction);
    }

    print(transactions.length);
    print(transactions);
    return transactions;
  }
}

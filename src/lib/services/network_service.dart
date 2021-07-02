import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/config.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/utils/export.dart';

class NetworkService {
  List<Validator> validators = [];
  int lastOffset = 0;

  List<Block> blocks = [];
  Block block;

  int latestBlockHeight = 0;
  int lastBlockOffset = 0;

  List<BlockTransaction> transactions = [];
  BlockTransaction transaction;

  Future<void> getValidators() async {
    List<Validator> validatorList = [];

    var apiUrl = await loadInterxURL();

    var data = await http.get(apiUrl[0] + "/valopers?offset=$lastOffset&count_total=true", headers: {'Access-Control-Allow-Origin': apiUrl[1]});

    var bodyData = json.decode(data.body);
    if (!bodyData.containsKey('validators')) return;
    var validators = bodyData['validators'];

    for (int i = 0; i < validators.length; i++)
      validatorList.add(Validator.fromJson(validators[i]));

    this.validators.addAll(validatorList);
    lastOffset = this.validators.length;
  }

  Future<Validator> searchValidator(String proposer) async {
    var apiUrl = await loadInterxURL();
    var data = await http.get(apiUrl[0] + "/valopers?proposer=$proposer",
        headers: {'Access-Control-Allow-Origin': apiUrl[1]});

    var bodyData = json.decode(data.body);
    if (!bodyData.containsKey("validators")) return null;
    var validator = bodyData['validators'][0];

    return Validator(
      address: validator['address'],
      valkey: validator['valkey'],
      pubkey: validator['pubkey'],
      moniker: validator['moniker'],
      website: validator['website'] ?? "",
      social: validator['social'] ?? "",
      identity: validator['identity'] ?? "",
      commission: double.parse(validator['commission'] ?? "0"),
      status: validator['status'],
      top: int.parse(validator['top'] ?? "0"),
      rank: int.parse(validator['rank'] ?? "0"),
      streak: int.parse(validator['streak'] ?? "0"),
      mischance: int.parse(validator['mischance'] ?? "0"),
    );
  }

  Future<void> getBlocks(bool loadNew) async {
    List<Block> blockList = [];

    var statusService = StatusService();
    await statusService.getNodeStatus();
    var offset, limit;
    if (loadNew) {
      offset = latestBlockHeight;
      latestBlockHeight = int.parse(statusService.syncInfo.latestBlockHeight);
      limit = latestBlockHeight - offset;
    } else {
      if (lastBlockOffset == 0)
        lastBlockOffset = latestBlockHeight = int.parse(statusService.syncInfo.latestBlockHeight);
      offset = max(lastBlockOffset - PAGE_COUNT, 0);
      limit = lastBlockOffset - offset;
      lastBlockOffset = offset;
    }
    if (limit == 0) return;

    var i = 1;
    while (i < limit) {
      if (!await checkModelExists(ModelType.BLOCK, (offset + i).toString()))
        break;
      var block = Block.fromJson(await getModel(ModelType.BLOCK, (offset + i).toString()));
      block.validator = await searchValidator(block.proposerAddress);
      if (block.validator == null) break;
      blockList.add(block);
      i++;
    }

    if (i < limit) {
      var apiUrl = await loadInterxURL();
      var data = await http.get(apiUrl[0] + '/blocks?minHeight=${offset + i}&maxHeight=${offset + limit}',
          headers: {'Access-Control-Allow-Origin': apiUrl[1]});

      var bodyData = json.decode(data.body);
      if (!bodyData.containsKey("block_metas")) return;
      var blocks = bodyData['block_metas'];

      for (int i = 0; i < blocks.length; i++) {
        Block block = Block.fromJson(blocks[i]);
        block.validator = await searchValidator(block.proposerAddress);
        blockList.add(block);
        storeModels(ModelType.BLOCK, block.height.toString(), block.jsonString);
      }
    }

    this.blocks.addAll(blockList);
    this.blocks.sort((a, b) => b.height.compareTo(a.height));
  }

  Future<void> searchTransaction(String query) async {
    transaction = null;
    var apiUrl = await loadInterxURL();
    var data = await http.get(apiUrl[0] + '/transactions/$query', headers: {'Access-Control-Allow-Origin': apiUrl[1]});
    var bodyData = json.decode(data.body);
    if (bodyData.containsKey("code")) return;
    transaction = BlockTransaction.fromJson(bodyData);
    if (transaction.blockHeight == 0) transaction = null;
  }

  Future<void> searchBlock(String query) async {
    block = null;
    var apiUrl = await loadInterxURL();
    var data = await http.get(apiUrl[0] + '/blocks/$query', headers: {'Access-Control-Allow-Origin': apiUrl[1]});
    var bodyData = json.decode(data.body);
    if (bodyData.containsKey("code"))
      await getTransactions(-1);
    else {
      var txAmount = (bodyData['block']['data']['txs'] as List).length;

      var header = bodyData['block']['header'];
      block = Block(
        blockSize: 1,
        txAmount: txAmount,
        hash: bodyData['block_id']['hash'],
        appHash: header['app_hash'],
        chainId: header['chain_id'],
        consensusHash: header['consensus_hash'],
        dataHash: header['data_hash'],
        evidenceHash: header['evidence_hash'],
        height: int.parse(header['height']),
        lastCommitHash: header['last_commit_hash'],
        lastResultsHash: header['last_results_hash'],
        nextValidatorsHash: header['next_validators_hash'],
        proposerAddress: header['proposer_address'],
        validatorsHash: header['validators_hash'],
        time: DateTime.parse(header['time'] ?? DateTime.now().toString()),
      );
      block.validator = await searchValidator(block.proposerAddress);
      storeModels(ModelType.BLOCK, block.height.toString(), block.jsonString);
      await getTransactions(block.height);
    }
  }

  Future<void> getTransactions(int height) async {
    if (height < 0)
      this.transactions = List.empty();
    else if (await checkModelExists(ModelType.TRANSACTION, height.toString()))
      this.transactions = await getTransactionsForHeight(height);
    else {
      List<BlockTransaction> transactionList = [];

      var apiUrl = await loadInterxURL();
      var data = await http
          .get(apiUrl[0] + '/blocks/$height/transactions', headers: {'Access-Control-Allow-Origin': apiUrl[1]});
      var bodyData = json.decode(data.body);
      var transactions = bodyData['txs'];

      for (int i = 0; i < transactions.length; i++) {
        BlockTransaction transaction = BlockTransaction.fromJson(transactions[i]);
        transactionList.add(transaction);
      }

      this.transactions = transactionList;
      storeModels(ModelType.TRANSACTION, height.toString(),
          jsonEncode(transactionList.map((e) => e.jsonString).toList()));
    }
  }
}

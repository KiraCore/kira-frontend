import 'dart:convert';

import 'package:kira_auth/models/block_transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String TS_PREFIX = 'spc_ts_';

Future setAccountData(String info) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final cachedData = prefs.getString('accounts');

  String accounts = cachedData == null ? "---" : cachedData;
  if (accounts.contains(info) != true) {
    accounts += info;
    accounts += "---";
    prefs.setString('accounts', accounts);
    setCurrentAccount(info);
  }
}

Future setCurrentAccount(String account) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('currentAccount', account);
}

Future<String> getCurrentAccount() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('currentAccount');
}

Future removeCachedAccount() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.remove('accounts');
}

Future setFeeToken(String token) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('feeToken', token);
}

Future<String> getFeeToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('feeToken');
}

Future removeFeeToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.remove('feeToken');
}

Future<bool> setPassword(String password) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await setLastFetchedTime('password');

  bool isExpiredTimeExists = await checkExpireTime();
  int expireTime = await getExpireTime();

  if (isExpiredTimeExists == false || expireTime == 0) {
    setExpireTime(Duration(minutes: 60));
  }

  prefs.setString('password', password);
  return true;
}

Future<bool> removePassword() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.remove('password');
  return true;
}

Future<String> getPassword() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('password');
}

Future<bool> checkPasswordExists() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.containsKey('password');
}

Future setFeeAmount(int feeAmount) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt('feeAmount', feeAmount);
}

Future setExpireTime(Duration maxAge) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt('expireTime', maxAge.inMilliseconds);
}

Future<bool> removeExpireTime() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.remove('expireTime');
  return true;
}

Future<bool> checkExpireTime() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.containsKey('expireTime');
}

Future<int> getExpireTime() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getInt('expireTime');
}

Future<String> getExplorerAddress() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('explorerAddress');
}

Future setExplorerAddress(String explorerAddress) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('explorerAddress', explorerAddress);
}

Future<String> getInterxRPCUrl() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('interxRPC');
}

Future setInterxRPCUrl(String interxRpcUrl) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('interxRPC', interxRpcUrl);
}

Future setTopBarStatus(bool display) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool('topBarStatus', display);
}

Future<bool> getTopBarStatus() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('topBarStatus');
}

Future setLoginStatus(bool isLoggedIn) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool('isLoggedIn', isLoggedIn);
}

Future<bool> getLoginStatus() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}

Future setLastFetchedTime(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int ts = DateTime.now().millisecondsSinceEpoch;
  prefs.setInt(getTimestampKey(key), ts);
}

String getTimestampKey(String forKey) {
  return TS_PREFIX + forKey;
}

Future setTopbarIndex(int index) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt('topBarIndex', index);
}

Future<int> getTopbarIndex() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getInt('topBarIndex') ?? 0;
}

Future setLastSearchedAccount(String account) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('lastSearchedAccount', account);
}

Future<String> getLastSearchedAccount() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('lastSearchedAccount') ?? "";
}

Future setTabIndex(int tabIndex) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt('tabIndex', tabIndex);
}

Future<int> getTabIndex() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getInt('tabIndex') ?? 0;
}

Future<bool> checkPasswordExpired() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  bool passwordExists = await checkPasswordExists();
  if (passwordExists == false) return true;

  // Get last fetched Time
  int ts = prefs.getInt(getTimestampKey('password'));
  if (ts == null) return true;

  int expireTime = prefs.getInt('expireTime');
  int diff = DateTime.now().millisecondsSinceEpoch - ts;

  if (diff > expireTime) {
    removePassword();
    return true;
  }

  return false;
}

enum ModelType { BLOCK, TRANSACTION, PROPOSAL }

// ignore: missing_return
String getKeyFromType(ModelType type) {
  switch (type) {
    case ModelType.BLOCK:
      return 'block';
    case ModelType.TRANSACTION:
      return 'tx_for_block';
    case ModelType.PROPOSAL:
      return 'proposal';
  }
}

Future<bool> checkModelExists(ModelType type, String id) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.containsKey('${getKeyFromType(type)}_$id');
}

Future storeModels(ModelType type, String id, String data) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('${getKeyFromType(type)}_$id', data);
}

Future<Map> getModel(ModelType type, String id) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var dataStr = prefs.getString('${getKeyFromType(type)}_$id');
  try {
    return jsonDecode(dataStr) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

Future<List<BlockTransaction>> getTransactionsForHeight(int height) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var txStrings = prefs.getString('tx_for_block_$height');
  try {
    return (jsonDecode(txStrings) as List<dynamic>)
        .map((e) => BlockTransaction.fromJson(jsonDecode(e.toString()) as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return List.empty();
  }
}

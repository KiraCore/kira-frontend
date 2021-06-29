// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:typed_data';
import 'package:kira_auth/utils/export.dart';
import 'package:kira_auth/widgets/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/blocs/export.dart';
import 'package:kira_auth/models/export.dart';
import 'package:convert/convert.dart';
import 'package:kira_auth/config.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TokenBalanceScreen extends StatefulWidget {
  @override
  _TokenBalanceScreenState createState() => _TokenBalanceScreenState();
}

class _TokenBalanceScreenState extends State<TokenBalanceScreen> {
  List<Validator> validators = [];
  List<Validator> filteredValidators = [];
  String query = "";
  NetworkService networkService = NetworkService();

  TokenService tokenService = TokenService();
  StatusService statusService = StatusService();
  TransactionService transactionService = TransactionService();
  String notification = '';
  String faucetToken;
  List<Token> tokens = [];
  List<String> faucetTokens = [];
  bool isNetworkHealthy = false;
  int sortIndex = 0;
  bool isAscending = false;
  bool isLoggedIn = false;
  TextEditingController searchController;
  Account explorerAccount;
  bool isValidAddress = false;
  bool isTyping = false;

  Account currentAccount;
  bool copied = false;
  String customInterxRPCUrl = "";
  int tabType = 0;

  double kexBalance = 0.0;
  List<String> networkIds = [Strings.customNetwork];
  String networkId = Strings.customNetwork;

  List<Transaction> depositTrx = [];
  List<Transaction> withdrawTrx = [];

  final List _isHovering = [false, false, false];

  String expandedHash;
  String lastTxHash;
  int page = 1;
  StreamController transactionsController = StreamController.broadcast();

  var apiUrl;
  var isSearchFinished = false;

  void getFaucetTokens() async {
    if (isLoggedIn) {
      currentAccount = BlocProvider.of<AccountBloc>(context).state.currentAccount;
    }

    if (currentAccount != null && mounted) {
      await tokenService.getAvailableFaucetTokens();
      await tokenService.getTokens(currentAccount.bech32Address);
      setState(() {
        tokens = tokenService.tokens;
        faucetTokens = tokenService.faucetTokens;
        faucetToken = faucetTokens.length > 0 ? faucetTokens[0] : null;

        for (int i = 0; i < tokens.length; i++) {
          if (tokens[i].ticker.toUpperCase() == "KEX") {
            this.kexBalance = tokens[i].balance;
            return;
          }
        }
      });
    }
  }

  void showSearchedAccount() async {
    String lastSearchedAccount = await getLastSearchedAccount();
    int tabIndex = await getTabIndex();
    if(lastSearchedAccount.isNotEmpty) {
      String rpc = this.apiUrl[0].toString().replaceAll("/api", "");
      rpc = rpc.replaceAll("http://", "");
      Navigator.pushReplacementNamed(context, '/account?addr=$lastSearchedAccount&type=$tabIndex&rpc=$rpc');
    }
  }

  void navigate2AccountScreen() async {
    int tabIndex = await getTabIndex();
    if(this.query.isNotEmpty) {
      String rpc = this.apiUrl[0].toString().replaceAll("/api", "");
      rpc = rpc.replaceAll("http://", "");
      rpc = rpc.replaceAll("https://", "");
      Navigator.pushReplacementNamed(context, '/account?addr=$query&type=$tabIndex&rpc=$rpc');
    }
  }

  void navigate2NetworkScreen() async {
    if(query.isNotEmpty) {
      String rpc = this.apiUrl[0].toString().replaceAll("/api", "");
      rpc = rpc.replaceAll("http://", "");
      Navigator.pushReplacementNamed(context, '/network?info=$query&rpc=$rpc');
    }
  }

  void navigate2BlockScreen() async {
    if(query.isNotEmpty) {
      String rpc = this.apiUrl[0].toString().replaceAll("/api", "");
      rpc = rpc.replaceAll("http://", "");
      Navigator.pushReplacementNamed(context, '/blocks?info=$query&rpc=$rpc');
    }
  }

  void getNodeStatus() async {
    await statusService.getNodeStatus();

    if (mounted) {
      setState(() {
        String testedRpcUrl = statusService.rpcUrl;
        if (statusService.nodeInfo != null && statusService.nodeInfo.network.isNotEmpty) {
          isNetworkHealthy = statusService.isNetworkHealthy;
          if (this.customInterxRPCUrl != "") {
            setState(() {
              if (!networkIds.contains(statusService.nodeInfo.network)) {
                networkIds.add(statusService.nodeInfo.network);
              }
              networkId = statusService.nodeInfo.network;
              isNetworkHealthy = statusService.isNetworkHealthy;
            });
            BlocProvider.of<NetworkBloc>(context).add(SetNetworkInfo(networkId, testedRpcUrl));
            this.customInterxRPCUrl = "";
          } else {
            BlocProvider.of<NetworkBloc>(context)
                .add(SetNetworkInfo(statusService.nodeInfo.network, statusService.rpcUrl));
          }
          checkAddress();
          getFaucetTokens();
        } else {
          isNetworkHealthy = false;
        }
      });
    }
  }

  void getInterxURL() async {
    apiUrl = await loadInterxURL();
  }

  Future<void> checkAddress() async {
    this.isSearchFinished = false;

    var uri = Uri.dataFromString(html.window.location.href); //converts string to a uri
    Map<String, String> params = uri.queryParameters; // query parameters automatically populated

    if(params.containsKey("addr")) {
      this.query = params['addr'];
    }
    if(params.containsKey("type")) {
      String pageType = params['type'];

      setState(() {
        this.tabType = int.parse(pageType);
      });
    }

    String hexAddress = "";

    try {
      var bech32 = Bech32Encoder.decode(this.query);

      Uint8List data = Uint8List.fromList(bech32);
      hexAddress = hex.encode(_convertBits(data, 5, 8));

      currentAccount = new Account(networkInfo: new NetworkInfo(bech32Hrp: "kira", lcdUrl: apiUrl[0] + '/cosmos'), hexAddress: hexAddress, privateKey: "", publicKey: "");

      this.depositTrx =
      await transactionService.getTransactions(account: currentAccount, max: 100, isWithdrawal: false);

      this.withdrawTrx =
      await transactionService.getTransactions(account: currentAccount, max: 100, isWithdrawal: true);

      setState(() {
        if (depositTrx.isEmpty) {
          isValidAddress = false;
        } else {
          isValidAddress = true;
          setLastSearchedAccount(this.query);
          this.isSearchFinished = true;
          return;
        }
      });
    } catch (e) {
      setState(() {
        isValidAddress = false;
      });
    }

    if (!isValidAddress) {
      await getValidators();
      if (filteredValidators.isNotEmpty) {
        this.navigate2NetworkScreen();
        this.isSearchFinished = true;
      } else {
        Block filteredBlock;
        BlockTransaction filteredTransaction;
        List<BlockTransaction> filteredTransactions = [];

        networkService.searchBlock(query).then((v) {
          this.setState(() {
            filteredTransactions.clear();
            filteredTransactions.addAll(networkService.transactions);
            filteredBlock = networkService.block;
            filteredTransaction = null;

            if (filteredTransactions.isNotEmpty || filteredBlock.getReducedHash.isNotEmpty) {
              navigate2BlockScreen();
            }

            this.isSearchFinished = true;
          });
        }).catchError((e) => {
          networkService.searchTransaction(query).then((v) {
            this.setState(() {
              filteredTransactions.clear();
              filteredBlock = null;
              filteredTransaction = networkService.transaction;

              if (filteredTransaction.getReducedHash.isNotEmpty) {
                navigate2BlockScreen();
              }

              this.isSearchFinished = true;
            });
          })
        });

        setState(() {
          this.isSearchFinished = true;
        });
      }
    }
  }

  getValidators() async {
    await networkService.getValidators();
    if (mounted) {
      setState(() {
        var temp = networkService.validators;

        validators.clear();
        validators.addAll(temp);
        filteredValidators.clear();
        filteredValidators.addAll(
            query.isEmpty ? validators : validators.where((x) =>
            x.moniker.toLowerCase().contains(query) ||
                x.address.toLowerCase().contains(query)));

        filteredValidators = validators
            .where((x) =>
        x.moniker.toLowerCase().contains(query.toLowerCase()) ||
            x.address.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  static Uint8List _convertBits(
    List<int> data,
    int from,
    int to, {
    bool pad = true,
  }) {
    var acc = 0;
    var bits = 0;
    final result = <int>[];
    final maxv = (1 << to) - 1;

    for (var v in data) {
      if (v < 0 || (v >> from) != 0) {
        throw Exception();
      }
      acc = (acc << from) | v;
      bits += from;
      while (bits >= to) {
        bits -= to;
        result.add((acc >> bits) & maxv);
      }
    }

    if (pad) {
      if (bits > 0) {
        result.add((acc << (to - bits)) & maxv);
      }
    } else if (bits >= from) {
      throw Exception('illegal zero padding');
    } else if (((acc << (to - bits)) & maxv) != 0) {
      throw Exception('non zero');
    }

    return Uint8List.fromList(result);
  }

  @override
  void initState() {
    super.initState();

    setTopbarIndex(0);
    setTopBarStatus(true);

    var uri = Uri.dataFromString(html.window.location.href); //converts string to a uri
    Map<String, String> params = uri.queryParameters; // query parameters automatically populated

    if(params.containsKey("rpc")) {
      customInterxRPCUrl = params['rpc'];

      setState(() {
        isNetworkHealthy = false;
      });

      setInterxRPCUrl(customInterxRPCUrl);
    } else {
      getLoginStatus().then((loggedIn) {
        isLoggedIn = loggedIn;
        if(isLoggedIn) {
          setState(() {
            checkPasswordExpired().then((success) {
              if (success) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            });
          });
        } else {
          setState(() {
            if(params.containsKey("addr") && params.containsKey("rpc")) {
            } else {
              showSearchedAccount();
            }
          });
        }
      });
    }

    getInterxURL();
    getNodeStatus();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AccountBloc, AccountState>(
        listener: (context, state) {},
        builder: (context, state) {
          return HeaderWrapper(
            isNetworkHealthy: isNetworkHealthy,
            childWidget: Container(
              alignment: Alignment.center,
              margin: EdgeInsets.only(top: 20, bottom: 50),
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    !isLoggedIn ? addSearchInput() : Container(),
                    SizedBox(height: 10),
                    !isTyping && query != "" ? addHeaderTitle() : Container(),
                    isValidAddress ? addAccountAddress() : Container(),
                    isValidAddress ? addAccountBalance() : Container(),
                    isValidAddress ? Wrap(children: tabItems()) : Container(),
                    isValidAddress && tabType == 0 ? Align(alignment: Alignment.center, child: qrCode()) : Container(),
                    (isLoggedIn || isValidAddress) ? addTableHeader() : Container(),
                    isValidAddress && tabType < 2 ? addTransactionsTable() : Container(),
                    (isLoggedIn || (isValidAddress && tabType == 2)) ? (tokens.isEmpty)
                      ? Container(
                        margin: EdgeInsets.only(top: 20, left: 20),
                        child: Text("No tokens",
                          style: TextStyle(
                            color: KiraColors.white, fontSize: 18, fontWeight: FontWeight.bold)))
                    : addTokenTable() : Container(),
                  ],
                ),
              )));
        }));
  }

  Widget qrCode() {
    return Container(
      width: 180,
      height: 180,
      margin: EdgeInsets.symmetric(vertical: 0, horizontal: 30),
      padding: EdgeInsets.all(0),
      decoration: new BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: new Border.all(
          color: KiraColors.kPurpleColor,
          width: 3,
        ),
      ),
      // dropdown below..
      child: QrImage(
        data: currentAccount != null ? currentAccount.bech32Address : '',
        embeddedImage: AssetImage(Strings.logoQRImage),
        embeddedImageStyle: QrEmbeddedImageStyle(
          size: Size(60, 60),
        ),
        version: QrVersions.auto,
        size: 300,
      ),
    );
  }

  Widget addSearchInput() {
    return Container(
      width: 500,
      child: AppTextField(
        hintText: Strings.validatorAccount,
        labelText: Strings.search,
        textInputAction: TextInputAction.search,
        maxLines: 1,
        autocorrect: false,
        keyboardType: TextInputType.text,
        textAlign: TextAlign.left,
        onChanged: (String newText) {
          this.setState(() {
            isTyping = true;
            isValidAddress = false;
          });
        },
        onSubmitted: (String newText) {
          isTyping = false;
          this.query = newText.replaceAll(" ", "");
          navigate2AccountScreen();
        },
        padding: EdgeInsets.only(bottom: 15),
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16.0,
          color: isTyping || isValidAddress ? KiraColors.white : KiraColors.danger,
          fontFamily: 'NunitoSans',
        ),
        topMargin: 10,
      ),
    );
  }

  Widget addHeaderTitle() {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: Text(
        isSearchFinished ? isValidAddress ? "" : Strings.searchFailed : "",
        textAlign: TextAlign.left,
        style: TextStyle(color: KiraColors.white, fontSize: 30, fontWeight: FontWeight.w900),
      ));
  }

  Widget faucetTokenList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: KiraColors.kPurpleColor),
        color: KiraColors.transparent,
        borderRadius: BorderRadius.circular(9)),
      child: DropdownButtonHideUnderline(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.only(top: 10, left: 15, bottom: 0),
              child: Text(Strings.faucetTokens, style: TextStyle(color: KiraColors.kGrayColor, fontSize: 12)),
            ),
            ButtonTheme(
              alignedDropdown: true,
              child: DropdownButton<String>(
                dropdownColor: KiraColors.kPurpleColor,
                value: faucetToken,
                icon: Icon(Icons.arrow_drop_down),
                iconSize: 32,
                underline: SizedBox(),
                onChanged: (String tokenName) {
                  setState(() {
                    faucetToken = tokenName;
                  });
                },
                items: faucetTokens.map<DropdownMenuItem<String>>((String token) {
                  return DropdownMenuItem<String>(
                    value: token,
                    child: Container(
                      height: 25,
                      alignment: Alignment.topCenter,
                      child: Text(Tokens.getTokenFromDenom(token),
                        style: TextStyle(color: KiraColors.white, fontSize: 18))),
                 );
                }).toList()),
          )
        ])));
  }

  Widget faucetTokenLayoutSmall() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        faucetTokenList(),
        SizedBox(height: 30),
        CustomButton(
          key: Key(Strings.faucet),
          text: Strings.faucet,
          height: 60,
          style: 2,
          fontSize: 15,
          onPressed: () async {
            if (this.query.length > 0) {
              String result = await tokenService.faucet(this.query, faucetToken);
              setState(() {
                notification = result;
              });
            }
          },
        )
      ],
    );
  }

  Widget faucetTokenLayoutBig() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: faucetTokenList()),
        SizedBox(width: 30),
        CustomButton(
          key: Key(Strings.faucet),
          text: Strings.faucet,
          width: 220,
          height: 60,
          style: 1,
          fontSize: 15,
          onPressed: () async {
            if (this.query.length > 0) {
              String result = await tokenService.faucet(this.query, faucetToken);
              setState(() {
                notification = result;
              });
            }
          },
        )
      ],
    );
  }

  Widget addFaucetTokens(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(bottom: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveWidget.isSmallScreen(context) ? faucetTokenLayoutSmall() : faucetTokenLayoutBig(),
            if (notification != "") SizedBox(height: 20),
            if (notification != "")
              Container(
                alignment: AlignmentDirectional(0, 0),
                margin: EdgeInsets.only(top: 3),
                child: Text(notification,
                  style: TextStyle(
                    fontSize: 15.0,
                    color: notification != "Success!" ? KiraColors.kYellowColor.withOpacity(0.6) : KiraColors.green3,
                    fontFamily: 'NunitoSans',
                    fontWeight: FontWeight.w600,
                  )),
              ),
          ],
        ));
  }

  Widget addAccountAddress() {
    return Container(
      padding: EdgeInsets.all(5),
      margin: EdgeInsets.only(right: ResponsiveWidget.isSmallScreen(context) ? 40 : 65, bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Address",
              style:
              TextStyle(color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
            InkWell(
              onTap: () {
                copyText(currentAccount.bech32Address);
                showToast(Strings.publicAddressCopied);
              },
              child: // Flexible(
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(currentAccount.getReducedBechAddress,
                    textAlign: TextAlign.end,
                    style: TextStyle(color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(width: 5),
                  Icon(Icons.copy, size: 20, color: KiraColors.white),
                ],
              ))
          ]
        )
    );
  }

  Widget addAccountBalance() {
    return Container(
      padding: EdgeInsets.all(5),
      margin: EdgeInsets.only(right: ResponsiveWidget.isSmallScreen(context) ? 40 : 65, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Balance (KEX)",
            style:
            TextStyle(color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(this.kexBalance.toString(),
            style:
            TextStyle(color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
        ]
      )
    );
  }

  List<Widget> tabItems() {
    List<Widget> items = [];

    for (int i = 0; i < 3; i++) {
      items.add(Container(
        margin: EdgeInsets.only(left: 30, right: 30, top: 30, bottom: 30),
        child: InkWell(
          onHover: (value) {
            setState(() {
              value ? _isHovering[i] = true : _isHovering[i] = false;
            });
          },
          onTap: () {
            this.tabType = i;
            sortIndex = 0;
            isAscending = true;
            lastTxHash = '';
            setTabIndex(this.tabType);
            showSearchedAccount();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                Strings.tabItemTitles[i],
                style: TextStyle(
                  fontSize: 15,
                  color: _isHovering[i] || i == this.tabType ? KiraColors.kYellowColor : KiraColors.kGrayColor,
                  ),
              ),
              SizedBox(height: 5),
              Visibility(
                maintainAnimation: true,
                maintainState: true,
                maintainSize: true,
                visible: _isHovering[i],
                child: Container(
                  alignment: Alignment.centerLeft,
                  height: 3,
                  width: 30,
                  color: KiraColors.kYellowColor,
                ),
              ),
            ]),
        ),
      ));
    }

    return items;
  }

  Widget addTransactionsTable() {
    return Container(
      margin: EdgeInsets.only(bottom: 50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TransactionsTable(
            page: page,
            setPage: (newPage) => this.setState(() {
              page = newPage;
            }),
            isDeposit: tabType == 0,
            transactions: tabType == 0 ? depositTrx : withdrawTrx,
            expandedHash: expandedHash,
            onTapRow: (hash) => this.setState(() {
              expandedHash = hash;
            }),
            controller: transactionsController,
          )
        ],
      ));
  }

  Widget addTableHeader() {
    List<String> titles = (!isLoggedIn && tabType < 2) ? ['Tx Hash', ['Sender', 'Recipient'][tabType], 'Amount', 'Time', 'Status'] : ['Token Name', 'Balance'];
    List<int> flexes = (!isLoggedIn && tabType < 2) ? [2, 2, 1, 1, 1] : [1, 1];

    return Container(
      padding: EdgeInsets.all(5),
      margin: EdgeInsets.only(top: 30, right: 40, bottom: 20),
      child: Row(children:
        titles.asMap().map((index, title) => MapEntry(index, Expanded(
          flex: flexes[index],
          child: InkWell(
            onTap: () => this.setState(() {
              if (sortIndex == index)
                isAscending = !isAscending;
              else {
                sortIndex = index;
                isAscending = true;
              }
              expandedHash = '';
              refreshTableSort();
            }),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: sortIndex != index ? [
                Text(title, style: TextStyle(color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
              ] : [
                Text(title, style: TextStyle(color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(width: 5),
                Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward, color: KiraColors.white),
              ],
          )))),
        ).values.toList(),
      ),
    );
  }

  Widget addTokenTable() {
    return Container(
        margin: EdgeInsets.only(bottom: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TokenTable(
              page: page,
              setPage: (newPage) => this.setState(() {
                page = newPage;
              }),
              tokens: tokens,
              address: this.query,
              expandedName: expandedHash,
              isLoggedIn: isLoggedIn,
              onTapRow: (name) => this.setState(() {
                expandedHash = name;
              }),
            ),
          ],
        ));
  }

  refreshTableSort() {
    if (sortIndex == 0) {
      depositTrx.sort((a, b) => isAscending ? a.hash.compareTo(b.hash) : b.hash.compareTo(a.hash));
      withdrawTrx.sort((a, b) => isAscending ? a.hash.compareTo(b.hash) : b.hash.compareTo(a.hash));
      tokens.sort((a, b) => isAscending ? a.assetName.compareTo(b.assetName) : b.assetName.compareTo(a.assetName));
    } else if (sortIndex == 1) {
      depositTrx.sort((a, b) => isAscending ? a.sender.compareTo(b.sender) : b.sender.compareTo(a.sender));
      withdrawTrx.sort((a, b) => isAscending ? a.recipient.compareTo(b.recipient) : b.sender.compareTo(a.recipient));
      tokens.sort((a, b) => isAscending ? a.balance.compareTo(b.balance) : b.balance.compareTo(a.balance));
    } else if (sortIndex == 2) {
      depositTrx.sort((a, b) => isAscending ? a.amount.compareTo(b.amount) : b.amount.compareTo(a.amount));
      withdrawTrx.sort((a, b) => isAscending ? a.amount.compareTo(b.amount) : b.amount.compareTo(a.amount));
    } else if (sortIndex == 3) {
      depositTrx.sort((a, b) => isAscending ? a.time.compareTo(b.time) : b.time.compareTo(a.time));
      withdrawTrx.sort((a, b) => isAscending ? a.time.compareTo(b.time) : b.time.compareTo(a.time));
    } else {
      depositTrx.sort((a, b) => isAscending ? a.status.compareTo(b.status) : b.status.compareTo(a.status));
      withdrawTrx.sort((a, b) => isAscending ? a.status.compareTo(b.status) : b.status.compareTo(a.status));
    }
    transactionsController.add(null);
  }
}

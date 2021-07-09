import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:kira_auth/utils/export.dart';
import 'package:kira_auth/widgets/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/blocs/export.dart';
import 'package:kira_auth/models/export.dart';

class NetworkScreen extends StatefulWidget {
  @override
  _NetworkScreenState createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  NetworkService networkService = NetworkService();
  StatusService statusService = StatusService();
  List<Validator> validators = [];
  String query = "";
  bool moreLoading = false;

  List<String> favoriteValidators = [];
  int expandedTop = -1;
  int sortIndex = 0;
  bool isAscending = true;
  bool isNetworkHealthy = false;
  int page = 1;
  StreamController validatorController = StreamController.broadcast();

  bool isLoggedIn = false;
  String customInterxRPCUrl = "";
  List<String> networkIds = [Strings.customNetwork];
  String networkId = Strings.customNetwork;
  Timer timer;

  @override
  void initState() {
    super.initState();

    setTopbarIndex(3);

    var uri = Uri.dataFromString(html.window.location.href); //converts string to a uri
    Map<String, String> params = uri.queryParameters; // query parameters automatically populated

    if(params.containsKey("rpc")) {
      customInterxRPCUrl = params['rpc'];
      setState(() {
        isNetworkHealthy = false;
      });
      setInterxRPCUrl(customInterxRPCUrl);
    } else {
      getLoginStatus().then((isLoggedIn) {
        if(isLoggedIn) {
          setState(() {
            checkPasswordExpired().then((success) {
              if (success) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            });
          });
        }
      });
    }

    getNodeStatus();
    getValidators();
    timer = Timer.periodic(Duration(minutes: 2), (timer) {
      getValidators();
    });
  }

  void getValidators() async {
    setState(() {
      moreLoading = true;
    });
    await networkService.getValidators();
    if (mounted) {
      setState(() {
        moreLoading = false;
        if (isLoggedIn)
          favoriteValidators = BlocProvider
              .of<ValidatorBloc>(context)
              .state
              .favoriteValidators;
        var temp = networkService.validators;
        temp.forEach((element) {
          element.isFavorite = isLoggedIn || favoriteValidators.contains(element.address);
        });
        if (sortIndex == 0) {
          temp.sort((a, b) => isAscending ? a.top.compareTo(b.top) : b.top.compareTo(a.top));
        } else if (sortIndex == 2) {
          temp
              .sort((a, b) => isAscending ? a.moniker.compareTo(b.moniker) : b.moniker.compareTo(a.moniker));
        } else if (sortIndex == 3) {
          temp.sort((a, b) => isAscending ? a.status.compareTo(b.status) : b.status.compareTo(a.status));
        } else if (sortIndex == 4) {
          temp.sort((a, b) => !isAscending
              ? a.isFavorite.toString().compareTo(b.isFavorite.toString())
              : b.isFavorite.toString().compareTo(a.isFavorite.toString()));
        }
        validators.clear();
        validators.addAll(temp);

        var uri = Uri.dataFromString(html.window.location.href);
        Map<String, String> params = uri.queryParameters;

        var keyword = query;
        if (params.containsKey("info"))
          keyword = params['info'].toLowerCase();

        validatorController.add(keyword);
      });
    }
  }

  void getNodeStatus() async {
    if (mounted) {
      await statusService.getNodeStatus();

      setState(() {
        String testedRpcUrl = statusService.rpcUrl;

        if (statusService.nodeInfo != null &&
            statusService.nodeInfo.network.isNotEmpty) {
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
                .add(SetNetworkInfo(
                statusService.nodeInfo.network, statusService.rpcUrl));
          }
        } else {
          isNetworkHealthy = false;
        }
      });
    }
  }

  @override
  void dispose() {
    timer.cancel();
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
                      margin: EdgeInsets.only(top: 50, bottom: 50),
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 1200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            addHeader(),
                            addTableHeader(),
                            moreLoading ? addLoadingIndicator() : validators.isEmpty ? Container(
                                margin: EdgeInsets.only(top: 20, left: 20),
                                child: Text("No validators to show",
                                    style: TextStyle(color: KiraColors.white, fontSize: 18, fontWeight: FontWeight.bold)))
                                : addValidatorsTable(),
                          ],
                        ),
                      )));
            }));
  }

  Widget addLoadingIndicator() {
    return Container(
        alignment: Alignment.center,
        child: Container(
          width: 20,
          height: 20,
          margin: EdgeInsets.symmetric(vertical: 0, horizontal: 30),
          padding: EdgeInsets.all(0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ));
  }

  Widget addHeader() {
    return Container(
      margin: EdgeInsets.only(bottom: 40),
      child: ResponsiveWidget.isLargeScreen(context) ? Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          addHeaderTitle(),
          addSearchInput(),
        ],
      ) : Column(
        children: <Widget>[
          addHeaderTitle(),
          addSearchInput(),
        ],
      ),
    );
  }

  Widget addHeaderTitle() {
    return Row(
      children: <Widget>[
        Container(
            margin: EdgeInsets.only(bottom: 50),
            child: Text(
              Strings.validators,
              textAlign: TextAlign.left,
              style: TextStyle(color: KiraColors.white, fontSize: 30, fontWeight: FontWeight.w900),
            )),
        SizedBox(width: 30),
        InkWell(
            onTap: () => Navigator.pushReplacementNamed(context, '/blocks'),
            child: Icon(Icons.swap_horiz, color: KiraColors.white.withOpacity(0.8))),
        SizedBox(width: 10),
        InkWell(
          onTap: () => Navigator.pushReplacementNamed(context, '/blocks'),
          child: Container(
              child: Text(
                Strings.blocks,
                textAlign: TextAlign.left,
                style: TextStyle(color: KiraColors.white, fontSize: 20, fontWeight: FontWeight.w900),
              )),
        ),
      ],
    );
  }

  Widget addSearchInput() {
    return Container(
      width: 500,
      child: AppTextField(
        hintText: Strings.validatorQuery,
        labelText: Strings.search,
        textInputAction: TextInputAction.search,
        maxLines: 1,
        autocorrect: false,
        keyboardType: TextInputType.text,
        textAlign: TextAlign.left,
        onChanged: (String newText) {
          this.setState(() {
            query = newText.toLowerCase();
            expandedTop = -1;
            page = 1;
            validatorController.add(query);
          });
        },
        padding: EdgeInsets.only(bottom: 15),
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16.0,
          color: KiraColors.white,
          fontFamily: 'NunitoSans',
        ),
        topMargin: 10,
      ),
    );
  }

  Widget addTableHeader() {
    return Container(
        padding: EdgeInsets.all(5),
        margin: EdgeInsets.only(right: 40, bottom: 20),
        child: Row(children: [
            Expanded(
            flex: 2,
            child: InkWell(
                onTap: () => this.setState(() {
                  if (sortIndex == 3)
                    isAscending = !isAscending;
                  else {
                    sortIndex = 3;
                    isAscending = true;
                  }
                  expandedTop = -1;
                  refreshTableSort();
                }),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: sortIndex != 3 ? [
                    Text("Status",
                        style: TextStyle(color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    ] : [
                Text("Status",
                style: TextStyle(color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(width: 5),
            Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward, color: KiraColors.white),
            ]))),
    Expanded(
    flex: ResponsiveWidget.isSmallScreen(context) ? 3 : 2,
    child: InkWell(
    onTap: () => this.setState(() {
    if (sortIndex == 0)
    isAscending = !isAscending;
    else {
    sortIndex = 0;
    isAscending = true;
    }
    expandedTop = -1;
    refreshTableSort();
    }),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: sortIndex != 0 ? [
    Text("Top",
    style: TextStyle(color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
    ] : [
    Text("Top",
    style: TextStyle(color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
    SizedBox(width: 5),
    Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward, color: KiraColors.white),
    ]))),
    Expanded(
    flex: 3,
    child: InkWell(
    onTap: () => this.setState(() {
    if (sortIndex == 2)
    isAscending = !isAscending;
    else {
    sortIndex = 2;
    isAscending = true;
    }
    expandedTop = -1;
    refreshTableSort();
    }),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: sortIndex != 2
    ? [
    Text("Moniker",
    style: TextStyle(
    color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
    ]
        : [
    Text("Moniker",
    style: TextStyle(
    color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
    SizedBox(width: 5),
    Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward, color: KiraColors.white),
    ]))),
    Expanded(
    flex: ResponsiveWidget.isSmallScreen(context) ? 4 : 9,
    child: Text("Validator Address",
    textAlign: TextAlign.center,
    style: TextStyle(color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold))),
    !isLoggedIn ? Container() :
    Expanded(
    flex: ResponsiveWidget.isSmallScreen(context) ? 3 : 2,
    child: InkWell(
    onTap: () => this.setState(() {
    if (sortIndex == 4)
    isAscending = !isAscending;
    else {
    sortIndex = 4;
    isAscending = true;
    }
    expandedTop = -1;
    refreshTableSort();
    }),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: sortIndex != 4
    ? [
    Text("Favorite",
    style: TextStyle(
    color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
    ]
        : [
    Text("Favorite",
    style: TextStyle(
    color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
    SizedBox(width: 5),
    Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward, color: KiraColors.white),
    ]))),
    ],
    ),
    );
  }

  Widget addValidatorsTable() {
    return Container(
        margin: EdgeInsets.only(bottom: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValidatorsTable(
              isLoggedIn: isLoggedIn,
              page: page,
              setPage: (newPage) => this.setState(() {
                page = newPage;
              }),
              validators: validators,
              expandedTop: expandedTop,
              onChangeLikes: (top) {
                var index = validators.indexWhere((element) => element.top == top);
                if (index >= 0) {
                  var currentAccount = BlocProvider.of<AccountBloc>(context).state.currentAccount;

                  BlocProvider.of<ValidatorBloc>(context)
                      .add(ToggleFavoriteAddress(validators[index].address, currentAccount.hexAddress));
                  this.setState(() {
                    validators[index].isFavorite = !validators[index].isFavorite;
                  });
                }
              },
              controller: validatorController,
              onTapRow: (top) => this.setState(() {
                expandedTop = top;
              }),
            ),
          ],
        ));
  }

  void refreshTableSort() {
    if (sortIndex == 0) {
      validators.sort((a, b) => isAscending ? a.top.compareTo(b.top) : b.top.compareTo(a.top));
    } else if (sortIndex == 2) {
      validators
          .sort((a, b) => isAscending ? a.moniker.compareTo(b.moniker) : b.moniker.compareTo(a.moniker));
    } else if (sortIndex == 3) {
      validators.sort((a, b) => isAscending ? a.status.compareTo(b.status) : b.status.compareTo(a.status));
    } else if (sortIndex == 4) {
      validators.sort((a, b) => !isAscending
          ? a.isFavorite.toString().compareTo(b.isFavorite.toString())
          : b.isFavorite.toString().compareTo(a.isFavorite.toString()));
    }
    validatorController.add(query);
  }
}

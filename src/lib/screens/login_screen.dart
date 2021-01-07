import 'package:flutter/material.dart';

import 'package:kira_auth/utils/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/widgets/export.dart';
import 'package:kira_auth/utils/responsive.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  StatusService statusService = StatusService();
  List<String> networkIds = [];
  String networkId;
  String passwordError;
  bool loading;

  FocusNode passwordFocusNode;
  TextEditingController passwordController;

  @override
  void initState() {
    // removeCachedAccount();
    super.initState();

    loading = true;

    this.passwordFocusNode = FocusNode();
    this.passwordController = TextEditingController();

    getNodeStatus();
  }

  void getNodeStatus() async {
    await statusService.getNodeStatus();

    if (mounted) {
      setState(() {
        loading = false;
        networkIds.add(statusService.nodeInfo.network);
        networkId = statusService.nodeInfo.network;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: HeaderWrapper(
            childWidget: Container(
                alignment: Alignment.center,
                margin: EdgeInsets.only(top: 50, bottom: 50),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      addHeaderTitle(),
                      addNetworks(context),
                      addPassword(),
                      ResponsiveWidget.isSmallScreen(context) ? addLoginButtonsSmall() : addLoginButtonsBig(),
                      addCreateNewAccount(),
                    ],
                  ),
                ))));
  }

  Widget addHeaderTitle() {
    return Container(
        margin: EdgeInsets.only(bottom: 40),
        child: Text(
          Strings.login,
          textAlign: TextAlign.left,
          style: TextStyle(color: KiraColors.white, fontSize: 30, fontWeight: FontWeight.w900),
        ));
  }

  Widget addNetworks(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      child: Container(
          decoration: BoxDecoration(
              border: Border.all(width: 2, color: KiraColors.kPurpleColor),
              color: KiraColors.transparent,
              borderRadius: BorderRadius.circular(9)),
          // dropdown below..
          child: DropdownButtonHideUnderline(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.only(top: 10, left: 15, bottom: 0),
                  child: Text(Strings.networkId, style: TextStyle(color: KiraColors.kGrayColor, fontSize: 12)),
                ),
                ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButton<String>(
                      value: networkId,
                      icon: Icon(Icons.arrow_drop_down),
                      iconSize: 32,
                      underline: SizedBox(),
                      onChanged: (String netId) {
                        setState(() {
                          networkId = netId;
                        });
                      },
                      items: networkIds.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Container(
                              height: 25,
                              alignment: Alignment.topCenter,
                              child: Text(value, style: TextStyle(color: KiraColors.white, fontSize: 18))),
                        );
                      }).toList()),
                ),
              ],
            ),
          )),
    );
  }

  Widget addPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          hintText: Strings.password,
          labelText: Strings.password,
          focusNode: passwordFocusNode,
          controller: passwordController,
          textInputAction: TextInputAction.done,
          maxLines: 1,
          autocorrect: false,
          keyboardType: TextInputType.text,
          obscureText: true,
          textAlign: TextAlign.left,
          onChanged: (String password) {
            if (password != "") {
              setState(() {
                passwordError = null;
              });
            }
          },
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 23.0,
            color: KiraColors.white,
            fontFamily: 'NunitoSans',
          ),
        ),
        SizedBox(height: 15),
        Container(
          alignment: AlignmentDirectional(0, 0),
          margin: EdgeInsets.only(top: 3),
          child: Text(this.passwordError == null ? "" : passwordError,
              style: TextStyle(
                fontSize: 13.0,
                color: KiraColors.kYellowColor,
                fontFamily: 'NunitoSans',
                fontWeight: FontWeight.w600,
              )),
        ),
        SizedBox(height: 30),
      ],
    );
  }

  Widget addDescription() {
    return Container(
        margin: EdgeInsets.only(bottom: 30),
        child: Row(children: <Widget>[
          Expanded(
              child: Text(
            Strings.networkDescription,
            textAlign: TextAlign.center,
            style: TextStyle(color: KiraColors.green2, fontSize: 18),
          ))
        ]));
  }

  Widget addLoginButtonsBig() {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CustomButton(
              key: Key('login_with_keyfile'),
              text: Strings.loginWithKeyFile,
              width: 220,
              height: 60,
              style: 1,
              onPressed: () {
                if (passwordController.text != "") {
                  Navigator.pushReplacementNamed(context, '/login-keyfile',
                      arguments: {'password': '${passwordController.text}'});
                } else {
                  this.setState(() {
                    passwordError = Strings.passwordBlank;
                  });
                }
              },
            ),
            CustomButton(
              key: Key('login_with_mnemonic'),
              text: Strings.loginWithMnemonic,
              width: 220,
              height: 60,
              style: 2,
              onPressed: () {
                if (passwordController.text != "") {
                  Navigator.pushReplacementNamed(context, '/login-mnemonic',
                      arguments: {'password': '${passwordController.text}'});
                } else {
                  this.setState(() {
                    passwordError = Strings.passwordBlank;
                  });
                }
              },
            )
          ]),
    );
  }

  Widget addLoginButtonsSmall() {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CustomButton(
              key: Key('login_with_keyfile'),
              text: Strings.loginWithKeyFile,
              height: 60,
              style: 1,
              onPressed: () {
                if (passwordController.text != "") {
                  Navigator.pushReplacementNamed(context, '/login-keyfile',
                      arguments: {'password': '${passwordController.text}'});
                } else {
                  this.setState(() {
                    passwordError = Strings.passwordBlank;
                  });
                }
              },
            ),
            SizedBox(height: 30),
            CustomButton(
              key: Key('login_with_mnemonic'),
              text: Strings.loginWithMnemonic,
              height: 60,
              style: 2,
              onPressed: () {
                if (passwordController.text != "") {
                  Navigator.pushReplacementNamed(context, '/login-mnemonic',
                      arguments: {'password': '${passwordController.text}'});
                } else {
                  this.setState(() {
                    passwordError = Strings.passwordBlank;
                  });
                }
              },
            )
          ]),
    );
  }

  Widget addCreateNewAccount() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      Ink(
        child: Text(
          "or",
          textAlign: TextAlign.center,
          style: TextStyle(color: KiraColors.kGrayColor, fontSize: 16),
        ),
      ),
      SizedBox(height: 20),
      CustomButton(
        key: Key('create_account'),
        text: Strings.createNewAccount,
        fontSize: 18,
        height: 60,
        onPressed: () {
          Navigator.pushReplacementNamed(context, '/create-account');
        },
      )
    ]);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kira_auth/utils/colors.dart';
import 'package:kira_auth/models/token_model.dart';

import 'package:kira_auth/utils/cache.dart';
import 'package:kira_auth/utils/strings.dart';
import 'package:kira_auth/utils/responsive.dart';
import 'package:kira_auth/bloc/account_bloc.dart';
import 'package:kira_auth/services/token_service.dart';
import 'package:kira_auth/widgets/app_text_field.dart';
import 'package:kira_auth/widgets/header_wrapper.dart';
import 'package:kira_auth/widgets/custom_button.dart';
import 'package:kira_auth/widgets/custom_slider_thumb_circle.dart';
import 'package:kira_auth/widgets/withdrawal_transactions_table.dart';

class WithdrawalScreen extends StatefulWidget {
  @override
  _WithdrawalScreenState createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  TokenService tokenService = TokenService();
  List<TokenModel> tokens;
  String tokenName;
  String tokenUnit;
  double amountInterval;
  double withdrawalAmount;
  double transactionFee;
  String amountError;
  String addressError;

  FocusNode amountFocusNode;
  TextEditingController amountController;

  FocusNode addressFocusNode;
  TextEditingController addressController;

  @override
  void initState() {
    tokenService.getDummyTokens();
    tokens = tokenService.tokens;

    transactionFee = 0.05;
    tokenName = tokens[0].assetName;
    tokenUnit = tokens[0].ticker;
    withdrawalAmount = 0;
    amountInterval = tokens[0].balance / 100;

    amountError = '';
    addressError = '';
    amountFocusNode = FocusNode();
    amountController = TextEditingController();
    amountController.text = withdrawalAmount.toString();

    addressFocusNode = FocusNode();
    addressController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    checkPasswordExpired().then((success) {
      if (success) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });

    return Scaffold(
        body: BlocConsumer<AccountBloc, AccountState>(
            listener: (context, state) {},
            builder: (context, state) {
              return HeaderWrapper(
                  childWidget: Padding(
                padding: const EdgeInsets.all(0.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    addHeaderText(),
                    addToken(context),
                    addWithdrawalAmount(),
                    addTransactionInformation(),
                    addWithdrawalAddress(),
                    addGravatar(context),
                    addWithdrawButton(),
                    addWithdrawalTransactionsTable(context),
                  ],
                ),
              ));
            }));
  }

  Widget addHeaderText() {
    return Container(
        margin: EdgeInsets.only(bottom: 50),
        child: Text(
          "Withdrawal",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: KiraColors.black,
              fontSize: 40,
              fontWeight: FontWeight.w900),
        ));
  }

  Widget addToken(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Token",
                style: TextStyle(color: KiraColors.kPurpleColor, fontSize: 20)),
            Container(
                width: MediaQuery.of(context).size.width *
                    (ResponsiveWidget.isSmallScreen(context) ? 0.62 : 0.32),
                margin: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                padding: EdgeInsets.all(0),
                decoration: BoxDecoration(
                    border:
                        Border.all(width: 2, color: KiraColors.kPrimaryColor),
                    color: KiraColors.kPrimaryLightColor,
                    borderRadius: BorderRadius.circular(25)),
                // dropdown below..
                child: DropdownButtonHideUnderline(
                  child: ButtonTheme(
                    alignedDropdown: true,
                    child: DropdownButton<String>(
                        value: tokenName,
                        icon: Icon(Icons.arrow_drop_down),
                        iconSize: 32,
                        underline: SizedBox(),
                        onChanged: (String assetName) {
                          setState(() {
                            tokenName = assetName;
                            TokenModel selectedToken = tokens.singleWhere(
                                (token) => token.assetName == assetName);

                            amountInterval = selectedToken.balance / 100;
                            tokenUnit = selectedToken.ticker;
                            withdrawalAmount = 0;
                            amountController.text = withdrawalAmount.toString();
                          });
                        },
                        items: tokens
                            .map<DropdownMenuItem<String>>((TokenModel token) {
                          return DropdownMenuItem<String>(
                            value: token.assetName,
                            child: Text(token.assetName,
                                style: TextStyle(
                                    color: KiraColors.kPurpleColor,
                                    fontSize: 18)),
                          );
                        }).toList()),
                  ),
                )),
          ],
        ));
  }

  Widget addWithdrawalAmount() {
    int sliderHeight = 40;

    return Container(
        margin: EdgeInsets.only(bottom: 0, left: 30, right: 30),
        child: Column(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(Strings.withdrawalAmount,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: KiraColors.kPurpleColor, fontSize: 20)),
                Container(
                  width: MediaQuery.of(context).size.width *
                      (ResponsiveWidget.isSmallScreen(context) ? 0.62 : 0.32),
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                  decoration: BoxDecoration(
                      border:
                          Border.all(width: 2, color: KiraColors.kPrimaryColor),
                      color: KiraColors.kPrimaryLightColor,
                      borderRadius: BorderRadius.circular(25)),
                  child: AppTextField(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    focusNode: amountFocusNode,
                    controller: amountController,
                    textInputAction: TextInputAction.next,
                    hintText: 'Minimum Withdrawal 0.05 ' + tokenUnit,
                    maxLines: 1,
                    autocorrect: false,
                    keyboardType: TextInputType.text,
                    textAlign: TextAlign.left,
                    showMax: true,
                    onHalfClicked: () {
                      setState(() {
                        amountError = "";
                        withdrawalAmount = amountInterval * 50;
                        amountController.text =
                            (amountInterval * 50).toStringAsFixed(6);
                      });
                    },
                    onMaxClicked: () {
                      setState(() {
                        amountError = "";
                        withdrawalAmount = amountInterval * 100;
                        amountController.text =
                            (amountInterval * 100).toStringAsFixed(6);
                      });
                    },
                    onChanged: (String text) {
                      if (text == '' ||
                          double.parse(text, (e) => null) == null) {
                        setState(() {
                          amountError = "Withdrawal amount is invalid";
                          withdrawalAmount = 0;
                        });
                        return;
                      }

                      double percent =
                          double.parse(amountController.text) / amountInterval;

                      if (double.parse(amountController.text) < 0.25 ||
                          percent > 100) {
                        setState(() {
                          amountError = percent > 100
                              ? "Withdrawal amount is out of range"
                              : "Amount to withdraw must be at least 0.05000000 " +
                                  tokenUnit;
                          withdrawalAmount = 0;
                        });
                        return;
                      }

                      setState(() {
                        amountError = "";
                        withdrawalAmount = double.parse(amountController.text);
                      });
                    },
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20.0,
                        color: KiraColors.kBrownColor,
                        fontFamily: 'NunitoSans'),
                  ),
                ),
                Text(
                  'Available Balance ' +
                      (amountInterval * 100).toStringAsFixed(6) +
                      " " +
                      tokenUnit,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: sliderHeight * .3,
                    fontWeight: FontWeight.w700,
                    color: KiraColors.black,
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width *
                      (ResponsiveWidget.isSmallScreen(context) ? 0.62 : 0.32),
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                  alignment: AlignmentDirectional.center,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 2, 0, 2),
                    child: Row(
                      children: <Widget>[
                        Text(
                          'min',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: sliderHeight * .5,
                            fontWeight: FontWeight.w700,
                            color: KiraColors.kPrimaryColor,
                          ),
                        ),
                        SizedBox(
                          width: sliderHeight * .1,
                        ),
                        Expanded(
                          child: Center(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor:
                                    KiraColors.kPurpleColor.withOpacity(.7),
                                inactiveTrackColor: KiraColors
                                    .kPrimaryLightColor
                                    .withOpacity(.5),
                                trackHeight: 5.0,
                                thumbShape: CustomSliderThumbCircle(
                                  thumbRadius: sliderHeight * .4,
                                  min: 0,
                                  max: 100,
                                ),
                                overlayColor:
                                    KiraColors.kPrimaryColor.withOpacity(.4),
                                valueIndicatorShape:
                                    PaddleSliderValueIndicatorShape(),
                                valueIndicatorColor: Colors.black,
                                tickMarkShape:
                                    RoundSliderTickMarkShape(tickMarkRadius: 5),
                                activeTickMarkColor:
                                    KiraColors.kLightPurpleColor,
                                inactiveTickMarkColor: KiraColors
                                    .kPrimaryLightColor
                                    .withOpacity(.7),
                              ),
                              child: Slider(
                                  value: withdrawalAmount / amountInterval,
                                  min: 0,
                                  max: 100,
                                  // divisions: 4,
                                  onChanged: (value) {
                                    setState(() {
                                      withdrawalAmount = value * amountInterval;
                                      amountController.text =
                                          withdrawalAmount.toStringAsFixed(6);
                                      amountError = "";
                                    });
                                  }),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: sliderHeight * .1,
                        ),
                        Text(
                          'max',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: sliderHeight * .5,
                            fontWeight: FontWeight.w700,
                            color: KiraColors.kPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ));
  }

  Widget addTransactionInformation() {
    int sliderHeight = 40;

    return Container(
        margin: EdgeInsets.only(bottom: 30),
        child: Container(
          width: MediaQuery.of(context).size.width *
              (ResponsiveWidget.isSmallScreen(context) ? 0.62 : 0.32),
          child: (Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                  "Transaction Fee: " +
                      transactionFee.toString() +
                      " " +
                      tokenUnit,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: sliderHeight * .4,
                      fontWeight: FontWeight.w700,
                      color: KiraColors.black)),
              SizedBox(height: 10),
              Text(
                withdrawalAmount > transactionFee
                    ? 'You Will Get: ' +
                        (withdrawalAmount - transactionFee).toStringAsFixed(6) +
                        " " +
                        tokenUnit
                    : 'You Will Get: 0.000000 ' + tokenUnit,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: sliderHeight * .4,
                  fontWeight: FontWeight.w700,
                  color: KiraColors.black,
                ),
              ),
            ],
          )),
        ));
  }

  Widget addWithdrawalAddress() {
    return Container(
        margin: EdgeInsets.only(bottom: 10, left: 30, right: 30),
        child: Column(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(Strings.withdrawal,
                    style: TextStyle(
                        color: KiraColors.kPurpleColor, fontSize: 20)),
                Container(
                  width: MediaQuery.of(context).size.width *
                      (ResponsiveWidget.isSmallScreen(context) ? 0.62 : 0.32),
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                  decoration: BoxDecoration(
                      border:
                          Border.all(width: 2, color: KiraColors.kPrimaryColor),
                      color: KiraColors.kPrimaryLightColor,
                      borderRadius: BorderRadius.circular(25)),
                  child: AppTextField(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    focusNode: addressFocusNode,
                    controller: addressController,
                    textInputAction: TextInputAction.next,
                    maxLines: 1,
                    autocorrect: false,
                    keyboardType: TextInputType.text,
                    textAlign: TextAlign.left,
                    onChanged: (String text) {
                      if (text == '') {
                        setState(() {
                          addressError = "";
                        });
                      }
                    },
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20.0,
                        color: KiraColors.kBrownColor,
                        fontFamily: 'NunitoSans'),
                  ),
                ),
                Container(
                  alignment: AlignmentDirectional(0, 0),
                  margin: EdgeInsets.only(top: 10),
                  child: Text(amountError,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: KiraColors.kYellowColor,
                        fontFamily: 'NunitoSans',
                        fontWeight: FontWeight.w600,
                      )),
                ),
                if (addressError != '')
                  Container(
                    alignment: AlignmentDirectional(0, 0),
                    margin: EdgeInsets.only(bottom: 10),
                    child: Text(addressError,
                        style: TextStyle(
                          fontSize: 14.0,
                          color: KiraColors.kYellowColor,
                          fontFamily: 'NunitoSans',
                          fontWeight: FontWeight.w600,
                        )),
                  ),
              ],
            ),
          ],
        ));
  }

  Widget addGravatar(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(bottom: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
                width: 120,
                height: 120,
                margin: EdgeInsets.symmetric(vertical: 0, horizontal: 30),
                padding: EdgeInsets.all(0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1000),
                  color: KiraColors.kPrimaryLightColor,
                ),
                // dropdown below..
                child: Image(
                    image: AssetImage(Strings.logoImage),
                    width: 80,
                    height: 80)),
          ],
        ));
  }

  Widget addWithdrawButton() {
    return Container(
        width: MediaQuery.of(context).size.width *
            (ResponsiveWidget.isSmallScreen(context) ? 0.62 : 0.25),
        margin: EdgeInsets.only(bottom: 100),
        child: CustomButton(
          key: Key('withdraw'),
          text: 'Withdraw',
          height: 44.0,
          onPressed: () {
            // Navigator.pushReplacementNamed(context, '/account');
          },
          backgroundColor: KiraColors.kPrimaryColor,
        ));
  }

  Widget addWithdrawalTransactionsTable(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(bottom: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Withdrawal Transactions",
                textAlign: TextAlign.left,
                style: TextStyle(color: KiraColors.black, fontSize: 30)),
            SizedBox(height: 30),
            WithdrawalTransactionsTable()
          ],
        ));
  }
}
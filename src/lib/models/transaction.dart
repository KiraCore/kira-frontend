import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
import 'package:date_time_format/date_time_format.dart';
import 'package:kira_auth/utils/colors.dart';

part 'transaction.g.dart';

enum TransactionStatus { CONFIRMED, UNCONFIRMED, FAILED }

@JsonSerializable(fieldRename: FieldRename.snake)
class Transaction {
  String hash;
  String action;
  String sender;
  String recipient;
  String token;
  String amount;
  String gas;
  String status;
  int time;
  String memo;
  bool isNew;

  Transaction({
    this.hash = "",
    this.action = "",
    this.sender = "",
    this.recipient = "",
    this.token = "",
    this.amount = "",
    this.isNew = false,
    this.gas = "",
    this.status = "",
    this.time,
    this.memo = "",
  }) {}

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  String toString() => jsonEncode(toJson());

  String get getReducedHash => hash.length > 7 ? hash.replaceRange(7, hash.length - 3, '....') : hash;
  String get getReducedSender => sender.length > 7 ? sender.replaceRange(7, sender.length - 7, '....') : sender;
  String get getReducedRecipient =>
      recipient.length > 7 ? recipient.replaceRange(7, recipient.length - 7, '....') : recipient;
  String get getAmount => this.amount + ' ' + this.token;
  String get getTimeString => new DateTime.fromMillisecondsSinceEpoch(this.time * 1000).relative(appendIfAfter: 'ago');

  TransactionStatus getStatus() {
    TransactionStatus tStatus;
    switch (status) {
      case "confirmed":
        tStatus = TransactionStatus.CONFIRMED;
        break;
      case "unconfirmed":
        tStatus = TransactionStatus.UNCONFIRMED;
        break;
      case "failed":
        tStatus = TransactionStatus.FAILED;
        break;
      default:
        tStatus = TransactionStatus.CONFIRMED;
        break;
    }
    return tStatus;
  }

  Color getStatusColor() {
    Color statusColor;
    switch (getStatus()) {
      case TransactionStatus.CONFIRMED:
        statusColor = KiraColors.green3;
        break;
      case TransactionStatus.UNCONFIRMED:
        statusColor = KiraColors.danger;
        break;
      case TransactionStatus.FAILED:
        statusColor = KiraColors.danger;
        break;
      default:
        statusColor = KiraColors.kGrayColor;
    }
    return statusColor;
  }
}

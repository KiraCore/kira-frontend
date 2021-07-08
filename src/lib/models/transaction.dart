import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
import 'package:date_time_format/date_time_format.dart';
import 'package:kira_auth/utils/colors.dart';

part 'transaction.g.dart';

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
  DateTime time;
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
  }) {
    // assert(time != null);
  }

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  String toString() => jsonEncode(toJson());

  String get getReducedHash => '0x$hash'.replaceRange(7, hash.length - 3, '....');
  String get getReducedSender => sender.replaceRange(7, sender.length - 7, '....');
  String get getReducedRecipient => recipient.replaceRange(7, sender.length - 7, '....');
  String get getAmount => this.amount + ' ' + this.token;
  String get getTimeString => time != null ? time.relative(appendIfAfter: 'ago') : "";

  Color getStatusColor() {
    switch (status) {
      case 'success':
        return KiraColors.green3;
      default:
        return KiraColors.kGrayColor;
    }
  }
}

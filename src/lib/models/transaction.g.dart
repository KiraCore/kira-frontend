// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) {
  return Transaction(
    hash: json['hash'] as String,
    action: json['action'] as String,
    sender: json['sender'] as String,
    recipient: json['recipient'] as String,
    token: json['token'] as String,
    amount: json['amount'] as String,
    isNew: false,
    gas: json['gas'] as String,
    status: json['status'] as String,
    time: json['time'] != null ? DateTime.parse(json['time'] ?? DateTime.now().toString()) : null,
    // memo: json['memo'] as String
  );
}

Map<String, dynamic> _$TransactionToJson(Transaction instance) => <String, dynamic>{
      'hash': instance.hash,
      'action': instance.action,
      'sender': instance.sender,
      'recipient': instance.recipient,
      'token': instance.token,
      'amount': instance.amount,
      'gas': instance.gas,
      'status': instance.status,
      'time': instance.time,
      // 'memo': instance.memo,
    };

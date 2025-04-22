import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/models/account.dart';

enum SurrenderStatus {
  Pending,
  Approved,
  Rejected,
  Completed,
  Cancelled,
} 

class Surrender {
  String surrender_id;
  String account_id;
  String org_id;
  String pet_id;
  SurrenderStatus surrender_status;
  DateTime date_surrendered;

  Surrender({
    required this.surrender_id,
    required this.account_id,
    required this.org_id,
    required this.pet_id,
    required this.surrender_status,
    required this.date_surrendered,
  });

  Surrender.fromJson(Map<String, dynamic> json)
      : surrender_id = json['surrender_id'] as String,
        account_id = json['account_id'] as String,
        org_id = json['org_id'] as String,
        pet_id = json['pet_id'] as String,
        surrender_status = SurrenderStatus.values.firstWhere((e) => e.toString() == 'SurrenderStatus.' + json['surrender_status']),
        date_surrendered = DateTime.parse(json['date_surrendered'] as String);

  Surrender copyWith({
    String? surrender_id,
    String? account_id,
    String? org_id,
    String? pet_id,
    SurrenderStatus? surrender_status,
    DateTime? date_surrendered,
  }) {
    return Surrender(
      surrender_id: surrender_id ?? this.surrender_id,
      account_id: account_id ?? this.account_id,
      org_id: org_id ?? this.org_id,
      pet_id: pet_id ?? this.pet_id,
      surrender_status: surrender_status ?? this.surrender_status,
      date_surrendered: date_surrendered ?? this.date_surrendered,
    );
  }

  Map<String, dynamic?> toJson() {
    return {
      'surrender_id': surrender_id,
      'account_id': account_id,
      'org_id': org_id,
      'pet_id': pet_id,
      'surrender_status': surrender_status.toString().split('.').last,
      'date_surrendered': date_surrendered.toIso8601String(),
    };
  }
}
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Organization {
  String org_id;
  String org_name;
  String org_proof_of_validation;
  DateTime date_created;
  List<String> admin_ids;
  bool isVerified;

  Organization({
    required this.org_id,
    required this.org_name,
    required this.org_proof_of_validation,
    required this.date_created,
    required this.admin_ids,
    this.isVerified = false,
  });

  Organization.fromJson(Map<String, dynamic> json)
      : org_id = json['org_id'] as String,
        org_name = json['org_name'] as String,
        org_proof_of_validation = json['org_proof_of_validation'] as String,
        date_created = (json['date_created'] is Timestamp)
            ? (json['date_created'] as Timestamp).toDate()
            : DateTime.parse(json['date_created'] as String),
        admin_ids = List<String>.from(json['admin_ids'] ?? []),
        isVerified = json['isVerified'] as bool? ?? false;

  Organization copyWith({
    String? org_id,
    String? org_name,
    String? org_proof_of_validation,
    DateTime? date_created,
    List<String>? admin_ids,
    bool? isVerified,
  }) {
    return Organization(
      org_id: org_id ?? this.org_id,
      org_name: org_name ?? this.org_name,
      org_proof_of_validation: org_proof_of_validation ?? this.org_proof_of_validation,
      date_created: date_created ?? this.date_created,
      admin_ids: admin_ids ?? this.admin_ids,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  Map<String, dynamic?> toJson() {
    return {
      'org_id': org_id,
      'org_name': org_name,
      'org_proof_of_validation': org_proof_of_validation,
      'date_created': date_created.toIso8601String(),
      'admin_ids': admin_ids,
      'isVerified': isVerified,
    };
  }
}
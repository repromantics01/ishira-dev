import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationStatus {
  Approved,
  Pending,
  Rejected,
  Completed,
  Cancelled,
}

class Adopt {
  String adopt_id;
  String pet_id;
  String account_id;
  String org_id;
  ApplicationStatus application_status; 
  String adopter_comment;
  DateTime? date_reviewed; //by the organization
  DateTime date_submitted; 
  DateTime? date_completed;

  Adopt({
    required this.adopt_id,
    required this.pet_id,
    required this.account_id,
    required this.org_id,
    required this.application_status,
    required this.adopter_comment,
    required this.date_reviewed,
    required this.date_submitted,
    required this.date_completed,
  });

  Adopt.fromJson(Map<String, dynamic> json)
      : adopt_id = json['adopt_id'] as String? ?? 'unknown_id',
        pet_id = json['pet_id'] as String? ?? 'unknown_pet_id',
        account_id = json['account_id'] as String? ?? 'unknown_account_id',
        org_id = json['org_id'] as String? ?? 'unknown_org_id',
        application_status = ApplicationStatus.values.firstWhere(
          (e) => e.toString() == 'ApplicationStatus.' + (json['application_status']?.toString() ?? 'Pending'),
          orElse: () => ApplicationStatus.Pending,
        ),
        adopter_comment = json['adopter_comment'] as String? ?? '',
        date_reviewed = json['date_reviewed'] == null || (json['date_reviewed'] as String).isEmpty
            ? null
            : DateTime.tryParse(json['date_reviewed'] as String),
        date_submitted = DateTime.tryParse(json['date_submitted'] as String? ?? '') ?? DateTime.now(),
        date_completed = json['date_completed'] == null || (json['date_completed'] as String).isEmpty
            ? null
            : DateTime.tryParse(json['date_completed'] as String);

  Adopt copyWith({
    String? adopt_id,
    String? pet_id,
    String? account_id,
    String? org_id,
    ApplicationStatus? application_status,
    String? adopter_comment,
    DateTime? date_reviewed,
    DateTime? date_submitted,
    DateTime? date_completed,
  }) {
    return Adopt(
      adopt_id: adopt_id ?? this.adopt_id,
      pet_id: pet_id ?? this.pet_id,
      account_id: account_id ?? this.account_id,
      org_id: org_id ?? this.org_id,
      application_status: application_status ?? this.application_status,
      adopter_comment: adopter_comment ?? this.adopter_comment,
      date_reviewed: date_reviewed ?? this.date_reviewed,
      date_submitted: date_submitted ?? this.date_submitted,
      date_completed: date_completed ?? this.date_completed,
    );
  }

  Map<String, dynamic?> toJson() {
    return {
      'adopt_id': adopt_id,
      'pet_id': pet_id,
      'account_id': account_id,
      'org_id': org_id,
      'application_status': application_status.toString().split('.').last,
      'adopter_comment': adopter_comment,
      'date_reviewed': date_reviewed?.toIso8601String(),
      'date_submitted': date_submitted.toIso8601String(),
      'date_completed': date_completed?.toIso8601String(),
    };
  }

}

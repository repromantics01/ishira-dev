import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

//change to org_admin, user, and moderator
enum AccountType {
  User,
  OrgAdmin,
  Moderator,
}

class Account {
  String account_id;
  AccountType account_type;
  String account_username;
  String account_email;
  String account_password;
  DateTime date_created;

  Account({
    required this.account_id,
    required this.account_type,
    required this.account_username,
    required this.account_email,
    required this.account_password,
    required this.date_created,
  });

  Account.fromJson(Map<String, dynamic> json)
      : account_id = json['account_id'] as String,
        // FIX: Accept both "OrgAdmin" and "org_admin" (and other case variants)
        account_type = _parseAccountType(json['account_type']),
        account_username = json['account_username'] as String,
        account_email = json['account_email'] as String,
        account_password = json['account_password'] as String,
        date_created = DateTime.parse(json['date_created'] as String);

  Account copyWith({
    String? account_id,
    AccountType? account_type,
    String? account_username,
    String? account_email,
    String? account_password,
    DateTime? date_created,
  }) {
    return Account(
      account_id: account_id ?? this.account_id,
      account_type: account_type ?? this.account_type,
      account_username: account_username ?? this.account_username,
      account_email: account_email ?? this.account_email,
      account_password: account_password ?? this.account_password,
      date_created: date_created ?? this.date_created,
    );
  }

  static AccountType _parseAccountType(dynamic value) {
    if (value is AccountType) return value;
    final str = value.toString();
    switch (str) {
      case 'OrgAdmin':
      case 'org_admin':
      case 'orgadmin':
      case 'ORGADMIN':
        return AccountType.OrgAdmin;
      case 'Moderator':
      case 'moderator':
        return AccountType.Moderator;
      case 'User':
      case 'user':
        return AccountType.User;
      default:
        // fallback to User if unknown
        return AccountType.User;
    }
  }

  Map<String, dynamic?> toJson() {
    return {
      'account_id': account_id,
      // Always save as "OrgAdmin", "User", "Moderator" for consistency
      'account_type': account_type.toString().split('.').last,
      'account_username': account_username,
      'account_email': account_email,
      'account_password': account_password,
      'date_created': date_created.toIso8601String(),
    };
  }
}
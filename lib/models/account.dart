import 'dart:convert';

//change to org_admin, user, and moderator
enum AccountType {
  Adopter,
  Surrenderer,
}
class Account {
  int account_id;
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
      : account_id = json['account_id'] as int,
        account_type = AccountType.values.firstWhere((e) => e.toString() == 'AccountType.' + json['account_type']),
        account_username = json['account_username'] as String,
        account_email = json['account_email'] as String,
        account_password = json['account_password'] as String,
        date_created = DateTime.parse(json['date_created'] as String);

  Account copyWith({
    int? account_id,
    AccountType? account_type,
    String? account_username,
    String? account_email,
    String? account_password,
    DateTime? date_created,
  }) {
    return Account(
      account_id: account_id?? this.account_id,
      account_type: account_type?? this.account_type,
      account_username: account_username?? this.account_username,
      account_email: account_email?? this.account_email,
      account_password: account_password?? this.account_password,
      date_created: date_created?? this.date_created
      );
  }

  Map<String, dynamic?> toJson() {
    return {
      'account_id': account_id,
      'account_type': account_type.toString().split('.').last,
      'account_username': account_username,
      'account_email': account_email,
      'account_password': account_password,
      'date_created': date_created.toIso8601String(),
    };
  }

}
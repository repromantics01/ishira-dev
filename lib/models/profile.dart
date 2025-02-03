import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType {
  Adopter,
  Surrenderer,
}

class Profile {
  String account_id;
  String profile_id;
  UserType user_type;
  String first_name;
  String middle_name;
  String last_name;
  String suffix;
  String bio;
  String address;
  DateTime date_created;

  Profile({
    required this.account_id,
    required this.profile_id,
    required this.user_type,
    required this.first_name,
    required this.middle_name,
    required this.last_name,
    required this.suffix,
    required this.bio,
    required this.address,
    required this.date_created,
  });

  Profile.fromJson(Map<String, dynamic> json)
      : account_id = json['account_id'] as String,
        profile_id = json['profile_id'] as String,
        user_type = UserType.values.firstWhere((e) => e.toString() == 'UserType.' + json['user_type']),
        first_name = json['first_name'] as String,
        middle_name = json['middle_name'] as String,
        last_name = json['last_name'] as String,
        suffix = json['suffix'] as String,
        bio = json['bio'] as String,
        address = json['address'] as String,
        date_created = DateTime.parse(json['date_created'] as String);

  Profile copyWith({
    String? account_id,
    String? profile_id,
    UserType? user_type,
    String? first_name,
    String? middle_name,
    String? last_name,
    String? suffix,
    String? bio,
    String? address,
    DateTime? date_created,
  }) {
    return Profile(
      account_id: account_id ?? this.account_id,
      profile_id: profile_id ?? this.profile_id,
      user_type: user_type ?? this.user_type,
      first_name: first_name ?? this.first_name,
      middle_name: middle_name ?? this.middle_name,
      last_name: last_name ?? this.last_name,
      suffix: suffix ?? this.suffix,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      date_created: date_created ?? this.date_created,
    );
  }

  Map<String, dynamic?> toJson() {
    return {
      'account_id': account_id,
      'profile_id': profile_id,
      'user_type': user_type.toString().split('.').last,
      'first_name': first_name,
      'middle_name': middle_name,
      'last_name': last_name,
      'suffix': suffix,
      'bio': bio,
      'address': address,
      'date_created': date_created.toIso8601String(),
    };
  }
}

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Swipe {
  String swipe_id;
  String account_id;
  String pet_id;
  String isActive;

  Swipe({
    required this.swipe_id,
    required this.account_id,
    required this.pet_id,
    required this.isActive,
  });
    
    Swipe.fromJson(Map<String, dynamic> json)
        : swipe_id = json['swipe_id'] as String,
          account_id = json['account_id'] as String,
          pet_id = json['pet_id'] as String,
          isActive = json['isActive'] as String;
    
    Swipe copyWith({
      String? swipe_id,
      String? account_id,
      String? pet_id,
      String? isActive,
    }) {
      return Swipe(
        swipe_id: swipe_id ?? this.swipe_id,
        account_id: account_id ?? this.account_id,
        pet_id: pet_id ?? this.pet_id,
        isActive: isActive ?? this.isActive,
      );
    }
    
    Map<String, dynamic?> toJson() {
      return {
        'swipe_id': swipe_id,
        'account_id': account_id,
        'pet_id': pet_id,
        'isActive': isActive,
      };
    }
}

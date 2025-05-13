import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Organization {
  String org_id;
  String org_name;
  String org_proof_of_validation;
  DateTime date_created;
  List<String> admin_ids;
  bool isVerified;
  bool isRejected; 
  
  String? location;
  String? address;
  String? about;
  String? mission;
  List<String>? services;
  String? weekday_hours;
  String? weekend_hours;
  String? email;
  String? landline;
  List<String>? contact_numbers;
  String? logo_url;  
  List<String>? social_media_links;
  List<String>? photo_ids;  

  Organization({
    required this.org_id,
    required this.org_name,
    required this.org_proof_of_validation,
    required this.date_created,
    required this.admin_ids,
    this.isVerified = false,
    this.isRejected = false, // Default to not rejected
    this.location,
    this.address,
    this.about,
    this.mission,
    this.services,
    this.weekday_hours,
    this.weekend_hours,
    this.email,
    this.landline,
    this.contact_numbers,
    this.logo_url,  // Direct URL for quick access
    this.social_media_links,
    this.photo_ids,  // References to photos collection
  });

  Organization.fromJson(Map<String, dynamic> json)
      : org_id = json['org_id'] as String? ?? 'unknown_id',
        org_name = json['org_name'] as String? ?? 'Unnamed Organization',
        org_proof_of_validation = json['org_proof_of_validation'] as String? ?? '',
        date_created = _parseDateTime(json['date_created']),
        admin_ids = _parseStringList(json['admin_ids']),
        isVerified = json['isVerified'] as bool? ?? false,
        isRejected = json['isRejected'] as bool? ?? false, // Parse isRejected with default false
        location = _parseString(json['location']),
        address = _parseString(json['address']),
        about = _parseString(json['about']),
        mission = _parseString(json['mission']),
        services = json['services'] != null ? List<String>.from(json['services']) : null,
        weekday_hours = _parseString(json['weekday_hours']),
        weekend_hours = _parseString(json['weekend_hours']),
        email = _parseString(json['email']),
        landline = _parseString(json['landline']),
        contact_numbers = _parseContactNumbers(json['contact_numbers']),
        logo_url = _parseString(json['logo_url']),
        social_media_links = _parseSocialMediaLinks(json['social_media_links']),
        photo_ids = json['photo_ids'] != null ? List<String>.from(json['photo_ids']) : null; // Parse photo_ids from json

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date string: $e');
        return DateTime.now();
      }
    }
    return DateTime.now(); // Default value
  }
  
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return []; // Default empty list
  }
  
  // New parsing method for contact numbers
  static List<String>? _parseContactNumbers(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is Map) {
      // Convert map values to a list of strings
      return value.values.map((e) => e.toString()).toList();
    }
    return null;
  }
  
  // New parsing method for social media links
  static List<String>? _parseSocialMediaLinks(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is Map) {
      // Convert map values to a list of strings
      return value.values.map((e) => e.toString()).toList();
    }
    return null;
  }

  // Helper to safely parse String? fields
  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    // If it's a Map or other type, try to convert to JSON string for debugging, or just return null
    try {
      return value.toString();
    } catch (_) {
      return null;
    }
  }

  Organization copyWith({
    String? org_id,
    String? org_name,
    String? org_proof_of_validation,
    DateTime? date_created,
    List<String>? admin_ids,
    bool? isVerified,
    bool? isRejected, // Add to copyWith
    String? location,
    String? address,
    String? about,
    String? mission,
    List<String>? services,
    String? weekday_hours,
    String? weekend_hours,
    String? email,
    String? landline,
    List<String>? contact_numbers,
    String? logo_url,  // Direct URL for quick access
    List<String>? social_media_links,
    List<String>? photo_ids,  // References to photos collection
  }) {
    return Organization(
      org_id: org_id ?? this.org_id,
      org_name: org_name ?? this.org_name,
      org_proof_of_validation: org_proof_of_validation ?? this.org_proof_of_validation,
      date_created: date_created ?? this.date_created,
      admin_ids: admin_ids ?? this.admin_ids,
      isVerified: isVerified ?? this.isVerified,
      isRejected: isRejected ?? this.isRejected, // Include in new object
      location: location ?? this.location,
      address: address ?? this.address,
      about: about ?? this.about,
      mission: mission ?? this.mission,
      services: services ?? this.services,
      weekday_hours: weekday_hours ?? this.weekday_hours,
      weekend_hours: weekend_hours ?? this.weekend_hours,
      email: email ?? this.email,
      landline: landline ?? this.landline,
      contact_numbers: contact_numbers ?? this.contact_numbers,
      logo_url: logo_url ?? this.logo_url,  // Direct URL for quick access
      social_media_links: social_media_links ?? this.social_media_links,
      photo_ids: photo_ids ?? this.photo_ids,  // References to photos collection
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'org_id': org_id,
      'org_name': org_name,
      'org_proof_of_validation': org_proof_of_validation,
      'date_created': date_created.toIso8601String(),
      'admin_ids': admin_ids,
      'isVerified': isVerified,
      'isRejected': isRejected, // Include in JSON
      'location': location,
      'address': address,
      'about': about,
      'mission': mission,
      'services': services,
      'weekday_hours': weekday_hours,
      'weekend_hours': weekend_hours,
      'email': email,
      'landline': landline,
      'contact_numbers': contact_numbers,
      'logo_url': logo_url,  // Direct URL for quick access
      'social_media_links': social_media_links,
      'photo_ids': photo_ids,  // References to photos collection
    };
  }
}
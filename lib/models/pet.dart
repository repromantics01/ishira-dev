// TODO Implement this library.
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AcquisitionType {
  Rescued,
  Surrendered,
}

enum VaccinationStatus {
  Full,
  Partial,
  None,
}

enum PetStatus {
  Adopted,
  Available,
  Pending,
}

class Pet {
  String pet_id;
  String pet_name;
  String gender;
  List<String> photo_id;
  PetStatus pet_status;
  DateTime birthdate;
  String address;
  String breed;
  AcquisitionType acquisition_type;
  String description;
  String species;
  bool is_neutered_or_spayed;
  VaccinationStatus vaccination_status;

  Pet({
    required this.pet_id,
    required this.pet_name,
    required this.gender,
    required this.photo_id,
    required this.pet_status,
    required this.birthdate,
    required this.address,
    required this.breed,
    required this.acquisition_type,
    required this.description,
    required this.species,
    required this.is_neutered_or_spayed,
    required this.vaccination_status,
  });

  Pet.fromJson(Map<String, dynamic> json)
      : pet_id = json['pet_id'] as String,
        pet_name = json['pet_name'] as String,
        gender = json['gender'] as String,
        photo_id = List<String>.from(json['photo_id'] as List),
        pet_status = PetStatus.values.firstWhere(
            (e) => e.toString() == 'PetStatus.' + json['pet_status']),
        birthdate = DateTime.parse(json['birthdate'] as String),
        address = json['address'] as String,
        breed = json['breed'] as String,
        acquisition_type = AcquisitionType.values.firstWhere((e) =>
            e.toString() == 'AcquisitionType.' + json['acquisition_type']),
        description = json['description'] as String,
        species = json['species'] as String,
        is_neutered_or_spayed = json['is_neutered_or_spayed'] as bool,
        vaccination_status = VaccinationStatus.values.firstWhere((e) =>
            e.toString() == 'VaccinationStatus.' + json['vaccination_status']);

  Pet copyWith({
    String? pet_id,
    String? pet_name,
    String? gender,
    List<String>? photo_id,
    PetStatus? pet_status,
    DateTime? birthdate,
    String? address,
    String? breed,
    AcquisitionType? acquisition_type,
    String? description,
    String? species,
    bool? is_neutered_or_spayed,
    VaccinationStatus? vaccination_status,
  }) {
    return Pet(
      pet_id: pet_id ?? this.pet_id,
      pet_name: pet_name ?? this.pet_name,
      gender: gender ?? this.gender,
      photo_id: photo_id ?? this.photo_id,
      pet_status: pet_status ?? this.pet_status,
      birthdate: birthdate ?? this.birthdate,
      address: address ?? this.address,
      breed: breed ?? this.breed,
      acquisition_type: acquisition_type ?? this.acquisition_type,
      description: description ?? this.description,
      species: species ?? this.species,
      is_neutered_or_spayed: is_neutered_or_spayed ?? this.is_neutered_or_spayed,
      vaccination_status: vaccination_status ?? this.vaccination_status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pet_id': pet_id,
      'pet_name': pet_name,
      'gender': gender,
      'photo_id': photo_id,
      'pet_status': pet_status.toString().split('.').last,
      'birthdate': birthdate.toIso8601String(),
      'address': address,
      'breed': breed,
      'acquisition_type': acquisition_type.toString().split('.').last,
      'description': description,
      'species': species,
      'is_neutered_or_spayed': is_neutered_or_spayed,
      'vaccination_status': vaccination_status.toString().split('.').last,
    };
  }
}

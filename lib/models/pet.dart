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
  double weight;
  List<String> pet_images;
  PetStatus pet_status;
  DateTime birthdate;
  String address;
  String breed;
  AcquisitionType acquisition_type;
  String description;
  String species;
  bool is_neutered_or_spayed;
  
  Pet({
    required this.pet_id,
    required this.pet_name,
    required this.gender,
    required this.weight,
    required this.pet_images,
    required this.pet_status,
    required this.birthdate,
    required this.address,
    required this.breed,
    required this.acquisition_type,
    required this.description,
    required this.species,
    required this.is_neutered_or_spayed,
  });

  Pet.fromJson(Map<String, dynamic> json)
      : pet_id = json['pet_id'] as String,
        pet_name = json['pet_name'] as String,
        gender = json['gender'] as String,
        weight = json['weight'] as double,
        pet_images = List<String>.from(json['pet_images'] as List),
        pet_status = PetStatus.values.firstWhere((e) => e.toString() == 'PetStatus.' + json['pet_status']),
        birthdate = DateTime.parse(json['birthdate'] as String),
        address = json['address'] as String,
        breed = json['breed'] as String,
        acquisition_type = AcquisitionType.values.firstWhere((e) => e.toString() == 'AcquisitionType.' + json['acquisition_type']),
        description = json['description'] as String,
        species = json['species'] as String,
        is_neutered_or_spayed = json['is_neutered_or_spayed'] as bool;
  
}
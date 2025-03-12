import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String PET_COLLECTION_REF = "pet";

class FirebasePetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final CollectionReference<Pet> _petCollectionRef;

  FirebasePetService() {
    _petCollectionRef = _firestore.collection(PET_COLLECTION_REF).withConverter<Pet>(
      fromFirestore: (snapshots, _) => Pet.fromJson(snapshots.data()!),
      toFirestore: (pet, _) => pet.toJson(),
    );
  }

  Stream <QuerySnapshot<Pet>> getPet() {
    return _petCollectionRef.snapshots();
  }

  Future<void> addPet(Pet pet) async {
    try {
      await _petCollectionRef.doc(pet.pet_id).set(pet);
    } catch (e) {
      print('Error adding pet: $e');
    }
  }

  String generateNewPetId() {
    return _petCollectionRef.doc().id;
  }

  getPetWithId(String id) {
    return _petCollectionRef.doc(id).get();
  }
}


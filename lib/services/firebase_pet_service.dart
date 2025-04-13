import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawsmatch/models/swipe.dart';
import 'package:pawsmatch/models/account.dart';

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

  // Get all pets from the database
  Stream<QuerySnapshot<Pet>> getAllPets() {
    return _petCollectionRef.snapshots();
  }
  
  // Get pets by surrenderer ID
  Stream<QuerySnapshot<Pet>> getPetsBySurrendererId(String surrendererId) {
    return _petCollectionRef
        .where('surrenderer_id', isEqualTo: surrendererId)
        .snapshots();
  }

  getPetWithId(String id) {
    return _petCollectionRef.doc(id).get();
  }
  
  // Get pets swiped by a specific account
  Future<List<Pet>> getPetsSwipedByAccount(String accountId, {bool liked = true}) async {
    try {
      // Reference to swipes collection
      final swipesRef = _firestore.collection('swipes').where(
          'account_id', isEqualTo: accountId);
      
      // If we only want liked pets, add that filter
      final query = liked 
          ? swipesRef.where('liked', isEqualTo: true)
          : swipesRef;
      
      // Get all swipes by this account
      final swipesSnapshot = await query.get();
      
      // Extract pet IDs from swipes
      final petIds = swipesSnapshot.docs
          .map((doc) => doc.data()['pet_id'] as String)
          .toList();
      
      // If no swipes found, return empty list
      if (petIds.isEmpty) {
        return [];
      }
      
      // Get all pets with the extracted IDs
      // Note: Firestore limits "in" queries to 10 items, so we may need to batch
      final List<Pet> swipedPets = [];
      
      // Process in batches of 10 to avoid Firestore limits
      for (int i = 0; i < petIds.length; i += 10) {
        final end = (i + 10 < petIds.length) ? i + 10 : petIds.length;
        final batch = petIds.sublist(i, end);
        
        final petsSnapshot = await _petCollectionRef
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        // Add pets from this batch to the result list
        swipedPets.addAll(petsSnapshot.docs.map((doc) => doc.data()));
      }
      
      return swipedPets;
    } catch (e) {
      print('Error getting swiped pets: $e');
      return [];
    }
  }
  
  // Stream of pets swiped by an account (for real-time updates)
  Stream<List<Pet>> streamPetsSwipedByAccount(String accountId, {bool liked = true}) {
    // Reference to swipes collection filtered by account ID
    final swipesRef = _firestore.collection('swipes')
        .where('account_id', isEqualTo: accountId);
    
    // If we only want liked pets, add that filter
    final query = liked
        ? swipesRef.where('liked', isEqualTo: true)
        : swipesRef;
    
    // Return a stream that transforms swipe snapshots into pet data
    return query.snapshots().asyncMap((swipesSnapshot) async {
      // Extract pet IDs from swipes
      final petIds = swipesSnapshot.docs
          .map((doc) => doc.data()['pet_id'] as String)
          .toList();
      
      if (petIds.isEmpty) {
        return [];
      }
      
      // Get all pets with the extracted IDs
      final List<Pet> swipedPets = [];
      
      // Process in batches of 10
      for (int i = 0; i < petIds.length; i += 10) {
        final end = (i + 10 < petIds.length) ? i + 10 : petIds.length;
        final batch = petIds.sublist(i, end);
        
        final petsSnapshot = await _petCollectionRef
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        swipedPets.addAll(petsSnapshot.docs.map((doc) => doc.data()));
      }
      
      return swipedPets;
    });
  }

  // Get a random pet from the database
  Future<Pet?> getRandomPet() async {
    try {
      print('Attempting to fetch random pet...');
      final petsSnapshot = await _petCollectionRef.get();
      
      print('Found ${petsSnapshot.docs.length} pets in database');
      
      if (petsSnapshot.docs.isEmpty) {
        print('No pets available in database');
        return null;
      }
      
      final random = DateTime.now().millisecondsSinceEpoch % petsSnapshot.docs.length;
      print('Selected random pet at index $random');
      
      Pet randomPet = petsSnapshot.docs[random].data();
      print('Random pet fetched: ${randomPet.pet_name}');
      
      return randomPet;
    } catch (e) {
      print('Error fetching random pet: $e');
      return null;
    }
  }

  // Get a limited number of pets from the database
  Future<List<Pet>> getPets({required int limit}) async {
    try {
      print('Fetching $limit pets...');
      // Just get any pets without filtering to ensure we have data
      final QuerySnapshot<Pet> petsSnapshot = await _petCollectionRef
          .limit(limit)
          .get();
      
      print('Found ${petsSnapshot.docs.length} pets in database');
      
      if (petsSnapshot.docs.isEmpty) {
        print('No pets available in database');
        return [];
      }
      
      // Convert the snapshot to a list of Pet objects
      List<Pet> pets = petsSnapshot.docs.map((doc) => doc.data()).toList();
      
      // Log each pet for debugging
      pets.forEach((pet) => print('Pet: ${pet.pet_name}, Status: ${pet.pet_status}'));
      
      return pets;
    } catch (e) {
      print('Error fetching pets: $e');
      return [];
    }
  }
  Future<Pet> getPetById(String petId) async {
    try {
      final petDoc = await _petCollectionRef.doc(petId).get();
      if (petDoc.exists) {
        return petDoc.data()!;
      } else {
        throw Exception('Pet not found');
      }
    } catch (e) {
      print('Error fetching pet by ID: $e');
      rethrow;
    }
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/models/surrender.dart';
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
  
  // Get pets by organization ID - only include pets that belong to this organization
  Stream<QuerySnapshot<Pet>> getPetsByOrganizationId(String organizationId) {
    return _firestore
        .collection('pet')
        .where('org_id', isEqualTo: organizationId)
        .withConverter<Pet>(
          fromFirestore: (snapshot, _) => Pet.fromJson(snapshot.data()!),
          toFirestore: (pet, _) => pet.toJson(),
        )
        .snapshots();
  }
  
  // Get pets by organization ID and exclude pets with pending surrender status
  Future<List<Pet>> getPetsForManagement(String organizationId) async {
    try {
      print('Getting pets for management with org_id: $organizationId');
      
      final snapshot = await _firestore
        .collection('pet')
        .where('org_id', isEqualTo: organizationId)
        .get();
      
      print('Found ${snapshot.docs.length} total pets with matching org_id');
      
      final pets = snapshot.docs.map((doc) => Pet.fromJson(doc.data())).toList();
      
      // Log acquisition types to debug
      for (var pet in pets) {
        print('Pet ${pet.pet_id} (${pet.pet_name}): Acquisition type = ${pet.acquisition_type}');
      }
      
      // We still want to exclude pets with pending surrender requests
      final surrenderSnapshot = await _firestore
        .collection('surrender')
        .where('org_id', isEqualTo: organizationId)
        .where('surrender_status', isEqualTo: SurrenderStatus.Pending.toString().split('.').last)
        .get();
      
      final pendingSurrenderPetIds = surrenderSnapshot.docs.map((doc) => doc.data()['pet_id'] as String).toSet();
      print('Found ${pendingSurrenderPetIds.length} pets with pending surrender requests');
      
      // Filter out pets with pending surrender requests only
      final result = pets.where((pet) => !pendingSurrenderPetIds.contains(pet.pet_id)).toList();
      print('Returning ${result.length} pets after filtering out pending surrenders');
      
      return result;
    } catch (e) {
      print('Error getting pets for management: $e');
      return [];
    }
  }
  
  // Update pet's organization ID when surrender is approved
  Future<bool> updatePetOrganization(String petId, String organizationId) async {
    try {
      await _petCollectionRef.doc(petId).update({
        'org_id': organizationId,
        'pet_status': 'Available' // Optionally update pet status when moved to organization
      });
      print('Successfully updated pet organization to $organizationId');
      return true;
    } catch (e) {
      print('Error updating pet organization: $e');
      return false;
    }
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

  // Add a method to update a pet
  Future<bool> updatePet(Pet pet) async {
    try {
      await _petCollectionRef.doc(pet.pet_id).update(pet.toJson());
      print('Successfully updated pet ${pet.pet_name}');
      return true;
    } catch (e) {
      print('Error updating pet: $e');
      return false;
    }
  }
}


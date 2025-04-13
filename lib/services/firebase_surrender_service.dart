import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/models/surrender.dart';
import 'package:pawsmatch/models/account.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';

const String SURRENDER_COLLECTION_REF = "surrender";

class FirebaseSurrenderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseAccountService _accountService = DatabaseAccountService();

  late final CollectionReference<Surrender> _surrenderCollectionRef;

  FirebaseSurrenderService() {
    _surrenderCollectionRef = _firestore.collection(SURRENDER_COLLECTION_REF).withConverter<Surrender>(
      fromFirestore: (snapshots, _) => Surrender.fromJson(snapshots.data()!),
      toFirestore: (surrender, _) => surrender.toJson(),
    );
  }

  Stream <QuerySnapshot<Surrender>> getSurrender() {
    return _surrenderCollectionRef.snapshots();
  }

  Future<void> addSurrender(Surrender surrender) async {
    try {
      await _surrenderCollectionRef.add(surrender);
    } catch (e) {
      print('Error adding surrender: $e');
    }
  }

  /// Surrenders a pet to an organization
  /// 
  /// Takes [petId], [accountId], and [organizationId] to create a surrender record
  /// Returns the ID of the created surrender document if successful, null otherwise
  Future<String?> surrenderPetToOrganization({
    required String petId, 
    required String accountId, 
    required String organizationId
  }) async {
    try {
      // Create a new surrender object
      final Surrender surrenderRecord = Surrender(
        surrender_id: _surrenderCollectionRef.doc().id,
        pet_id: petId,
        account_id: accountId,
        org_id: organizationId,
        surrender_status: SurrenderStatus.Pending, // Initial status as pending
        date_surrendered: DateTime.now(),
      );
      
      // Add the surrender record to Firestore
      DocumentReference docRef = await _surrenderCollectionRef.add(surrenderRecord);
      
      // Log the successful surrender
      print('Pet successfully surrendered. Surrender ID: ${docRef.id}');
      
      // Return the ID of the newly created surrender document
      return docRef.id;
    } catch (e) {
      print('Error surrendering pet to organization: $e');
      return null;
    }
  }
  
  /// Gets all surrender records associated with a specific account ID
  /// 
  /// Takes the [accountId] to filter surrender records
  /// Returns a list of Surrender objects for that account
  Future<List<Surrender>> getSurrendersByAccountId(String accountId) async {
    try {
      final querySnapshot = await _surrenderCollectionRef
          .where('account_id', isEqualTo: accountId)
          .get();
      
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting surrenders by account ID: $e');
      return [];
    }
  }
  
  /// Gets all surrender records associated with a specific organization ID
  /// 
  /// Takes the [organizationId] to filter surrender records
  /// Returns a list of Surrender objects for that organization
  Future<List<Surrender>> getSurrendersByOrganizationId(String organizationId) async {
    try {
      final querySnapshot = await _surrenderCollectionRef
          .where('org_id', isEqualTo: organizationId)
          .get();
      
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting surrenders by organization ID: $e');
      return [];
    }
  }
  
  /// Gets the surrender record for a specific pet
  /// 
  /// Takes the [petId] to find its surrender record
  /// Returns the Surrender object if found, null otherwise
  Future<Surrender?> getSurrenderByPetId(String petId) async {
    try {
      final querySnapshot = await _surrenderCollectionRef
          .where('pet_id', isEqualTo: petId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print('Error getting surrender by pet ID: $e');
      return null;
    }
  }
}
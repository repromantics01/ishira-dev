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
      
      DocumentReference docRef = _surrenderCollectionRef.doc();
      final Surrender surrenderRecord = Surrender(
        surrender_id: docRef.id,
        pet_id: petId,
        account_id: accountId,
        org_id: organizationId,
        surrender_status: SurrenderStatus.Pending, 
        date_surrendered: DateTime.now(),
      );
      
     await docRef.set(surrenderRecord);
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

  Future<List<Surrender>> getSurrendersByPetId(String petId) async {
    try {
      final querySnapshot = await _surrenderCollectionRef
          .where('pet_id', isEqualTo: petId)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting surrenders by pet ID: $e');
      return [];
    }
  }

  // Update surrender request status
  Future<void> updateSurrenderStatus(String surrenderId, SurrenderStatus newStatus) async {
    try {
      await _firestore.collection('surrender').doc(surrenderId).update({
        'surrender_status': newStatus.toString().split('.').last,
      });
      
      // If the status is Approved, update the pet's ownership to the organization
      if (newStatus == SurrenderStatus.Approved) {
        final surrenderDoc = await _firestore.collection('surrender').doc(surrenderId).get();
        final data = surrenderDoc.data();
        
        if (data != null && data.containsKey('pet_id') && data.containsKey('org_id')) {
          final petId = data['pet_id'] as String;
          final orgId = data['org_id'] as String;
          
          // Update the pet document to assign it to the organization
          await _firestore.collection('pet').doc(petId).update({
            'org_id': orgId,
            'acquisition_type': AcquisitionType.Surrendered.toString().split('.').last,
          });
        }
      }
    } catch (e) {
      print('Error updating surrender status: $e');
      throw e;
    }
  }
  
  // Get all surrender requests for a specific organization
  Stream<QuerySnapshot> getSurrenderRequestsForOrganization(String orgId) {
    return _firestore
        .collection('surrender')
        .where('org_id', isEqualTo: orgId)
        .snapshots();
  }
  
  // Get pending surrender requests count for an organization
  Future<int> getPendingSurrenderRequestsCount(String orgId) async {
    try {
      final snapshot = await _firestore
          .collection('surrender')
          .where('org_id', isEqualTo: orgId)
          .where('surrender_status', isEqualTo: SurrenderStatus.Pending.toString().split('.').last)
          .get();
          
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting pending surrender requests count: $e');
      return 0;
    }
  }
}
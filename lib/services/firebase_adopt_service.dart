import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/models/surrender.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:pawsmatch/models/adopt.dart';

const String ADOPTION_COLLECTION_REF = "adopt";

class FirebaseAdoptService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseAccountService _accountService = DatabaseAccountService();

  late final CollectionReference<Adopt> _adoptCollectionRef;
  late final CollectionReference<Surrender> _surrenderCollectionRef;

  FirebaseAdoptService() {
    _adoptCollectionRef = _firestore.collection(ADOPTION_COLLECTION_REF).withConverter<Adopt>(
      fromFirestore: (snapshots, _) => Adopt.fromJson(snapshots.data()!),
      toFirestore: (adopt, _) => adopt.toJson(),
    );
  }

  Stream <QuerySnapshot<Adopt>> getAdopt() {
    return _adoptCollectionRef.snapshots();
  }

  Future<List<Map<String, dynamic>>> getAdoptList() async {
    try {
      final QuerySnapshot<Adopt> snapshot = await _adoptCollectionRef.get();
      return snapshot.docs.map((doc) => doc.data().toJson()).toList();
    } catch (e) {
      print('Error getting adoption list: $e');
      return [];
    }
  }

  Future<List<Map<Object, dynamic>>> getCurrentUserAdopts() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print("No authenticated user found");
        return [];
      }
      
      print("Querying adoptions for user ID: ${currentUser.uid}");
      
      final adoptionsSnapshot = await _firestore
          .collection(ADOPTION_COLLECTION_REF)
          .where('account_id', isEqualTo: currentUser.uid)
          .get();
      // final QuerySnapshot<Adopt> snapshot = await _adoptCollectionRef
      //   .where('account_id', isEqualTo: currentUser.uid)
      //   .get();
      
      //print("Found ${snapshot.docs.length} adoption documents");
      
      // Return the list of Adopt objects
      return adoptionsSnapshot.docs.map((doc) {
        final data = doc.data();
        return data;
      }).toList();
    } catch (e) {
      print('Error getting current user adopts: $e');
      return [];
    }
  }

  Future<void> addAdopt(Adopt adopt) async {
    try {
      await _adoptCollectionRef.add(adopt);
    } catch (e) {
      print('Error adding adoption: $e');
    }
  }

  Future<String?> adoptPetFromOrganization({
    required String petId, 
    required String accountId, 
    required String organizationId
  }) async {
    try {
      DocumentReference docRef = _adoptCollectionRef.doc();
      
      final Adopt adoptRecord = Adopt(
        adopt_id: docRef.id, // Use the generated document ID
        pet_id: petId,
        account_id: accountId,
        org_id: organizationId,
        application_status: ApplicationStatus.Pending, 
        adopter_comment: '', 
        date_reviewed: null,
        date_submitted: DateTime.now(),
        date_completed: null, 
      );
      
      // Use set instead of add to use the predetermined ID
      await docRef.set(adoptRecord);
      return docRef.id;
    } catch (e) {
      //print('Error adopting pet from organization: $e');
      return null;
    }
  }

  // New method to get pet IDs for which the current user has active adoption requests
  Future<List<String>> getCurrentUserAdoptionRequestPetIds() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print("No authenticated user found");
        return [];
      }
      
      // Query adoptions for the current user
      final adoptionsSnapshot = await _firestore
          .collection(ADOPTION_COLLECTION_REF)
          .where('account_id', isEqualTo: currentUser.uid)
          // We only care about active adoption requests 
          // (not rejected or cancelled)
          .where('application_status', whereIn: [
            'Pending', 'Approved', 'Completed'
          ])
          .get();
      
      // Extract pet IDs from adoption requests
      final petIds = adoptionsSnapshot.docs
          .map((doc) => doc.data()['pet_id'] as String)
          .toList();
      
      return petIds;
    } catch (e) {
      print('Error getting adoption request pet IDs: $e');
      return [];
    }
  }

}
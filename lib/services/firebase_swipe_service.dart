import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/models/swipe.dart';



const String SWIPE_COLLECTION_REF = "swipes";

class FirebaseSwipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final CollectionReference<Swipe> _swipeCollectionRef;
  late final CollectionReference _rawSwipeCollectionRef;

  FirebaseSwipeService() {
    _swipeCollectionRef = _firestore.collection(SWIPE_COLLECTION_REF).withConverter<Swipe>(
      fromFirestore: (snapshots, _) => Swipe.fromJson(snapshots.data()!),
      toFirestore: (swipe, _) => swipe.toJson(),
    );
    _rawSwipeCollectionRef = _firestore.collection(SWIPE_COLLECTION_REF);
  }  Future<bool> recordSwipe(String petId, bool liked) async {
    try {
      // Get the current user's ID
      final User? user = _auth.currentUser;
      if (user == null) return false;
      
      // Record the swipe in Firestore
      await _rawSwipeCollectionRef.add({
        'account_id': user.uid,
        'pet_id': petId,
        'liked': liked,
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': 'true' // Set to active by default
      });
      
      return true;
    } catch (e) {
      print('Error recording swipe: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCurrentUserSwipes() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return [];
      
      final swipesSnapshot = await _firestore
          .collection(SWIPE_COLLECTION_REF)
          .where('account_id', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      return swipesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['swipe_id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching user swipes: $e');
      return [];
    }
  }

  // Get all liked pets for the current user
  Future<List<String>> getCurrentUserLikedPetIds() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return [];
      
      final swipesSnapshot = await _firestore
          .collection(SWIPE_COLLECTION_REF)
          .where('account_id', isEqualTo: user.uid)
          .where('liked', isEqualTo: true)
          .where('isActive', isEqualTo: 'true') 
          .get();

      return swipesSnapshot.docs
          .map((doc) => doc.data()['pet_id'] as String)
          .toList();
    } catch (e) {
      print('Error fetching liked pet IDs: $e');
      return [];
    }
  }

  // New method to set a swipe as inactive when pet is adopted
  Future<bool> setSwipeInactive(String petId) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return false;
      
      // Find swipe documents matching the user and pet
      final swipesSnapshot = await _firestore
          .collection(SWIPE_COLLECTION_REF)
          .where('account_id', isEqualTo: user.uid)
          .where('pet_id', isEqualTo: petId)
          .get();
      
      // Update all matching swipes to inactive
      for (var doc in swipesSnapshot.docs) {
        await doc.reference.update({'isActive': 'false'});
      }
      
      return true;
    } catch (e) {
      print('Error setting swipe inactive: $e');
      return false;
    }
  }

  // Returns info about how many users have liked a specific pet
  Future<Map<String, dynamic>> getPetLikeStatistics(String petId) async {
    try {
      final likesSnapshot = await _firestore
          .collection(SWIPE_COLLECTION_REF)
          .where('pet_id', isEqualTo: petId)
          .where('liked', isEqualTo: true)
          .get();
      
      return {
        'totalLikes': likesSnapshot.docs.length,
        'recentLikes': likesSnapshot.docs
            .where((doc) {
              final timestamp = doc.data()['timestamp'] as Timestamp?;
              if (timestamp == null) return false;
              // Consider "recent" as within the last 7 days
              return timestamp.toDate().isAfter(
                  DateTime.now().subtract(Duration(days: 7)));
            })
            .length
      };
    } catch (e) {
      print('Error fetching pet like statistics: $e');
      return {'totalLikes': 0, 'recentLikes': 0};
    }
  }

  // Stream-related and original methods below
  Stream <QuerySnapshot<Swipe>> getSwipe() {
    return _swipeCollectionRef.snapshots();
  }

  Stream <QuerySnapshot<Swipe>> getSwipeByAccountId(String accountId) {
    return _swipeCollectionRef.where('account_id', isEqualTo: accountId).snapshots();
  }

  Stream <QuerySnapshot<Swipe>> getSwipeByPetId(String petId) {
    return _swipeCollectionRef.where('pet_id', isEqualTo: petId).snapshots();
  }
  
  Future<void> addSwipe(Swipe swipe) async {
    try {
      await _swipeCollectionRef.doc(swipe.swipe_id).set(swipe);
    } catch (e) {
      print('Error adding swipe: $e');
    }
  }
  
  String generateNewSwipeId() {
    return _swipeCollectionRef.doc().id;
  }
  
  Future<List<Swipe>> getSwipesByAccountId(String accountId) async {
    try {
      final querySnapshot = await _swipeCollectionRef
          .where('account_id', isEqualTo: accountId)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting swipes by account ID: $e');
      return [];
    }
  }
}
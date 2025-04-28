import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/models/profile.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';

const String PROFILE_COLLECTION_REF = "profile";

class FirebaseProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseAccountService _accountService = DatabaseAccountService();

  late final CollectionReference<Profile> _profileCollectionRef;

  FirebaseProfileService() {
    _profileCollectionRef = _firestore.collection(PROFILE_COLLECTION_REF).withConverter<Profile>(
      fromFirestore: (snapshots, _) => Profile.fromJson(snapshots.data()!),
      toFirestore: (profile, _) => profile.toJson(),
    );
  }

  Stream <QuerySnapshot<Profile>> getProfile() {
    return _profileCollectionRef.snapshots();
  }

  Future<void> addProfile(Profile profile) async {
    try {
      await _profileCollectionRef.add(profile);
    } catch (e) {
      print('Error adding profile: $e');
    }
  }

  Future<DocumentSnapshot<Profile>> getProfileWithId(String id) {
    return _profileCollectionRef.doc(id).get();
  }

  Future<String> getProfileID(String accountId) async {
    try {
      final profileQuery = await _firestore
          .collection(PROFILE_COLLECTION_REF)
          .where('account_id', isEqualTo: accountId)
          .limit(1)
          .get();
      
      if (profileQuery.docs.isNotEmpty) {
        return profileQuery.docs.first.id;
      } else {
        print('No profile found for account ID: $accountId');
        return 'No profile found';
      }
    } catch (e) {
      print('Error getting profile ID: $e');
      return 'Error retrieving profile ID';
    }
  }
  
  // Updated method to get user dashboard information with better error handling
  Future<Map<String, String>> getUserDashboardInfo() async {
    try {
      // Get current auth user
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('Dashboard info: No authenticated user found');
        return {
          'username': 'User',
          'email': 'No email available',
          'displayName': 'User',
        };
      }
      
      print('Current user ID: ${currentUser.uid}');
      
      // Get account info (username and email)
      final userInfo = await _accountService.getUserInfo();
      print('Account info retrieved: ${userInfo.toString()}');
      
      // Get profile info for display name
      String displayName = 'User';
      try {
        // Query for profiles where account_id equals the user's uid
        print('Querying profiles for account_id: ${currentUser.uid}');
        final profileQuery = await _firestore
            .collection(PROFILE_COLLECTION_REF)
            .where('account_id', isEqualTo: currentUser.uid)
            .limit(1)
            .get();
        
        if (profileQuery.docs.isNotEmpty) {
          final profileData = profileQuery.docs.first.data();
          print('Profile found: ${profileData['first_name']} ${profileData['last_name']}');
          
          if (profileData['first_name'] != null && profileData['first_name'].toString().isNotEmpty) {
            displayName = "${profileData['first_name']} ${profileData['last_name']}".trim();
          } else {
            displayName = userInfo['username'] ?? 'User';
          }
        } else {
          print('No profile document found for this user');
          displayName = userInfo['username'] ?? 'User';
        }
      } catch (e) {
        print('Error loading profile: $e');
        displayName = userInfo['username'] ?? 'User';
      }
      
      Map<String, String> result = {
        'username': userInfo['username'] ?? 'User',
        'email': userInfo['email'] ?? 'No email available',
        'displayName': displayName,
      };
      
      print('Final dashboard info: $result');
      return result;
    } catch (e) {
      print('Error getting dashboard info: $e');
      return {
        'username': 'User',
        'email': 'No email available',
        'displayName': 'User',
      };
    }
  }

  // Implement getUserProfile method
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final profileQuery = await _firestore
          .collection(PROFILE_COLLECTION_REF)
          .where('account_id', isEqualTo: uid)
          .limit(1)
          .get();
      
      if (profileQuery.docs.isNotEmpty) {
        return profileQuery.docs.first.data();
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Add this method to update profile
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    try {
      final profileQuery = await _firestore
          .collection(PROFILE_COLLECTION_REF)
          .where('account_id', isEqualTo: uid)
          .limit(1)
          .get();
      
      if (profileQuery.docs.isNotEmpty) {
        await _firestore
            .collection(PROFILE_COLLECTION_REF)
            .doc(profileQuery.docs.first.id)
            .update(data);
      } else {
        print('No profile found to update');
        throw Exception('Profile not found');
      }
    } catch (e) {
      print('Error updating profile: $e');
      throw e;
    }
  }

  // Public method to get user type with improved field checking
  Future<String> getUserType(String profileId) async {
    try {
      // Get the profile document
      final profileDoc = await _firestore.collection('profile').doc(profileId).get();
      
      if (profileDoc.exists) {
        final data = profileDoc.data() as Map<String, dynamic>;
        
        // Check various field names that might contain user type
        String? userType = data['user_type'] as String?;

   
        // If we found a user type, return it
        if (userType != null && userType.isNotEmpty) {
          return userType;
        }
      } else {
        print('Profile document not found for ID: $profileId');
      }
      
      // Default return value
      return 'user';
    } catch (e) {
      print('Error determining user type: $e');
      return 'user';
    }
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/models/account.dart';
import 'dart:core';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/models/profile.dart';

const String ACCOUNT_COLLECTION_REF = "account";

class DatabaseAccountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final CollectionReference<Account> _accountCollectionRef;

  DatabaseAccountService() {
    _accountCollectionRef = _firestore.collection(ACCOUNT_COLLECTION_REF).withConverter<Account>(
      fromFirestore: (snapshots, _) => Account.fromJson(snapshots.data()!),
      toFirestore: (account, _) => account.toJson(),
    );
  }

  Future<void> addAccount(Account account, String uid) async {
    try {
      await _accountCollectionRef.doc(uid).set(account);
    } catch (e) {
      print('Error adding account: $e');
    }
  }

  Future<Account> getAccount(String uid) async {
    try {
      final docSnapshot = await _accountCollectionRef.doc(uid).get();
      if (docSnapshot.exists) {
        return docSnapshot.data()!;
      } else {
        throw Exception('Account not found');
      }
    } catch (e) {
      print('Error getting account: $e');
      rethrow;
    }
  }

  Future<int> getNextAccountId() async {
    try {
      final querySnapshot = await _accountCollectionRef.get();
      return querySnapshot.docs.length + 1;
    } catch (e) {
      print('Error getting next account ID: $e');
      return 1; 
    }
  }

  // New method to get the current user's account username
  Future<String> getCurrentUsername() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      final docSnapshot = await _firestore
          .collection(ACCOUNT_COLLECTION_REF)
          .doc(userId)
          .get();
          
      if (!docSnapshot.exists) {
        return 'User';
      }
      
      return docSnapshot.data()?['account_username'] ?? 'User';
    } catch (e) {
      print('Error getting username: $e');
      return 'User';
    }
  }
  
  // Always fetch username from Firestore (not from Auth cache)
  Future<String> getCurrentUsernameFromDB() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }
      final docSnapshot = await _firestore
          .collection(ACCOUNT_COLLECTION_REF)
          .doc(userId)
          .get();
      if (!docSnapshot.exists) {
        return 'User';
      }
      return docSnapshot.data()?['account_username'] ?? 'User';
    } catch (e) {
      print('Error getting username from DB: $e');
      return 'User';
    }
  }
  
  // Get current email - easier from Auth than Firestore
  Future<String> getCurrentEmail() async {
    return _auth.currentUser?.email ?? '';
  }
  
  // Update username in Firestore
  Future<void> updateUsername(String newUsername) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      await _firestore
          .collection(ACCOUNT_COLLECTION_REF)
          .doc(userId)
          .update({'account_username': newUsername});
    } catch (e) {
      print('Error updating username: $e');
      throw Exception('Failed to update username: $e');
    }
  }
  
  
  
  // Update email (requires re-authentication)
  Future<void> updateEmail(String newEmail, String currentPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Get current email for re-authentication
      final String email = user.email ?? '';
      if (email.isEmpty) {
        throw Exception('Current user has no email');
      }
      
      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Update email in Firebase Auth
      await user.updateEmail(newEmail);
      
      // Update email in Firestore
      await _firestore
          .collection(ACCOUNT_COLLECTION_REF)
          .doc(user.uid)
          .update({'account_email': newEmail});
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        throw Exception('Email update is not allowed. Please contact support.');
      }
      print('Error updating email: $e');
      throw Exception(e.message ?? e.code);
    } catch (e) {
      print('Error updating email: $e');
      throw Exception(e);
    }
  }
  
  // Update password (requires re-authentication)
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Get current email for re-authentication
      final String email = user.email ?? '';
      if (email.isEmpty) {
        throw Exception('Current user has no email');
      }
      
      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Update password in Firebase Auth
      await user.updatePassword(newPassword);
      
      // Optional: Update hashed password in Firestore
      // In most cases, it's better not to store the password in Firestore,
      // since Firebase Auth handles password hashing and authentication
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        throw Exception('Password update is not allowed. Please contact support.');
      }
      print('Error updating password: $e');
      throw Exception(e.message ?? e.code);
    } catch (e) {
      print('Error updating password: $e');
      throw Exception(e);
    }
  }

  addProfile(Profile profile, String uid) {
    try {
      _firestore.collection('profile').doc(uid).set(profile.toJson());
    } catch (e) {
      print('Error adding profile: $e');
    }
  }

  Future<String?> getUserType(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['user_type'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting user type: $e');
      return null;
    }
  }

  getUserInfo() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return {
          'username': user.displayName ?? 'User',
          'email': user.email ?? 'No email available',
          'displayName': user.displayName ?? 'User',
        };
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }
}

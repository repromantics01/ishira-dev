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
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final account = await getAccount(currentUser.uid);
        return account.account_username;
      } else {
        return 'User';
      }
    } catch (e) {
      print('Error getting username: $e');
      return 'User';
    }
  }

  // New method to get the current user's account email
  Future<String> getCurrentEmail() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final account = await getAccount(currentUser.uid);
        return account.account_email;
      } else {
        return 'No email available';
      }
    } catch (e) {
      print('Error getting email: $e');
      return 'No email available';
    }
  }

  // New method to get both username and email together
  Future<Map<String, String>> getUserInfo() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final account = await getAccount(currentUser.uid);
        return {
          'username': account.account_username,
          'email': account.account_email
        };
      } else {
        return {
          'username': 'User',
          'email': 'No email available'
        };
      }
    } catch (e) {
      print('Error getting user info: $e');
      return {
        'username': 'User',
        'email': 'No email available'
      };
    }
  }

  addProfile(Profile profile, String uid) {}
}

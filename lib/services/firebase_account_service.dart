import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/models/account.dart';

const String ACCOUNT_COLLECTION_REF = "account";

class DatabaseAccountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final CollectionReference<Account> _accountCollectionRef;

  DatabaseAccountService() {
    _accountCollectionRef = _firestore.collection(ACCOUNT_COLLECTION_REF).withConverter<Account>(
      fromFirestore: (snapshots, _) => Account.fromJson(snapshots.data()!),
      toFirestore: (account, _) => account.toJson(),
    );
  }

  Stream<QuerySnapshot<Account>> getAccount() {
    return _accountCollectionRef.snapshots();
  } 

  Future<String> addAccount(Account account) async {
    try {
      DocumentReference<Account> docRef = await _accountCollectionRef.add(account);
      return docRef.id;
    } catch (e) {
      print('Error adding account: $e');
      return '';
    }
  }

  Future<int> getNextAccountId() async {
    try {
      final querySnapshot = await _accountCollectionRef.get();
      return querySnapshot.docs.length + 1;
    } catch (e) {
      print('Error getting next account ID: $e');
      return 1; // Default to 1 if there's an error
    }
  }
}
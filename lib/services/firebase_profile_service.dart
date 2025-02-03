// TODO Implement this library.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/models/profile.dart';
import 'package:pawsmatch/services/firebase_profile_service.dart';

const String PROFILE_COLLECTION_REF = "profile";

class FirebaseProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  getProfileWithId(String id) {
    return _profileCollectionRef.doc(id).get();
  }


}
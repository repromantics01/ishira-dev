import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/models/photo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String PHOTO_COLLECTION_REF = "photo";

class FirebasePhotoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final CollectionReference<Photo> _photoCollectionRef;

  FirebasePhotoService() {
    _photoCollectionRef = _firestore.collection(PHOTO_COLLECTION_REF).withConverter<Photo>(
      fromFirestore: (snapshots, _) => Photo.fromJson(snapshots.data()!),
      toFirestore: (photo, _) => photo.toJson(),
    );
  }

  Stream <QuerySnapshot<Photo>> getPhoto() {
    return _photoCollectionRef.snapshots();
  }

  Future<void> addPhoto(Photo photo) async {
    try {
      await _photoCollectionRef.doc(photo.photo_id).set(photo);
    } catch (e) {
      print('Error adding photo: $e');
    }
  }

  Future<void> addPhotoToFirestore(String photoUrl, String photoId) async {
    try {
      Photo photo = Photo(
        photo_id: photoId,
        photo_url: photoUrl,
        date_added: DateTime.now(),
      );
      await _photoCollectionRef.doc(photoId).set(photo);
    } catch (e) {
      print('Error adding photo to Firestore: $e');
    }
  }

  String generateNewPhotoId() {
    return _photoCollectionRef.doc().id;
  }

  Future<DocumentSnapshot<Photo>> getPhotoWithId(String id) {
    print('Requesting photo document with ID: $id');
    return _photoCollectionRef.doc(id).get();
  }

  Future<String?> getPhotoUrl(String photoId) async {
    try {
      var doc = await _photoCollectionRef.doc(photoId).get();
      if (doc.exists) {
        return doc.data()?.photo_url;
      }
      return null;
    } catch (e) {
      print('Error getting photo URL: $e');
      return null;
    }
  }

  String getPhotoURLFromSupabase(String photo_id, dynamic supabase) {
    return supabase.storage.from('pet').createPublicUrl('uploads/$photo_id');
  }
}
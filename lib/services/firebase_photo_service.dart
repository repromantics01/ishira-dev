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
  
  // New method to get multiple photo URLs for an organization
  Future<List<String>> getOrganizationPhotoUrls(List<String>? photoIds) async {
    if (photoIds == null || photoIds.isEmpty) {
      return [];
    }
    
    List<String> photoUrls = [];
    
    try {
      // Get photos in parallel for better performance
      final futures = photoIds.map((id) => getPhotoUrl(id));
      final results = await Future.wait(futures);
      
      // Filter out null results and add valid URLs to the list
      photoUrls = results.whereType<String>().toList();
      
      print('Retrieved ${photoUrls.length} photo URLs from ${photoIds.length} photo IDs');
    } catch (e) {
      print('Error getting organization photo URLs: $e');
    }
    
    return photoUrls;
  }

  

  // String getPhotoURLFromSupabase(String photo_id, dynamic supabase) {
  //   return supabase.storage.from('pet').createPublicUrl('uploads/$photo_id');
  // }

  // String getOrgLogoURLFromSupabase(String org_id, dynamic supabase) {
  //   return supabase.storage.from('organization-logo').createPublicUrl('uploads/$org_id');
  // }

  // String getOrgDocURLFromSupabase(String org_id, dynamic supabase) {
  //   return supabase.storage.from('organization_documents').createPublicUrl('uploads/$org_id');
  // }

  // String getOrgPhotosFromSupabase(String org_id, dynamic supabase) {
  //   return supabase.storage.from('organization_photos').createPublicUrl('uploads/$org_id');
  // }
}
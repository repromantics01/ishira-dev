import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
    //print('Requesting photo document with ID: $id');
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
      
      //print('Retrieved ${photoUrls.length} photo URLs from ${photoIds.length} photo IDs');
    } catch (e) {
      print('Error getting organization photo URLs: $e');
    }
    
    return photoUrls;
  }

  // Updated Supabase bucket names
  static const String LOGO_BUCKET = 'organization-logo';
  static const String PETS_BUCKET = 'pets';
  static const String DOCUMENTS_BUCKET = 'organization_documents';

  // Define expiry time for signed URLs (30 days in seconds)
  static const int SIGNED_URL_EXPIRY = 60 * 60 * 24 * 30;

  // Completely refactored logo upload method with better error handling
  Future<String?> uploadLogo(Uint8List imageBytes, String logoId) async {
    try {
      final client = Supabase.instance.client;
      
      // First ensure the client is properly authenticated
      final session = client.auth.currentSession;
      if (session == null) {
        print('No active session, attempting anonymous upload');
      } else {
        print('Using authenticated session, JWT expires: ${session.expiresAt}');
      }
      
      // Use a simpler path without subdirectories
      final path = logoId;
      
      // Upload directly without folders
      await client.storage
          .from(LOGO_BUCKET)
          .uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      
      // Generate signed URL instead of public URL for private buckets
      final logoUrl = await client.storage
          .from(LOGO_BUCKET)
          .createSignedUrl(path, SIGNED_URL_EXPIRY);
      
      print('Generated signed logo URL: $logoUrl');
      
      // Store URL in Firestore for reference
      final photoId = generateNewPhotoId();
      await addPhotoToFirestore(logoUrl, photoId);
      
      return logoUrl;
    } catch (e) {
      print('Error during logo upload process: $e');
      return null;
    }
  }

  // Updated to create signed URLs instead of public URLs
  Future<String> getLogoUrl(String logoId) async {
    try {
      final path = getOrganizationLogoPath(logoId);
      final url = await Supabase.instance.client.storage
          .from(LOGO_BUCKET)
          .createSignedUrl(path, SIGNED_URL_EXPIRY);
      print('Generated signed logo URL: $url');
      return url;
    } catch (e) {
      print('Error generating signed logo URL: $e');
      return ''; // Return empty string on error
    }
  }

  // Add utility methods for consistent path generation
  String getPetPhotoPath(String photoId) {
    return 'uploads/$photoId';
  }

  String getOrganizationLogoPath(String logoId) {
    return '$logoId';
  }

  String getOrganizationDocumentPath(String docId) {
    return 'documents/$docId';
  }

  // Update methods to use signed URLs for private buckets
  Future<String> getPhotoURLFromSupabase(String photoId) async {
    try {
      final path = getPetPhotoPath(photoId);
      return await Supabase.instance.client.storage
          .from(PETS_BUCKET)
          .createSignedUrl(path, SIGNED_URL_EXPIRY);
    } catch (e) {
      print('Error generating signed pet photo URL: $e');
      return ''; 
    }
  }

  Future<String> getOrgLogoURLFromSupabase(String logoId) async {
    try {
      final path = getOrganizationLogoPath(logoId);
      return await Supabase.instance.client.storage
          .from(LOGO_BUCKET)
          .createSignedUrl(path, SIGNED_URL_EXPIRY);
    } catch (e) {
      print('Error generating signed organization logo URL: $e');
      return '';
    }
  }

  Future<String> getOrgDocURLFromSupabase(String docId) async {
    try {
      final path = getOrganizationDocumentPath(docId);
      return await Supabase.instance.client.storage
          .from(DOCUMENTS_BUCKET)
          .createSignedUrl(path, SIGNED_URL_EXPIRY);
    } catch (e) {
      print('Error generating signed organization document URL: $e');
      return '';
    }
  }

  Future<String> convertToSignedUrlIfNeeded(String storedUrl) async {
    try {
      // Check if this is already a signed URL (has 'sign' and 'token' in it)
      if (storedUrl.contains('/sign/') && storedUrl.contains('token=')) {
        return storedUrl; // Already a signed URL
      }
      
      final uri = Uri.parse(storedUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length < 5) {
        print('Invalid stored URL format: $storedUrl');
        return storedUrl;
      }
      
      final bucketName = pathSegments[4];
      final objectPath = pathSegments.sublist(5).join('/');
      
      // Generate a new signed URL
      final signedUrl = await Supabase.instance.client.storage
          .from(bucketName)
          .createSignedUrl(objectPath, SIGNED_URL_EXPIRY);
          
      print('Converted public URL to signed URL: $signedUrl');
      return signedUrl;
    } catch (e) {
      print('Error converting to signed URL: $e');
      return storedUrl; // Return original on error
    }
  }
}
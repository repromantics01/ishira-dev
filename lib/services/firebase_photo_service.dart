import 'dart:typed_data';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/models/photo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

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
      if (photoId.isEmpty) {
        print('Empty photo ID provided');
        return null;
      }
      
      var doc = await _photoCollectionRef.doc(photoId).get();
      if (doc.exists) {
        final url = doc.data()?.photo_url;
        
        // Validate the URL
        if (url == null || url.isEmpty) {
          print('Invalid URL for photo ID $photoId: URL is null or empty');
          return null;
        }
        
        // Basic URL validation
        if (!url.startsWith('http')) {
          print('Invalid URL format for photo ID $photoId: $url');
          return null;
        }
        
        return url;
      } else {
        print('Photo document not found for ID: $photoId');
        return null;
      }
    } catch (e) {
      print('Error getting photo URL for $photoId: $e');
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

  // Upload multiple images and return the photo IDs
  Future<List<String>> uploadImages(List<XFile> images) async {
    List<String> photoIds = [];
    
    try {
      // Get Supabase client
      final supabase = Supabase.instance.client;
      if (supabase == null) {
        print('Supabase client not initialized');
        return photoIds;
      }
      
      for (var image in images) {
        // Generate a unique photo ID
        String photoId = generateNewPhotoId();
        final fileName = photoId;
        final path = 'uploads/$fileName';
        
        // Read image as bytes - works on all platforms
        final imageBytes = await image.readAsBytes();
        
        // Upload to Supabase storage using bytes - works on web and mobile
        await supabase.storage
            .from('pets')
            .uploadBinary(path, imageBytes);
            
        // Create a public URL
        final photoUrl = supabase.storage
            .from('pets')
            .getPublicUrl(path);
            
        // Add photo to Firestore
        await addPhotoToFirestore(photoUrl, photoId);
        
        // Add to the list of IDs to return
        photoIds.add(photoId);
        
        print('Successfully uploaded image: $photoId');
      }
      
      return photoIds;
    } catch (e) {
      print('Error uploading images: $e');
      return photoIds; // Return whatever IDs were successfully processed
    }
  }
  
  // Upload a single image and return the photo ID - updated for web compatibility
  Future<String?> uploadSingleImage(XFile image) async {
    try {
      // Get Supabase client
      final supabase = Supabase.instance.client;
      if (supabase == null) {
        print('Supabase client not initialized');
        return null;
      }
      
      // Generate a unique photo ID
      String photoId = generateNewPhotoId();
      final fileName = photoId;
      final path = 'uploads/$fileName';
      
      // Read image as bytes - works on all platforms
      final imageBytes = await image.readAsBytes();
      
      // Upload to Supabase storage using bytes - works on web and mobile
      await supabase.storage
          .from('pets')
          .uploadBinary(path, imageBytes);
          
      // Create a public URL
      final photoUrl = supabase.storage
          .from('pets')
          .getPublicUrl(path);
          
      // Add photo to Firestore
      await addPhotoToFirestore(photoUrl, photoId);
      
      return photoId;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
  
  Future<bool> deletePhoto(String photoId) async {
    try {
      // First get the photo URL before deleting from Firestore
      final photoDoc = await _photoCollectionRef.doc(photoId).get();
      if (!photoDoc.exists) {
        print('Photo document with ID $photoId does not exist');
        return false;
      }
      
      final photoUrl = photoDoc.data()?.photo_url;
      if (photoUrl == null) {
        print('Photo URL is null for photo ID: $photoId');
        return false;
      }
      
      // Delete the document from Firestore
      await _photoCollectionRef.doc(photoId).delete();
      print('Deleted photo document from Firestore: $photoId');
      
      // Now delete the file from Supabase storage
      try {
        final supabase = Supabase.instance.client;
        if (supabase == null) {
          print('Supabase client not initialized');
          return false;
        }
        
        // Parse the URL to get the path
        final Uri uri = Uri.parse(photoUrl);
        final pathSegments = uri.pathSegments;
        
        String? storagePath;
        for (int i = 0; i < pathSegments.length; i++) {
          if (pathSegments[i] == 'uploads' && i < pathSegments.length - 1) {
            storagePath = 'uploads/${pathSegments[i + 1]}';
            break;
          }
        }
        
        // If we couldn't parse the path, try a different approach
        if (storagePath == null) {
          // Assume the photoId is the filename
          storagePath = 'uploads/$photoId';
        }
        
        // Delete from Supabase storage
        final response = await supabase.storage
            .from('pets')
            .remove([storagePath]);
            
        print('Deleted photo file from Supabase storage: $storagePath');
        return true;
      } catch (e) {
        print('Error deleting photo file from storage: $e');
        // Even if storage deletion fails, we've already deleted from Firestore
        // so we return true to allow the UI to update
        return true;
      }
    } catch (e) {
      print('Error deleting photo: $e');
      return false;
    }
  }
}
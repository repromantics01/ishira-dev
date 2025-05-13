import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';

class SelectedImage {
  final Uint8List bytes;
  final String name;
  final String? mimeType;

  SelectedImage({required this.bytes, required this.name, this.mimeType});
}

class ImagePickerService {
  // Platform-agnostic method to pick images
  Future<List<SelectedImage>> pickImages({bool multiple = true, int maxImages = 5}) async {
    List<SelectedImage> result = [];
    
    // Web implementation
    if (kIsWeb) {
      try {
        final pickerResult = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: multiple,
          withData: true, // Important for web to get the bytes
        );

        if (pickerResult != null && pickerResult.files.isNotEmpty) {
          // Limit to maxImages
          final filesToProcess = pickerResult.files.length > maxImages 
              ? pickerResult.files.sublist(0, maxImages)
              : pickerResult.files;
          
          for (final file in filesToProcess) {
            if (file.bytes != null) {
              final mimeType = lookupMimeType(file.name);
              result.add(SelectedImage(
                bytes: file.bytes!,
                name: file.name,
                mimeType: mimeType,
              ));
            }
          }
        }
      } catch (e) {
        print('Error picking images on web: $e');
        rethrow;
      }
    } 
    // Mobile implementation
    else {
      try {
        final picker = img_picker.ImagePicker();
        List<img_picker.XFile> pickedFiles = [];
        
        if (multiple) {
          pickedFiles = await picker.pickMultiImage();
        } else {
          final pickedFile = await picker.pickImage(source: img_picker.ImageSource.gallery);
          if (pickedFile != null) {
            pickedFiles = [pickedFile];
          }
        }
        
        // Limit to maxImages
        if (pickedFiles.length > maxImages) {
          pickedFiles = pickedFiles.sublist(0, maxImages);
        }
        
        for (final file in pickedFiles) {
          final bytes = await file.readAsBytes();
          result.add(SelectedImage(
            bytes: bytes,
            name: file.name,
            mimeType: file.mimeType,
          ));
        }
      } catch (e) {
        print('Error picking images on mobile: $e');
        rethrow;
      }
    }
    
    return result;
  }
}

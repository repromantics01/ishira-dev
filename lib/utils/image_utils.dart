import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

class ImageUtils {
  /// Creates a widget that displays an image from an XFile in a cross-platform way
  static Widget buildImageFromXFile(XFile file, {
    BoxFit fit = BoxFit.cover,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    if (kIsWeb) {
      // For web, use Image.network with a cached object URL
      return FutureBuilder<Uint8List>(
        future: file.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              fit: fit,
              errorBuilder: errorBuilder,
            );
          } else if (snapshot.hasError) {
            return errorBuilder != null 
                ? errorBuilder(context, snapshot.error!, null)
                : Center(child: Icon(Icons.error, color: Colors.red));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      );
    } else {
      // For mobile platforms, use Image.file
      return Image.file(
        File(file.path),
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }
  }
  
  /// Upload a file to Supabase storage in a cross-platform way
  static Future<Uint8List> getFileBytes(XFile file) async {
    return await file.readAsBytes();
  }
}

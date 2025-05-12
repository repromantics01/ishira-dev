import 'package:flutter/material.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';

/// Reusable widget to display user profile images consistently across the app
class UserProfileImage extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackText;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final bool showBorder; // Added missing parameter
  final Color? backgroundColor; // Added missing parameter

  const UserProfileImage({
    Key? key,
    this.imageUrl,
    this.fallbackText,
    required this.size,
    this.borderColor,
    this.borderWidth = 1.0,
    this.showBorder = false, // Added with default value
    this.backgroundColor, // Added with default null
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? const Color(0xFFE9F1E5), // Use backgroundColor if provided
        border: (showBorder || borderColor != null) // Apply border if showBorder is true or if borderColor is provided
            ? Border.all(color: borderColor ?? Colors.grey.shade200, width: borderWidth)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackText();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: size / 3,
                      height: size / 3,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC0D6B6)),
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              )
            : _buildFallbackText(),
      ),
    );
  }

  Widget _buildFallbackText() {
    // Use first letter of fallbackText or '?' if empty
    final displayText = (fallbackText != null && fallbackText!.isNotEmpty)
        ? fallbackText![0].toUpperCase()
        : '?';

    return Center(
      child: Text(
        displayText,
        style: TextStyle(
          color: const Color(0xFF545454),
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

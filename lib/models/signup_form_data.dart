import 'package:file_picker/file_picker.dart';

class SignUpFormData {
  // Step 1 data
  String username;
  String email;
  String password;
  
  // Step 2 data
  String organizationName;
  List<PlatformFile> proofOfValidationFiles;
  
  // Step 3 data
  String? location;
  String? address;
  String? about;
  String? contactNumber;
  String? mission;
  String? weekdayHours;
  String? weekendHours;
  PlatformFile? logoFile;
  
  SignUpFormData({
    this.username = '',
    this.email = '',
    this.password = '',
    this.organizationName = '',
    this.proofOfValidationFiles = const [],
    this.location,
    this.address,
    this.about,
    this.contactNumber,
    this.mission,
    this.weekdayHours,
    this.weekendHours,
    this.logoFile,
  });
}

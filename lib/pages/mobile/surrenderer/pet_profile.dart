import 'package:flutter/material.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:intl/intl.dart';

class PetProfile extends StatelessWidget {
  final Pet pet;

  const PetProfile({Key? key, required this.pet}) : super(key: key);

  // Helper method to calculate age from birthdate
  String _calculateAge(DateTime birthdate) {
    final now = DateTime.now();
    int years = now.year - birthdate.year;
    if (now.month < birthdate.month || 
        (now.month == birthdate.month && now.day < birthdate.day)) {
      years--;
    }
    return years.toString();
  }

  // Get profile image from photo_id list
  String _getProfileImage() {
    if (pet.photo_id.isNotEmpty) {
      return pet.photo_id.first;
    }
    return "https://placehold.co/416x389";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image
            Container(
              height: 389,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(_getProfileImage()),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // Image Indicators
            Container(
              margin: EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pet.photo_id.length > 0 ? pet.photo_id.length : 1, (index) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: ShapeDecoration(
                      color: index == 0 
                          ? const Color(0xFF686868) 
                          : const Color(0xFF1F2024).withOpacity(0.10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            // Pet Name and Basic Information
            Padding(
              padding: EdgeInsets.fromLTRB(15, 20, 15, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.pet_name,
                          style: TextStyle(
                            color: const Color(0xFF545454),
                            fontSize: 30,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w700,
                            height: 0.80,
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '${pet.breed} • ${_calculateAge(pet.birthdate)} years old',
                          style: TextStyle(
                            color: const Color(0xFF545454),
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w700,
                            height: 1.50,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              pet.gender.toLowerCase() == 'male' 
                                  ? Icons.male 
                                  : Icons.female,
                              color: pet.gender.toLowerCase() == 'male'
                                  ? Colors.blue
                                  : Colors.pink,
                              size: 22,
                            ),
                            SizedBox(width: 5),
                            Text(
                              pet.gender,
                              style: TextStyle(
                                color: const Color(0xFF545454),
                                fontSize: 16,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w500,
                                height: 1.50,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Pet additional photo
                  Container(
                    width: 70,
                    height: 70,
                    decoration: ShapeDecoration(
                      image: DecorationImage(
                        image: NetworkImage(pet.photo_id.length > 1 
                          ? pet.photo_id[1]
                          : "https://placehold.co/70x69"),
                        fit: BoxFit.cover,
                      ),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: const Color(0x8E725F63),
                        ),
                        borderRadius: BorderRadius.circular(92.50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // About Pet
            Padding(
              padding: EdgeInsets.fromLTRB(15, 40, 15, 0),
              child: Column(
                children: [
                  Text(
                    'About ${pet.pet_name}',
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 20,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      height: 1.20,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    pet.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 15,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w400,
                      height: 1.47,
                    ),
                  ),
                ],
              ),
            ),
            
            // Characteristics
            Padding(
              padding: EdgeInsets.fromLTRB(15, 40, 15, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Characteristics',
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 20,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      height: 1.20,
                    ),
                  ),
                  SizedBox(height: 15),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildCharacteristicChip(pet.species),
                      _buildCharacteristicChip(pet.breed),
                      _buildCharacteristicChip(
                        pet.acquisition_type == AcquisitionType.Rescued ? 'Rescued' : 'Surrendered'
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Health Information
            Padding(
              padding: EdgeInsets.fromLTRB(15, 40, 15, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Information',
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 20,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      height: 1.20,
                    ),
                  ),
                  SizedBox(height: 15),
                  _buildHealthInfoRow('Spayed/Neutered:', pet.is_neutered_or_spayed),
                  _buildHealthInfoRow('Vaccination Status:', _getVaccinationStatus()),
                  SizedBox(height: 10),
                ],
              ),
            ),
            
            // Adoption Information
            Padding(
              padding: EdgeInsets.fromLTRB(15, 40, 15, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Adoption Information',
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 20,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      height: 1.20,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Status: ${_getPetStatusString()}',
                    style: TextStyle(
                      color: _getPetStatusColor(),
                      fontSize: 16,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      height: 1.50,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Located at: ${pet.address}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 15,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w400,
                      height: 1.47,
                    ),
                  ),
                  
                  // Contact Button
                  SizedBox(height: 40),
                  if (pet.pet_status == PetStatus.Available) ...[
                    Container(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Implement contact functionality
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEFCECB),
                          side: BorderSide(width: 1, color: const Color(0xFF8B8B8B)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(250),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'CONTACT NOW',
                          style: TextStyle(
                            color: const Color(0xFF1E2C2B),
                            fontSize: 14,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w500,
                            height: 1.14,
                            letterSpacing: 1.25,
                          ),
                        ),
                      ),
                    ),
                    
                    // Adoption Button
                    SizedBox(height: 15),
                    Container(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Implement adoption application
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB6CBCA),
                          side: BorderSide(width: 1, color: const Color(0xFF8B8B8B)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(250),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'ADOPT ME',
                          style: TextStyle(
                            color: const Color(0xFF1E2C2B),
                            fontSize: 14,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w500,
                            height: 1.14,
                            letterSpacing: 1.25,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pet.pet_status == PetStatus.Adopted 
                            ? 'This pet has been adopted' 
                            : 'Adoption pending approval',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Add bottom padding for better scrolling
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacteristicChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: const Color(0xFFEDEDED),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(250),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFF545454),
          fontSize: 14,
        ),
      ),
    );
  }
  
  bool _getVaccinatedStatus() {
    return pet.vaccination_status == VaccinationStatus.Full || 
           pet.vaccination_status == VaccinationStatus.Partial;
  }
  
  String _getVaccinationStatus() {
    switch (pet.vaccination_status) {
      case VaccinationStatus.Full:
        return 'Fully vaccinated';
      case VaccinationStatus.Partial:
        return 'Partially vaccinated';
      case VaccinationStatus.None:
        return 'Not vaccinated';
      default:
        return 'Unknown';
    }
  }
  
  String _getPetStatusString() {
    switch (pet.pet_status) {
      case PetStatus.Available:
        return 'Available for adoption';
      case PetStatus.Adopted:
        return 'Adopted';
      case PetStatus.Pending:
        return 'Adoption pending';
      default:
        return 'Unknown';
    }
  }
  
  Color _getPetStatusColor() {
    switch (pet.pet_status) {
      case PetStatus.Available:
        return Colors.green;
      case PetStatus.Adopted:
        return Colors.blue;
      case PetStatus.Pending:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  Widget _buildHealthInfoRow(String label, dynamic value) {
    String displayValue;
    IconData iconData;
    Color iconColor;
    
    if (value is bool) {
      displayValue = value ? 'Yes' : 'No';
      iconData = value ? Icons.check_circle : Icons.cancel;
      iconColor = value ? Colors.green : Colors.red;
    } else {
      displayValue = value.toString();
      iconData = displayValue.contains('Full') ? Icons.check_circle : 
                (displayValue.contains('Partial') ? Icons.remove_circle_outline : Icons.cancel);
      iconColor = displayValue.contains('Full') ? Colors.green : 
                 (displayValue.contains('Partial') ? Colors.orange : Colors.red);
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF545454),
              fontSize: 16,
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w700,
              height: 1.50,
            ),
          ),
          SizedBox(width: 8),
          Icon(
            iconData,
            color: iconColor,
            size: 20,
          ),
          SizedBox(width: 5),
          Text(
            displayValue,
            style: TextStyle(
              color: const Color(0xFF545454),
              fontSize: 16,
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w400,
              height: 1.50,
            ),
          ),
        ],
      ),
    );
  }
}

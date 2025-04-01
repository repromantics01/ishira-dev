import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbols.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';

const String ORGANIZATION_COLLECTION_REF = "organization";

class FirebaseOrganizationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final CollectionReference<Organization> _organizationCollectionRef;

  FirebaseOrganizationService() {
    _organizationCollectionRef = _firestore.collection(ORGANIZATION_COLLECTION_REF).withConverter<Organization>(
      fromFirestore: (snapshots, _) => Organization.fromJson(snapshots.data()!),
      toFirestore: (organization, _) => organization.toJson(),
    );
  }

  Stream <QuerySnapshot<Organization>> getOrganization() {
    return _organizationCollectionRef.snapshots();
  }


  Future<void> addOrganizationWithId(Organization organization, String orgId) async {
    try {
      await _organizationCollectionRef.doc(orgId).set(organization);
    } catch (e) {
      print('Error adding organization: $e');
    }
  }

  String generateNewOrganizationId() {
    return _organizationCollectionRef.doc().id;
  }

  Future<void> updateOrganization(String orgId, Organization updatedOrganization) async {
    try {
      final querySnapshot = await _organizationCollectionRef
          .where('org_id', isEqualTo: orgId)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.set(updatedOrganization);
      }
    } catch (e) {
      print('Error updating organization: $e');
    }
  }

  Future<String> getOrganizationId(String orgId) async {
    try {
      final querySnapshot = await _organizationCollectionRef
          .where('org_id', isEqualTo: orgId)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.reference.id;
      }
    } catch (e) {
      print('Error getting organization id: $e');
    }
    return ''; // Return an empty string or handle the error appropriately
  }

  Future<List<Organization>> getUnverifiedOrgs() async {
    try {
      final querySnapshot = await _organizationCollectionRef
          .where('isVerified', isEqualTo: false)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting unverified organizations: $e');
      return [];
    }
  }

  Future<Organization?> getOrganizationById(String orgId) async {
    try {
      final querySnapshot = await _organizationCollectionRef
          .where('org_id', isEqualTo: orgId)
          .limit(1)
          .get();
          
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      
      // If not found by org_id field, try to get directly by document ID
      final docSnapshot = await _organizationCollectionRef.doc(orgId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      
      print('Organization not found with id: $orgId');
      return null;
    } catch (e) {
      print('Error getting organization by id: $e');
      return null;
    }
  }

  Future<List<Organization>> searchOrganizations(String searchTerm) async {
    try {
      // Search term is empty, return all organizations
      if (searchTerm.isEmpty) {
        final querySnapshot = await _organizationCollectionRef.get();
        return querySnapshot.docs.map((doc) => doc.data()).toList();
      }
      
      // Convert search term to lowercase for case-insensitive search
      final term = searchTerm.toLowerCase();
      
      // Get all organizations and filter in-memory
      // Note: Firestore doesn't support direct case-insensitive search, so we fetch and filter
      final querySnapshot = await _organizationCollectionRef.get();
      return querySnapshot.docs
          .map((doc) => doc.data())
          .where((org) => 
              org.org_name.toLowerCase().contains(term) ||
              (org.location != null && org.location!.toLowerCase().contains(term)))
          .toList();
    } catch (e) {
      print('Error searching organizations: $e');
      return [];
    }
  }
  
  // New method to fetch all organizations
  Future<List<Organization>> fetchAllOrganizations() async {
    try {
      print("Beginning fetchAllOrganizations in service...");
      
      // First try to get raw data to debug
      final rawSnapshot = await _firestore.collection(ORGANIZATION_COLLECTION_REF).get();
      print("Raw collection snapshot has ${rawSnapshot.docs.length} documents");
      
      if (rawSnapshot.docs.isNotEmpty) {
        // Print the first raw document for debugging
        print("Raw document data: ${rawSnapshot.docs.first.data()}");
      }
      
      // Now use the converter for proper typing
      final querySnapshot = await _organizationCollectionRef.get();
      final organizations = querySnapshot.docs.map((doc) => doc.data()).toList();
      print('Successfully fetched ${organizations.length} organizations with converter');
      
      if (organizations.isEmpty) {
        print('No organizations found in Firestore, using mock data');
        return _getMockOrganizations();
      }
      
      return organizations;
    } catch (e) {
      print('Error fetching all organizations: $e');
      // Try a direct approach without the converter
      try {
        print("Trying direct Firestore access without converter...");
        final snapshot = await _firestore.collection(ORGANIZATION_COLLECTION_REF).get();
        
        List<Organization> organizations = [];
        for (var doc in snapshot.docs) {
          try {
            final data = doc.data();
            print("Processing document ${doc.id}");
            organizations.add(Organization.fromJson(data));
          } catch (parseError) {
            print("Error parsing organization document ${doc.id}: $parseError");
          }
        }
        
        print("Direct access fetched ${organizations.length} valid organizations");
        
        if (organizations.isEmpty) {
          return _getMockOrganizations();
        }
        
        return organizations;
      } catch (fallbackError) {
        print("Fallback also failed: $fallbackError");
        return _getMockOrganizations();
      }
    }
  }
  
  // Add mock data generator in service
  List<Organization> _getMockOrganizations() {
    print('Returning mock organization data');
    return [
      Organization(
        org_id: "mock1",
        org_name: "Happy Paws Rescue (Mock)",
        org_proof_of_validation: "proof_url",
        date_created: DateTime.now(),
        admin_ids: ["admin1"],
        isVerified: true,
        location: "Manila, Philippines",
        address: "123 Main Street, Manila",
        about: "A shelter dedicated to rescuing and rehoming abandoned pets.",
        mission: "To find loving homes for all animals in need",
        services: ["Adoption", "Rescue", "Veterinary Care"],
        weekday_hours: "9:00 AM - 5:00 PM",
        weekend_hours: "10:00 AM - 3:00 PM",
        email: "contact@happypaws.org",
        landline: "(02) 8123-4567",
        logo_url: "https://placehold.co/70x70?text=HP",
        contact_numbers: {
          "Main": "+63 912 345 6789",
          "Emergency": "+63 998 765 4321"
        },
        social_media_links: {
          "facebook": "https://facebook.com/happypaws",
          "instagram": "https://instagram.com/happypaws"
        }
      ),
      Organization(
        org_id: "mock2",
        org_name: "Second Chance Animal Shelter (Mock)",
        org_proof_of_validation: "proof_url",
        date_created: DateTime.now(),
        admin_ids: ["admin2"],
        isVerified: true,
        location: "Quezon City, Philippines",
        address: "456 Animal Road, Quezon City",
        about: "Providing care and finding homes for abandoned and surrendered animals.",
        mission: "To give every animal a second chance at happiness",
        services: ["Adoption", "Foster Care", "Animal Welfare Education"],
        weekday_hours: "8:00 AM - 6:00 PM",
        weekend_hours: "9:00 AM - 4:00 PM",
        email: "info@secondchance.org",
        landline: "(02) 8765-4321",
        logo_url: "https://placehold.co/70x70?text=SC",
        contact_numbers: {
          "Office": "+63 932 109 8765", 
          "Rescue Hotline": "+63 917 765 4321"
        },
        social_media_links: {
          "facebook": "https://facebook.com/secondchance",
          "twitter": "https://twitter.com/secondchance"
        }
      ),
    ];
  }
}
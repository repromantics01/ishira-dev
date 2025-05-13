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


Future<List<Organization>> getUnverifiedOrgs() async {
  try {
    final querySnapshot = await _organizationCollectionRef
        .where('isVerified', isEqualTo: false)
        .where('isRejected', isEqualTo: false)
        .get();
    print('Fetched ${querySnapshot.docs.length} unverified orgs');
    for (var doc in querySnapshot.docs) {
      print(doc.data());
    }
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  } catch (e) {
    print('Error getting unverified organizations: $e');
    return [];
  }
}

  Future<Organization?> getOrganizationById(String accountId) async {
    try {
      final querySnapshot = await _organizationCollectionRef
          .where('admin_ids', arrayContains: accountId)
          .limit(1)
          .get();
          
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      
      // If not found by org_id field, try to get directly by document ID
      final docSnapshot = await _organizationCollectionRef.doc(accountId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      
      print('Organization not found with id: $accountId');
      return null;
    } catch (e) {
      print('Error getting organization by id: $e');
      return null;
    }
  }

   Future<String?> getOrganizationIDById(String accountId) async {
    try {
      final querySnapshot = await _organizationCollectionRef
          .where('admin_ids', arrayContains: accountId)
          .limit(1)
          .get();
          
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      
      // If not found by org_id field, try to get directly by document ID
      final docSnapshot = await _organizationCollectionRef.doc(accountId).get();
      if (docSnapshot.exists) {
        return docSnapshot.id;
      }
      
      print('Organization not found with id: $accountId');
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
        isRejected: false, // Add field
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
        contact_numbers: [
          "+63 912 345 6789",
          "+63 998 765 4321"
        ],
        social_media_links: [
          "https://facebook.com/happypaws",
          "https://instagram.com/happypaws"
        ]
      ),
      Organization(
        org_id: "mock2",
        org_name: "Second Chance Animal Shelter (Mock)",
        org_proof_of_validation: "proof_url",
        date_created: DateTime.now(),
        admin_ids: ["admin2"],
        isVerified: true,
        isRejected: false, // Add field
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
        contact_numbers: [
          "+63 912 345 6789",
          "+63 998 765 4321"
        ],
        social_media_links: [
          "https://facebook.com/happypaws",
          "https://instagram.com/happypaws"
        ]
      ),
      // Add a rejected org for testing
      Organization(
        org_id: "mock3",
        org_name: "Rejected Organization (Mock)",
        org_proof_of_validation: "invalid_proof",
        date_created: DateTime.now(),
        admin_ids: ["admin3"],
        isVerified: false,
        isRejected: true,
        location: "Manila, Philippines",
        address: "789 Rejected Road, Manila",
        about: "This organization was rejected for verification.",
        email: "rejected@example.com",
      ),
    ];
  }
  
  // Cache organization IDs for better performance
  final Map<String, String> _orgIdCache = {};

  // Get all organizations
  Stream<List<Organization>> getOrganizations() {
    return _firestore
        .collection('organization')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                data['org_id'] = doc.id;
                return Organization.fromJson(data);
              })
              .toList();
        });
  }

  // Get organization by ID
  // Future<Organization?> getOrganizationById(String orgId) async {
  //   try {
  //     final docSnapshot = await _firestore.collection('organizations').doc(orgId).get();
  //     if (!docSnapshot.exists) {
  //       return null;
  //     }
  //     final data = docSnapshot.data()!;
  //     data['org_id'] = docSnapshot.id;
  //     return Organization.fromJson(data);
  //   } catch (e) {
  //     print('Error getting organization by ID: $e');
  //     return null;
  //   }
  // }

  // // Get organization ID by admin user ID
  // Future<String?> getOrganizationIDById(String userId) async {
  //   // Check cache first
  //   if (_orgIdCache.containsKey(userId)) {
  //     return _orgIdCache[userId];
  //   }
    
  //   try {
  //     // Query organizations where admin_ids contains the user ID
  //     final querySnapshot = await _firestore
  //         .collection('organizations')
  //         .where('admin_ids', arrayContains: userId)
  //         .limit(1)
  //         .get();

  //     if (querySnapshot.docs.isEmpty) {
  //       return null;
  //     }

  //     final orgId = querySnapshot.docs.first.id;
      
  //     // Cache the result
  //     _orgIdCache[userId] = orgId;
      
  //     return orgId;
  //   } catch (e) {
  //     print('Error getting organization ID for user $userId: $e');
  //     return null;
  //   }
  // }
  
  // // Clear cache (useful for testing)
  // void clearCache() {
  //   _orgIdCache.clear();
  // }

  // New method to get rejected organizations
  Future<List<Organization>> getRejectedOrgs() async {
    try {
      final querySnapshot = await _organizationCollectionRef
          .where('isRejected', isEqualTo: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting rejected organizations: $e');
      return [];
    }
  }
  
  // Helper method to check if an organization is accessible to a specific moderator
  // This could be extended with permission checks in the future
  Future<bool> canModerateOrganization(String moderatorId, String organizationId) async {
    try {
      // For now, all moderators can access all organizations
      // In the future, this could check for specific permissions
      return true;
    } catch (e) {
      print('Error checking moderation permissions: $e');
      return false;
    }
  }
  
  Future<List<Organization>> getOrganizationsByStatus({
    bool? isVerified,
    bool? isRejected,
  }) async {
    try {
      print('Getting organizations with filters - isVerified: $isVerified, isRejected: $isRejected');
      Query<Organization> query = _organizationCollectionRef;
      
      // Apply filters if provided
      if (isVerified != null) {
        query = query.where('isVerified', isEqualTo: isVerified);
      }
      
      if (isRejected != null) {
        query = query.where('isRejected', isEqualTo: isRejected);
      }
      
      final querySnapshot = await query.get();
      final organizations = querySnapshot.docs.map((doc) => doc.data()).toList();
      print('Found ${organizations.length} organizations matching filter criteria');
      
      // If no organizations found and we're looking for verified ones, return mock data for testing
      if (organizations.isEmpty && isVerified == true) {
        print('No verified organizations found - including mock verified orgs for testing');
        return _getMockOrganizations().where((org) => org.isVerified).toList();
      }
      
      return organizations;
    } catch (e) {
      print('Error filtering organizations: $e');
      
      // Return mock data on error for development purposes
      if (isVerified == true) {
        print('Returning mock verified organizations due to error');
        return _getMockOrganizations().where((org) => org.isVerified).toList();
      }
      
      return [];
    }
  }
}


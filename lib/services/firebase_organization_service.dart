import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> addOrganization(Organization organization) async {
    try {
      await _organizationCollectionRef.add(organization);
    } catch (e) {
      print('Error adding organization: $e');
    }
  }

  Future<int> getNextOrganizationId() async {
    try {
      final querySnapshot = await _organizationCollectionRef.get();
      return querySnapshot.docs.length + 1;
    } catch (e) {
      print('Error getting next organization ID: $e');
      return 1; // Default to 1 if there's an error
    }
  }

  Future<void> updateOrganization(int orgId, Organization updatedOrganization) async {
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
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting unverified organizations: $e');
      return [];
    }
  }
}
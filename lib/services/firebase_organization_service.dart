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
}
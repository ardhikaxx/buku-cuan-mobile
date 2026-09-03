import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/license_model.dart';
import '../../../core/services/firebase_service.dart';

class LicenseService {
  final CollectionReference _licensesCollection = FirebaseService.firestore.collection('licenses');
  final CollectionReference _usersCollection = FirebaseService.firestore.collection('users');

  Future<LicenseModel?> validateToken(String tokenKey) async {
    try {
      final query = await _licensesCollection
          .where('tokenKey', isEqualTo: tokenKey)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final license = LicenseModel.fromFirestore(query.docs.first);

      await _licensesCollection.doc(license.id).update({
        'lastValidatedAt': FieldValue.serverTimestamp(),
      });

      return license;
    } catch (e) {
      throw Exception('Gagal memvalidasi token: $e');
    }
  }

  Future<void> activateToken(String tokenKey, String userId, String workspaceId) async {
    try {
      final query = await _licensesCollection
          .where('tokenKey', isEqualTo: tokenKey)
          .limit(1)
          .get();

      if (query.docs.isEmpty) throw Exception('Token tidak ditemukan');

      final licenseDoc = query.docs.first;
      final license = LicenseModel.fromFirestore(licenseDoc);

      if (license.status == LicenseStatus.inactive) {
        throw Exception('Token telah dinonaktifkan');
      }

      DateTime? expiredAt;
      if (license.packageType == PackageType.monthly) {
        expiredAt = DateTime.now().add(const Duration(days: 30));
      }

      await _licensesCollection.doc(license.id).update({
        'userId': userId,
        'workspaceId': workspaceId,
        'status': 'active',
        'activatedAt': FieldValue.serverTimestamp(),
        if (expiredAt != null) 'expiredAt': Timestamp.fromDate(expiredAt),
        'lastValidatedAt': FieldValue.serverTimestamp(),
      });

      await _usersCollection.doc(userId).set({
        'workspaceId': workspaceId,
        'licenseId': license.id,
        'name': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal mengaktifkan token: $e');
    }
  }

  Future<LicenseModel?> getActiveLicense(String workspaceId) async {
    try {
      final query = await _licensesCollection
          .where('workspaceId', isEqualTo: workspaceId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return LicenseModel.fromFirestore(query.docs.first);
    } catch (e) {
      return null;
    }
  }

  Future<LicenseModel?> getLicenseByToken(String tokenKey) async {
    try {
      final query = await _licensesCollection
          .where('tokenKey', isEqualTo: tokenKey)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return LicenseModel.fromFirestore(query.docs.first);
    } catch (e) {
      return null;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/formatters.dart';

enum PackageType { monthly, lifetime }

enum LicenseStatus { active, expired, inactive }

class LicenseModel {
  final String id;
  final String userId;
  final String workspaceId;
  final String tokenKey;
  final PackageType packageType;
  final LicenseStatus status;
  final DateTime createdAt;
  final DateTime? activatedAt;
  final DateTime? expiredAt;
  final DateTime? lastValidatedAt;

  LicenseModel({
    required this.id,
    required this.userId,
    required this.workspaceId,
    required this.tokenKey,
    required this.packageType,
    required this.status,
    required this.createdAt,
    this.activatedAt,
    this.expiredAt,
    this.lastValidatedAt,
  });

  factory LicenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return LicenseModel(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      workspaceId: (data['workspaceId'] ?? '').toString(),
      tokenKey: (data['tokenKey'] ?? '').toString(),
      packageType: PackageType.values.firstWhere(
        (e) => e.name == data['packageType']?.toString(),
        orElse: () => PackageType.monthly,
      ),
      status: LicenseStatus.values.firstWhere(
        (e) => e.name == data['status']?.toString(),
        orElse: () => LicenseStatus.inactive,
      ),
      createdAt: SafeParser.parseDateTime(data['createdAt']),
      activatedAt: SafeParser.parseNullableDateTime(data['activatedAt']),
      expiredAt: SafeParser.parseNullableDateTime(data['expiredAt']),
      lastValidatedAt: SafeParser.parseNullableDateTime(data['lastValidatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'workspaceId': workspaceId,
      'tokenKey': tokenKey,
      'packageType': packageType.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'activatedAt': activatedAt != null ? Timestamp.fromDate(activatedAt!) : null,
      'expiredAt': expiredAt != null ? Timestamp.fromDate(expiredAt!) : null,
      'lastValidatedAt': lastValidatedAt != null ? Timestamp.fromDate(lastValidatedAt!) : null,
    };
  }

  bool get isExpired {
    if (packageType == PackageType.lifetime) return false;
    if (expiredAt == null) return false;
    return DateTime.now().isAfter(expiredAt!);
  }

  bool get isActive => status == LicenseStatus.active && !isExpired;

  int get daysRemaining {
    if (packageType == PackageType.lifetime) return 9999;
    if (expiredAt == null) return 9999;
    final diff = expiredAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}

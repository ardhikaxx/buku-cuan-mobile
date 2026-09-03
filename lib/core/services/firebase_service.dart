import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  static FirebaseFirestore get firestore => _firestore;

  static Future<void> initialize() async {
    await Firebase.initializeApp();
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  static String generateId() => _uuid.v4();

  static Timestamp now() => Timestamp.now();
}

class StorageService {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<void> saveToken(String token) async {
    final p = await prefs;
    await p.setString('activation_token', token);
  }

  static Future<String?> getToken() async {
    final p = await prefs;
    return p.getString('activation_token');
  }

  static Future<void> saveWorkspaceId(String workspaceId) async {
    final p = await prefs;
    await p.setString('workspace_id', workspaceId);
  }

  static Future<String?> getWorkspaceId() async {
    final p = await prefs;
    return p.getString('workspace_id');
  }

  static Future<void> saveUserId(String userId) async {
    final p = await prefs;
    await p.setString('user_id', userId);
  }

  static Future<String?> getUserId() async {
    final p = await prefs;
    return p.getString('user_id');
  }

  static Future<void> saveActivated(bool activated) async {
    final p = await prefs;
    await p.setBool('is_activated', activated);
  }

  static Future<bool> isActivated() async {
    final p = await prefs;
    return p.getBool('is_activated') ?? false;
  }

  static Future<void> saveUserName(String name) async {
    final p = await prefs;
    await p.setString('user_name', name);
  }

  static Future<String?> getUserName() async {
    final p = await prefs;
    return p.getString('user_name');
  }

  static Future<void> clearAll() async {
    final p = await prefs;
    await p.clear();
  }
}

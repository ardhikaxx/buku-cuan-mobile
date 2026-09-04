import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/activation/data/license_model.dart';
import '../../features/activation/data/license_service.dart';
import '../../features/categories/models/category_model.dart';
import '../../features/categories/services/category_service.dart';
import 'firebase_service.dart';

class AppProvider extends ChangeNotifier {
  final LicenseService _licenseService = LicenseService();
  final CategoryService _categoryService = CategoryService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isActivated = false;
  bool get isActivated => _isActivated;

  bool _isExpired = false;
  bool get isExpired => _isExpired;

  LicenseModel? _license;
  LicenseModel? get license => _license;

  String? _workspaceId;
  String? get workspaceId => _workspaceId;

  String? _userId;
  String? get userId => _userId;

  String? _userName;
  String? get userName => _userName;

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<List<CategoryModel>>? _categorySubscription;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isActivated = await StorageService.isActivated();
      _workspaceId = await StorageService.getWorkspaceId();
      _userId = await StorageService.getUserId();
      _userName = await StorageService.getUserName();

      if (_isActivated && _workspaceId != null) {
        await _validateLicense();
        _loadCategories();
      }
    } catch (e) {
      debugPrint('Error initializing: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> activateWithToken(String tokenKey) async {
    _isLoading = true;
    notifyListeners();

    try {
      final license = await _licenseService.validateToken(tokenKey);
      if (license == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (license.status == LicenseStatus.inactive) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final workspaceId = license.workspaceId;

      await _licenseService.activateToken(tokenKey, workspaceId);

      await StorageService.saveToken(tokenKey);
      await StorageService.saveWorkspaceId(workspaceId);
      await StorageService.saveActivated(true);

      _license = license;
      _workspaceId = workspaceId;
      _isActivated = true;
      _isExpired = false;

      await _categoryService.initializeDefaultCategories(workspaceId);
      _loadCategories();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _validateLicense() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        _isActivated = false;
        _isExpired = false;
        notifyListeners();
        return;
      }

      final license = await _licenseService.getLicenseByToken(token);
      if (license == null) {
        _isActivated = false;
        _isExpired = false;
        notifyListeners();
        return;
      }

      if (license.status == LicenseStatus.inactive) {
        _isActivated = false;
        _isExpired = false;
        notifyListeners();
        return;
      }

      _license = license;

      if (license.isExpired) {
        _isActivated = true;
        _isExpired = true;
      } else {
        _isActivated = true;
        _isExpired = false;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('License validation error: $e');
    }
  }

  void _loadCategories() {
    if (_workspaceId == null) return;
    _categorySubscription?.cancel();
    _categorySubscription = _categoryService.getCategories(_workspaceId!).listen((categories) {
      _categories = categories;
      notifyListeners();
    });
  }

  Future<void> refreshLicense() async {
    await _validateLicense();
  }

  void setOnlineStatus(bool online) {
    _isOnline = online;
    notifyListeners();
  }

  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  Future<void> logout() async {
    _categorySubscription?.cancel();
    _categorySubscription = null;
    await StorageService.clearAll();
    _isActivated = false;
    _isExpired = false;
    _workspaceId = null;
    _userId = null;
    _userName = null;
    _license = null;
    _categories = [];
    notifyListeners();
  }
}

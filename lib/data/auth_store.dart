import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

class AuthStore extends ChangeNotifier {
  static final AuthStore instance = AuthStore._();
  AuthStore._();

  static const _key = 'user_profile_v1';

  UserProfile? _currentUser;
  bool _loaded = false;
  Object? _loadError;

  UserProfile? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;
  bool get loaded => _loaded;
  Object? get loadError => _loadError;

  Future<void> load() async {
    if (_loaded) return;
    _loadError = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        _currentUser =
            UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
      _loaded = true;
      notifyListeners();
    } catch (error) {
      _loadError = error;
    }
  }

  Future<void> reload() async {
    _loaded = false;
    _currentUser = null;
    await load();
  }

  Future<UserProfile> registerManual({
    required String name,
    required String email,
    required String password,
    required String schoolLevelId,
  }) async {
    final user = UserProfile(
      name: name.trim(),
      email: email.trim(),
      password: password,
      authMethod: AuthMethod.manual,
      schoolLevelId: schoolLevelId,
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    notifyListeners();
    await _persist();
    return user;
  }

  Future<UserProfile> signUpWithGoogle({
    required String name,
    required String email,
    required String schoolLevelId,
  }) async {
    final user = UserProfile(
      name: name.trim(),
      email: email.trim(),
      authMethod: AuthMethod.google,
      schoolLevelId: schoolLevelId,
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    notifyListeners();
    await _persist();
    return user;
  }

  Future<void> updateSchool(String schoolLevelId) async {
    final user = _currentUser;
    if (user == null) return;
    _currentUser = user.copyWith(schoolLevelId: schoolLevelId);
    notifyListeners();
    await _persist();
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? password,
  }) async {
    final user = _currentUser;
    if (user == null) return;
    _currentUser = user.copyWith(
      name: name,
      email: email,
      password: password,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _currentUser;
    if (user == null) return;
    await prefs.setString(_key, jsonEncode(user.toJson()));
  }
}
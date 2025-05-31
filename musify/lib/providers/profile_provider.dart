import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define keys for SharedPreferences
const String _profileNameKey = 'profile_name';
const String _profileImagePathKey = 'profile_image_path';

class ProfileProvider with ChangeNotifier {
  String? _name;
  String? _imagePath;

  String? get name => _name;
  String? get imagePath => _imagePath;

  ProfileProvider() {
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString(_profileNameKey);
    _imagePath = prefs.getString(_profileImagePathKey);
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? imagePath}) async {
    final prefs = await SharedPreferences.getInstance();
    bool changed = false;

    if (name != null && name != _name) {
      _name = name;
      await prefs.setString(_profileNameKey, name);
      changed = true;
    }

    if (imagePath != null && imagePath != _imagePath) {
      _imagePath = imagePath;
      await prefs.setString(_profileImagePathKey, imagePath);
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }
}

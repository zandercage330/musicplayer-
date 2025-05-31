import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define keys for SharedPreferences
const String _themeModeKey = 'theme_mode';
const String _accentColorKey = 'accent_color';

// Define available accent colors (can be expanded)
// Storing hex strings for persistence, Color objects for use.
final Map<String, Color> _availableAccentColors = {
  'Teal (Default)': const Color(0xFF34D1BF),
  'Blue': Colors.blue,
  'Pink': Colors.pink,
  'Orange': Colors.orange,
  'Purple': Colors.purple,
  'Green': Colors.green,
};

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor =
      _availableAccentColors['Teal (Default)']!; // Default accent

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  Map<String, Color> get availableAccentColors => _availableAccentColors;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load ThemeMode
    final themeModeString = prefs.getString(_themeModeKey);
    if (themeModeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeModeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system; // Default
    }

    // Load AccentColor
    final accentColorHex = prefs.getString(_accentColorKey);
    if (accentColorHex != null) {
      // Find the color by its hex string (or a name if we stored names)
      // For simplicity, let's assume we stored a name that matches a key in _availableAccentColors
      // Or, if storing hex, convert hex to Color. Here, we'll assume we stored a "name" or find by value.
      _accentColor =
          _availableAccentColors.entries
              .firstWhere(
                (entry) =>
                    entry.value.value.toRadixString(16) == accentColorHex,
                orElse: () => _availableAccentColors.entries.first,
              )
              .value;
      // A more robust way if storing names:
      // _accentColor = _availableAccentColors[accentColorName] ?? _availableAccentColors['Teal (Default)']!;
    } else {
      _accentColor = _availableAccentColors['Teal (Default)']!;
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    String themeModeString = 'system';
    if (mode == ThemeMode.light) {
      themeModeString = 'light';
    } else if (mode == ThemeMode.dark) {
      themeModeString = 'dark';
    }
    await prefs.setString(_themeModeKey, themeModeString);
  }

  Future<void> setAccentColor(Color color) async {
    if (_accentColor == color) return;
    _accentColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    // Store the hex string of the color
    await prefs.setString(_accentColorKey, color.value.toRadixString(16));
  }

  // Helper to get the name of the current accent color
  String getAccentColorName(Color color) {
    return _availableAccentColors.entries
        .firstWhere(
          (entry) => entry.value == color,
          orElse: () => _availableAccentColors.entries.first,
        )
        .key;
  }
}

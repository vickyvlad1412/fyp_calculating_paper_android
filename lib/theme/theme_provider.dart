import 'package:calculating_paper/theme/theme.dart';
import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  // Initial theme is light mode
  ThemeData _themeData = lightMode;

  // Getter method to access the theme
  ThemeData get themeData => _themeData;

  // Getter method to see if we are in dark mode or not
  bool get isDarkMode => _themeData == darkMode;

  // Setter method to set the new theme
  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  // Toggle between light and dark mode
  void toggleTheme() {
    if(_themeData == lightMode) {
      themeData = darkMode;
    } else {
      themeData = lightMode;
    }
  }
}
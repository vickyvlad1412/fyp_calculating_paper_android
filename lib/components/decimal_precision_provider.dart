import 'package:flutter/material.dart';

class DecimalPrecisionProvider with ChangeNotifier {
  int _decimalPrecision = 6;

  int get decimalPrecision => _decimalPrecision;

  void updatePrecision(int precision) {
    if (precision >= 0) {
      _decimalPrecision = precision;
      notifyListeners();
    }
  }
}

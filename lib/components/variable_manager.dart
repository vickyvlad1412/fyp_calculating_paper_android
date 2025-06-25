import 'package:decimal/decimal.dart';

class VariableManager {
  final Map<int, Map<String, Decimal>> _noteVariables = {};

  // Set a variable for a specific Note ID
  void setVariable(int noteId, String key, Decimal value) {
    if (!_noteVariables.containsKey(noteId)) {
      _noteVariables[noteId] = {};
    }
    _noteVariables[noteId]![key] = value;
  }

  // Get a variable for a specific Note ID
  Decimal? getVariable(int noteId, String key) {
    return _noteVariables[noteId]?[key];
  }

  // Get all variables for a specific Note ID
  Map<String, Decimal>? getVariables(int noteId) {
    return _noteVariables[noteId];
  }
}

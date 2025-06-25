import 'package:flutter/services.dart';

class CalculationChannel {
  static const MethodChannel _channel =
  MethodChannel('calculating_paper/calculation');

  static Future<String> evaluateExpression(String expression, int precision) async {
    final arguments = {'expression': expression, 'precision': precision};
    try {
      final result = await _channel.invokeMethod<String>('evaluateExpression', arguments);
      if (result == null) throw PlatformException(code: 'NULL_RESULT', message: 'Received null result from native code.');
      return result;
    } on PlatformException catch (e) {
      throw Exception(_friendlyErrorMessage(e));
    }
  }

  static String _friendlyErrorMessage(PlatformException e) {
    switch (e.code) {
      case 'EVALUATION_ERROR':
        return 'There was an error evaluating your expression. Please check your input.';
      case 'INVALID_INPUT':
        return 'Your input was invalid. Double check the expression.';
      case 'INVALID_ARGUMENTS':
        return 'Invalid arguments. The expression cannot be evaluated.';
      default:
        return 'Unexpected error: ${e.message}';
    }
  }

}

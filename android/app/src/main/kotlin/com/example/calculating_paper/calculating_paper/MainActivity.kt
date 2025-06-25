package com.example.calculating_paper.calculating_paper

import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.math.BigDecimal
import java.math.BigDecimal.*
import java.math.MathContext
import ch.obermuhlner.math.big.BigDecimalMath
import java.util.Stack

class MainActivity : FlutterActivity() {
    private val calculationChannel = "calculating_paper/calculation"
    private lateinit var channel: MethodChannel
    private val variables = mutableMapOf<String, BigDecimal>()

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, calculationChannel)

        channel.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            if (call.method == "evaluateExpression") {
                val arguments = call.arguments as? Map<String, Any?>

                if (arguments == null) {
                    result.error("INVALID_ARGUMENTS", "Arguments are null or improperly formatted", null)
                    return@setMethodCallHandler
                }

                val expression = arguments["expression"] as? String
                val precision = arguments["precision"] as? Int

                if (!expression.isNullOrBlank() && precision != null) {
                    try {
                        val mathContext = MathContext(precision)
                        val evaluatedResult = parseExpression(expression, mathContext)
                        result.success(evaluatedResult.toString())
                    } catch (e: Exception) {
                        result.error("EVALUATION_ERROR", "Error evaluating expression: ${e.message}", null)
                    }
                } else {
                    result.error("INVALID_INPUT", "Expression or precision is null/blank", null)
                }
            }
        }
    }

    private fun parseExpression(expression: String, mathContext: MathContext): BigDecimal {
        val sanitizedExpression = if (expression.startsWith("=")) expression.substring(1) else expression
        val tokens = tokenize(sanitizedExpression)
        return evaluateTokens(tokens, mathContext)
    }

    private fun tokenize(expression: String): List<String> {
        val tokens = mutableListOf<String>()
        var currentToken = StringBuilder()

        for (char in expression) {
            when {
                char.isDigit() || char == '.' -> currentToken.append(char)
                char == 'E' && currentToken.any { it.isDigit() } -> {
                    currentToken.append(char)
                }
                (char == '+' || char == '-') &&
                        currentToken.endsWith("E") -> {
                    currentToken.append(char)
                }
                char.isLetter() -> {
                    if (currentToken.isNotEmpty() && !currentToken[0].isLetter()) {
                        tokens.add(currentToken.toString())
                        currentToken = StringBuilder()
                    }
                    currentToken.append(char)
                }
                char in "+-*÷/^()√!" || char == 'π' || char == 'e' -> {
                    if (currentToken.isNotEmpty()) {
                        tokens.add(currentToken.toString())
                        currentToken = StringBuilder()
                    }
                    tokens.add(char.toString())  // Add the operator as a token
                }
                char.isWhitespace() -> continue
                else -> throw IllegalArgumentException("Invalid character in expression: $char")
            }
        }

        if (currentToken.isNotEmpty()) tokens.add(currentToken.toString())
        return tokens
    }



    private fun evaluateTokens(tokens: List<String>, mathContext: MathContext): BigDecimal {
        val values = Stack<BigDecimal>()
        val operators = Stack<String>()

        var index = 0
        while (index < tokens.size) {
            val token = tokens[index]

            when {
                token.isNumber() -> values.push(BigDecimal(token))
                token == "π" -> values.push(BigDecimalMath.pi(mathContext))
                token == "e" -> values.push(BigDecimalMath.e(mathContext))
                token.isOperator() -> {
                    // Handle unary minus directly
                    if (token == "-" && (index == 0 || tokens[index - 1] in listOf("+", "-", "*", "÷", "/", "(", "^"))) {
                        // Next token should be a number or sub-expression
                        val nextToken = tokens.getOrNull(index + 1)
                        if (nextToken != null && nextToken.isNumber()) {
                            values.push(BigDecimal(nextToken).negate())
                            index++ // Skip the next token as it's already processed
                        } else if (nextToken == "(") {
                            operators.push("-")
                        } else {
                            throw IllegalArgumentException("Invalid use of unary minus")
                        }
                    } else {
                        while (operators.isNotEmpty() && hasPrecedence(token, operators.peek())) {
                            values.push(applyOperator(operators.pop(), values.pop(), values.pop(), mathContext))
                        }
                        operators.push(token)
                    }
                }
                token == "(" -> operators.push(token)
                token == ")" -> {
                    while (operators.peek() != "(") {
                        values.push(applyOperator(operators.pop(), values.pop(), values.pop(), mathContext))
                    }
                    operators.pop()
                }
                token == "!" -> { // Handle factorial as a postfix operator
                    if (values.isEmpty()) throw IllegalArgumentException("Invalid use of factorial (!)")

                    val value = values.pop()
                    values.push(factorial(value.toInt()))
                }
                token.isFunction() -> { // Handle functions
                    val function = token
                    index++
                    if (index >= tokens.size || tokens[index] != "(") {
                        throw IllegalArgumentException("Expected '(' after function name: $function")
                    }

                    val subExpression = mutableListOf<String>()
                    var parenthesesCount = 1
                    index++

                    while (index < tokens.size && parenthesesCount > 0) {
                        if (tokens[index] == "(") parenthesesCount++
                        else if (tokens[index] == ")") parenthesesCount--
                        if (parenthesesCount > 0) subExpression.add(tokens[index])
                        index++
                    }

                    val result = applyFunction(function, evaluateTokens(subExpression, mathContext), mathContext)
                    values.push(result)
                    continue
                }
                else -> throw IllegalArgumentException("Unknown token: $token")
            }
            index++
        }

        while (operators.isNotEmpty()) {
            values.push(applyOperator(operators.pop(), values.pop(), values.pop(), mathContext))
        }

        return values.pop()
    }




    private fun String.isNumber(): Boolean = this.toBigDecimalOrNull() != null

    private fun String.isOperator(): Boolean = this in listOf("+", "-", "*", "÷", "/", "^", "C", "P")

    private fun String.isFunction(): Boolean = this in listOf(
        "sin", "cos", "tan", "arcsin", "arccos", "arctan",
        "sinh", "cosh", "tanh", "√", "log", "ln", "exp",
    )

    private fun hasPrecedence(currentOp: String, previousOp: String): Boolean {
        val precedence = mapOf(
            "+" to 1, "-" to 1,
            "*" to 2, "÷" to 2, "/" to 2,
            "^" to 3
        )
        return (precedence[currentOp] ?: 0) <= (precedence[previousOp] ?: 0)
    }

    private fun applyOperator(op: String, b: BigDecimal, a: BigDecimal, mathContext: MathContext): BigDecimal {
        println("Applying operator: $op")

        return when (op) {
            "+" -> a.add(b, mathContext)
            "-" -> a.subtract(b, mathContext)
            "*" -> a.multiply(b, mathContext)
            "÷", "/" -> {
                if (b == BigDecimal.ZERO) {
                    throw ArithmeticException("Division by zero")
                }
                a.divide(b, mathContext)  // Handle both '÷' and '/' for division
            }
            "^" -> BigDecimalMath.pow(a, b, mathContext)
            else -> throw IllegalArgumentException("Invalid operator: $op")
        }
    }



    private fun applyFunction(function: String, value: BigDecimal, mathContext: MathContext): BigDecimal {
        return when (function) {
            "sin" -> BigDecimalMath.sin(value, mathContext)
            "cos" -> BigDecimalMath.cos(value, mathContext)
            "tan" -> BigDecimalMath.tan(value, mathContext)
            "arcsin" -> BigDecimalMath.asin(value, mathContext)
            "arccos" -> BigDecimalMath.acos(value, mathContext)
            "arctan" -> BigDecimalMath.atan(value, mathContext)
            "sinh" -> BigDecimalMath.sinh(value, mathContext)
            "cosh" -> BigDecimalMath.cosh(value, mathContext)
            "tanh" -> BigDecimalMath.tanh(value, mathContext)
            "exp" -> BigDecimalMath.exp(value, mathContext)
            "√" -> BigDecimalMath.sqrt(value, mathContext)
            "log" -> BigDecimalMath.log10(value, mathContext)
            "ln" -> BigDecimalMath.log(value, mathContext)
            else -> throw IllegalArgumentException("Unknown function: $function")
        }
    }

    private fun factorial(n: Int): BigDecimal {
        return if (n == 0 || n == 1) BigDecimal.ONE else (2..n).fold(BigDecimal.ONE) { acc, i -> acc.multiply(BigDecimal(i)) }
    }
}


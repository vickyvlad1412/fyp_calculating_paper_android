package com.example.calculation;

import java.math.BigDecimal;
import java.math.MathContext;
import java.util.ArrayList;
import java.util.List;
import java.util.Stack;

import ch.obermuhlner.math.big.BigDecimalMath;

public class ExpressionEvaluator {
    /** Entry point from C++/JNI: */
    public static String evaluate(String expr, int precision) throws Exception {
        MathContext mc = new MathContext(precision);
        BigDecimal result = parseExpression(expr.startsWith("=") ? expr.substring(1) : expr, mc);
        return result.toString();
    }

    private static BigDecimal parseExpression(String expr, MathContext mc) throws Exception {
        List<String> tokens = tokenize(expr);
        return evaluateTokens(tokens, mc);
    }

    /** Very literal port of your tokenize(...) from Kotlin */
    private static List<String> tokenize(String in) {
        List<String> out = new ArrayList<>();
        StringBuilder cur = new StringBuilder();
        for (int i = 0; i < in.length(); i++) {
            char c = in.charAt(i);
            if ((Character.isDigit(c) || c == '.') ||
                    (c == 'E' && cur.length() > 0 && Character.isDigit(cur.charAt(cur.length()-1))) ||
                    ((c == '+' || c == '-') && cur.length() >= 1 && cur.charAt(cur.length()-1) == 'E')
            ) {
                cur.append(c);
            } else if (Character.isLetter(c)) {
                if (cur.length() > 0 && !Character.isLetter(cur.charAt(0))) {
                    out.add(cur.toString());
                    cur.setLength(0);
                }
                cur.append(c);
            } else if ("+-*÷/^()√!".indexOf(c) >= 0 || c == 'π' || c == 'e') {
                if (cur.length() > 0) {
                    out.add(cur.toString());
                    cur.setLength(0);
                }
                out.add(Character.toString(c));
            } else if (Character.isWhitespace(c)) {
                // skip
            } else {
                throw new IllegalArgumentException("Invalid character in expression: " + c);
            }
        }
        if (cur.length() > 0) {
            out.add(cur.toString());
        }
        return out;
    }

    private static BigDecimal evaluateTokens(List<String> tokens, MathContext mc) throws Exception {
        Stack<BigDecimal> values = new Stack<>();
        Stack<String> ops    = new Stack<>();

        for (int i = 0; i < tokens.size(); i++) {
            String tok = tokens.get(i);

            if (isNumber(tok)) {
                values.push(new BigDecimal(tok));
            }
            else if (tok.equals("π")) {
                values.push(BigDecimalMath.pi(mc));
            }
            else if (tok.equals("e")) {
                values.push(BigDecimalMath.e(mc));
            }
            else if (isOperator(tok)) {
                // unary minus?
                if (tok.equals("-") &&
                        (i == 0 || tokens.get(i-1).equals("(") || isOperator(tokens.get(i-1)))) {
                    // attach to next number
                    if (i+1 < tokens.size() && isNumber(tokens.get(i+1))) {
                        values.push(new BigDecimal(tokens.get(++i)).negate(mc));
                        continue;
                    }
                }
                while (!ops.isEmpty() && precedence(ops.peek()) >= precedence(tok)) {
                    String op = ops.pop();
                    BigDecimal b = values.pop();
                    BigDecimal a = values.pop();
                    values.push(applyOperator(op,a,b,mc));
                }
                ops.push(tok);
            }
            else if (tok.equals("(")) {
                ops.push(tok);
            }
            else if (tok.equals(")")) {
                while (!ops.peek().equals("(")) {
                    String op = ops.pop();
                    BigDecimal b = values.pop();
                    BigDecimal a = values.pop();
                    values.push(applyOperator(op,a,b,mc));
                }
                ops.pop(); // discard "("
            }
            else if (tok.equals("!")) {
                BigDecimal v = values.pop();
                values.push(factorial(v.intValue()));
            }
            else if (isFunction(tok)) {
                // grab sub‐expression in parentheses
                i++;
                if (i >= tokens.size() || !tokens.get(i).equals("("))
                    throw new IllegalArgumentException("Expected '(' after function " + tok);
                int depth = 1;
                List<String> sub = new ArrayList<>();
                while (++i < tokens.size() && depth > 0) {
                    String t = tokens.get(i);
                    if (t.equals("(")) depth++;
                    else if (t.equals(")")) depth--;
                    if (depth > 0) sub.add(t);
                }
                BigDecimal r = evaluateTokens(sub, mc);
                values.push(applyFunction(tok, r, mc));
            }
            else {
                throw new IllegalArgumentException("Unknown token: " + tok);
            }
        }

        while (!ops.isEmpty()) {
            String op = ops.pop();
            BigDecimal b = values.pop();
            BigDecimal a = values.pop();
            values.push(applyOperator(op,a,b,mc));
        }
        return values.pop();
    }

    private static boolean isNumber(String t) {
        try {
            new BigDecimal(t);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
    private static boolean isOperator(String t) {
        return "+-*/÷^".contains(t);
    }
    private static boolean isFunction(String t) {
        switch(t) {
            case "sin": case "cos": case "tan":
            case "arcsin": case "arccos": case "arctan":
            case "sinh": case "cosh": case "tanh":
            case "log": case "ln": case "exp":
            case "√":
                return true;
            default:
                return false;
        }
    }
    private static int precedence(String op) {
        if (op.equals("+")||op.equals("-")) return 1;
        if (op.equals("*")||op.equals("/")||op.equals("÷")) return 2;
        if (op.equals("^")) return 3;
        return 0;
    }

    private static BigDecimal applyOperator(String op, BigDecimal a, BigDecimal b, MathContext mc) {
        switch(op) {
            case "+":  return a.add(b, mc);
            case "-":  return a.subtract(b, mc);
            case "*":  return a.multiply(b, mc);
            case "/":  // fall‐through
            case "÷":  return a.divide(b, mc);
            case "^":  return BigDecimalMath.pow(a, b, mc);
            default:   throw new IllegalArgumentException("Bad operator: " + op);
        }
    }
    private static BigDecimal applyFunction(String fn, BigDecimal v, MathContext mc) {
        switch(fn) {
            case "sin":    return BigDecimalMath.sin(v, mc);
            case "cos":    return BigDecimalMath.cos(v, mc);
            case "tan":    return BigDecimalMath.tan(v, mc);
            case "arcsin": return BigDecimalMath.asin(v, mc);
            case "arccos": return BigDecimalMath.acos(v, mc);
            case "arctan": return BigDecimalMath.atan(v, mc);
            case "sinh":   return BigDecimalMath.sinh(v, mc);
            case "cosh":   return BigDecimalMath.cosh(v, mc);
            case "tanh":   return BigDecimalMath.tanh(v, mc);
            case "log":    return BigDecimalMath.log10(v, mc);
            case "ln":     return BigDecimalMath.log(v, mc);
            case "exp":    return BigDecimalMath.exp(v, mc);
            case "√":      return BigDecimalMath.sqrt(v, mc);
            default:       throw new IllegalArgumentException("Unknown function: " + fn);
        }
    }
    private static BigDecimal factorial(int n) {
        if (n < 0) throw new IllegalArgumentException("Negative factorial");
        BigDecimal res = BigDecimal.ONE;
        for (int i = 2; i <= n; i++) {
            res = res.multiply(new BigDecimal(i));
        }
        return res;
    }
}

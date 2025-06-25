#pragma once
#include <string>
#include <vector>
#include <stack>
#include <boost/multiprecision/cpp_dec_float.hpp>
#include <boost/math/constants/constants.hpp>

// Use a decimal type with user‐controlled precision:
using BigDec = boost::multiprecision::number<
boost::multiprecision::cpp_dec_float<50>>;

struct EvalResult {
    BigDec value;
    bool   isError;
    std::string errMsg;
};

class ExpressionEvaluator {
public:
    // precision = number of decimal digits
    static EvalResult evaluate(const std::string& expr, unsigned precision);

private:
    static std::vector<std::string> tokenize(const std::string&);
    static BigDec parseExpression(const std::string&, unsigned prec);
    static BigDec evaluateTokens(const std::vector<std::string>&, unsigned prec);

    // helpers
    static bool isNumber(const std::string&);
    static bool isOperator(const std::string&);
    static bool isFunction(const std::string&);
    static int  precedence(const std::string&);
    static BigDec applyOperator(const std::string&, BigDec a, BigDec b, unsigned prec);
    static BigDec applyFunction(const std::string&, BigDec, unsigned prec);
    static BigDec factorial(int n);
};

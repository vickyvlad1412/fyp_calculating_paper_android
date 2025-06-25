#include "expression_evaluator.h"
#include <regex>
#include <stdexcept>
#include <boost/math/constants/constants.hpp>
#include <boost/math/special_functions/factorials.hpp>
#include <boost/math/special_functions/pow.hpp>

using boost::multiprecision::cpp_dec_float;

// Entry point:
EvalResult ExpressionEvaluator::evaluate(const std::string& expr, unsigned prec) {
    try {
        BigDec::default_precision(prec);
        BigDec result = parseExpression(expr, prec);
        return { result, false, "" };
    } catch (std::exception& e) {
        return { BigDec(0), true, e.what() };
    }
}

// Strip leading '=' and run:
BigDec ExpressionEvaluator::parseExpression(const std::string& expr, unsigned prec) {
    std::string s = expr;
    if (!s.empty() && s.front()=='=') s.erase(0,1);
    auto tokens = tokenize(s);
    return evaluateTokens(tokens, prec);
}

// **Tokenizer**: digits, decimal, E-exponents, letters, operators exactly like your Kotlin
std::vector<std::string> ExpressionEvaluator::tokenize(const std::string& in) {
    std::vector<std::string> out;
    std::string cur;
    auto pushCur=[&](){
        if(!cur.empty()){ out.push_back(cur); cur.clear(); }
    };
    for(size_t i=0;i<in.size();++i){
        char c=in[i];
        if((c>='0' && c<='9')||c=='.'||
           (c=='E' && !cur.empty() && std::isdigit(cur.back())) ||
           ((c=='+'||c=='-') && cur.size()>=1 && cur.back()=='E')
                ){
            cur.push_back(c);
        } else if(std::isalpha(c)){
            if(!cur.empty() && !std::isalpha(cur[0])){
                pushCur();
            }
            cur.push_back(c);
        } else if(std::string("+-*/÷^()√!").find(c)!=std::string::npos
                  || c=='π' || c=='e')
        {
            pushCur();
            out.push_back(std::string(1,c));
        } else if(std::isspace(c)) {
            continue;
        } else {
            throw std::invalid_argument(std::string("Invalid char: ")+c);
        }
    }
    pushCur();
    return out;
}

// Check numeric:
bool ExpressionEvaluator::isNumber(const std::string& t) {
    std::stringstream ss(t);
    cpp_dec_float<> x;
    return (ss >> x) ? true : false;
}
bool ExpressionEvaluator::isOperator(const std::string& t) {
    return t=="+"||t=="-"||t=="*"||t=="/"||t=="÷"||t=="^";
}
bool ExpressionEvaluator::isFunction(const std::string& t) {
    static const std::vector<std::string> f={
            "sin","cos","tan","arcsin","arccos","arctan",
            "sinh","cosh","tanh","√","log","ln","exp"
    };
    return std::find(f.begin(),f.end(),t)!=f.end();
}
int ExpressionEvaluator::precedence(const std::string& op){
    if(op=="+"||op=="-") return 1;
    if(op=="*"||op=="/"||op=="÷") return 2;
    if(op=="^") return 3;
    return 0;
}

// Core Shunting-Yard + RPN evaluation:
BigDec ExpressionEvaluator::evaluateTokens(
        const std::vector<std::string>& tokens, unsigned prec) {
    std::stack<BigDec> vals;
    std::stack<std::string> ops;
    for(size_t i=0;i<tokens.size();++i){
        const auto &tok = tokens[i];
        if(isNumber(tok)) {
            vals.push(BigDec(tok));
        }
        else if(tok=="π") {
            vals.push(boost::math::constants::pi<BigDec>());
        }
        else if(tok=="e") {
            vals.push(boost::math::constants::e<BigDec>());
        }
        else if(isOperator(tok)){
            // unary minus?
            if(tok=="-" && (i==0 || tokens[i-1]=="("||isOperator(tokens[i-1]))){
                // attach to next number
                if(i+1< tokens.size() && isNumber(tokens[i+1])){
                    vals.push(-BigDec(tokens[++i]));
                    continue;
                }
            }
            while(!ops.empty() && precedence(ops.top())>=precedence(tok)){
                auto b=vals.top(); vals.pop();
                auto a=vals.top(); vals.pop();
                auto op=ops.top(); ops.pop();
                vals.push(applyOperator(op,a,b,prec));
            }
            ops.push(tok);
        }
        else if(tok=="(") {
            ops.push(tok);
        }
        else if(tok==")"){
            while(!ops.empty() && ops.top()!="("){
                auto b=vals.top(); vals.pop();
                auto a=vals.top(); vals.pop();
                auto op=ops.top(); ops.pop();
                vals.push(applyOperator(op,a,b,prec));
            }
            if(ops.top()=="(") ops.pop();
        }
        else if(tok=="!"){
            auto v=vals.top(); vals.pop();
            vals.push(factorial((int) v.convert_to<int>()));
        }
        else if(isFunction(tok)){
            // expect "(" then sub-expression, exactly like Kotlin
            i++; // skip function name
            if(i>=tokens.size()||tokens[i]!="(") throw std::invalid_argument("Expected (");
            int depth=1;
            std::vector<std::string> sub;
            while(++i<tokens.size() && depth){
                if(tokens[i]=="(") depth++;
                else if(tokens[i]==")") depth--;
                if(depth) sub.push_back(tokens[i]);
            }
            auto r = evaluateTokens(sub,prec);
            vals.push(applyFunction(tok,r,prec));
        }
        else {
            throw std::invalid_argument("Unknown token: "+tok);
        }
    }
    while(!ops.empty()){
        auto b=vals.top(); vals.pop();
        auto a=vals.top(); vals.pop();
        auto op=ops.top(); ops.pop();
        vals.push(applyOperator(op,a,b,prec));
    }
    return vals.top();
}

// Arithmetic ops:
BigDec ExpressionEvaluator::applyOperator(
        const std::string& op, BigDec a, BigDec b, unsigned prec) {
    BigDec::default_precision(prec);
    if(op=="+") return a + b;
    if(op=="-") return a - b;
    if(op=="*" ) return a * b;
    if(op=="/" || op=="÷") {
        if(b==0) throw std::overflow_error("Division by zero");
        return a / b;
    }
    if(op=="^") {
        using boost::math::pow;
        return pow(a,b);
    }
    throw std::invalid_argument("Bad op "+op);
}

// Transcendentals:
BigDec ExpressionEvaluator::applyFunction(
        const std::string& fn, BigDec v, unsigned prec) {
    BigDec::default_precision(prec);
    using boost::math::sin; using boost::math::cos; using boost::math::tan;
    using boost::math::asin; using boost::math::acos; using boost::math::atan;
    using boost::math::sinh; using boost::math::cosh; using boost::math::tanh;
    using boost::math::exp; using boost::math::log; using boost::math::log10;
    if(fn=="sin")    return sin(v);
    if(fn=="cos")    return cos(v);
    if(fn=="tan")    return tan(v);
    if(fn=="arcsin") return asin(v);
    if(fn=="arccos") return acos(v);
    if(fn=="arctan") return atan(v);
    if(fn=="sinh")   return sinh(v);
    if(fn=="cosh")   return cosh(v);
    if(fn=="tanh")   return tanh(v);
    if(fn=="exp")    return exp(v);
    if(fn=="√")      return sqrt(v);
    if(fn=="log")    return log10(v);
    if(fn=="ln")     return log(v);
    throw std::invalid_argument("Unknown fn "+fn);
}

// Factorial via Boost:
BigDec ExpressionEvaluator::factorial(int n){
    return boost::math::factorial<BigDec>(n);
}

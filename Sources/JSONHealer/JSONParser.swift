import Foundation

public class JSONParser {
    private let input: String
    private var position: Int = 0
    private var line: Int = 1
    private var column: Int = 1
    private var errors: [JSONError] = []
    
    public init(_ input: String) {
        self.input = input
    }
    
    public func parse() -> JSONDiagnostic {
        position = 0
        line = 1
        column = 1
        errors = []
        
        skipWhitespace()
        
        if position >= input.count {
            let error = JSONError(
                type: .unexpectedEnd,
                position: currentPosition(),
                message: "JSON 文本为空"
            )
            errors.append(error)
            return createDiagnostic(isValid: false, healthStatus: .fatal)
        }
        
        do {
            _ = try parseValue()
            skipWhitespace()
            
            if position < input.count {
                let remaining = String(input.suffix(from: input.index(input.startIndex, offsetBy: position)))
                let error = JSONError(
                    type: .invalidCharacter,
                    position: currentPosition(),
                    message: "JSON 解析完成后还有额外的字符",
                    context: String(remaining.prefix(20))
                )
                errors.append(error)
            }
        } catch {
            if let jsonError = error as? JSONError {
                errors.append(jsonError)
            } else {
                let unknownError = JSONError(
                    type: .invalidCharacter,
                    position: currentPosition(),
                    message: "未知解析错误: \(error.localizedDescription)"
                )
                errors.append(unknownError)
            }
        }
        
        let isValid = errors.isEmpty
        let healthStatus: JSONHealthStatus = {
            if errors.isEmpty { return .healthy }
            if errors.contains(where: { $0.type == .unexpectedEnd || $0.type == .unmatchedBrackets }) {
                return .fatal
            }
            if errors.count > 5 { return .critical }
            return .warning
        }()
        
        return createDiagnostic(isValid: isValid, healthStatus: healthStatus)
    }
    
    private func createDiagnostic(isValid: Bool, healthStatus: JSONHealthStatus) -> JSONDiagnostic {
        return JSONDiagnostic(
            originalJSON: input,
            isValid: isValid,
            healthStatus: healthStatus,
            errors: errors,
            repairSuggestions: [],
            repairedJSON: nil,
            repairSummary: nil
        )
    }
    
    private func parseValue() throws -> Any {
        skipWhitespace()
        
        guard position < input.count else {
            throw JSONError(
                type: .unexpectedEnd,
                position: currentPosition(),
                message: "期望值但遇到文件结束"
            )
        }
        
        let char = input[input.index(input.startIndex, offsetBy: position)]
        
        switch char {
        case "\"":
            return try parseString()
        case "{":
            return try parseObject()
        case "[":
            return try parseArray()
        case "t", "f":
            return try parseBoolean()
        case "n":
            return try parseNull()
        case "-", "0"..."9":
            return try parseNumber()
        case "'":
            throw JSONError(
                type: .singleQuotes,
                position: currentPosition(),
                message: "发现单引号，JSON 只支持双引号",
                context: String(char)
            )
        case "/":
            if position + 1 < input.count {
                let nextChar = input[input.index(input.startIndex, offsetBy: position + 1)]
                if nextChar == "/" || nextChar == "*" {
                    throw JSONError(
                        type: .commentFound,
                        position: currentPosition(),
                        message: "JSON 不支持注释",
                        context: "/\(nextChar)"
                    )
                }
            }
            fallthrough
        default:
            throw JSONError(
                type: .invalidCharacter,
                position: currentPosition(),
                message: "无效的字符 '\(char)'",
                context: String(char)
            )
        }
    }
    
    private func parseString() throws -> String {
        guard consumeCharacter("\"") else {
            throw JSONError(
                type: .missingQuotes,
                position: currentPosition(),
                message: "期望双引号开始字符串"
            )
        }
        
        var result = ""
        
        while position < input.count {
            let char = input[input.index(input.startIndex, offsetBy: position)]
            
            if char == "\"" {
                advance()
                return result
            } else if char == "\\" {
                advance()
                if position >= input.count {
                    throw JSONError(
                        type: .invalidEscape,
                        position: currentPosition(),
                        message: "不完整的转义序列"
                    )
                }
                
                let escapeChar = input[input.index(input.startIndex, offsetBy: position)]
                advance()
                
                switch escapeChar {
                case "\"", "\\", "/":
                    result.append(escapeChar)
                case "b":
                    result.append("\u{0008}")
                case "f":
                    result.append("\u{000C}")
                case "n":
                    result.append("\n")
                case "r":
                    result.append("\r")
                case "t":
                    result.append("\t")
                case "u":
                    let unicode = try parseUnicodeEscape()
                    result.append(Character(UnicodeScalar(unicode)!))
                default:
                    throw JSONError(
                        type: .invalidEscape,
                        position: currentPosition(),
                        message: "无效的转义字符 '\(escapeChar)'"
                    )
                }
            } else if char.isASCII && char.asciiValue! < 32 {
                throw JSONError(
                    type: .invalidCharacter,
                    position: currentPosition(),
                    message: "字符串中包含未转义的控制字符"
                )
            } else {
                result.append(char)
                advance()
            }
        }
        
        throw JSONError(
            type: .missingQuotes,
            position: currentPosition(),
            message: "字符串未正确结束，缺少结束引号"
        )
    }
    
    private func parseUnicodeEscape() throws -> Int {
        var unicode = 0
        for _ in 0..<4 {
            guard position < input.count else {
                throw JSONError(
                    type: .invalidUnicode,
                    position: currentPosition(),
                    message: "不完整的 Unicode 转义序列"
                )
            }
            
            let char = input[input.index(input.startIndex, offsetBy: position)]
            advance()
            
            if let digit = char.hexDigitValue {
                unicode = unicode * 16 + digit
            } else {
                throw JSONError(
                    type: .invalidUnicode,
                    position: currentPosition(),
                    message: "Unicode 转义序列中包含无效字符 '\(char)'"
                )
            }
        }
        return unicode
    }
    
    private func parseObject() throws -> [String: Any] {
        guard consumeCharacter("{") else {
            throw JSONError(
                type: .invalidCharacter,
                position: currentPosition(),
                message: "期望 '{' 开始对象"
            )
        }
        
        var object: [String: Any] = [:]
        var keys: Set<String> = []
        skipWhitespace()
        
        if position < input.count && input[input.index(input.startIndex, offsetBy: position)] == "}" {
            advance()
            return object
        }
        
        while true {
            skipWhitespace()
            
            guard position < input.count else {
                throw JSONError(
                    type: .unexpectedEnd,
                    position: currentPosition(),
                    message: "对象未正确结束，缺少 '}'"
                )
            }
            
            if input[input.index(input.startIndex, offsetBy: position)] == "}" {
                advance()
                return object
            }
            
            let keyStart = position
            let key: String
            let currentChar = input[input.index(input.startIndex, offsetBy: position)]
            
            if currentChar == "\"" {
                key = try parseString()
            } else if currentChar.isLetter || currentChar == "_" {
                key = try parseUnquotedKey()
                throw JSONError(
                    type: .unquotedKey,
                    position: JSONPosition(line: line, column: column - key.count, offset: keyStart),
                    message: "对象键名必须用双引号包围",
                    context: key
                )
            } else {
                throw JSONError(
                    type: .invalidCharacter,
                    position: currentPosition(),
                    message: "期望对象键名"
                )
            }
            
            if keys.contains(key) {
                throw JSONError(
                    type: .duplicateKey,
                    position: currentPosition(),
                    message: "重复的键名 '\(key)'"
                )
            }
            keys.insert(key)
            
            skipWhitespace()
            
            guard consumeCharacter(":") else {
                throw JSONError(
                    type: .invalidCharacter,
                    position: currentPosition(),
                    message: "期望 ':' 分隔键值对"
                )
            }
            
            let value = try parseValue()
            object[key] = value
            
            skipWhitespace()
            
            guard position < input.count else {
                throw JSONError(
                    type: .unexpectedEnd,
                    position: currentPosition(),
                    message: "对象未正确结束，缺少 '}'"
                )
            }
            
            let nextChar = input[input.index(input.startIndex, offsetBy: position)]
            if nextChar == "}" {
                continue
            } else if nextChar == "," {
                advance()
                skipWhitespace()
                
                if position < input.count && input[input.index(input.startIndex, offsetBy: position)] == "}" {
                    throw JSONError(
                        type: .trailingComma,
                        position: currentPosition(),
                        message: "对象末尾多余的逗号"
                    )
                }
            } else {
                throw JSONError(
                    type: .missingComma,
                    position: currentPosition(),
                    message: "期望 ',' 或 '}'"
                )
            }
        }
    }
    
    private func parseUnquotedKey() throws -> String {
        var key = ""
        while position < input.count {
            let char = input[input.index(input.startIndex, offsetBy: position)]
            if char.isLetter || char.isNumber || char == "_" {
                key.append(char)
                advance()
            } else {
                break
            }
        }
        return key
    }
    
    private func parseArray() throws -> [Any] {
        guard consumeCharacter("[") else {
            throw JSONError(
                type: .invalidCharacter,
                position: currentPosition(),
                message: "期望 '[' 开始数组"
            )
        }
        
        var array: [Any] = []
        skipWhitespace()
        
        if position < input.count && input[input.index(input.startIndex, offsetBy: position)] == "]" {
            advance()
            return array
        }
        
        while true {
            let value = try parseValue()
            array.append(value)
            
            skipWhitespace()
            
            guard position < input.count else {
                throw JSONError(
                    type: .unexpectedEnd,
                    position: currentPosition(),
                    message: "数组未正确结束，缺少 ']'"
                )
            }
            
            let nextChar = input[input.index(input.startIndex, offsetBy: position)]
            if nextChar == "]" {
                advance()
                return array
            } else if nextChar == "," {
                advance()
                skipWhitespace()
                
                if position < input.count && input[input.index(input.startIndex, offsetBy: position)] == "]" {
                    throw JSONError(
                        type: .trailingComma,
                        position: currentPosition(),
                        message: "数组末尾多余的逗号"
                    )
                }
            } else {
                throw JSONError(
                    type: .missingComma,
                    position: currentPosition(),
                    message: "期望 ',' 或 ']'"
                )
            }
        }
    }
    
    private func parseBoolean() throws -> Bool {
        if consumeString("true") {
            return true
        } else if consumeString("false") {
            return false
        } else {
            throw JSONError(
                type: .invalidLiteral,
                position: currentPosition(),
                message: "无效的布尔值"
            )
        }
    }
    
    private func parseNull() throws -> NSNull {
        if consumeString("null") {
            return NSNull()
        } else {
            throw JSONError(
                type: .invalidLiteral,
                position: currentPosition(),
                message: "无效的 null 值"
            )
        }
    }
    
    private func parseNumber() throws -> NSNumber {
        let start = position
        
        if consumeCharacter("-") {
        }
        
        guard position < input.count else {
            throw JSONError(
                type: .invalidNumber,
                position: currentPosition(),
                message: "不完整的数字"
            )
        }
        
        let currentChar = input[input.index(input.startIndex, offsetBy: position)]
        if currentChar == "0" {
            advance()
        } else if currentChar.isNumber {
            while position < input.count && input[input.index(input.startIndex, offsetBy: position)].isNumber {
                advance()
            }
        } else {
            throw JSONError(
                type: .invalidNumber,
                position: currentPosition(),
                message: "无效的数字格式"
            )
        }
        
        if position < input.count && input[input.index(input.startIndex, offsetBy: position)] == "." {
            advance()
            guard position < input.count && input[input.index(input.startIndex, offsetBy: position)].isNumber else {
                throw JSONError(
                    type: .invalidNumber,
                    position: currentPosition(),
                    message: "小数点后必须有数字"
                )
            }
            
            while position < input.count && input[input.index(input.startIndex, offsetBy: position)].isNumber {
                advance()
            }
        }
        
        if position < input.count {
            let char = input[input.index(input.startIndex, offsetBy: position)]
            if char == "e" || char == "E" {
                advance()
                
                if position < input.count {
                    let signChar = input[input.index(input.startIndex, offsetBy: position)]
                    if signChar == "+" || signChar == "-" {
                        advance()
                    }
                }
                
                guard position < input.count && input[input.index(input.startIndex, offsetBy: position)].isNumber else {
                    throw JSONError(
                        type: .invalidNumber,
                        position: currentPosition(),
                        message: "指数部分必须有数字"
                    )
                }
                
                while position < input.count && input[input.index(input.startIndex, offsetBy: position)].isNumber {
                    advance()
                }
            }
        }
        
        let numberString = String(input[input.index(input.startIndex, offsetBy: start)..<input.index(input.startIndex, offsetBy: position)])
        
        if let double = Double(numberString) {
            if double.truncatingRemainder(dividingBy: 1) == 0 && double >= Double(Int.min) && double <= Double(Int.max) {
                return NSNumber(value: Int(double))
            } else {
                return NSNumber(value: double)
            }
        } else {
            throw JSONError(
                type: .invalidNumber,
                position: currentPosition(),
                message: "无法解析数字 '\(numberString)'"
            )
        }
    }
    
    private func skipWhitespace() {
        while position < input.count {
            let char = input[input.index(input.startIndex, offsetBy: position)]
            if char.isWhitespace {
                advance()
            } else {
                break
            }
        }
    }
    
    private func consumeCharacter(_ expected: Character) -> Bool {
        guard position < input.count else { return false }
        
        let char = input[input.index(input.startIndex, offsetBy: position)]
        if char == expected {
            advance()
            return true
        }
        return false
    }
    
    private func consumeString(_ expected: String) -> Bool {
        guard position + expected.count <= input.count else { return false }
        
        let startIndex = input.index(input.startIndex, offsetBy: position)
        let endIndex = input.index(startIndex, offsetBy: expected.count)
        let substring = String(input[startIndex..<endIndex])
        
        if substring == expected {
            for _ in 0..<expected.count {
                advance()
            }
            return true
        }
        return false
    }
    
    private func advance() {
        guard position < input.count else { return }
        
        let char = input[input.index(input.startIndex, offsetBy: position)]
        position += 1
        
        if char == "\n" {
            line += 1
            column = 1
        } else {
            column += 1
        }
    }
    
    private func currentPosition() -> JSONPosition {
        return JSONPosition(line: line, column: column, offset: position)
    }
}
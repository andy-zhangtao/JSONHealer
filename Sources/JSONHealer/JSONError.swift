import Foundation

public struct JSONPosition: Equatable, Codable {
    public let line: Int
    public let column: Int
    public let offset: Int
    
    public init(line: Int, column: Int, offset: Int) {
        self.line = line
        self.column = column
        self.offset = offset
    }
}

public enum JSONErrorType: String, CaseIterable, Codable {
    case missingQuotes = "missing_quotes"
    case singleQuotes = "single_quotes"
    case unquotedKey = "unquoted_key"
    case trailingComma = "trailing_comma"
    case missingComma = "missing_comma"
    case unmatchedBrackets = "unmatched_brackets"
    case invalidCharacter = "invalid_character"
    case commentFound = "comment_found"
    case invalidEscape = "invalid_escape"
    case invalidNumber = "invalid_number"
    case invalidLiteral = "invalid_literal"
    case unexpectedEnd = "unexpected_end"
    case duplicateKey = "duplicate_key"
    case invalidUnicode = "invalid_unicode"
    
    public var localizedDescription: String {
        switch self {
        case .missingQuotes:
            return "字符串缺少双引号"
        case .singleQuotes:
            return "使用了单引号，JSON 只支持双引号"
        case .unquotedKey:
            return "对象键名没有用引号包围"
        case .trailingComma:
            return "多余的逗号"
        case .missingComma:
            return "缺少逗号分隔符"
        case .unmatchedBrackets:
            return "括号不匹配"
        case .invalidCharacter:
            return "无效字符"
        case .commentFound:
            return "JSON 不支持注释"
        case .invalidEscape:
            return "无效的转义序列"
        case .invalidNumber:
            return "无效的数字格式"
        case .invalidLiteral:
            return "无效的字面量"
        case .unexpectedEnd:
            return "意外的文件结束"
        case .duplicateKey:
            return "重复的键名"
        case .invalidUnicode:
            return "无效的 Unicode 转义"
        }
    }
}

public struct JSONError: Error, Equatable, Codable {
    public let type: JSONErrorType
    public let position: JSONPosition
    public let message: String
    public let context: String?
    
    public init(type: JSONErrorType, position: JSONPosition, message: String, context: String? = nil) {
        self.type = type
        self.position = position
        self.message = message
        self.context = context
    }
    
    public var localizedDescription: String {
        let contextStr = context.map { " (\($0))" } ?? ""
        return "\(type.localizedDescription): \(message) 在第 \(position.line) 行，第 \(position.column) 列\(contextStr)"
    }
}
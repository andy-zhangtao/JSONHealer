// MARK: - Main Library Export

@_exported import Foundation

// MARK: - Core Types
public typealias JSONHealerError = JSONError
public typealias JSONHealerPosition = JSONPosition
public typealias JSONHealerDiagnostic = JSONDiagnostic
public typealias JSONHealerSuggestion = JSONRepairSuggestion

// MARK: - JSONHealer Options

public struct JSONHealerOptions {
    public let autoRepairQuotes: Bool
    public let autoRepairTrailingCommas: Bool
    public let autoRepairUnquotedKeys: Bool
    public let removeComments: Bool
    public let autoRepairSingleQuotes: Bool
    public let maxRepairAttempts: Int
    
    public init(
        autoRepairQuotes: Bool = true,
        autoRepairTrailingCommas: Bool = true,
        autoRepairUnquotedKeys: Bool = true,
        removeComments: Bool = true,
        autoRepairSingleQuotes: Bool = true,
        maxRepairAttempts: Int = 10
    ) {
        self.autoRepairQuotes = autoRepairQuotes
        self.autoRepairTrailingCommas = autoRepairTrailingCommas
        self.autoRepairUnquotedKeys = autoRepairUnquotedKeys
        self.removeComments = removeComments
        self.autoRepairSingleQuotes = autoRepairSingleQuotes
        self.maxRepairAttempts = maxRepairAttempts
    }
    
    public static let `default` = JSONHealerOptions()
    public static let conservative = JSONHealerOptions(
        autoRepairQuotes: true,
        autoRepairTrailingCommas: true,
        autoRepairUnquotedKeys: false,
        removeComments: false,
        autoRepairSingleQuotes: false,
        maxRepairAttempts: 5
    )
    public static let aggressive = JSONHealerOptions(
        autoRepairQuotes: true,
        autoRepairTrailingCommas: true,
        autoRepairUnquotedKeys: true,
        removeComments: true,
        autoRepairSingleQuotes: true,
        maxRepairAttempts: 15
    )
}

// MARK: - Main JSONHealer Class

public class JSONHealer {
    private let options: JSONHealerOptions
    
    public init(options: JSONHealerOptions = .default) {
        self.options = options
    }
    
    /// 诊断 JSON 字符串，返回详细的健康报告
    /// - Parameter jsonString: 要诊断的 JSON 字符串
    /// - Returns: 包含错误信息和修复建议的诊断结果
    public func diagnose(_ jsonString: String) -> JSONDiagnostic {
        let parser = JSONParser(jsonString)
        let initialDiagnostic = parser.parse()
        
        if initialDiagnostic.isValid {
            return initialDiagnostic
        }
        
        let repairSuggestions = generateRepairSuggestions(for: initialDiagnostic.errors, in: jsonString)
        
        var repairedJSON: String? = nil
        var repairSummary: String? = nil
        
        if !repairSuggestions.isEmpty {
            let repairResult = attemptRepair(jsonString, with: repairSuggestions)
            repairedJSON = repairResult.repairedJSON
            repairSummary = repairResult.summary
        }
        
        return JSONDiagnostic(
            originalJSON: jsonString,
            isValid: initialDiagnostic.isValid,
            healthStatus: initialDiagnostic.healthStatus,
            errors: initialDiagnostic.errors,
            repairSuggestions: repairSuggestions,
            repairedJSON: repairedJSON,
            repairSummary: repairSummary
        )
    }
    
    /// 治愈 JSON 字符串（diagnose 的别名）
    /// - Parameter jsonString: 要治愈的 JSON 字符串
    /// - Returns: 包含修复结果的诊断报告
    public func heal(_ jsonString: String) -> JSONDiagnostic {
        return diagnose(jsonString)
    }
    
    /// 快速检查 JSON 是否有效
    /// - Parameter jsonString: 要检查的 JSON 字符串
    /// - Returns: JSON 是否有效
    public func isValid(_ jsonString: String) -> Bool {
        return diagnose(jsonString).isValid
    }
    
    /// 尝试快速修复 JSON，返回修复后的字符串
    /// - Parameter jsonString: 要修复的 JSON 字符串
    /// - Returns: 修复后的 JSON 字符串，如果无法修复则返回 nil
    public func quickRepair(_ jsonString: String) -> String? {
        return diagnose(jsonString).repairedJSON
    }
    
    // MARK: - Private Implementation
    
    private func generateRepairSuggestions(for errors: [JSONError], in jsonString: String) -> [JSONRepairSuggestion] {
        var suggestions: [JSONRepairSuggestion] = []
        
        for error in errors {
            switch error.type {
            case .trailingComma:
                if options.autoRepairTrailingCommas {
                    suggestions.append(createTrailingCommaSuggestion(for: error, in: jsonString))
                }
                
            case .singleQuotes:
                if options.autoRepairSingleQuotes {
                    suggestions.append(createSingleQuotesSuggestion(for: error, in: jsonString))
                }
                
            case .unquotedKey:
                if options.autoRepairUnquotedKeys {
                    if let suggestion = createUnquotedKeySuggestion(for: error, in: jsonString) {
                        suggestions.append(suggestion)
                    }
                }
                
            case .commentFound:
                if options.removeComments {
                    if let suggestion = createCommentRemovalSuggestion(for: error, in: jsonString) {
                        suggestions.append(suggestion)
                    }
                }
                
            case .missingQuotes:
                if options.autoRepairQuotes {
                    if let suggestion = createMissingQuotesSuggestion(for: error, in: jsonString) {
                        suggestions.append(suggestion)
                    }
                }
                
            case .missingComma:
                if let suggestion = createMissingCommaSuggestion(for: error, in: jsonString) {
                    suggestions.append(suggestion)
                }
                
            default:
                break
            }
        }
        
        return suggestions.sorted { $0.position.offset < $1.position.offset }
    }
    
    private func createTrailingCommaSuggestion(for error: JSONError, in jsonString: String) -> JSONRepairSuggestion {
        let lines = jsonString.components(separatedBy: .newlines)
        let lineText = lines[error.position.line - 1]
        let commaIndex = lineText.index(lineText.startIndex, offsetBy: min(error.position.column - 1, lineText.count - 1))
        
        return JSONRepairSuggestion(
            type: .trailingComma,
            position: error.position,
            originalText: String(lineText[commaIndex]),
            suggestedFix: "",
            explanation: "移除多余的逗号",
            confidence: 0.95
        )
    }
    
    private func createSingleQuotesSuggestion(for error: JSONError, in jsonString: String) -> JSONRepairSuggestion {
        return JSONRepairSuggestion(
            type: .singleQuotes,
            position: error.position,
            originalText: "'",
            suggestedFix: "\"",
            explanation: "将单引号替换为双引号",
            confidence: 0.9
        )
    }
    
    private func createUnquotedKeySuggestion(for error: JSONError, in jsonString: String) -> JSONRepairSuggestion? {
        guard let context = error.context else { return nil }
        
        return JSONRepairSuggestion(
            type: .unquotedKey,
            position: error.position,
            originalText: context,
            suggestedFix: "\"\(context)\"",
            explanation: "为对象键名添加双引号",
            confidence: 0.85
        )
    }
    
    private func createCommentRemovalSuggestion(for error: JSONError, in jsonString: String) -> JSONRepairSuggestion? {
        let lines = jsonString.components(separatedBy: .newlines)
        let lineIndex = error.position.line - 1
        guard lineIndex < lines.count else { return nil }
        
        let lineText = lines[lineIndex]
        
        var originalText = ""
        
        if lineText.contains("//") {
            if let range = lineText.range(of: "//") {
                originalText = String(lineText[range.lowerBound...])
            }
        } else if lineText.contains("/*") {
            if let startRange = lineText.range(of: "/*"),
               let endRange = lineText.range(of: "*/", range: startRange.upperBound..<lineText.endIndex) {
                originalText = String(lineText[startRange.lowerBound..<endRange.upperBound])
            }
        }
        
        return JSONRepairSuggestion(
            type: .commentFound,
            position: error.position,
            originalText: originalText,
            suggestedFix: "",
            explanation: "移除注释（JSON 不支持注释）",
            confidence: 0.8
        )
    }
    
    private func createMissingQuotesSuggestion(for error: JSONError, in jsonString: String) -> JSONRepairSuggestion? {
        return JSONRepairSuggestion(
            type: .missingQuotes,
            position: error.position,
            originalText: "",
            suggestedFix: "\"",
            explanation: "添加缺失的双引号",
            confidence: 0.7
        )
    }
    
    private func createMissingCommaSuggestion(for error: JSONError, in jsonString: String) -> JSONRepairSuggestion? {
        return JSONRepairSuggestion(
            type: .missingComma,
            position: error.position,
            originalText: "",
            suggestedFix: ",",
            explanation: "添加缺失的逗号分隔符",
            confidence: 0.8
        )
    }
    
    private func attemptRepair(_ jsonString: String, with suggestions: [JSONRepairSuggestion]) -> (repairedJSON: String?, summary: String?) {
        var workingJSON = jsonString
        var appliedFixes: [String] = []
        
        let sortedSuggestions = suggestions.sorted { $0.position.offset > $1.position.offset }
        
        for suggestion in sortedSuggestions.prefix(options.maxRepairAttempts) {
            let lines = workingJSON.components(separatedBy: .newlines)
            guard suggestion.position.line - 1 < lines.count else { continue }
            
            var lineText = lines[suggestion.position.line - 1]
            let columnIndex = max(0, min(suggestion.position.column - 1, lineText.count))
            
            switch suggestion.type {
            case .trailingComma:
                if columnIndex < lineText.count {
                    let charIndex = lineText.index(lineText.startIndex, offsetBy: columnIndex)
                    if charIndex < lineText.endIndex && lineText[charIndex] == "," {
                        lineText.remove(at: charIndex)
                        appliedFixes.append("移除第 \(suggestion.position.line) 行的多余逗号")
                    }
                }
                
            case .singleQuotes:
                lineText = lineText.replacingOccurrences(of: "'", with: "\"")
                appliedFixes.append("第 \(suggestion.position.line) 行：单引号替换为双引号")
                
            case .unquotedKey:
                let keyName = suggestion.originalText
                lineText = lineText.replacingOccurrences(of: "\(keyName):", with: "\"\(keyName)\":")
                appliedFixes.append("第 \(suggestion.position.line) 行：为键名 \(keyName) 添加引号")
                
            case .commentFound:
                if lineText.contains("//") {
                    if let range = lineText.range(of: "//") {
                        lineText = String(lineText[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                    }
                } else if lineText.contains("/*") && lineText.contains("*/") {
                    lineText = lineText.replacingOccurrences(of: #"\/\*.*?\*\/"#, with: "", options: .regularExpression)
                }
                appliedFixes.append("第 \(suggestion.position.line) 行：移除注释")
                
            default:
                continue
            }
            
            var newLines = lines
            newLines[suggestion.position.line - 1] = lineText
            workingJSON = newLines.joined(separator: "\n")
        }
        
        if !appliedFixes.isEmpty {
            let parser = JSONParser(workingJSON)
            let diagnostic = parser.parse()
            
            if diagnostic.isValid {
                let summary = "成功修复 \(appliedFixes.count) 个问题：\n" + appliedFixes.joined(separator: "\n")
                return (workingJSON, summary)
            }
        }
        
        return (nil, appliedFixes.isEmpty ? nil : "尝试了 \(appliedFixes.count) 个修复，但仍有错误")
    }
}
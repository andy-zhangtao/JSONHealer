import Foundation

public enum JSONHealthStatus: String, Codable {
    case healthy = "healthy"
    case warning = "warning"
    case critical = "critical"
    case fatal = "fatal"
}

public struct JSONRepairSuggestion: Codable {
    public let type: JSONErrorType
    public let position: JSONPosition
    public let originalText: String
    public let suggestedFix: String
    public let explanation: String
    public let confidence: Double
    
    public init(type: JSONErrorType, position: JSONPosition, originalText: String, suggestedFix: String, explanation: String, confidence: Double = 1.0) {
        self.type = type
        self.position = position
        self.originalText = originalText
        self.suggestedFix = suggestedFix
        self.explanation = explanation
        self.confidence = max(0.0, min(1.0, confidence))
    }
}

public struct JSONDiagnostic: Codable {
    public let originalJSON: String
    public let isValid: Bool
    public let healthStatus: JSONHealthStatus
    public let errors: [JSONError]
    public let repairSuggestions: [JSONRepairSuggestion]
    public let repairedJSON: String?
    public let repairSummary: String?
    
    public init(
        originalJSON: String,
        isValid: Bool,
        healthStatus: JSONHealthStatus,
        errors: [JSONError] = [],
        repairSuggestions: [JSONRepairSuggestion] = [],
        repairedJSON: String? = nil,
        repairSummary: String? = nil
    ) {
        self.originalJSON = originalJSON
        self.isValid = isValid
        self.healthStatus = healthStatus
        self.errors = errors
        self.repairSuggestions = repairSuggestions
        self.repairedJSON = repairedJSON
        self.repairSummary = repairSummary
    }
    
    public var hasRepairableFixes: Bool {
        return !repairSuggestions.isEmpty
    }
    
    public var errorCount: Int {
        return errors.count
    }
    
    public var highConfidenceFixes: [JSONRepairSuggestion] {
        return repairSuggestions.filter { $0.confidence >= 0.8 }
    }
    
    public func errorsByType(_ type: JSONErrorType) -> [JSONError] {
        return errors.filter { $0.type == type }
    }
    
    public func suggestionsForError(_ error: JSONError) -> [JSONRepairSuggestion] {
        return repairSuggestions.filter { 
            $0.type == error.type && $0.position == error.position 
        }
    }
}
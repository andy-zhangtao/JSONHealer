import Foundation

// MARK: - Convenience Functions

public func diagnoseJSON(_ jsonString: String, options: JSONHealerOptions = .default) -> JSONDiagnostic {
    let healer = JSONHealer(options: options)
    return healer.diagnose(jsonString)
}

public func healJSON(_ jsonString: String, options: JSONHealerOptions = .default) -> JSONDiagnostic {
    let healer = JSONHealer(options: options)
    return healer.heal(jsonString)
}

public func isValidJSON(_ jsonString: String) -> Bool {
    return diagnoseJSON(jsonString).isValid
}

// MARK: - String Extensions

extension String {
    public func diagnoseJSON(options: JSONHealerOptions = .default) -> JSONDiagnostic {
        return JSONHealer.diagnoseJSON(self, options: options)
    }
    
    public func healJSON(options: JSONHealerOptions = .default) -> JSONDiagnostic {
        return JSONHealer.healJSON(self, options: options)
    }
    
    public var isValidJSON: Bool {
        return JSONHealer.isValidJSON(self)
    }
    
    public func repairJSON(options: JSONHealerOptions = .default) -> String? {
        return healJSON(options: options).repairedJSON
    }
}

// MARK: - JSONHealer Static Methods

extension JSONHealer {
    public static func diagnoseJSON(_ jsonString: String, options: JSONHealerOptions = .default) -> JSONDiagnostic {
        let healer = JSONHealer(options: options)
        return healer.diagnose(jsonString)
    }
    
    public static func healJSON(_ jsonString: String, options: JSONHealerOptions = .default) -> JSONDiagnostic {
        let healer = JSONHealer(options: options)
        return healer.heal(jsonString)
    }
    
    public static func isValidJSON(_ jsonString: String) -> Bool {
        let healer = JSONHealer()
        return healer.diagnose(jsonString).isValid
    }
    
    public static func quickFix(_ jsonString: String) -> String? {
        let options = JSONHealerOptions(
            autoRepairQuotes: true,
            autoRepairTrailingCommas: true,
            autoRepairUnquotedKeys: true,
            removeComments: true,
            autoRepairSingleQuotes: true,
            maxRepairAttempts: 5
        )
        let healer = JSONHealer(options: options)
        return healer.heal(jsonString).repairedJSON
    }
}

// MARK: - Result Types for Better Error Handling

public enum JSONHealingResult {
    case healthy(String)
    case healed(original: String, repaired: String, summary: String)
    case critical(String, errors: [JSONError])
    
    public var isSuccessful: Bool {
        switch self {
        case .healthy, .healed:
            return true
        case .critical:
            return false
        }
    }
    
    public var finalJSON: String? {
        switch self {
        case .healthy(let json):
            return json
        case .healed(_, let repaired, _):
            return repaired
        case .critical:
            return nil
        }
    }
    
    public var errors: [JSONError] {
        switch self {
        case .healthy, .healed:
            return []
        case .critical(_, let errors):
            return errors
        }
    }
}

extension JSONHealer {
    public func process(_ jsonString: String) -> JSONHealingResult {
        let diagnostic = diagnose(jsonString)
        
        if diagnostic.isValid {
            return .healthy(jsonString)
        }
        
        if let repairedJSON = diagnostic.repairedJSON,
           let summary = diagnostic.repairSummary {
            return .healed(original: jsonString, repaired: repairedJSON, summary: summary)
        }
        
        return .critical(jsonString, errors: diagnostic.errors)
    }
}

// MARK: - Data Extensions for Data Input

extension Data {
    public func diagnoseJSON(options: JSONHealerOptions = .default) -> JSONDiagnostic? {
        guard let string = String(data: self, encoding: .utf8) else { return nil }
        return string.diagnoseJSON(options: options)
    }
    
    public func healJSON(options: JSONHealerOptions = .default) -> JSONDiagnostic? {
        guard let string = String(data: self, encoding: .utf8) else { return nil }
        return string.healJSON(options: options)
    }
    
    public var isValidJSON: Bool {
        guard let string = String(data: self, encoding: .utf8) else { return false }
        return string.isValidJSON
    }
}
import XCTest
@testable import JSONHealer

final class JSONHealerTests: XCTestCase {
    
    var healer: JSONHealer!
    
    override func setUp() {
        super.setUp()
        healer = JSONHealer()
    }
    
    override func tearDown() {
        healer = nil
        super.tearDown()
    }
    
    // MARK: - Valid JSON Tests
    
    func testValidJSON() {
        let validJSON = """
        {
            "name": "测试",
            "age": 25,
            "isStudent": true,
            "scores": [85, 92, 78],
            "address": {
                "city": "北京",
                "zipCode": "100000"
            }
        }
        """
        
        let diagnostic = healer.diagnose(validJSON)
        
        XCTAssertTrue(diagnostic.isValid)
        XCTAssertEqual(diagnostic.healthStatus, .healthy)
        XCTAssertTrue(diagnostic.errors.isEmpty)
        XCTAssertTrue(diagnostic.repairSuggestions.isEmpty)
        XCTAssertNil(diagnostic.repairedJSON)
    }
    
    func testEmptyObject() {
        let json = "{}"
        let diagnostic = healer.diagnose(json)
        
        XCTAssertTrue(diagnostic.isValid)
        XCTAssertEqual(diagnostic.healthStatus, .healthy)
    }
    
    func testEmptyArray() {
        let json = "[]"
        let diagnostic = healer.diagnose(json)
        
        XCTAssertTrue(diagnostic.isValid)
        XCTAssertEqual(diagnostic.healthStatus, .healthy)
    }
    
    // MARK: - Trailing Comma Tests
    
    func testTrailingCommaInObject() {
        let invalidJSON = """
        {
            "name": "测试",
            "age": 25,
        }
        """
        
        let diagnostic = healer.diagnose(invalidJSON)
        
        XCTAssertFalse(diagnostic.isValid)
        XCTAssertEqual(diagnostic.errors.count, 1)
        XCTAssertEqual(diagnostic.errors[0].type, .trailingComma)
        XCTAssertNotNil(diagnostic.repairedJSON)
        
        // 验证修复后的 JSON 是有效的
        if let repairedJSON = diagnostic.repairedJSON {
            let repairedDiagnostic = healer.diagnose(repairedJSON)
            XCTAssertTrue(repairedDiagnostic.isValid)
        }
    }
    
    func testTrailingCommaInArray() {
        let invalidJSON = """
        [
            "apple",
            "banana",
            "orange",
        ]
        """
        
        let diagnostic = healer.diagnose(invalidJSON)
        
        XCTAssertFalse(diagnostic.isValid)
        XCTAssertEqual(diagnostic.errors.count, 1)
        XCTAssertEqual(diagnostic.errors[0].type, .trailingComma)
        XCTAssertNotNil(diagnostic.repairedJSON)
    }
    
    // MARK: - Single Quotes Tests
    
    func testSingleQuotesInString() {
        let invalidJSON = """
        {
            'name': 'John',
            'age': 30
        }
        """
        
        let diagnostic = healer.diagnose(invalidJSON)
        
        XCTAssertFalse(diagnostic.isValid)
        XCTAssertTrue(diagnostic.errors.contains { $0.type == .singleQuotes })
        XCTAssertNotNil(diagnostic.repairedJSON)
        
        // 验证修复后的 JSON 是有效的
        if let repairedJSON = diagnostic.repairedJSON {
            let repairedDiagnostic = healer.diagnose(repairedJSON)
            XCTAssertTrue(repairedDiagnostic.isValid)
        }
    }
    
    // MARK: - Unquoted Keys Tests
    
    func testUnquotedKeys() {
        let invalidJSON = """
        {
            name: "John",
            age: 30
        }
        """
        
        let diagnostic = healer.diagnose(invalidJSON)
        
        XCTAssertFalse(diagnostic.isValid)
        XCTAssertTrue(diagnostic.errors.contains { $0.type == .unquotedKey })
    }
    
    // MARK: - Comments Tests
    
    func testSingleLineComments() {
        let invalidJSON = """
        {
            "name": "John", // 这是一个注释
            "age": 30
        }
        """
        
        let diagnostic = healer.diagnose(invalidJSON)
        
        XCTAssertFalse(diagnostic.isValid)
        XCTAssertTrue(diagnostic.errors.contains { $0.type == .commentFound })
        XCTAssertNotNil(diagnostic.repairedJSON)
    }
    
    func testMultiLineComments() {
        let invalidJSON = """
        {
            "name": "John", /* 这是一个
                               多行注释 */
            "age": 30
        }
        """
        
        let diagnostic = healer.diagnose(invalidJSON)
        
        XCTAssertFalse(diagnostic.isValid)
        XCTAssertTrue(diagnostic.errors.contains { $0.type == .commentFound })
    }
    
    // MARK: - Bracket Matching Tests
    
    func testUnmatchedBrackets() {
        let invalidJSON = """
        {
            "name": "John",
            "scores": [85, 92, 78
        }
        """
        
        let diagnostic = healer.diagnose(invalidJSON)
        
        XCTAssertFalse(diagnostic.isValid)
        XCTAssertEqual(diagnostic.healthStatus, .fatal)
        XCTAssertTrue(diagnostic.errors.contains { $0.type == .unmatchedBrackets || $0.type == .unexpectedEnd })
    }
    
    // MARK: - Invalid Character Tests
    
    func testInvalidCharacters() {
        let invalidJSON = """
        {
            "name": "John",
            "age": 30@
        }
        """
        
        let diagnostic = healer.diagnose(invalidJSON)
        
        XCTAssertFalse(diagnostic.isValid)
        XCTAssertTrue(diagnostic.errors.contains { $0.type == .invalidCharacter })
    }
    
    // MARK: - Number Format Tests
    
    func testInvalidNumbers() {
        let invalidJSON = """
        {
            "price": 123.
        }
        """
        
        let diagnostic = healer.diagnose(invalidJSON)
        
        XCTAssertFalse(diagnostic.isValid)
        XCTAssertTrue(diagnostic.errors.contains { $0.type == .invalidNumber })
    }
    
    // MARK: - Multiple Errors Tests
    
    func testMultipleErrors() {
        let invalidJSON = """
        {
            'name': 'John', // 注释
            age: 30,        // 无引号键名和注释
            "scores": [85, 92, 78,], // 多余逗号
        }
        """
        
        let diagnostic = healer.diagnose(invalidJSON)
        
        XCTAssertFalse(diagnostic.isValid)
        XCTAssertGreaterThan(diagnostic.errors.count, 1)
        XCTAssertGreaterThan(diagnostic.repairSuggestions.count, 0)
    }
    
    // MARK: - Empty Input Tests
    
    func testEmptyInput() {
        let diagnostic = healer.diagnose("")
        
        XCTAssertFalse(diagnostic.isValid)
        XCTAssertEqual(diagnostic.healthStatus, .fatal)
        XCTAssertTrue(diagnostic.errors.contains { $0.type == .unexpectedEnd })
    }
    
    // MARK: - Options Tests
    
    func testConservativeOptions() {
        let conservativeHealer = JSONHealer(options: .conservative)
        
        let invalidJSON = """
        {
            name: "John", // 注释
            'age': 30
        }
        """
        
        let diagnostic = conservativeHealer.diagnose(invalidJSON)
        
        XCTAssertFalse(diagnostic.isValid)
        // 保守模式不应该修复无引号键名和注释
        let unquotedKeyFixes = diagnostic.repairSuggestions.filter { $0.type == .unquotedKey }
        let commentFixes = diagnostic.repairSuggestions.filter { $0.type == .commentFound }
        
        XCTAssertTrue(unquotedKeyFixes.isEmpty)
        XCTAssertTrue(commentFixes.isEmpty)
    }
    
    func testAggressiveOptions() {
        let aggressiveHealer = JSONHealer(options: .aggressive)
        
        let invalidJSON = """
        {
            'name': 'John',
            age: 30,
            "scores": [85, 92, 78,],
        }
        """
        
        let diagnostic = aggressiveHealer.diagnose(invalidJSON)
        
        XCTAssertFalse(diagnostic.isValid)
        XCTAssertGreaterThan(diagnostic.repairSuggestions.count, 0)
        XCTAssertNotNil(diagnostic.repairedJSON)
    }
    
    // MARK: - Convenience Methods Tests
    
    func testStaticMethods() {
        let validJSON = "{\"name\": \"test\"}"
        let invalidJSON = "{'name': 'test',}"
        
        XCTAssertTrue(JSONHealer.isValidJSON(validJSON))
        XCTAssertFalse(JSONHealer.isValidJSON(invalidJSON))
        
        let diagnostic = JSONHealer.diagnoseJSON(invalidJSON)
        XCTAssertFalse(diagnostic.isValid)
        
        let repaired = JSONHealer.quickFix(invalidJSON)
        XCTAssertNotNil(repaired)
    }
    
    func testStringExtensions() {
        let validJSON = "{\"name\": \"test\"}"
        let invalidJSON = "{'name': 'test',}"
        
        XCTAssertTrue(validJSON.isValidJSON)
        XCTAssertFalse(invalidJSON.isValidJSON)
        
        let diagnostic = invalidJSON.diagnoseJSON()
        XCTAssertFalse(diagnostic.isValid)
        
        let repaired = invalidJSON.repairJSON()
        XCTAssertNotNil(repaired)
    }
    
    // MARK: - Error Position Tests
    
    func testErrorPositions() {
        let invalidJSON = """
        {
            "name": "John",
            "age": 30,
        }
        """
        
        let diagnostic = healer.diagnose(invalidJSON)
        
        XCTAssertFalse(diagnostic.isValid)
        XCTAssertEqual(diagnostic.errors.count, 1)
        
        let error = diagnostic.errors[0]
        XCTAssertEqual(error.type, .trailingComma)
        XCTAssertEqual(error.position.line, 4)
        XCTAssertGreaterThan(error.position.column, 0)
    }
    
    // MARK: - Performance Tests
    
    func testLargeJSONPerformance() {
        let largeJSON = generateLargeJSON(itemCount: 1000)
        
        measure {
            let diagnostic = healer.diagnose(largeJSON)
            XCTAssertTrue(diagnostic.isValid)
        }
    }
    
    private func generateLargeJSON(itemCount: Int) -> String {
        var items: [String] = []
        
        for i in 0..<itemCount {
            let item = """
            {
                "id": \(i),
                "name": "Item \(i)",
                "value": \(Double.random(in: 0...100)),
                "active": \(Bool.random())
            }
            """
            items.append(item)
        }
        
        return "[\(items.joined(separator: ","))]"
    }
}

// MARK: - JSON Diagnostic Tests

final class JSONDiagnosticTests: XCTestCase {
    
    func testDiagnosticProperties() {
        let errors = [
            JSONError(type: .trailingComma, position: JSONPosition(line: 1, column: 10, offset: 9), message: "多余逗号"),
            JSONError(type: .singleQuotes, position: JSONPosition(line: 2, column: 5, offset: 15), message: "单引号")
        ]
        
        let suggestions = [
            JSONRepairSuggestion(type: .trailingComma, position: JSONPosition(line: 1, column: 10, offset: 9), originalText: ",", suggestedFix: "", explanation: "移除逗号", confidence: 0.9)
        ]
        
        let diagnostic = JSONDiagnostic(
            originalJSON: "test",
            isValid: false,
            healthStatus: .warning,
            errors: errors,
            repairSuggestions: suggestions,
            repairedJSON: "fixed",
            repairSummary: "修复完成"
        )
        
        XCTAssertEqual(diagnostic.errorCount, 2)
        XCTAssertTrue(diagnostic.hasRepairableFixes)
        XCTAssertEqual(diagnostic.highConfidenceFixes.count, 1)
        
        let trailingCommaErrors = diagnostic.errorsByType(.trailingComma)
        XCTAssertEqual(trailingCommaErrors.count, 1)
        
        let suggestionsForFirstError = diagnostic.suggestionsForError(errors[0])
        XCTAssertEqual(suggestionsForFirstError.count, 1)
    }
}

// MARK: - JSON Error Tests

final class JSONErrorTests: XCTestCase {
    
    func testErrorDescription() {
        let position = JSONPosition(line: 5, column: 12, offset: 45)
        let error = JSONError(type: .trailingComma, position: position, message: "发现多余逗号", context: ",")
        
        let description = error.localizedDescription
        XCTAssertTrue(description.contains("多余的逗号"))
        XCTAssertTrue(description.contains("第 5 行"))
        XCTAssertTrue(description.contains("第 12 列"))
    }
    
    func testAllErrorTypes() {
        let position = JSONPosition(line: 1, column: 1, offset: 0)
        
        for errorType in JSONErrorType.allCases {
            let error = JSONError(type: errorType, position: position, message: "测试消息")
            XCTAssertFalse(error.localizedDescription.isEmpty)
            XCTAssertFalse(errorType.localizedDescription.isEmpty)
        }
    }
}
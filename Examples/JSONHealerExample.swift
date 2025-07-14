import Foundation
import JSONHealer

// MARK: - JSONHealer 使用示例

print("🩺 JSONHealer 示例演示")
print("=" * 50)

// MARK: - 示例 1: 基本用法

print("\n📋 示例 1: 基本用法")
print("-" * 30)

let healer = JSONHealer()

let problematicJSON = """
{
    'name': 'John Smith',    // 单引号问题
    age: 30,                 // 无引号键名
    "email": "john@test.com",
    "scores": [85, 92, 78,], // 多余逗号
    "active": true,
}
"""

let diagnostic = healer.diagnose(problematicJSON)

print("JSON 是否有效: \(diagnostic.isValid)")
print("健康状态: \(diagnostic.healthStatus)")
print("发现错误数量: \(diagnostic.errorCount)")

print("\n发现的错误:")
for (index, error) in diagnostic.errors.enumerated() {
    print("\(index + 1). \(error.localizedDescription)")
}

print("\n修复建议:")
for (index, suggestion) in diagnostic.repairSuggestions.enumerated() {
    print("\(index + 1). \(suggestion.explanation) (置信度: \(Int(suggestion.confidence * 100))%)")
}

if let repairedJSON = diagnostic.repairedJSON {
    print("\n✅ 修复后的 JSON:")
    print(repairedJSON)
    
    // 验证修复后的 JSON 是否有效
    let repairedDiagnostic = healer.diagnose(repairedJSON)
    print("\n修复后验证: \(repairedDiagnostic.isValid ? "✅ 有效" : "❌ 仍有错误")")
}

if let summary = diagnostic.repairSummary {
    print("\n📝 修复摘要:")
    print(summary)
}

// MARK: - 示例 2: 不同配置选项

print("\n\n📋 示例 2: 配置选项对比")
print("-" * 30)

let testJSON = """
{
    name: "Test", // 注释
    'type': 'example',
    "items": [1, 2, 3,]
}
"""

// 保守模式
let conservativeHealer = JSONHealer(options: .conservative)
let conservativeDiag = conservativeHealer.diagnose(testJSON)

print("保守模式:")
print("- 可修复建议数: \(conservativeDiag.repairSuggestions.count)")
print("- 有修复结果: \(conservativeDiag.repairedJSON != nil)")

// 积极模式
let aggressiveHealer = JSONHealer(options: .aggressive)
let aggressiveDiag = aggressiveHealer.diagnose(testJSON)

print("\n积极模式:")
print("- 可修复建议数: \(aggressiveDiag.repairSuggestions.count)")
print("- 有修复结果: \(aggressiveDiag.repairedJSON != nil)")

// MARK: - 示例 3: 便利方法

print("\n\n📋 示例 3: 便利方法")
print("-" * 30)

let quickTestJSON = "{'quick': 'test',}"

// String 扩展方法
print("使用 String 扩展:")
print("- 是否有效: \(quickTestJSON.isValidJSON)")
print("- 快速修复: \(quickTestJSON.repairJSON() ?? "无法修复")")

// 静态方法
print("\n使用静态方法:")
print("- 是否有效: \(JSONHealer.isValidJSON(quickTestJSON))")
print("- 快速修复: \(JSONHealer.quickFix(quickTestJSON) ?? "无法修复")")

// MARK: - 示例 4: 错误分析

print("\n\n📋 示例 4: 详细错误分析")
print("-" * 30)

let complexJSON = """
{
    'user': {
        name: 'Alice',           // 无引号键名
        "age": 25,
        'hobbies': ['reading', 'coding',], // 单引号 + 多余逗号
    },
    "settings": {
        "theme": "dark", // 注释
        "notifications": true,
    }
}
"""

let complexDiag = healer.diagnose(complexJSON)

print("复杂 JSON 分析:")
print("- 总错误数: \(complexDiag.errorCount)")
print("- 健康状态: \(complexDiag.healthStatus)")

// 按错误类型分组
let errorTypes = Set(complexDiag.errors.map { $0.type })
for errorType in errorTypes {
    let count = complexDiag.errorsByType(errorType).count
    print("- \(errorType.localizedDescription): \(count) 个")
}

// 高置信度修复
print("\n高置信度修复建议 (≥80%):")
for fix in complexDiag.highConfidenceFixes {
    print("- \(fix.explanation) (\(Int(fix.confidence * 100))%)")
}

// MARK: - 示例 5: 处理结果类型

print("\n\n📋 示例 5: 结果处理")
print("-" * 30)

let testCases = [
    ("有效 JSON", """{"name": "valid", "age": 30}"""),
    ("可修复 JSON", """{'name': 'repairable',}"""),
    ("严重错误 JSON", """{"name": "broken", "age":""")
]

for (description, json) in testCases {
    print("\n处理 \(description):")
    let result = healer.process(json)
    
    switch result {
    case .healthy(let json):
        print("✅ JSON 完全健康")
        
    case .healed(let original, let repaired, let summary):
        print("🔧 成功修复")
        print("修复摘要: \(summary)")
        
    case .critical(let json, let errors):
        print("💥 严重错误，无法修复")
        print("错误数量: \(errors.count)")
    }
}

// MARK: - 示例 6: 性能测试

print("\n\n📋 示例 6: 性能演示")
print("-" * 30)

// 生成大型 JSON 进行性能测试
func generateLargeJSON(itemCount: Int) -> String {
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

let largeJSON = generateLargeJSON(itemCount: 100)
let startTime = Date()
let largeDiag = healer.diagnose(largeJSON)
let endTime = Date()

print("大型 JSON (100 项) 处理:")
print("- 处理时间: \(String(format: "%.3f", endTime.timeIntervalSince(startTime))) 秒")
print("- JSON 有效: \(largeDiag.isValid)")
print("- JSON 大小: \(largeJSON.count) 字符")

// MARK: - 示例 7: Data 类型支持

print("\n\n📋 示例 7: Data 类型支持")
print("-" * 30)

let jsonString = "{'data': 'example',}"
if let jsonData = jsonString.data(using: .utf8) {
    print("处理 Data 类型:")
    print("- 是否有效: \(jsonData.isValidJSON)")
    
    if let diagnostic = jsonData.diagnoseJSON() {
        print("- 错误数量: \(diagnostic.errorCount)")
        if let repaired = diagnostic.repairedJSON {
            print("- 修复成功: ✅")
        }
    }
}

print("\n🎉 示例演示完成！")
print("=" * 50)

// MARK: - 工具函数

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}
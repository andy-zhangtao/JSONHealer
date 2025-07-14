# JSONHealer 🩺

一个强大的 Swift JSON 修复工具，就像一个 JSON 医生，能够诊断 JSON 数据的问题并尝试智能修复它们。

## 特性

✅ **JSON 健康检查** - 准确检测 JSON 格式问题  
🔧 **智能修复** - 自动修复常见的 JSON 错误  
📍 **精确定位** - 提供错误的行号、列号和详细说明  
⚙️ **灵活配置** - 可自定义修复选项  
🚀 **高性能** - 快速处理大型 JSON 文件  
📱 **多平台支持** - 兼容 macOS、iOS、watchOS、tvOS

## 安装

### Swift Package Manager

在你的 `Package.swift` 文件中添加：

```swift
dependencies: [
    .package(url: "https://github.com/your-username/JSONHealer.git", from: "1.0.0")
]
```

### Xcode

1. 选择 **File > Add Package Dependencies...**
2. 输入仓库 URL: `https://github.com/your-username/JSONHealer.git`
3. 点击 **Add Package**

## 快速开始

### 基本使用

```swift
import JSONHealer

// 创建 JSONHealer 实例
let healer = JSONHealer()

// 诊断 JSON
let problematicJSON = """
{
    'name': 'John',    // 单引号问题
    age: 30,           // 无引号键名
    "scores": [85, 92, 78,],  // 多余逗号
}
"""

let diagnostic = healer.diagnose(problematicJSON)

print("JSON 是否有效: \(diagnostic.isValid)")
print("健康状态: \(diagnostic.healthStatus)")
print("发现 \(diagnostic.errorCount) 个错误")

// 查看修复建议
for suggestion in diagnostic.repairSuggestions {
    print("建议: \(suggestion.explanation)")
}

// 获取修复后的 JSON
if let repairedJSON = diagnostic.repairedJSON {
    print("修复后的 JSON:")
    print(repairedJSON)
}
```

### 便利方法

```swift
import JSONHealer

let jsonString = "{'name': 'test',}"

// 快速检查 JSON 是否有效
let isValid = jsonString.isValidJSON

// 快速修复 JSON
let repaired = jsonString.repairJSON()

// 使用静态方法
let diagnostic = JSONHealer.diagnoseJSON(jsonString)
let quickFix = JSONHealer.quickFix(jsonString)
```

### 配置选项

```swift
// 使用预设配置
let conservativeHealer = JSONHealer(options: .conservative)  // 保守修复
let aggressiveHealer = JSONHealer(options: .aggressive)      // 积极修复

// 自定义配置
let customOptions = JSONHealerOptions(
    autoRepairQuotes: true,           // 自动修复引号问题
    autoRepairTrailingCommas: true,   // 自动移除多余逗号
    autoRepairUnquotedKeys: false,    // 不修复无引号键名
    removeComments: true,             // 移除注释
    autoRepairSingleQuotes: true,     // 修复单引号
    maxRepairAttempts: 10             // 最大修复尝试次数
)

let customHealer = JSONHealer(options: customOptions)
```

## 支持的错误类型

JSONHealer 能够检测和修复以下 JSON 错误：

| 错误类型 | 描述 | 示例 | 修复 |
|---------|------|------|------|
| `missingQuotes` | 字符串缺少双引号 | `{name: John}` | `{"name": "John"}` |
| `singleQuotes` | 使用单引号 | `{'name': 'John'}` | `{"name": "John"}` |
| `unquotedKey` | 对象键名未加引号 | `{name: "John"}` | `{"name": "John"}` |
| `trailingComma` | 多余的逗号 | `[1, 2, 3,]` | `[1, 2, 3]` |
| `commentFound` | JSON 中包含注释 | `{"a": 1} // 注释` | `{"a": 1}` |
| `unmatchedBrackets` | 括号不匹配 | `{"a": [1, 2}` | 提示错误位置 |
| `invalidNumber` | 无效数字格式 | `{"a": 123.}` | 提示格式错误 |

## 高级用法

### 错误分析

```swift
let diagnostic = healer.diagnose(jsonString)

// 获取特定类型的错误
let trailingCommaErrors = diagnostic.errorsByType(.trailingComma)

// 获取高置信度的修复建议
let highConfidenceFixes = diagnostic.highConfidenceFixes

// 为特定错误获取建议
if let firstError = diagnostic.errors.first {
    let suggestions = diagnostic.suggestionsForError(firstError)
}
```

### 结果处理

```swift
let result = healer.process(jsonString)

switch result {
case .healthy(let json):
    print("JSON 完全健康: \(json)")
    
case .healed(let original, let repaired, let summary):
    print("修复成功!")
    print("原始: \(original)")
    print("修复后: \(repaired)")
    print("修复摘要: \(summary)")
    
case .critical(let json, let errors):
    print("无法修复的严重错误:")
    for error in errors {
        print("- \(error.localizedDescription)")
    }
}
```

### 处理 Data 类型

```swift
let jsonData = Data(/* JSON 数据 */)

// 直接从 Data 诊断
if let diagnostic = jsonData.diagnoseJSON() {
    print("诊断结果: \(diagnostic.isValid)")
}

// 检查 Data 是否为有效 JSON
let isValidData = jsonData.isValidJSON
```

## 性能优化

- JSONHealer 针对大文件进行了优化
- 使用流式解析，内存占用低
- 支持配置最大修复尝试次数以平衡性能和修复效果

## 集成示例

### 在 macOS 应用中使用

```swift
import SwiftUI
import JSONHealer

struct JSONValidatorView: View {
    @State private var jsonText = ""
    @State private var diagnostic: JSONDiagnostic?
    
    var body: some View {
        VStack {
            TextEditor(text: $jsonText)
                .font(.monospaced(.body)())
            
            Button("验证 JSON") {
                let healer = JSONHealer()
                diagnostic = healer.diagnose(jsonText)
            }
            
            if let diagnostic = diagnostic {
                if diagnostic.isValid {
                    Text("✅ JSON 有效")
                        .foregroundColor(.green)
                } else {
                    VStack(alignment: .leading) {
                        Text("❌ 发现 \(diagnostic.errorCount) 个错误")
                            .foregroundColor(.red)
                        
                        ForEach(diagnostic.errors.indices, id: \.self) { index in
                            Text(diagnostic.errors[index].localizedDescription)
                                .font(.caption)
                        }
                        
                        if let repaired = diagnostic.repairedJSON {
                            Button("应用修复") {
                                jsonText = repaired
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}
```

## 错误信息

所有错误信息都提供中文描述，包括：

- 错误类型的详细说明
- 错误发生的精确位置（行号、列号）
- 上下文信息
- 修复建议

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 贡献

欢迎提交 Issue 和 Pull Request！

## 更新日志

### v1.0.0
- 初始版本发布
- 支持基本的 JSON 错误检测和修复
- 提供灵活的配置选项
- 完整的单元测试覆盖

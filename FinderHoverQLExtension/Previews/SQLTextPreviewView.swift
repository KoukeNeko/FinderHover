//
//  SQLTextPreviewView.swift
//  FinderHoverQLExtension
//
//  SwiftUI view for SQL text file preview with syntax highlighting
//

import SwiftUI
import Combine

// MARK: - SQL Syntax Highlighter

struct SQLSyntaxHighlighter {
    // SQL Keywords
    private static let keywords: Set<String> = [
        "SELECT", "FROM", "WHERE", "AND", "OR", "NOT", "IN", "LIKE", "BETWEEN",
        "INSERT", "INTO", "VALUES", "UPDATE", "SET", "DELETE", "DROP", "CREATE",
        "TABLE", "INDEX", "VIEW", "TRIGGER", "DATABASE", "SCHEMA", "ALTER", "ADD",
        "PRIMARY", "KEY", "FOREIGN", "REFERENCES", "UNIQUE", "CHECK", "DEFAULT",
        "NULL", "NOT", "AUTO_INCREMENT", "AUTOINCREMENT", "IF", "EXISTS", "CASCADE",
        "ON", "AS", "JOIN", "LEFT", "RIGHT", "INNER", "OUTER", "CROSS", "NATURAL",
        "ORDER", "BY", "ASC", "DESC", "LIMIT", "OFFSET", "GROUP", "HAVING", "DISTINCT",
        "UNION", "ALL", "EXCEPT", "INTERSECT", "CASE", "WHEN", "THEN", "ELSE", "END",
        "BEGIN", "COMMIT", "ROLLBACK", "TRANSACTION", "PRAGMA", "EXPLAIN", "ANALYZE",
        "REPLACE", "IGNORE", "CONFLICT", "ABORT", "FAIL", "CONSTRAINT", "TEMPORARY",
        "TEMP", "WITH", "RECURSIVE", "VACUUM", "REINDEX", "ATTACH", "DETACH"
    ]

    // SQL Data Types
    private static let dataTypes: Set<String> = [
        "INTEGER", "INT", "TINYINT", "SMALLINT", "MEDIUMINT", "BIGINT", "UNSIGNED",
        "TEXT", "VARCHAR", "CHAR", "CLOB", "BLOB", "REAL", "DOUBLE", "FLOAT",
        "NUMERIC", "DECIMAL", "BOOLEAN", "DATE", "TIME", "DATETIME", "TIMESTAMP"
    ]

    // SQL Functions
    private static let functions: Set<String> = [
        "COUNT", "SUM", "AVG", "MIN", "MAX", "ABS", "ROUND", "LENGTH", "UPPER",
        "LOWER", "SUBSTR", "TRIM", "LTRIM", "RTRIM", "REPLACE", "INSTR", "COALESCE",
        "NULLIF", "IFNULL", "IIF", "TYPEOF", "PRINTF", "RANDOM", "DATETIME", "DATE",
        "TIME", "JULIANDAY", "STRFTIME", "TOTAL", "GROUP_CONCAT", "HEX", "QUOTE",
        "UNICODE", "ZEROBLOB", "LIKELIHOOD", "LIKELY", "UNLIKELY", "GLOB", "LIKE"
    ]

    static func highlight(_ sql: String) -> AttributedString {
        var result = AttributedString()

        let lines = sql.components(separatedBy: "\n")

        for (lineIndex, line) in lines.enumerated() {
            var currentIndex = line.startIndex
            var inString = false
            var stringChar: Character = "\""
            var inComment = false

            while currentIndex < line.endIndex {
                let remaining = String(line[currentIndex...])

                // Check for single-line comment
                if remaining.hasPrefix("--") && !inString {
                    var commentStr = AttributedString(String(line[currentIndex...]))
                    commentStr.foregroundColor = .gray
                    result += commentStr
                    break
                }

                // Check for string start/end
                if (remaining.first == "'" || remaining.first == "\"") && !inComment {
                    if inString && remaining.first == stringChar {
                        // End of string
                        var charStr = AttributedString(String(remaining.first!))
                        charStr.foregroundColor = .orange
                        result += charStr
                        currentIndex = line.index(after: currentIndex)
                        inString = false
                        continue
                    } else if !inString {
                        // Start of string
                        inString = true
                        stringChar = remaining.first!
                        var charStr = AttributedString(String(remaining.first!))
                        charStr.foregroundColor = .orange
                        result += charStr
                        currentIndex = line.index(after: currentIndex)
                        continue
                    }
                }

                if inString {
                    var charStr = AttributedString(String(remaining.first!))
                    charStr.foregroundColor = .orange
                    result += charStr
                    currentIndex = line.index(after: currentIndex)
                    continue
                }

                // Check for numbers
                if let firstChar = remaining.first, firstChar.isNumber {
                    var numberStr = ""
                    var tempIndex = currentIndex
                    while tempIndex < line.endIndex {
                        let char = line[tempIndex]
                        if char.isNumber || char == "." {
                            numberStr.append(char)
                            tempIndex = line.index(after: tempIndex)
                        } else {
                            break
                        }
                    }
                    var attrNum = AttributedString(numberStr)
                    attrNum.foregroundColor = .cyan
                    result += attrNum
                    currentIndex = tempIndex
                    continue
                }

                // Check for words (keywords, functions, types)
                if let firstChar = remaining.first, firstChar.isLetter || firstChar == "_" {
                    var word = ""
                    var tempIndex = currentIndex
                    while tempIndex < line.endIndex {
                        let char = line[tempIndex]
                        if char.isLetter || char.isNumber || char == "_" {
                            word.append(char)
                            tempIndex = line.index(after: tempIndex)
                        } else {
                            break
                        }
                    }

                    let upperWord = word.uppercased()
                    var attrWord = AttributedString(word)

                    if keywords.contains(upperWord) {
                        attrWord.foregroundColor = .purple
                        attrWord.font = .system(size: 12, weight: .bold, design: .monospaced)
                    } else if dataTypes.contains(upperWord) {
                        attrWord.foregroundColor = .green
                    } else if functions.contains(upperWord) {
                        attrWord.foregroundColor = .blue
                    } else {
                        attrWord.foregroundColor = .primary
                    }

                    result += attrWord
                    currentIndex = tempIndex
                    continue
                }

                // Default: add character as-is
                var charStr = AttributedString(String(remaining.first!))
                charStr.foregroundColor = .primary
                result += charStr
                currentIndex = line.index(after: currentIndex)
            }

            // Add newline if not last line
            if lineIndex < lines.count - 1 {
                result += AttributedString("\n")
            }
        }

        return result
    }
}

// MARK: - View Model

@MainActor
class SQLTextPreviewViewModel: ObservableObject {
    let fileName: String
    let fileSize: Int64
    let content: String
    let lineCount: Int
    let statementCount: Int

    @Published var highlightedContent: AttributedString?
    @Published var isHighlighting = true

    init(fileName: String, fileSize: Int64, content: String) {
        self.fileName = fileName
        self.fileSize = fileSize
        self.content = content
        self.lineCount = content.components(separatedBy: "\n").count

        // Count SQL statements (rough estimate based on semicolons)
        self.statementCount = content.components(separatedBy: ";")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .count

        // Highlight in background for large files
        Task {
            await highlightContent()
        }
    }

    func highlightContent() async {
        // For very large files, skip highlighting
        if content.count > 500_000 {
            highlightedContent = AttributedString(content)
            isHighlighting = false
            return
        }

        // Highlight on background thread
        let highlighted = await Task.detached { [content] in
            SQLSyntaxHighlighter.highlight(content)
        }.value

        highlightedContent = highlighted
        isHighlighting = false
    }

    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

// MARK: - Main Preview View

struct SQLTextPreviewView: View {
    @StateObject var viewModel: SQLTextPreviewViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Content
            contentView

            Divider()

            // Footer
            footerView
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 24))
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.fileName)
                    .font(.headline)
                    .lineLimit(1)

                Text("SQL Script \u{00B7} \(viewModel.formattedFileSize)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Stats
            HStack(spacing: 16) {
                statBadge(icon: "text.alignleft", value: "\(viewModel.lineCount)", label: "lines")
                statBadge(icon: "command", value: "\(viewModel.statementCount)", label: "statements")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func statBadge(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView([.horizontal, .vertical]) {
            if viewModel.isHighlighting {
                VStack {
                    ProgressView()
                    Text("Highlighting...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            } else if let highlighted = viewModel.highlightedContent {
                HStack(alignment: .top, spacing: 0) {
                    // Line numbers
                    lineNumbersView

                    Divider()

                    // Code content
                    Text(highlighted)
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            } else {
                // Fallback plain text
                HStack(alignment: .top, spacing: 0) {
                    lineNumbersView

                    Divider()

                    Text(viewModel.content)
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            }
        }
    }

    private var lineNumbersView: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(1...max(1, viewModel.lineCount), id: \.self) { lineNum in
                Text("\(lineNum)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(height: 17) // Match line height
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Text("SQL")
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .cornerRadius(3)

            Spacer()

            Text("UTF-8")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Preview

#if DEBUG
struct SQLTextPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Preview not available")
            .frame(width: 800, height: 600)
    }
}
#endif

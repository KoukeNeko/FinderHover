//
//  SQLTextPreviewView.swift
//  FinderHoverQLExtension
//
//  SwiftUI view for SQL text file preview with syntax highlighting and table extraction
//

import SwiftUI
import Combine

// MARK: - SQL Table Definition Parser

struct SQLTableDefinition: Identifiable {
    let id = UUID()
    let name: String
    let columns: [SQLColumnDefinition]
    let sourceRange: Range<String.Index>?
    let lineNumber: Int
}

struct SQLColumnDefinition: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let constraints: [String]

    var isPrimaryKey: Bool {
        constraints.contains { $0.uppercased().contains("PRIMARY KEY") }
    }

    var isNotNull: Bool {
        constraints.contains { $0.uppercased().contains("NOT NULL") }
    }

    var isUnique: Bool {
        constraints.contains { $0.uppercased().contains("UNIQUE") }
    }
}

struct SQLDDLParser {
    static func extractTables(from sql: String) -> [SQLTableDefinition] {
        var tables: [SQLTableDefinition] = []

        // Pattern to match CREATE TABLE statements
        let pattern = #"CREATE\s+(?:TEMPORARY\s+)?TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?[`"\[]?(\w+)[`"\]]?\s*\(([\s\S]*?)\)\s*(?:ENGINE|DEFAULT|;|$)"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return tables
        }

        let nsString = sql as NSString
        let matches = regex.matches(in: sql, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            guard match.numberOfRanges >= 3,
                  let tableNameRange = Range(match.range(at: 1), in: sql),
                  let columnsRange = Range(match.range(at: 2), in: sql) else {
                continue
            }

            let tableName = String(sql[tableNameRange])
            let columnsStr = String(sql[columnsRange])

            // Calculate line number
            let lineNumber = sql[..<tableNameRange.lowerBound].filter { $0 == "\n" }.count + 1

            // Parse columns
            let columns = parseColumns(from: columnsStr)

            let sourceRange = Range(match.range, in: sql)

            let table = SQLTableDefinition(
                name: tableName,
                columns: columns,
                sourceRange: sourceRange,
                lineNumber: lineNumber
            )
            tables.append(table)
        }

        return tables
    }

    private static func parseColumns(from columnsStr: String) -> [SQLColumnDefinition] {
        var columns: [SQLColumnDefinition] = []

        // Split by comma but be careful with nested parentheses
        let parts = splitColumnDefinitions(columnsStr)

        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip constraints like PRIMARY KEY(...), FOREIGN KEY(...), etc.
            let upperTrimmed = trimmed.uppercased()
            if upperTrimmed.hasPrefix("PRIMARY KEY") ||
               upperTrimmed.hasPrefix("FOREIGN KEY") ||
               upperTrimmed.hasPrefix("UNIQUE") ||
               upperTrimmed.hasPrefix("CHECK") ||
               upperTrimmed.hasPrefix("CONSTRAINT") ||
               upperTrimmed.hasPrefix("INDEX") ||
               upperTrimmed.hasPrefix("KEY ") {
                continue
            }

            // Parse column: name type [constraints...]
            if let column = parseColumn(from: trimmed) {
                columns.append(column)
            }
        }

        return columns
    }

    private static func splitColumnDefinitions(_ str: String) -> [String] {
        var parts: [String] = []
        var current = ""
        var depth = 0

        for char in str {
            if char == "(" {
                depth += 1
                current.append(char)
            } else if char == ")" {
                depth -= 1
                current.append(char)
            } else if char == "," && depth == 0 {
                parts.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }

        if !current.isEmpty {
            parts.append(current)
        }

        return parts
    }

    private static func parseColumn(from str: String) -> SQLColumnDefinition? {
        // Remove backticks, quotes, brackets from column name
        let cleanStr = str.trimmingCharacters(in: .whitespacesAndNewlines)

        // Pattern: [name] [type] [constraints...]
        let pattern = #"^[`"\[]?(\w+)[`"\]]?\s+(\w+(?:\([^)]*\))?)\s*(.*)?$"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: cleanStr, options: [], range: NSRange(location: 0, length: cleanStr.count)) else {
            // Try simpler pattern for just name and type
            let simplePattern = #"^[`"\[]?(\w+)[`"\]]?\s+(\w+)"#
            guard let simpleRegex = try? NSRegularExpression(pattern: simplePattern, options: [.caseInsensitive]),
                  let simpleMatch = simpleRegex.firstMatch(in: cleanStr, options: [], range: NSRange(location: 0, length: cleanStr.count)),
                  simpleMatch.numberOfRanges >= 3,
                  let nameRange = Range(simpleMatch.range(at: 1), in: cleanStr),
                  let typeRange = Range(simpleMatch.range(at: 2), in: cleanStr) else {
                return nil
            }

            return SQLColumnDefinition(
                name: String(cleanStr[nameRange]),
                type: String(cleanStr[typeRange]),
                constraints: []
            )
        }

        guard match.numberOfRanges >= 3,
              let nameRange = Range(match.range(at: 1), in: cleanStr),
              let typeRange = Range(match.range(at: 2), in: cleanStr) else {
            return nil
        }

        let name = String(cleanStr[nameRange])
        let type = String(cleanStr[typeRange])

        var constraints: [String] = []
        if match.numberOfRanges >= 4, let constraintRange = Range(match.range(at: 3), in: cleanStr) {
            let constraintStr = String(cleanStr[constraintRange])
            if !constraintStr.isEmpty {
                constraints.append(constraintStr)
            }
        }

        return SQLColumnDefinition(name: name, type: type, constraints: constraints)
    }
}

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
        "TEMP", "WITH", "RECURSIVE", "VACUUM", "REINDEX", "ATTACH", "DETACH", "COMMENT"
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
                if (remaining.first == "'" || remaining.first == "\"") {
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
    @Published var tables: [SQLTableDefinition] = []
    @Published var selectedTable: SQLTableDefinition?

    init(fileName: String, fileSize: Int64, content: String) {
        self.fileName = fileName
        self.fileSize = fileSize
        self.content = content
        self.lineCount = content.components(separatedBy: "\n").count

        // Count SQL statements (rough estimate based on semicolons)
        self.statementCount = content.components(separatedBy: ";")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .count

        // Parse tables and highlight in background
        Task {
            await parseAndHighlight()
        }
    }

    func parseAndHighlight() async {
        // Parse table definitions
        let parsedTables = await Task.detached { [content] in
            SQLDDLParser.extractTables(from: content)
        }.value

        tables = parsedTables

        // Auto-select first table if available
        if let firstTable = parsedTables.first {
            selectedTable = firstTable
        }

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

    func selectTable(_ table: SQLTableDefinition) {
        selectedTable = table
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

            // Main content with split view
            HSplitView {
                // Left sidebar - Tables (only show if tables found)
                if !viewModel.tables.isEmpty {
                    tableSidebar
                        .frame(minWidth: 200, idealWidth: 250, maxWidth: 350)
                }

                // Right content - SQL source
                sourceCodeView
            }

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

                Text("SQL Script · \(viewModel.formattedFileSize)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Stats
            HStack(spacing: 16) {
                statBadge(icon: "text.alignleft", value: "\(viewModel.lineCount)", label: "lines")
                statBadge(icon: "command", value: "\(viewModel.statementCount)", label: "statements")
                if !viewModel.tables.isEmpty {
                    statBadge(icon: "tablecells", value: "\(viewModel.tables.count)", label: "tables")
                }
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

    // MARK: - Table Sidebar

    private var tableSidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Tables section
                schemaSection(
                    title: "Tables",
                    icon: "tablecells",
                    count: viewModel.tables.count
                ) {
                    ForEach(viewModel.tables) { table in
                        tableRow(table)
                    }
                }

                // Selected table schema
                if let selectedTable = viewModel.selectedTable {
                    Divider()

                    schemaSection(
                        title: "Schema: \(selectedTable.name)",
                        icon: "list.bullet.rectangle",
                        count: selectedTable.columns.count
                    ) {
                        ForEach(selectedTable.columns) { column in
                            columnRow(column)
                        }
                    }
                }
            }
            .padding(12)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func schemaSection<Content: View>(
        title: String,
        icon: String,
        count: Int,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()

                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            content()
        }
    }

    private func tableRow(_ table: SQLTableDefinition) -> some View {
        Button(action: {
            viewModel.selectTable(table)
        }) {
            HStack(spacing: 8) {
                Image(systemName: "tablecells")
                    .font(.caption)
                    .foregroundColor(viewModel.selectedTable?.id == table.id ? .white : .secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text(table.name)
                        .font(.system(size: 12))
                        .lineLimit(1)

                    Text("\(table.columns.count) columns · Line \(table.lineNumber)")
                        .font(.system(size: 10))
                        .foregroundColor(viewModel.selectedTable?.id == table.id ? .white.opacity(0.8) : .secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                viewModel.selectedTable?.id == table.id
                    ? Color.accentColor
                    : Color.clear
            )
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private func columnRow(_ column: SQLColumnDefinition) -> some View {
        HStack(spacing: 8) {
            // Column icon based on constraints
            if column.isPrimaryKey {
                Image(systemName: "key.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)
            } else {
                Image(systemName: "circle.fill")
                    .font(.system(size: 6))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(column.name)
                        .font(.system(size: 11, weight: column.isPrimaryKey ? .semibold : .regular))
                        .lineLimit(1)

                    if column.isNotNull {
                        Text("*")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                    }
                }

                Text(column.type)
                    .font(.system(size: 10))
                    .foregroundColor(.green)
            }

            Spacer()

            // Constraint badges
            if column.isUnique && !column.isPrimaryKey {
                Text("UQ")
                    .font(.system(size: 9))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(3)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - Source Code View

    private var sourceCodeView: some View {
        VStack(spacing: 0) {
            // Source header
            HStack {
                Text("SQL Source")
                    .font(.headline)

                Spacer()

                if viewModel.isHighlighting {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Highlighting...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Content
            contentView
        }
    }

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

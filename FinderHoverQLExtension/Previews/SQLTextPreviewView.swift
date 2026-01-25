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
    var data: [[String]] = []  // Parsed INSERT data
    var rowCount: Int { data.count }
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

            var table = SQLTableDefinition(
                name: tableName,
                columns: columns,
                sourceRange: sourceRange,
                lineNumber: lineNumber
            )

            // Parse INSERT data for this table
            table.data = parseInsertData(for: tableName, columns: columns, from: sql)

            tables.append(table)
        }

        return tables
    }

    // Parse INSERT statements to extract data
    static func parseInsertData(for tableName: String, columns: [SQLColumnDefinition], from sql: String) -> [[String]] {
        var rows: [[String]] = []

        // Pattern to match INSERT INTO statements for this table
        // Matches: INSERT INTO `tablename` (...) VALUES (...), (...), ...;
        let pattern = #"INSERT\s+INTO\s+[`"\[]?\#(NSRegularExpression.escapedPattern(for: tableName))[`"\]]?\s*(?:\([^)]*\))?\s*VALUES\s*([\s\S]*?);"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return rows
        }

        let nsString = sql as NSString
        let matches = regex.matches(in: sql, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            guard match.numberOfRanges >= 2,
                  let valuesRange = Range(match.range(at: 1), in: sql) else {
                continue
            }

            let valuesStr = String(sql[valuesRange])
            let parsedRows = parseValueTuples(from: valuesStr)
            rows.append(contentsOf: parsedRows)

            // Limit to 100 rows for performance
            if rows.count >= 100 {
                break
            }
        }

        return rows
    }

    // Parse value tuples like (1, 'hello', 2), (3, 'world', 4)
    static func parseValueTuples(from str: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentValue = ""
        var inString = false
        var stringChar: Character = "'"
        var depth = 0
        var escapeNext = false

        for char in str {
            if escapeNext {
                currentValue.append(char)
                escapeNext = false
                continue
            }

            if char == "\\" {
                escapeNext = true
                continue
            }

            if !inString {
                if char == "'" || char == "\"" {
                    inString = true
                    stringChar = char
                    continue
                }

                if char == "(" {
                    depth += 1
                    if depth == 1 {
                        currentRow = []
                        currentValue = ""
                    }
                    continue
                }

                if char == ")" {
                    depth -= 1
                    if depth == 0 {
                        // End of tuple
                        let trimmed = currentValue.trimmingCharacters(in: .whitespaces)
                        currentRow.append(trimmed.isEmpty ? "NULL" : trimmed)
                        rows.append(currentRow)
                        currentRow = []
                        currentValue = ""

                        // Limit rows
                        if rows.count >= 100 {
                            return rows
                        }
                    }
                    continue
                }

                if char == "," && depth == 1 {
                    let trimmed = currentValue.trimmingCharacters(in: .whitespaces)
                    currentRow.append(trimmed.isEmpty ? "NULL" : trimmed)
                    currentValue = ""
                    continue
                }

                if depth >= 1 {
                    currentValue.append(char)
                }
            } else {
                // Inside string
                if char == stringChar {
                    inString = false
                } else {
                    currentValue.append(char)
                }
            }
        }

        return rows
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

                // Handle escape sequences inside strings
                if inString && remaining.first == "\\" {
                    // Check if there's a next character to escape
                    let nextIndex = line.index(after: currentIndex)
                    if nextIndex < line.endIndex {
                        // Add backslash and escaped character together
                        let escapedChar = line[nextIndex]
                        var escapeStr = AttributedString(String(remaining.first!) + String(escapedChar))
                        escapeStr.foregroundColor = .yellow  // Different color for escape sequences
                        result += escapeStr
                        currentIndex = line.index(after: nextIndex)
                        continue
                    }
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

// MARK: - View Mode

enum SQLViewMode: String, CaseIterable {
    case schema = "Schema"
    case data = "Data"
    case source = "Source"
}

// MARK: - View Model

@MainActor
class SQLTextPreviewViewModel: ObservableObject {
    let fileName: String
    let fileSize: Int64
    let content: String
    let lineCount: Int
    let statementCount: Int
    let lineNumbersString: String  // Cached for performance

    // Pre-computed content for instant switching
    @Published var highlightedContent: AttributedString?
    @Published var plainContent: AttributedString  // Fallback plain text
    @Published var isReady = false  // All content ready for display
    @Published var tables: [SQLTableDefinition] = []
    @Published var selectedTable: SQLTableDefinition?
    @Published var viewMode: SQLViewMode = .data

    // Pre-cached NSAttributedString for Source view (created in background)
    var cachedPlainNSAttributedString: NSAttributedString?
    var cachedHighlightedNSAttributedString: NSAttributedString?

    init(fileName: String, fileSize: Int64, content: String) {
        self.fileName = fileName
        self.fileSize = fileSize
        self.content = content
        let count = content.components(separatedBy: "\n").count
        self.lineCount = count
        self.lineNumbersString = (1...max(1, count)).map { String($0) }.joined(separator: "\n")

        // Pre-compute plain content immediately
        var plain = AttributedString(content)
        plain.font = .system(size: 12, design: .monospaced)
        self.plainContent = plain

        // Count SQL statements (rough estimate based on semicolons)
        self.statementCount = content.components(separatedBy: ";")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .count

        // Parse tables and highlight in background
        Task(priority: .userInitiated) {
            await parseAndHighlight()
        }
    }

    func parseAndHighlight() async {
        // Run parsing and highlighting in parallel
        let contentCopy = content

        async let tablesTask: [SQLTableDefinition] = Task.detached(priority: .userInitiated) {
            SQLDDLParser.extractTables(from: contentCopy)
        }.value

        async let highlightTask: AttributedString? = Task.detached(priority: .userInitiated) {
            // Skip highlighting for very large files
            guard contentCopy.count <= 500_000 else { return nil }
            return SQLSyntaxHighlighter.highlight(contentCopy)
        }.value

        // Pre-cache plain NSAttributedString in background
        async let plainNSTask: NSAttributedString = Task.detached(priority: .userInitiated) {
            let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.labelColor
            ]
            return NSAttributedString(string: contentCopy, attributes: attributes)
        }.value

        // Wait for both to complete
        let (parsedTables, highlighted) = await (tablesTask, highlightTask)

        // Cache plain NSAttributedString
        cachedPlainNSAttributedString = await plainNSTask

        // Update tables
        tables = parsedTables

        // Auto-select first table if available
        if let firstTable = parsedTables.first {
            selectedTable = firstTable
            viewMode = firstTable.data.isEmpty ? .schema : .data
        }

        // Update highlighted content and cache NSAttributedString
        if let highlighted = highlighted {
            highlightedContent = highlighted

            // Convert to NSAttributedString in background
            Task.detached(priority: .userInitiated) {
                let nsAttrString = NSAttributedString(highlighted)
                await MainActor.run {
                    self.cachedHighlightedNSAttributedString = nsAttrString
                }
            }
        }

        // Mark as ready
        isReady = true
    }

    func selectTable(_ table: SQLTableDefinition) {
        selectedTable = table
    }

    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    // Get the best available content for source view
    var sourceContent: AttributedString {
        highlightedContent ?? plainContent
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
                        .frame(minWidth: 180, idealWidth: 200, maxWidth: 300)
                }

                // Right content - Based on view mode
                rightContentView
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

                    Text("\(table.columns.count) cols · \(table.rowCount) rows")
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

    // MARK: - Right Content View

    private var rightContentView: some View {
        VStack(spacing: 0) {
            // Tab bar for view mode
            if let selectedTable = viewModel.selectedTable {
                viewModeTabBar(table: selectedTable)
                Divider()
            }

            // Conditional rendering - only render active view
            Group {
                switch viewModel.viewMode {
                case .schema:
                    schemaView
                case .data:
                    dataTableView
                case .source:
                    sourceCodeView
                }
            }
            .animation(.easeInOut(duration: 0.1), value: viewModel.viewMode)
        }
    }

    private func viewModeTabBar(table: SQLTableDefinition) -> some View {
        HStack(spacing: 0) {
            Text("Table: \(table.name)")
                .font(.headline)
                .padding(.leading, 16)

            Spacer()

            // View mode tabs
            HStack(spacing: 2) {
                ForEach(SQLViewMode.allCases, id: \.self) { mode in
                    Button(action: {
                        viewModel.viewMode = mode
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: iconForMode(mode))
                                .font(.caption)
                            Text(mode.rawValue)
                                .font(.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            viewModel.viewMode == mode
                                ? Color.accentColor
                                : Color.secondary.opacity(0.2)
                        )
                        .foregroundColor(viewModel.viewMode == mode ? .white : .primary)
                        .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.trailing, 16)
        }
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func iconForMode(_ mode: SQLViewMode) -> String {
        switch mode {
        case .schema: return "list.bullet.rectangle"
        case .data: return "tablecells"
        case .source: return "doc.text"
        }
    }

    // MARK: - Schema View

    private var schemaView: some View {
        ScrollView {
            if let selectedTable = viewModel.selectedTable {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(selectedTable.columns) { column in
                        schemaColumnRow(column)
                    }
                }
                .padding(16)
            } else {
                noSelectionView
            }
        }
        .drawingGroup()  // Flatten for better performance
    }

    private func schemaColumnRow(_ column: SQLColumnDefinition) -> some View {
        HStack(spacing: 12) {
            // Column icon
            if column.isPrimaryKey {
                Image(systemName: "key.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.yellow)
                    .frame(width: 20)
            } else {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(column.name)
                        .font(.system(size: 13, weight: column.isPrimaryKey ? .semibold : .regular, design: .monospaced))

                    if column.isNotNull {
                        Text("NOT NULL")
                            .font(.system(size: 9))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(3)
                    }

                    if column.isUnique && !column.isPrimaryKey {
                        Text("UNIQUE")
                            .font(.system(size: 9))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(3)
                    }

                    if column.isPrimaryKey {
                        Text("PRIMARY KEY")
                            .font(.system(size: 9))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.2))
                            .foregroundColor(.yellow)
                            .cornerRadius(3)
                    }
                }

                Text(column.type)
                    .font(.system(size: 11))
                    .foregroundColor(.green)
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(6)
    }

    // MARK: - Data Table View

    private var dataTableView: some View {
        Group {
            if let selectedTable = viewModel.selectedTable {
                if selectedTable.data.isEmpty {
                    emptyDataView
                } else {
                    ScrollView([.horizontal, .vertical]) {
                        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                            Section(header: columnHeaderRow(columns: selectedTable.columns, table: selectedTable)) {
                                // Data rows
                                ForEach(Array(selectedTable.data.enumerated()), id: \.offset) { index, row in
                                    dataRow(row: row, columns: selectedTable.columns, index: index, table: selectedTable)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .drawingGroup()  // Flatten for better performance
                }
            } else {
                noSelectionView
            }
        }
    }

    private func columnHeaderRow(columns: [SQLColumnDefinition], table: SQLTableDefinition) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(columns.enumerated()), id: \.offset) { index, column in
                columnHeader(column, width: columnWidth(for: index, in: table))
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func dataRow(row: [String], columns: [SQLColumnDefinition], index: Int, table: SQLTableDefinition) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(row.enumerated()), id: \.offset) { colIndex, value in
                dataCell(value: value, width: columnWidth(for: colIndex, in: table))
            }
            // Fill remaining columns if row is shorter
            if row.count < columns.count {
                ForEach(row.count..<columns.count, id: \.self) { colIndex in
                    dataCell(value: "NULL", width: columnWidth(for: colIndex, in: table))
                }
            }
        }
        .background(
            index % 2 == 0
                ? Color.clear
                : Color.secondary.opacity(0.05)
        )
    }

    private func columnHeader(_ column: SQLColumnDefinition, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                if column.isPrimaryKey {
                    Image(systemName: "key.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.yellow)
                }

                Text(column.name)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }

            Text(column.type.isEmpty ? "ANY" : column.type)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(width: width, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .border(Color.secondary.opacity(0.2), width: 0.5)
    }

    private func dataCell(value: String, width: CGFloat) -> some View {
        Text(value)
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(value == "NULL" ? .secondary : .primary)
            .lineLimit(2)
            .frame(width: width, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .border(Color.secondary.opacity(0.1), width: 0.5)
    }

    // Calculate optimal column width based on content
    private func columnWidth(for columnIndex: Int, in table: SQLTableDefinition) -> CGFloat {
        let minWidth: CGFloat = 60
        let maxWidth: CGFloat = 250

        guard columnIndex < table.columns.count else { return minWidth }

        let column = table.columns[columnIndex]

        // Start with column name length
        var maxLength = column.name.count

        // Check data values (sample first 20 rows)
        for row in table.data.prefix(20) {
            if columnIndex < row.count {
                maxLength = max(maxLength, row[columnIndex].count)
            }
        }

        // Calculate width: ~7 points per character + padding
        let calculatedWidth = CGFloat(maxLength) * 7 + 24

        return min(max(calculatedWidth, minWidth), maxWidth)
    }

    private var emptyDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.title)
                .foregroundColor(.secondary)

            Text("No Data")
                .font(.headline)

            Text("No INSERT statements found for this table")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noSelectionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.point.left")
                .font(.title)
                .foregroundColor(.secondary)

            Text("Select a table")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Choose a table from the sidebar")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Source Code View

    private var sourceCodeView: some View {
        SourceCodeTextView(
            cachedPlainNS: viewModel.cachedPlainNSAttributedString,
            cachedHighlightedNS: viewModel.cachedHighlightedNSAttributedString,
            fallbackContent: viewModel.content
        )
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

            if let selectedTable = viewModel.selectedTable, viewModel.viewMode == .data {
                Text("\(selectedTable.rowCount) rows (max 100)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

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

// MARK: - Native Source Code View (NSTextView for performance)

struct SourceCodeTextView: NSViewRepresentable {
    // Pre-cached NSAttributedStrings from ViewModel (already created in background)
    let cachedPlainNS: NSAttributedString?
    let cachedHighlightedNS: NSAttributedString?
    let fallbackContent: String  // Only used if no cache available

    class Coordinator {
        var hasSetContent = false
        var hasAppliedHighlight = false
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder

        let textView = LineNumberTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.allowsUndo = false
        textView.isRichText = true
        textView.usesFontPanel = false
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textContainerInset = NSSize(width: 8, height: 8)

        // Configure text container for horizontal scrolling
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isHorizontallyResizable = true
        textView.isVerticallyResizable = true
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        scrollView.documentView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? LineNumberTextView else { return }

        let coordinator = context.coordinator

        // If highlighted content is available and not yet applied, use it
        if let highlighted = cachedHighlightedNS, !coordinator.hasAppliedHighlight {
            textView.textStorage?.setAttributedString(highlighted)
            textView.updateLineNumbers()
            coordinator.hasSetContent = true
            coordinator.hasAppliedHighlight = true
            return
        }

        // If no content set yet, use plain cached or fallback
        if !coordinator.hasSetContent {
            if let plain = cachedPlainNS {
                textView.textStorage?.setAttributedString(plain)
            } else {
                // Fallback: create plain content (should rarely happen)
                let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: NSColor.labelColor
                ]
                let attrString = NSAttributedString(string: fallbackContent, attributes: attributes)
                textView.textStorage?.setAttributedString(attrString)
            }
            textView.updateLineNumbers()
            coordinator.hasSetContent = true
        }
    }
}

// Custom NSTextView with line numbers
class LineNumberTextView: NSTextView {
    private var lineNumberView: LineNumberRulerView?

    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        setupLineNumbers()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLineNumbers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLineNumbers()
    }

    private func setupLineNumbers() {
        // Set up font
        self.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)

        // Enable line number ruler
        postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange(_:)),
            name: NSText.didChangeNotification,
            object: self
        )
    }

    func updateLineNumbers() {
        guard let scrollView = enclosingScrollView else { return }

        if lineNumberView == nil {
            lineNumberView = LineNumberRulerView(textView: self)
            scrollView.verticalRulerView = lineNumberView
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
        }

        lineNumberView?.needsDisplay = true
    }

    @objc private func textDidChange(_ notification: Notification) {
        updateLineNumbers()
    }

    override func didChangeText() {
        super.didChangeText()
        updateLineNumbers()
    }
}

// Line number ruler view
class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?

    init(textView: NSTextView) {
        self.textView = textView
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 50
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        // Background
        NSColor.controlBackgroundColor.withAlphaComponent(0.5).setFill()
        rect.fill()

        // Draw line numbers
        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.secondaryLabelColor
        ]

        let content = textView.string
        let visibleRect = textView.visibleRect
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        // Calculate line numbers
        var lineNumber = 1
        var index = content.startIndex

        // Count lines before visible range
        let charStartIndex = content.index(content.startIndex, offsetBy: charRange.location, limitedBy: content.endIndex) ?? content.startIndex
        var tempIndex = content.startIndex
        while tempIndex < charStartIndex {
            if content[tempIndex] == "\n" {
                lineNumber += 1
            }
            tempIndex = content.index(after: tempIndex)
        }

        // Draw visible line numbers
        index = charStartIndex
        let endIndex = content.index(content.startIndex, offsetBy: min(charRange.location + charRange.length, content.count), limitedBy: content.endIndex) ?? content.endIndex

        var lastDrawnLine = 0
        while index < endIndex {
            let charIndex = content.distance(from: content.startIndex, to: index)
            let glyphIndex = layoutManager.glyphIndexForCharacter(at: charIndex)
            var lineFragmentRect = NSRect.zero
            layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil, withoutAdditionalLayout: true)
            lineFragmentRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)

            if lineNumber != lastDrawnLine {
                let yPos = lineFragmentRect.origin.y - visibleRect.origin.y + textView.textContainerInset.height
                let lineStr = "\(lineNumber)"
                let size = lineStr.size(withAttributes: attributes)
                let drawRect = NSRect(
                    x: ruleThickness - size.width - 8,
                    y: yPos + (lineFragmentRect.height - size.height) / 2,
                    width: size.width,
                    height: size.height
                )
                lineStr.draw(in: drawRect, withAttributes: attributes)
                lastDrawnLine = lineNumber
            }

            // Find next line
            while index < endIndex && content[index] != "\n" {
                index = content.index(after: index)
            }
            if index < endIndex {
                index = content.index(after: index)
                lineNumber += 1
            }
        }
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

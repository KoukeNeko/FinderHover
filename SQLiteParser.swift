//
//  SQLiteParser.swift
//  FinderHover
//
//  SQLite database parser for Quick Look preview
//  Shared between main app and QL Extension
//

import Foundation
import SQLite3

// MARK: - Error Types

enum SQLiteError: Error, LocalizedError {
    case cannotOpen(String)
    case queryFailed(String)
    case invalidDatabase
    case timeout

    var errorDescription: String? {
        switch self {
        case .cannotOpen(let path):
            return "Cannot open database: \(path)"
        case .queryFailed(let message):
            return "Query failed: \(message)"
        case .invalidDatabase:
            return "Invalid SQLite database file"
        case .timeout:
            return "Database operation timed out"
        }
    }
}

// MARK: - Data Structures

/// Information about a database table
struct TableInfo: Identifiable {
    let id = UUID()
    let name: String
    let columns: [ColumnInfo]
    let rowCount: Int
    let type: String // "table" or "view"

    var isSystemTable: Bool {
        name.hasPrefix("sqlite_")
    }
}

/// Information about a table column
struct ColumnInfo: Identifiable {
    let id = UUID()
    let cid: Int           // Column ID
    let name: String
    let type: String       // Data type (TEXT, INTEGER, REAL, BLOB, NULL)
    let isNotNull: Bool
    let defaultValue: String?
    let isPrimaryKey: Bool
}

/// Information about a database index
struct IndexInfo: Identifiable {
    let id = UUID()
    let name: String
    let tableName: String
    let isUnique: Bool
    let columns: [String]
}

/// Information about a database trigger
struct TriggerInfo: Identifiable {
    let id = UUID()
    let name: String
    let tableName: String
    let timing: String     // BEFORE, AFTER, INSTEAD OF
    let event: String      // INSERT, UPDATE, DELETE
}

/// Database statistics summary
struct DatabaseStats {
    let tableCount: Int
    let viewCount: Int
    let indexCount: Int
    let triggerCount: Int
    let totalRows: Int?
    let schemaVersion: Int?
    let pageSize: Int?
    let pageCount: Int?
    let encoding: String?
    let sqliteVersion: String
    let fileSize: Int64

    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var summary: String {
        var parts: [String] = []
        parts.append("\(tableCount) table\(tableCount == 1 ? "" : "s")")
        if viewCount > 0 {
            parts.append("\(viewCount) view\(viewCount == 1 ? "" : "s")")
        }
        if indexCount > 0 {
            parts.append("\(indexCount) index\(indexCount == 1 ? "" : "es")")
        }
        if let rows = totalRows {
            parts.append("\(formatNumber(rows)) row\(rows == 1 ? "" : "s")")
        }
        return parts.joined(separator: " · ")
    }

    private func formatNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }
}

/// A row of data from a table
struct TableRow: Identifiable {
    let id = UUID()
    let values: [String: Any?]

    func stringValue(for column: String) -> String {
        guard let value = values[column] else { return "NULL" }
        if value == nil { return "NULL" }
        if let data = value as? Data {
            return "<BLOB \(data.count) bytes>"
        }
        return "\(value!)"
    }
}

// MARK: - SQLite Database Parser

/// Thread-safe SQLite database parser
final class SQLiteDatabase {
    private var db: OpaquePointer?
    private let path: String
    private let queue = DispatchQueue(label: "com.finderhover.sqliteparser")

    // MARK: - Initialization

    init(path: String) throws {
        self.path = path

        // Verify SQLite magic number first
        guard Self.isSQLiteFile(at: path) else {
            throw SQLiteError.invalidDatabase
        }

        // Open database in read-only mode
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX
        guard sqlite3_open_v2(path, &db, flags, nil) == SQLITE_OK else {
            let errorMsg = db != nil ? String(cString: sqlite3_errmsg(db)) : "Unknown error"
            throw SQLiteError.cannotOpen(errorMsg)
        }

        // Set busy timeout to prevent blocking
        sqlite3_busy_timeout(db, 5000) // 5 seconds
    }

    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }

    // MARK: - Static Helpers

    /// Check if file is a valid SQLite database by reading magic bytes
    static func isSQLiteFile(at path: String) -> Bool {
        guard let handle = FileHandle(forReadingAtPath: path) else { return false }
        defer { try? handle.close() }

        guard let data = try? handle.read(upToCount: 16),
              data.count >= 16 else {
            return false
        }

        let magic = String(data: data, encoding: .utf8)
        return magic?.hasPrefix("SQLite format") == true
    }

    /// Get supported file extensions
    static var supportedExtensions: [String] {
        ["db", "sqlite", "sqlite3", "db3"]
    }

    // MARK: - Public API

    /// Get database statistics
    func getStatistics() throws -> DatabaseStats {
        let tableCount = try queryInt("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'") ?? 0
        let viewCount = try queryInt("SELECT COUNT(*) FROM sqlite_master WHERE type='view'") ?? 0
        let indexCount = try queryInt("SELECT COUNT(*) FROM sqlite_master WHERE type='index'") ?? 0
        let triggerCount = try queryInt("SELECT COUNT(*) FROM sqlite_master WHERE type='trigger'") ?? 0
        let schemaVersion = try queryInt("PRAGMA schema_version")
        let pageSize = try queryInt("PRAGMA page_size")
        let pageCount = try queryInt("PRAGMA page_count")
        let encoding = try queryString("PRAGMA encoding")
        let sqliteVersion = String(cString: sqlite3_libversion())

        // Get file size
        let fileSize: Int64
        if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
           let size = attrs[.size] as? Int64 {
            fileSize = size
        } else {
            fileSize = 0
        }

        return DatabaseStats(
            tableCount: tableCount,
            viewCount: viewCount,
            indexCount: indexCount,
            triggerCount: triggerCount,
            totalRows: nil, // Skip for performance
            schemaVersion: schemaVersion,
            pageSize: pageSize,
            pageCount: pageCount,
            encoding: encoding,
            sqliteVersion: sqliteVersion,
            fileSize: fileSize
        )
    }

    /// Get all tables (excluding system tables)
    func getTables() throws -> [TableInfo] {
        let query = """
            SELECT name, type FROM sqlite_master
            WHERE (type='table' OR type='view')
            AND name NOT LIKE 'sqlite_%'
            ORDER BY type DESC, name ASC
            """

        var tables: [TableInfo] = []

        try executeQuery(query) { statement in
            while sqlite3_step(statement) == SQLITE_ROW {
                guard let namePtr = sqlite3_column_text(statement, 0) else { continue }
                let name = String(cString: namePtr)
                let typePtr = sqlite3_column_text(statement, 1)
                let type = typePtr != nil ? String(cString: typePtr!) : "table"

                // Get columns for this table
                let columns = (try? getColumns(for: name)) ?? []

                // Get row count (with limit for performance)
                let rowCount = (try? getRowCount(for: name)) ?? 0

                tables.append(TableInfo(
                    name: name,
                    columns: columns,
                    rowCount: rowCount,
                    type: type
                ))
            }
        }

        return tables
    }

    /// Get columns for a specific table
    func getColumns(for tableName: String) throws -> [ColumnInfo] {
        var columns: [ColumnInfo] = []

        // Use PRAGMA to get column info
        let query = "PRAGMA table_info('\(escapeSQLString(tableName))')"

        try executeQuery(query) { statement in
            while sqlite3_step(statement) == SQLITE_ROW {
                let cid = Int(sqlite3_column_int(statement, 0))
                let name = sqlite3_column_text(statement, 1).map { String(cString: $0) } ?? ""
                let type = sqlite3_column_text(statement, 2).map { String(cString: $0) } ?? ""
                let notNull = sqlite3_column_int(statement, 3) != 0
                let defaultValue = sqlite3_column_text(statement, 4).map { String(cString: $0) }
                let pk = sqlite3_column_int(statement, 5) != 0

                columns.append(ColumnInfo(
                    cid: cid,
                    name: name,
                    type: type,
                    isNotNull: notNull,
                    defaultValue: defaultValue,
                    isPrimaryKey: pk
                ))
            }
        }

        return columns
    }

    /// Get all indexes
    func getIndexes() throws -> [IndexInfo] {
        var indexes: [IndexInfo] = []

        let query = """
            SELECT name, tbl_name FROM sqlite_master
            WHERE type='index' AND name NOT LIKE 'sqlite_%'
            ORDER BY tbl_name, name
            """

        try executeQuery(query) { statement in
            while sqlite3_step(statement) == SQLITE_ROW {
                guard let namePtr = sqlite3_column_text(statement, 0),
                      let tablePtr = sqlite3_column_text(statement, 1) else { continue }

                let name = String(cString: namePtr)
                let tableName = String(cString: tablePtr)

                // Get index details
                let indexInfo = try? getIndexInfo(name: name, tableName: tableName)

                indexes.append(IndexInfo(
                    name: name,
                    tableName: tableName,
                    isUnique: indexInfo?.isUnique ?? false,
                    columns: indexInfo?.columns ?? []
                ))
            }
        }

        return indexes
    }

    /// Get all triggers
    func getTriggers() throws -> [TriggerInfo] {
        var triggers: [TriggerInfo] = []

        let query = """
            SELECT name, tbl_name, sql FROM sqlite_master
            WHERE type='trigger'
            ORDER BY tbl_name, name
            """

        try executeQuery(query) { statement in
            while sqlite3_step(statement) == SQLITE_ROW {
                guard let namePtr = sqlite3_column_text(statement, 0),
                      let tablePtr = sqlite3_column_text(statement, 1) else { continue }

                let name = String(cString: namePtr)
                let tableName = String(cString: tablePtr)
                let sql = sqlite3_column_text(statement, 2).map { String(cString: $0) } ?? ""

                // Parse timing and event from SQL
                let (timing, event) = parseTriggerSQL(sql)

                triggers.append(TriggerInfo(
                    name: name,
                    tableName: tableName,
                    timing: timing,
                    event: event
                ))
            }
        }

        return triggers
    }

    /// Get table data with pagination
    func getTableData(tableName: String, limit: Int = 100, offset: Int = 0) throws -> [TableRow] {
        var rows: [TableRow] = []

        // Get column names first
        let columns = try getColumns(for: tableName)
        let columnNames = columns.map { $0.name }

        let query = "SELECT * FROM \"\(escapeSQLString(tableName))\" LIMIT \(limit) OFFSET \(offset)"

        try executeQuery(query) { statement in
            let columnCount = Int(sqlite3_column_count(statement))

            while sqlite3_step(statement) == SQLITE_ROW {
                var values: [String: Any?] = [:]

                for i in 0..<columnCount {
                    let colName = columnNames.indices.contains(i) ? columnNames[i] : "col_\(i)"
                    let colType = sqlite3_column_type(statement, Int32(i))

                    switch colType {
                    case SQLITE_INTEGER:
                        values[colName] = sqlite3_column_int64(statement, Int32(i))
                    case SQLITE_FLOAT:
                        values[colName] = sqlite3_column_double(statement, Int32(i))
                    case SQLITE_TEXT:
                        if let text = sqlite3_column_text(statement, Int32(i)) {
                            values[colName] = String(cString: text)
                        } else {
                            values[colName] = nil
                        }
                    case SQLITE_BLOB:
                        let bytes = sqlite3_column_bytes(statement, Int32(i))
                        if let blob = sqlite3_column_blob(statement, Int32(i)) {
                            values[colName] = Data(bytes: blob, count: Int(bytes))
                        } else {
                            values[colName] = nil
                        }
                    case SQLITE_NULL:
                        values[colName] = nil
                    default:
                        values[colName] = nil
                    }
                }

                rows.append(TableRow(values: values))
            }
        }

        return rows
    }

    // MARK: - Private Helpers

    private func executeQuery(_ sql: String, handler: (OpaquePointer) throws -> Void) throws {
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            throw SQLiteError.queryFailed(errorMsg)
        }

        defer { sqlite3_finalize(statement) }

        try handler(statement!)
    }

    private func queryInt(_ sql: String) throws -> Int? {
        var result: Int?

        try executeQuery(sql) { statement in
            if sqlite3_step(statement) == SQLITE_ROW {
                result = Int(sqlite3_column_int64(statement, 0))
            }
        }

        return result
    }

    private func queryString(_ sql: String) throws -> String? {
        var result: String?

        try executeQuery(sql) { statement in
            if sqlite3_step(statement) == SQLITE_ROW {
                if let text = sqlite3_column_text(statement, 0) {
                    result = String(cString: text)
                }
            }
        }

        return result
    }

    private func getRowCount(for tableName: String) throws -> Int {
        // Use a fast approximation for large tables
        let query = "SELECT COUNT(*) FROM \"\(escapeSQLString(tableName))\" LIMIT 1"
        return try queryInt(query) ?? 0
    }

    private func getIndexInfo(name: String, tableName: String) throws -> (isUnique: Bool, columns: [String])? {
        var isUnique = false
        var columns: [String] = []

        let query = "PRAGMA index_info('\(escapeSQLString(name))')"
        try executeQuery(query) { statement in
            while sqlite3_step(statement) == SQLITE_ROW {
                if let colName = sqlite3_column_text(statement, 2) {
                    columns.append(String(cString: colName))
                }
            }
        }

        // Check if unique
        let listQuery = "PRAGMA index_list('\(escapeSQLString(tableName))')"
        try executeQuery(listQuery) { statement in
            while sqlite3_step(statement) == SQLITE_ROW {
                if let indexName = sqlite3_column_text(statement, 1),
                   String(cString: indexName) == name {
                    isUnique = sqlite3_column_int(statement, 2) != 0
                    break
                }
            }
        }

        return (isUnique, columns)
    }

    private func parseTriggerSQL(_ sql: String) -> (timing: String, event: String) {
        let uppercased = sql.uppercased()

        var timing = "AFTER"
        if uppercased.contains("BEFORE") {
            timing = "BEFORE"
        } else if uppercased.contains("INSTEAD OF") {
            timing = "INSTEAD OF"
        }

        var event = "INSERT"
        if uppercased.contains("UPDATE") {
            event = "UPDATE"
        } else if uppercased.contains("DELETE") {
            event = "DELETE"
        }

        return (timing, event)
    }

    private func escapeSQLString(_ str: String) -> String {
        str.replacingOccurrences(of: "'", with: "''")
    }
}

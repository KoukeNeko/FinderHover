//
//  SQLitePreviewView.swift
//  FinderHoverQLExtension
//
//  SwiftUI view for SQLite database preview
//

import SwiftUI
import Combine

// MARK: - View Model

@MainActor
class SQLitePreviewViewModel: ObservableObject {
    let fileName: String
    let stats: DatabaseStats
    let tables: [TableInfo]
    let indexes: [IndexInfo]
    let triggers: [TriggerInfo]

    @Published var selectedTable: TableInfo?
    @Published var tableData: [TableRow] = []
    @Published var isLoadingData = false
    @Published var dataError: String?

    private let database: SQLiteDatabase

    init(fileName: String,
         stats: DatabaseStats,
         tables: [TableInfo],
         indexes: [IndexInfo],
         triggers: [TriggerInfo],
         database: SQLiteDatabase) {
        self.fileName = fileName
        self.stats = stats
        self.tables = tables
        self.indexes = indexes
        self.triggers = triggers
        self.database = database

        // Auto-select first table
        if let firstTable = tables.first {
            self.selectedTable = firstTable
            Task {
                await loadTableData(for: firstTable)
            }
        }
    }

    func loadTableData(for table: TableInfo) async {
        isLoadingData = true
        dataError = nil

        do {
            let rows = try database.getTableData(tableName: table.name, limit: 100)
            tableData = rows
        } catch {
            dataError = error.localizedDescription
            tableData = []
        }

        isLoadingData = false
    }

    func selectTable(_ table: TableInfo) {
        // Immediately clear old data and show loading state
        selectedTable = table
        tableData = []
        isLoadingData = true
        dataError = nil

        Task {
            await loadTableData(for: table)
        }
    }
}

// MARK: - Main Preview View

struct SQLitePreviewView: View {
    @StateObject var viewModel: SQLitePreviewViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Main content
            HSplitView {
                // Left sidebar - Schema
                schemaSidebar
                    .frame(minWidth: 200, idealWidth: 250, maxWidth: 350)

                // Right content - Data preview
                dataPreviewArea
            }

            Divider()

            // Footer - Statistics
            footerView
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "cylinder.split.1x2")
                .font(.system(size: 24))
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.fileName)
                    .font(.headline)
                    .lineLimit(1)

                Text("\(NSLocalizedString("ql.sqlite.title", comment: "")) · \(viewModel.stats.formattedFileSize)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // SQLite version badge
            Text("SQLite \(viewModel.stats.sqliteVersion)")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Schema Sidebar

    private var schemaSidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Tables section
                schemaSection(
                    title: NSLocalizedString("ql.common.tables", comment: ""),
                    icon: "tablecells",
                    count: viewModel.tables.filter { $0.type == "table" }.count
                ) {
                    ForEach(viewModel.tables.filter { $0.type == "table" }) { table in
                        tableRow(table)
                    }
                }

                // Views section
                if viewModel.tables.contains(where: { $0.type == "view" }) {
                    schemaSection(
                        title: NSLocalizedString("ql.common.views", comment: ""),
                        icon: "eye",
                        count: viewModel.tables.filter { $0.type == "view" }.count
                    ) {
                        ForEach(viewModel.tables.filter { $0.type == "view" }) { table in
                            tableRow(table)
                        }
                    }
                }

                // Indexes section
                if !viewModel.indexes.isEmpty {
                    schemaSection(
                        title: NSLocalizedString("ql.common.indexes", comment: ""),
                        icon: "list.number",
                        count: viewModel.indexes.count
                    ) {
                        ForEach(viewModel.indexes) { index in
                            indexRow(index)
                        }
                    }
                }

                // Triggers section
                if !viewModel.triggers.isEmpty {
                    schemaSection(
                        title: NSLocalizedString("ql.common.triggers", comment: ""),
                        icon: "bolt",
                        count: viewModel.triggers.count
                    ) {
                        ForEach(viewModel.triggers) { trigger in
                            triggerRow(trigger)
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

                Spacer()

                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            content()
        }
    }

    private func tableRow(_ table: TableInfo) -> some View {
        Button(action: {
            viewModel.selectTable(table)
        }) {
            HStack(spacing: 8) {
                Image(systemName: table.type == "view" ? "eye" : "tablecells")
                    .font(.caption)
                    .foregroundColor(viewModel.selectedTable?.id == table.id ? .white : .secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text(table.name)
                        .font(.system(size: 12))
                        .lineLimit(1)

                    Text("\(table.columns.count) \(NSLocalizedString("ql.common.cols", comment: "")) · \(formatNumber(table.rowCount)) \(NSLocalizedString("ql.common.rows", comment: ""))")
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

    private func indexRow(_ index: IndexInfo) -> some View {
        HStack(spacing: 8) {
            Image(systemName: index.isUnique ? "key" : "list.number")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 1) {
                Text(index.name)
                    .font(.system(size: 12))
                    .lineLimit(1)

                Text("\(NSLocalizedString("ql.common.on", comment: "")) \(index.tableName)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if index.isUnique {
                Text(NSLocalizedString("ql.constraint.unique", comment: ""))
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

    private func triggerRow(_ trigger: TriggerInfo) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 1) {
                Text(trigger.name)
                    .font(.system(size: 12))
                    .lineLimit(1)

                Text("\(trigger.timing) \(trigger.event) on \(trigger.tableName)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - Data Preview Area

    private var dataPreviewArea: some View {
        VStack(spacing: 0) {
            if let table = viewModel.selectedTable {
                // Table header
                HStack {
                    Text("\(NSLocalizedString("ql.common.table", comment: "")): \(table.name)")
                        .font(.headline)

                    Spacer()

                    if viewModel.isLoadingData {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Text("\(formatNumber(viewModel.tableData.count)) of \(formatNumber(table.rowCount)) rows")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor))

                Divider()

                // Data table
                if viewModel.isLoadingData {
                    loadingView
                } else if let error = viewModel.dataError {
                    errorView(error)
                } else if viewModel.tableData.isEmpty {
                    emptyTableView
                } else {
                    dataTableView(table: table)
                }
            } else {
                noSelectionView
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(NSLocalizedString("ql.sqlite.loading", comment: ""))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundColor(.orange)

            Text(NSLocalizedString("ql.sqlite.errorLoading", comment: ""))
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyTableView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.title)
                .foregroundColor(.secondary)

            Text(NSLocalizedString("ql.sqlite.noData", comment: ""))
                .font(.headline)

            Text(NSLocalizedString("ql.sqlite.tableEmpty", comment: ""))
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

            Text(NSLocalizedString("ql.sqlite.selectTable", comment: ""))
                .font(.headline)
                .foregroundColor(.secondary)

            Text(NSLocalizedString("ql.sqlite.selectTableHint", comment: ""))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func dataTableView(table: TableInfo) -> some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                // Column headers
                HStack(spacing: 0) {
                    ForEach(table.columns) { column in
                        columnHeader(column)
                    }
                }
                .background(Color(nsColor: .controlBackgroundColor))

                Divider()

                // Data rows
                ForEach(viewModel.tableData) { row in
                    HStack(spacing: 0) {
                        ForEach(table.columns) { column in
                            dataCell(value: row.stringValue(for: column.name))
                        }
                    }
                    .background(
                        viewModel.tableData.firstIndex(where: { $0.id == row.id })! % 2 == 0
                            ? Color.clear
                            : Color.secondary.opacity(0.05)
                    )
                }
            }
        }
    }

    private func columnHeader(_ column: ColumnInfo) -> some View {
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
        .frame(width: 160, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .border(Color.secondary.opacity(0.2), width: 0.5)
    }

    private func dataCell(value: String) -> some View {
        Text(value)
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(value == "NULL" ? .secondary : .primary)
            .lineLimit(1)
            .frame(width: 160, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .border(Color.secondary.opacity(0.1), width: 0.5)
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack(spacing: 16) {
            statsItem(icon: "tablecells", value: "\(viewModel.stats.tableCount)", label: NSLocalizedString("ql.common.tables", comment: "").lowercased())

            if viewModel.stats.viewCount > 0 {
                statsItem(icon: "eye", value: "\(viewModel.stats.viewCount)", label: NSLocalizedString("ql.common.views", comment: "").lowercased())
            }

            if viewModel.stats.indexCount > 0 {
                statsItem(icon: "list.number", value: "\(viewModel.stats.indexCount)", label: NSLocalizedString("ql.common.indexes", comment: "").lowercased())
            }

            if viewModel.stats.triggerCount > 0 {
                statsItem(icon: "bolt", value: "\(viewModel.stats.triggerCount)", label: NSLocalizedString("ql.common.triggers", comment: "").lowercased())
            }

            Spacer()

            if let encoding = viewModel.stats.encoding {
                Text(encoding)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let pageSize = viewModel.stats.pageSize {
                Text(String(format: NSLocalizedString("ql.sqlite.pageSize", comment: ""), pageSize))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func statsItem(icon: String, value: String, label: String) -> some View {
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

    // MARK: - Helpers

    private func formatNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }
}

// MARK: - Preview

#if DEBUG
struct SQLitePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Preview not available - requires database")
            .frame(width: 800, height: 600)
    }
}
#endif

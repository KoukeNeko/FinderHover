//
//  PreviewViewController.swift
//  FinderHoverQLExtension
//
//  Quick Look Preview Extension for SQLite databases and SQL files
//
//  Created by doeshing on 2026/1/25.
//

import Cocoa
import Quartz
import SwiftUI

class PreviewViewController: NSViewController, QLPreviewingController {

    // MARK: - Properties

    private var hostingView: NSView?

    // MARK: - Lifecycle

    override var nibName: NSNib.Name? {
        // Return nil to use programmatic view instead of XIB
        return nil
    }

    override func loadView() {
        // Create view programmatically instead of loading from XIB
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set preferred content size - wider format for table preview
        self.preferredContentSize = NSSize(width: 1600, height: 900)
    }

    // MARK: - QLPreviewingController

    func preparePreviewOfFile(at url: URL) async throws {
        // Verify file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            await showError(
                title: NSLocalizedString("ql.error.fileNotFound", comment: ""),
                message: NSLocalizedString("ql.error.fileNotFoundMessage", comment: "")
            )
            throw PreviewError.fileNotFound
        }

        let fileExtension = url.pathExtension.lowercased()

        // Supported SQL text file extensions
        let sqlTextExtensions = ["sql"]

        // Supported SQLite database extensions
        let sqliteExtensions = ["db", "sqlite", "sqlite3", "db3"]

        // Determine file type and show appropriate preview
        if sqlTextExtensions.contains(fileExtension) {
            try await prepareSQLTextPreview(at: url)
        } else if sqliteExtensions.contains(fileExtension) || SQLiteDatabase.isSQLiteFile(at: url.path) {
            try await prepareSQLitePreview(at: url)
        } else {
            // Unsupported file type
            await showError(
                title: NSLocalizedString("ql.error.unsupportedFormat", comment: ""),
                message: NSLocalizedString("ql.error.unsupportedFormatMessage", comment: "")
            )
            throw PreviewError.unsupportedFormat
        }
    }

    // MARK: - SQLite Database Preview

    private func prepareSQLitePreview(at url: URL) async throws {
        do {
            // Open database
            let database = try SQLiteDatabase(path: url.path)

            // Load metadata
            let stats = try database.getStatistics()
            let tables = try database.getTables()
            let indexes = try database.getIndexes()
            let triggers = try database.getTriggers()

            // Create view model
            let viewModel = SQLitePreviewViewModel(
                fileName: url.lastPathComponent,
                stats: stats,
                tables: tables,
                indexes: indexes,
                triggers: triggers,
                database: database
            )

            // Update UI on main thread
            await MainActor.run {
                let previewView = SQLitePreviewView(viewModel: viewModel)
                embedHostingView(previewView)
            }

        } catch let error as SQLiteError {
            await showError(
                title: NSLocalizedString("ql.error.databaseError", comment: ""),
                message: error.errorDescription ?? "Unknown error"
            )
            throw error
        } catch {
            await showError(
                title: NSLocalizedString("ql.error.error", comment: ""),
                message: error.localizedDescription
            )
            throw error
        }
    }

    // MARK: - SQL Text File Preview

    private func prepareSQLTextPreview(at url: URL) async throws {
        do {
            // Get file attributes
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int64 ?? 0

            // Read file content (limit to 2MB for performance)
            let maxSize: Int64 = 2 * 1024 * 1024
            let content: String

            if fileSize > maxSize {
                // Read only first 2MB
                let fileHandle = try FileHandle(forReadingFrom: url)
                defer { try? fileHandle.close() }

                if let data = try fileHandle.read(upToCount: Int(maxSize)),
                   let text = String(data: data, encoding: .utf8) {
                    content = text + "\n\n... (file truncated, showing first 2MB)"
                } else {
                    throw PreviewError.cannotReadFile
                }
            } else {
                content = try String(contentsOf: url, encoding: .utf8)
            }

            // Create view model
            let viewModel = SQLTextPreviewViewModel(
                fileName: url.lastPathComponent,
                fileSize: fileSize,
                content: content
            )

            // Update UI on main thread
            await MainActor.run {
                let previewView = SQLTextPreviewView(viewModel: viewModel)
                embedHostingView(previewView)
            }

        } catch {
            await showError(
                title: NSLocalizedString("ql.error.readingFile", comment: ""),
                message: error.localizedDescription
            )
            throw error
        }
    }

    // MARK: - Helper Methods

    @MainActor
    private func embedHostingView<V: View>(_ view: V) {
        let hosting = NSHostingView(rootView: view)
        hosting.translatesAutoresizingMaskIntoConstraints = false

        // Remove any existing subviews
        self.view.subviews.forEach { $0.removeFromSuperview() }

        self.view.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: self.view.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])

        self.hostingView = hosting
    }

    // MARK: - Error Handling

    @MainActor
    private func showError(title: String, message: String) {
        let errorView = ErrorPreviewView(title: title, message: message)
        embedHostingView(errorView)
    }
}

// MARK: - Preview Error

enum PreviewError: LocalizedError {
    case fileNotFound
    case cannotReadFile
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "The file could not be found."
        case .cannotReadFile:
            return "The file could not be read."
        case .unsupportedFormat:
            return "This file format is not supported."
        }
    }
}

// MARK: - Error Preview View

struct ErrorPreviewView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

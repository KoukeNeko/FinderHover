//
//  PreviewViewController.swift
//  FinderHoverQLExtension
//
//  Quick Look Preview Extension for SQLite databases
//
//  Created by doeshing on 2026/1/25.
//

import Cocoa
import Quartz
import SwiftUI

class PreviewViewController: NSViewController, QLPreviewingController {

    // MARK: - Properties

    private var hostingView: NSHostingView<SQLitePreviewView>?
    private var errorHostingView: NSHostingView<ErrorPreviewView>?

    // MARK: - Lifecycle

    override var nibName: NSNib.Name? {
        // Return nil to use programmatic view instead of XIB
        return nil
    }

    override func loadView() {
        // Create view programmatically instead of loading from XIB
        self.view = NSView()
    }

    // MARK: - QLPreviewingController

    func preparePreviewOfFile(at url: URL) async throws {
        // Verify file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            await showError(
                title: "File Not Found",
                message: "The database file could not be found."
            )
            throw SQLiteError.cannotOpen("File not found")
        }

        // Verify it's a SQLite file
        guard SQLiteDatabase.isSQLiteFile(at: url.path) else {
            await showError(
                title: "Invalid Database",
                message: "This file is not a valid SQLite database."
            )
            throw SQLiteError.invalidDatabase
        }

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
                let hosting = NSHostingView(rootView: previewView)
                hosting.translatesAutoresizingMaskIntoConstraints = false

                // Remove any existing subviews
                view.subviews.forEach { $0.removeFromSuperview() }

                view.addSubview(hosting)
                NSLayoutConstraint.activate([
                    hosting.topAnchor.constraint(equalTo: view.topAnchor),
                    hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    hosting.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])

                self.hostingView = hosting
            }

        } catch let error as SQLiteError {
            await showError(
                title: "Database Error",
                message: error.errorDescription ?? "Unknown error"
            )
            throw error
        } catch {
            await showError(
                title: "Error",
                message: error.localizedDescription
            )
            throw error
        }
    }

    // MARK: - Error Handling

    @MainActor
    private func showError(title: String, message: String) {
        let errorView = ErrorPreviewView(title: title, message: message)
        let hosting = NSHostingView(rootView: errorView)
        hosting.translatesAutoresizingMaskIntoConstraints = false

        view.subviews.forEach { $0.removeFromSuperview() }
        view.addSubview(hosting)

        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        self.errorHostingView = hosting
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

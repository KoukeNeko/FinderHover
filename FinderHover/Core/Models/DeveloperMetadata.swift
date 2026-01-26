//
//  DeveloperMetadata.swift
//  FinderHover
//
//  Developer-related metadata structures (Code, Git, Xcode, Executable, App, SQLite)
//

import Foundation

// MARK: - Code File Metadata Structure
struct CodeMetadata {
    let language: String?         // Programming language
    let lineCount: Int?           // Total lines
    let codeLines: Int?           // Lines of code (excluding blank and comments)
    let commentLines: Int?        // Comment lines
    let blankLines: Int?          // Blank lines
    let encoding: String?         // File encoding (UTF-8, ASCII, etc.)

    var hasData: Bool {
        return language != nil || lineCount != nil || codeLines != nil ||
               commentLines != nil || blankLines != nil || encoding != nil
    }
}

// MARK: - Git Repository Metadata Structure
struct GitMetadata {
    let branchCount: Int?
    let currentBranch: String?
    let commitCount: Int?
    let lastCommitDate: String?
    let lastCommitMessage: String?
    let remoteURL: String?
    let hasUncommittedChanges: Bool?
    let tagCount: Int?

    var hasData: Bool {
        return branchCount != nil || currentBranch != nil || commitCount != nil ||
               lastCommitDate != nil || lastCommitMessage != nil || remoteURL != nil ||
               hasUncommittedChanges != nil || tagCount != nil
    }
}

// MARK: - Xcode Project Metadata Structure
struct XcodeProjectMetadata {
    let projectName: String?
    let targetCount: Int?             // Number of targets
    let configurationCount: Int?      // Number of build configurations
    let swiftVersion: String?         // Swift version
    let deploymentTarget: String?     // Deployment target
    let organizationName: String?     // Organization name
    let hasTests: Bool?               // Has test target
    let hasUITests: Bool?             // Has UI test target

    var hasData: Bool {
        return projectName != nil ||
               targetCount != nil ||
               configurationCount != nil ||
               swiftVersion != nil ||
               deploymentTarget != nil ||
               organizationName != nil ||
               hasTests != nil ||
               hasUITests != nil
    }
}

// MARK: - Executable Metadata Structure
struct ExecutableMetadata {
    let architecture: String?      // arm64, x86_64, Universal
    let isCodeSigned: Bool?
    let signingAuthority: String?
    let minimumOS: String?
    let sdkVersion: String?
    let fileType: String?          // Mach-O, dylib, etc.

    var hasData: Bool {
        return architecture != nil || isCodeSigned != nil || signingAuthority != nil ||
               minimumOS != nil || sdkVersion != nil || fileType != nil
    }
}

// MARK: - App Bundle Metadata Structure
struct AppBundleMetadata {
    let bundleID: String?
    let version: String?
    let buildNumber: String?
    let minimumOS: String?
    let category: String?
    let copyright: String?
    let isCodeSigned: Bool?
    let hasEntitlements: Bool?

    var hasData: Bool {
        return bundleID != nil || version != nil || buildNumber != nil ||
               minimumOS != nil || category != nil || copyright != nil ||
               isCodeSigned != nil || hasEntitlements != nil
    }
}

// MARK: - SQLite Metadata Structure
struct SQLiteMetadata {
    let tableCount: Int?
    let indexCount: Int?
    let triggerCount: Int?
    let viewCount: Int?
    let totalRows: Int?
    let schemaVersion: Int?
    let pageSize: Int?
    let encoding: String?

    var hasData: Bool {
        return tableCount != nil || indexCount != nil || triggerCount != nil ||
               viewCount != nil || totalRows != nil || schemaVersion != nil ||
               pageSize != nil || encoding != nil
    }
}

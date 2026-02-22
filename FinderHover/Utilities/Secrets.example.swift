//
//  Secrets.example.swift
//  FinderHover
//
//  Copy this file as Secrets.swift and fill in your Paddle credentials:
//    cp Secrets.example.swift Secrets.swift
//
//  Secrets.swift is gitignored and will NOT be committed.
//  Without Secrets.swift the project still compiles — Paddle features
//  are conditionally compiled (#if canImport(Paddle)).
//

enum PaddleSecrets {
    static let vendorID = "YOUR_VENDOR_ID"
    static let apiKey = "YOUR_API_KEY"
    static let productID = "YOUR_PRODUCT_ID"
}

//
//  Secrets.example.swift
//  FinderHover
//
//  Copy this file as Secrets.swift and fill in your Paddle Billing credentials:
//    cp Secrets.example.swift Secrets.swift
//
//  Secrets.swift is gitignored and will NOT be committed.
//  Without real credentials, all features are unlocked (open-source build).
//

enum PaddleSecrets {
    /// Paddle Billing API key (read-only scope)
    static let apiKey = "YOUR_API_KEY"

    /// Paddle price ID for FinderHover (pri_xxx)
    static let priceID = "YOUR_PRICE_ID"

    /// Full checkout URL opened in user's default browser
    static let checkoutURL = "YOUR_CHECKOUT_URL"
}

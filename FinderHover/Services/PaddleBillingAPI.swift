//
//  PaddleBillingAPI.swift
//  FinderHover
//
//  URLSession-based REST client for Paddle Billing API.
//  Follows the async/await pattern established by GitHubService.swift.
//

import Foundation

enum PaddleBillingAPI {

    // MARK: - Configuration

    private static var baseURL: String {
        #if DEBUG
        return "https://sandbox-api.paddle.com"
        #else
        return "https://api.paddle.com"
        #endif
    }

    // MARK: - Response Models

    private struct PaddleListResponse<T: Codable>: Codable {
        let data: [T]
    }

    struct Customer: Codable {
        let id: String
        let email: String
        let name: String?
    }

    struct Transaction: Codable {
        let id: String
        let status: String
        let customerId: String?
        let createdAt: String

        enum CodingKeys: String, CodingKey {
            case id, status
            case customerId = "customer_id"
            case createdAt = "created_at"
        }
    }

    // MARK: - Errors

    enum APIError: LocalizedError {
        case invalidURL
        case httpError(statusCode: Int)
        case noCustomerFound
        case noCompletedTransaction
        case decodingFailed(Error)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid API URL"
            case .httpError(let code):
                return "HTTP error \(code)"
            case .noCustomerFound:
                return "No customer found for this email"
            case .noCompletedTransaction:
                return "No completed transaction found"
            case .decodingFailed(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - API Calls

    /// Find a customer by exact email match
    static func findCustomer(email: String) async throws -> Customer {
        guard var components = URLComponents(string: "\(baseURL)/customers") else {
            throw APIError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "email", value: email),
        ]

        let data = try await performRequest(url: components.url)
        let response = try decodeResponse(PaddleListResponse<Customer>.self, from: data)

        guard let customer = response.data.first else {
            throw APIError.noCustomerFound
        }

        return customer
    }

    /// Find completed transactions for a customer
    static func findCompletedTransactions(customerID: String) async throws -> [Transaction] {
        guard var components = URLComponents(string: "\(baseURL)/transactions") else {
            throw APIError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "customer_id", value: customerID),
            URLQueryItem(name: "status", value: "completed"),
        ]

        let data = try await performRequest(url: components.url)
        let response = try decodeResponse(PaddleListResponse<Transaction>.self, from: data)

        return response.data
    }

    /// Verify a specific transaction by ID
    static func verifyTransaction(transactionID: String) async throws -> Transaction {
        guard let url = URL(string: "\(baseURL)/transactions/\(transactionID)") else {
            throw APIError.invalidURL
        }

        let data = try await performRequest(url: url)

        // Single transaction response wraps in { "data": { ... } }
        struct SingleResponse: Codable {
            let data: Transaction
        }

        let response = try decodeResponse(SingleResponse.self, from: data)
        return response.data
    }

    // MARK: - Private Helpers

    private static func performRequest(url: URL?) async throws -> Data {
        guard let url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(PaddleSecrets.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.httpError(statusCode: 0)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        return data
    }

    private static func decodeResponse<T: Codable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}

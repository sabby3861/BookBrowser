//
//  NetworkServiceProtocol.swift
//  BookBrowser
//
//  Created by Sanjay Kumar on 30/03/2026.
//

import Foundation
/*
/// Stores `String` descriptions rather than nested `Error` values
/// so the enum can conform to `Equatable` for direct test assertions.
enum NetworkError: LocalizedError, Equatable, Sendable {
    case invalidURL
    case requestFailed(statusCode: Int)
    case decodingFailed(String)
    case noConnection
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL was invalid."
        case .requestFailed(let code):
            return "Server returned status \(code)."
        case .decodingFailed(let detail):
            return "Failed to parse the server response: \(detail)"
        case .noConnection:
            return "No internet connection available."
        case .unknown(let detail):
            return detail
        }
    }
}

protocol NetworkServiceProtocol: Sendable {
    func fetchBooks() async throws -> [Work]
}
*/

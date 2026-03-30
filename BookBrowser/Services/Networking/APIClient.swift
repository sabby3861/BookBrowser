//
//  APIClient.swift
//  BookBrowser
//
//  Created by Sanjay Kumar on 30/03/2026.
//

import Foundation

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

/// Thin wrapper around URLSession that handles request execution, status
/// validation, and JSON decoding. Domain services use this to avoid
/// duplicating HTTP plumbing.
///
/// `@unchecked Sendable` — URLSession.shared is thread-safe per Apple docs.
struct APIClient: @unchecked Sendable {
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetch<T: Decodable & Sendable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        guard let request = endpoint.urlRequest else {
            throw NetworkError.invalidURL
        }
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            throw mapURLError(urlError)
        } catch {
            throw NetworkError.unknown(error.localizedDescription)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown("Unexpected response type.")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed(statusCode: httpResponse.statusCode)
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }
    
    private func mapURLError(_ error: URLError) -> NetworkError {
        let connectivityCodes: Set<URLError.Code> = [
            .notConnectedToInternet,
            .networkConnectionLost,
            .dataNotAllowed,
            .internationalRoamingOff,
            .timedOut
        ]
        return connectivityCodes.contains(error.code)
            ? .noConnection
            : .unknown(error.localizedDescription)
    }
}

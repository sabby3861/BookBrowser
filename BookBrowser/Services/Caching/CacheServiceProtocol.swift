//
//  CacheServiceProtocol.swift
//  BookBrowser
//
//  Created by Sanjay Kumar on 30/03/2026.
//

import Foundation

enum CacheError: LocalizedError, Equatable, Sendable {
    case writeFailed(String)
    case readFailed(String)
    case noCache
    
    var errorDescription: String? {
        switch self {
        case .writeFailed(let detail):
            return "Failed to write cache: \(detail)"
        case .readFailed(let detail):
            return "Failed to read cache: \(detail)"
        case .noCache:
            return "No cached data available."
        }
    }
}

/// Generic — works with any `Codable` type, not just books.
protocol CacheServiceProtocol<Item>: Sendable {
    associatedtype Item: Codable & Sendable
    
    func save(_ items: [Item]) throws
    func load() throws -> [Item]
    func clear() throws
}

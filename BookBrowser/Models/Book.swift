//
//  Book.swift
//  BookBrowser
//
//  Created by Sanjay Kumar on 30/03/2026.
//

import Foundation
// MARK: - API Response

/// Top-level response from the Open Library subjects endpoint.
struct SubjectResponse: Codable, Sendable, Equatable {
    let works: [Work]
}

// MARK: - Work

/// Uses the API's `key` field as stable identity — title+author
/// would collide across editions of the same book.
struct Work: Codable, Sendable, Hashable, Identifiable {
    let key: String
    let title: String
    let authors: [Author]
    let coverID: Int?
    
    var id: String { key }
    
    var displayAuthor: String {
        guard !authors.isEmpty else { return "Unknown Author" }
        return authors.map(\.name).joined(separator: ", ")
    }
    
    var coverURL: URL? {
        coverID.flatMap { Endpoint.coverImageURL(coverID: $0) }
    }
    
    enum CodingKeys: String, CodingKey {
        case key, title, authors
        case coverID = "cover_id"
    }
}

// MARK: - Author

struct Author: Codable, Sendable, Hashable {
    let name: String
}

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

/// A single book entry from the Open Library API.
///
/// The subjects endpoint returns a `key` per work (e.g. "/works/OL27482W")
/// which provides a stable unique identifier — far safer than deriving
/// identity from title+author, which can collide across editions.
struct Work: Codable, Sendable, Hashable, Identifiable {
    let key: String
    let title: String
    let authors: [Author]
    let coverID: Int?
    
    var id: String { key }
    
    /// Joins multiple author names for display. Falls back gracefully
    /// rather than leaving the label blank.
    var displayAuthor: String {
        guard !authors.isEmpty else { return "Unknown Author" }
        return authors.map(\.name).joined(separator: ", ")
    }
    
    /// Constructs the Open Library cover image URL at medium resolution.
    /// Returns `nil` when the API didn't supply a cover ID.
    var coverURL: URL? {
        coverID.flatMap { URL(string: "https://covers.openlibrary.org/b/id/\($0)-M.jpg") }
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

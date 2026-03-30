//
//  BookService.swift
//  BookBrowser
//
//  Created by Sanjay Kumar on 31/03/2026.
//

import Foundation

protocol BookServiceProtocol: Sendable {
    func fetchBooks() async throws -> [Work]
}

/// Fetches science fiction books from the Open Library API.
/// Uses `APIClient` for the HTTP layer — this class only knows
/// about the endpoint and the response shape.
struct OpenLibraryBookService: BookServiceProtocol {
    
    private let client: APIClient
    private let endpoint: Endpoint
    
    init(
        client: APIClient = APIClient(),
        endpoint: Endpoint = .scienceFictionBooks()
    ) {
        self.client = client
        self.endpoint = endpoint
    }
    
    func fetchBooks() async throws -> [Work] {
        let response = try await client.fetch(endpoint, as: SubjectResponse.self)
        return response.works
    }
}

//
//  BookListViewModel.swift
//  BookBrowser
//
//  Created by Sanjay Kumar on 31/03/2026.
//

import Foundation

enum BookListState: Hashable, Sendable {
    case idle
    case loading
    case loaded([Work])
    case error(String)
}

enum DataSource: Sendable {
    case network
    case cache
}

// MARK: - BookListViewModel

/// Tries the network first, falls back to cache, surfaces a friendly
/// error if both fail. `@MainActor` so all @Published writes are safe.
@MainActor
final class BookListViewModel: ObservableObject {
    
    @Published private(set) var state: BookListState = .idle
    @Published private(set) var dataSource: DataSource = .network
    
    private let bookService: any BookServiceProtocol
    private let cacheService: any CacheServiceProtocol<Work>
    private var isFetching = false
    
    init(
        bookService: any BookServiceProtocol,
        cacheService: any CacheServiceProtocol<Work>
    ) {
        self.bookService = bookService
        self.cacheService = cacheService
    }
    
    // MARK: - Public
    
    func fetchBooks() async {
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }
        
        state = .loading
        
        do {
            let books = try await bookService.fetchBooks()
            state = .loaded(books)
            dataSource = .network
            persistToCache(books)
        } catch is CancellationError {
            return // View disappeared, don't write stale state
        } catch {
            loadFromCacheOrFail(networkError: error)
        }
    }
    
    // MARK: - Private
    
    private func loadFromCacheOrFail(networkError: Error) {
        do {
            let cachedBooks = try cacheService.load()
            guard !cachedBooks.isEmpty else {
                state = .error(friendlyMessage(for: networkError))
                return
            }
            state = .loaded(cachedBooks)
            dataSource = .cache
        } catch {
            state = .error(friendlyMessage(for: networkError))
        }
    }
    
    private func persistToCache(_ books: [Work]) {
        do {
            try cacheService.save(books)
        } catch {
            #if DEBUG
            print("⚠️ Cache write failed: \(error.localizedDescription)")
            #endif
        }
    }
    
    private func friendlyMessage(for error: Error) -> String {
        guard let networkError = error as? NetworkError else {
            return "Unable to load books right now. Please try again later."
        }
        switch networkError {
        case .noConnection:
            return "You appear to be offline. Please check your connection and try again."
        case .requestFailed(let code):
            return "The server returned an error (\(code)). Please try again."
        case .decodingFailed:
            return "We received an unexpected response. The app may need updating."
        case .invalidURL, .unknown:
            return "Something went wrong loading books. Pull down to try again."
        }
    }
}

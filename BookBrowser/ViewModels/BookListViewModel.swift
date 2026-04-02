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

/// Shows cached data instantly, then refreshes from the network in the
/// background. This avoids a 2-4 second loading spinner on every launch
/// just because the Open Library API is slow.
///
/// First launch (no cache): shows loading → fetches from network.
/// Subsequent launches: shows cached books immediately → silently
/// refreshes and updates the list when fresh data arrives.
/// Pull-to-refresh: always hits the network with a visible spinner.
@MainActor
final class BookListViewModel: ObservableObject {
    
    @Published private(set) var state: BookListState = .idle
    @Published private(set) var dataSource: DataSource = .network
    @Published private(set) var isRefreshing = false
    
    private let bookService: any BookServiceProtocol
    private let cacheService: any CacheServiceProtocol<Work>
    
    init(
        bookService: any BookServiceProtocol,
        cacheService: any CacheServiceProtocol<Work>
    ) {
        self.bookService = bookService
        self.cacheService = cacheService
    }
    
    // MARK: - Public
    
    /// Called on initial launch. Shows cache immediately if available,
    /// then refreshes from the network in the background.
    func loadBooks() async {
        // Show cached data right away so the user isn't staring at a spinner
        let hasCachedData = loadFromCache()
        
        // Then refresh from network
        await refreshFromNetwork(showLoading: !hasCachedData)
    }
    
    /// Called on pull-to-refresh. Always shows the loading indicator
    /// and hits the network.
    func refreshBooks() async {
        await refreshFromNetwork(showLoading: false)
    }
    
    // MARK: - Private
    
    /// Returns `true` if cache had usable data.
    @discardableResult
    private func loadFromCache() -> Bool {
        do {
            let cachedBooks = try cacheService.load()
            guard !cachedBooks.isEmpty else { return false }
            state = .loaded(cachedBooks)
            dataSource = .cache
            return true
        } catch {
            return false
        }
    }
    
    private func refreshFromNetwork(showLoading: Bool) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        
        if showLoading {
            state = .loading
        }
        
        do {
            let books = try await bookService.fetchBooks()
            state = .loaded(books)
            dataSource = .network
            persistToCache(books)
        } catch is CancellationError {
            return
        } catch {
            // If we already have cached data on screen, don't replace it
            // with an error. Only show error if there's nothing to display.
            if case .loaded = state { return }
            state = .error(friendlyMessage(for: error))
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

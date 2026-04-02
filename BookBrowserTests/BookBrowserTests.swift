//
//  BookBrowserTests.swift
//  BookBrowserTests
//
//  Created by Sanjay Kumar on 30/03/2026.
//

import Testing
import Foundation
@testable import BookBrowser

// MARK: - ViewModel

@Suite("BookListViewModel")
@MainActor
struct BookListViewModelTests {
    
    let mockService = MockBookService()
    let mockCache = MockCacheService()
    var sut: BookListViewModel
    
    init() {
        sut = BookListViewModel(bookService: mockService, cacheService: mockCache)
    }
    
    @Test("Starts idle")
    func initialState() {
        #expect(sut.state == .idle)
        #expect(sut.dataSource == .network)
        #expect(sut.isRefreshing == false)
    }
    
    // MARK: - loadBooks (initial launch)
    
    @Test("First launch, no cache → shows loading then network result")
    func firstLaunch_noCacheShowsLoading() async {
        mockService.stubbedResult = .success(TestFixtures.sampleBooks)
        
        await sut.loadBooks()
        
        #expect(sut.state == .loaded(TestFixtures.sampleBooks))
        #expect(sut.dataSource == .network)
        #expect(sut.isRefreshing == false)
    }
    
    @Test("Has cache → shows cache instantly, then updates from network")
    func hasCache_showsCacheThenNetwork() async {
        mockCache.storedItems = TestFixtures.singleBook
        mockService.stubbedResult = .success(TestFixtures.sampleBooks)
        
        await sut.loadBooks()
        
        // After loadBooks completes, network data should replace cache
        #expect(sut.state == .loaded(TestFixtures.sampleBooks))
        #expect(sut.dataSource == .network)
    }
    
    @Test("Has cache, network fails → keeps showing cache")
    func hasCache_networkFails_keepsCached() async {
        mockCache.storedItems = TestFixtures.singleBook
        mockService.stubbedResult = .failure(NetworkError.noConnection)
        
        await sut.loadBooks()
        
        // Cache data stays on screen, network failure is silent
        #expect(sut.state == .loaded(TestFixtures.singleBook))
        #expect(sut.dataSource == .cache)
    }
    
    @Test("No cache, network fails → error")
    func noCache_networkFails_error() async {
        mockService.stubbedResult = .failure(NetworkError.noConnection)
        
        await sut.loadBooks()
        
        guard case .error(let message) = sut.state else {
            Issue.record("Expected .error, got \(sut.state)")
            return
        }
        #expect(message.lowercased().contains("offline"))
    }
    
    @Test("Network success writes to cache")
    func networkSuccess_cachesResult() async {
        mockService.stubbedResult = .success(TestFixtures.sampleBooks)
        
        await sut.loadBooks()
        
        #expect(mockCache.saveCallCount == 1)
        #expect(mockCache.storedItems == TestFixtures.sampleBooks)
    }
    
    // MARK: - refreshBooks (pull-to-refresh)
    
    @Test("Refresh hits network directly")
    func refresh_hitsNetwork() async {
        mockService.stubbedResult = .success(TestFixtures.sampleBooks)
        
        await sut.refreshBooks()
        
        #expect(sut.state == .loaded(TestFixtures.sampleBooks))
        #expect(sut.dataSource == .network)
        #expect(mockService.fetchCallCount == 1)
    }
    
    // MARK: - Error messages
    
    @Test("Server 503 → shows status code")
    func serverError_showsCode() async {
        mockService.stubbedResult = .failure(NetworkError.requestFailed(statusCode: 503))
        
        await sut.loadBooks()
        
        guard case .error(let message) = sut.state else {
            Issue.record("Expected .error, got \(sut.state)")
            return
        }
        #expect(message.contains("503"))
    }
    
    @Test("Decoding error → suggests app update")
    func decodingError_suggestsUpdate() async {
        mockService.stubbedResult = .failure(NetworkError.decodingFailed("bad key"))
        
        await sut.loadBooks()
        
        guard case .error(let message) = sut.state else {
            Issue.record("Expected .error, got \(sut.state)")
            return
        }
        #expect(message.contains("updating"))
    }
    
    // MARK: - Edge cases
    
    @Test("Empty cache counts as no cache")
    func emptyCacheIsFailure() async {
        mockCache.storedItems = []
        mockService.stubbedResult = .failure(NetworkError.noConnection)
        
        await sut.loadBooks()
        
        guard case .error = sut.state else {
            Issue.record("Expected .error for empty cache, got \(sut.state)")
            return
        }
    }
    
    @Test("Concurrent calls deduplicated")
    func deduplication() async {
        mockService.stubbedResult = .success(TestFixtures.sampleBooks)
        
        async let first: Void = sut.loadBooks()
        async let second: Void = sut.loadBooks()
        _ = await (first, second)
        
        // Network should only be hit once
        #expect(mockService.fetchCallCount == 1)
    }
    
    @Test("Cancellation bails without touching state")
    func cancellation() async {
        mockService.stubbedResult = .failure(CancellationError())
        
        await sut.loadBooks()
        
        // No cached data, network cancelled — state stays at loading
        // (not an error, because cancellation is not a real failure)
        guard case .error = sut.state else {
            // Loading or idle is acceptable — not error
            return
        }
        Issue.record("Cancellation should not produce an error state")
    }
}

// MARK: - Models

@Suite("Work Model")
struct WorkModelTests {
    
    @Test("Single author")
    func singleAuthor() {
        let work = Work(key: "/works/OL1W", title: "Dune",
                        authors: [Author(name: "Frank Herbert")], coverID: nil)
        #expect(work.displayAuthor == "Frank Herbert")
    }
    
    @Test("Multiple authors joined with comma")
    func multipleAuthors() {
        #expect(TestFixtures.multiAuthorBook.displayAuthor == "Terry Pratchett, Neil Gaiman")
    }
    
    @Test("No authors → fallback text")
    func noAuthors() {
        #expect(TestFixtures.noAuthorBook.displayAuthor == "Unknown Author")
    }
    
    @Test("Cover URL from cover ID")
    func coverURL() {
        let work = Work(key: "/works/OL1W", title: "Dune", authors: [], coverID: 12345)
        #expect(work.coverURL?.absoluteString == "https://covers.openlibrary.org/b/id/12345-M.jpg")
    }
    
    @Test("No cover ID → nil URL")
    func noCoverURL() {
        #expect(TestFixtures.noAuthorBook.coverURL == nil)
    }
    
    @Test("ID comes from API key")
    func idFromKey() {
        let work = Work(key: "/works/OL893415W", title: "Dune", authors: [], coverID: nil)
        #expect(work.id == "/works/OL893415W")
    }
    
    @Test("Hashable gives us Equatable for free")
    func hashableImpliesEquatable() {
        let a = Work(key: "/works/OL1W", title: "Dune", authors: [], coverID: nil)
        let b = Work(key: "/works/OL1W", title: "Dune", authors: [], coverID: nil)
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }
}

// MARK: - Endpoint

@Suite("Endpoint")
struct EndpointTests {
    
    @Test("Default limit is 20")
    func defaultLimit() {
        let request = Endpoint.scienceFictionBooks().urlRequest
        #expect(request != nil)
        #expect(request?.url?.host == "openlibrary.org")
        #expect(request?.url?.absoluteString.contains("limit=20") == true)
    }
    
    @Test("Custom limit")
    func customLimit() {
        let request = Endpoint.scienceFictionBooks(limit: 50).urlRequest
        #expect(request?.url?.absoluteString.contains("limit=50") == true)
    }
    
    @Test("Sets Accept: application/json")
    func acceptHeader() {
        let request = Endpoint.scienceFictionBooks().urlRequest
        #expect(request?.value(forHTTPHeaderField: "Accept") == "application/json")
    }
    
    @Test("HTTP method is GET")
    func httpMethod() {
        #expect(Endpoint.scienceFictionBooks().urlRequest?.httpMethod == "GET")
    }
    
    @Test("Custom timeout")
    func timeout() {
        let endpoint = Endpoint(path: "/test", timeoutInterval: 15)
        #expect(endpoint.urlRequest?.timeoutInterval == 15)
    }
    
    @Test("Custom headers override defaults")
    func headerOverride() {
        let endpoint = Endpoint(
            path: "/test",
            headers: ["Accept": "text/plain", "X-Custom": "value"]
        )
        let request = endpoint.urlRequest
        #expect(request?.value(forHTTPHeaderField: "Accept") == "text/plain")
        #expect(request?.value(forHTTPHeaderField: "X-Custom") == "value")
    }
    
    @Test("Cover image URL constructed correctly")
    func coverImageURL() {
        let url = Endpoint.coverImageURL(coverID: 12345)
        #expect(url?.absoluteString == "https://covers.openlibrary.org/b/id/12345-M.jpg")
    }
    
    @Test("Cover image URL with custom size")
    func coverImageURL_large() {
        let url = Endpoint.coverImageURL(coverID: 12345, size: "L")
        #expect(url?.absoluteString == "https://covers.openlibrary.org/b/id/12345-L.jpg")
    }
}

// MARK: - JSON Decoding

@Suite("JSON Decoding")
struct DecodingTests {
    
    @Test("Full work from API JSON")
    func fullWork() throws {
        let json = """
        {
            "key": "/works/OL893415W",
            "title": "Dune",
            "authors": [{"name": "Frank Herbert"}],
            "cover_id": 8231856
        }
        """.data(using: .utf8)!
        
        let work = try JSONDecoder().decode(Work.self, from: json)
        
        #expect(work.key == "/works/OL893415W")
        #expect(work.title == "Dune")
        #expect(work.authors.first?.name == "Frank Herbert")
        #expect(work.coverID == 8_231_856)
    }
    
    @Test("Null cover_id → nil")
    func nullCoverID() throws {
        let json = """
        {"key": "/works/OL1W", "title": "Test", "authors": [], "cover_id": null}
        """.data(using: .utf8)!
        
        #expect(try JSONDecoder().decode(Work.self, from: json).coverID == nil)
    }
    
    @Test("Missing cover_id → nil")
    func missingCoverID() throws {
        let json = """
        {"key": "/works/OL1W", "title": "Test", "authors": []}
        """.data(using: .utf8)!
        
        #expect(try JSONDecoder().decode(Work.self, from: json).coverID == nil)
    }
    
    @Test("Multiple works in response")
    func multipleWorks() throws {
        let json = """
        {
            "works": [
                {"key": "/works/OL1W", "title": "Book A", "authors": [], "cover_id": 111},
                {"key": "/works/OL2W", "title": "Book B", "authors": [{"name": "Author"}]}
            ]
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(SubjectResponse.self, from: json)
        #expect(response.works.count == 2)
        #expect(response.works[1].coverID == nil)
    }
    
    @Test("Encode → decode round-trip")
    func roundTrip() throws {
        let original = TestFixtures.sampleBooks[0]
        let data = try JSONEncoder().encode(original)
        #expect(try JSONDecoder().decode(Work.self, from: data) == original)
    }
    
    @Test("All fixtures round-trip", arguments: TestFixtures.sampleBooks)
    func fixtureRoundTrip(work: Work) throws {
        let data = try JSONEncoder().encode(work)
        #expect(try JSONDecoder().decode(Work.self, from: data) == work)
    }
}

// MARK: - Errors

@Suite("Error Types")
struct ErrorTests {
    
    @Test("NetworkError equality")
    func networkErrors() {
        #expect(NetworkError.noConnection == NetworkError.noConnection)
        #expect(NetworkError.requestFailed(statusCode: 500) == NetworkError.requestFailed(statusCode: 500))
        #expect(NetworkError.requestFailed(statusCode: 500) != NetworkError.requestFailed(statusCode: 404))
    }
    
    @Test("CacheError equality")
    func cacheErrors() {
        #expect(CacheError.noCache == CacheError.noCache)
        #expect(CacheError.noCache != CacheError.writeFailed("disk full"))
    }
}


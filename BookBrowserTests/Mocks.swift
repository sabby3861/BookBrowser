//
//  Mocks.swift
//  BookBrowserTests
//
//  Created by Sanjay Kumar on 02/04/2026.
//

import Testing
@testable import BookBrowser

final class MockBookService: BookServiceProtocol, @unchecked Sendable {
    
    var stubbedResult: Result<[Work], Error> = .success([])
    var fetchCallCount = 0
    
    func fetchBooks() async throws -> [Work] {
        fetchCallCount += 1
        return try stubbedResult.get()
    }
}

final class MockCacheService: CacheServiceProtocol, @unchecked Sendable {
    typealias Item = Work
    
    var storedItems: [Work]?
    var stubbedLoadError: Error?
    var saveCallCount = 0
    var loadCallCount = 0
    var clearCallCount = 0
    
    func save(_ items: [Work]) throws {
        saveCallCount += 1
        storedItems = items
    }
    
    func load() throws -> [Work] {
        loadCallCount += 1
        if let error = stubbedLoadError { throw error }
        guard let items = storedItems else { throw CacheError.noCache }
        return items
    }
    
    func clear() throws {
        clearCallCount += 1
        storedItems = nil
    }
}

enum TestFixtures {
    
    static let sampleBooks: [Work] = [
        Work(key: "/works/OL893415W", title: "Dune",
             authors: [Author(name: "Frank Herbert")], coverID: 8_231_856),
        Work(key: "/works/OL27258W", title: "Neuromancer",
             authors: [Author(name: "William Gibson")], coverID: 12_645_114),
        Work(key: "/works/OL46125W", title: "Foundation",
             authors: [Author(name: "Isaac Asimov")], coverID: 45_732)
    ]
    
    static let singleBook: [Work] = [
        Work(key: "/works/OL59860W", title: "The Left Hand of Darkness",
             authors: [Author(name: "Ursula K. Le Guin")], coverID: nil)
    ]
    
    static let multiAuthorBook = Work(
        key: "/works/OL12345W", title: "Good Omens",
        authors: [Author(name: "Terry Pratchett"), Author(name: "Neil Gaiman")],
        coverID: 99999
    )
    
    static let noAuthorBook = Work(
        key: "/works/OL00000W", title: "Anonymous Sci-Fi",
        authors: [], coverID: nil
    )
}


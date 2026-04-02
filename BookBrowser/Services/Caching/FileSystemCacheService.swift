//
//  FileSystemCacheService.swift
//  BookBrowser
//
//  Created by Sanjay Kumar on 30/03/2026.
//

import Foundation

/// Saves any `Codable` array as JSON in the Caches directory.
///
/// Went with this over CoreData — for a flat list with no relationships,
/// CoreData's migration overhead and context threading aren't worth it.
/// The OS can reclaim cache files under storage pressure, which is fine
/// since we can always re-fetch.
///
/// `@unchecked Sendable` — FileManager.default is thread-safe per Apple docs.
final class FileSystemCacheService<Item: Codable & Sendable>: CacheServiceProtocol, @unchecked Sendable {
    
    private let fileManager: FileManager
    private let cacheFileName: String
    
    init(
        fileManager: FileManager = .default,
        cacheFileName: String = "cached_data.json"
    ) {
        self.fileManager = fileManager
        self.cacheFileName = cacheFileName
    }
    
    // MARK: - CacheServiceProtocol
    
    func save(_ items: [Item]) throws {
        let url = try cacheFileURL()
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(items)
            try data.write(to: url, options: .atomic)
        } catch {
            throw CacheError.writeFailed(error.localizedDescription)
        }
    }
    
    func load() throws -> [Item] {
        let url = try cacheFileURL()
        
        guard fileManager.fileExists(atPath: url.path()) else {
            throw CacheError.noCache
        }
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Item].self, from: data)
        } catch {
            throw CacheError.readFailed(error.localizedDescription)
        }
    }
    
    func clear() throws {
        let url = try cacheFileURL()
        guard fileManager.fileExists(atPath: url.path()) else { return }
        try fileManager.removeItem(at: url)
    }
    
    // MARK: - Private
    
    private func cacheFileURL() throws -> URL {
        guard let cachesDir = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first else {
            throw CacheError.writeFailed("Caches directory not found.")
        }
        return cachesDir.appending(path: cacheFileName)
    }
}

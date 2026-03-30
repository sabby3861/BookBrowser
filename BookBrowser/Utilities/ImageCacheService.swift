//
//  ImageCacheService.swift
//  BookBrowser
//
//  Created by Sanjay Kumar on 31/03/2026.
//

import UIKit
import CryptoKit

/// In-memory NSCache + disk persistence in the Caches directory.
/// Actor isolation handles thread safety. Coalesces duplicate in-flight
/// downloads so the same cover is only fetched once even if multiple
/// cells request it simultaneously.
actor ImageCacheService {
    
    static let shared = ImageCacheService()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let diskCacheDirectory: URL?
    private var activeTasks: [URL: Task<UIImage?, Never>] = [:]
    
    private init() {
        memoryCache.countLimit = 50
        
        diskCacheDirectory = fileManager
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("CoverImages", isDirectory: true)
        
        if let directory = diskCacheDirectory,
           !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
    
    func image(for url: URL) async -> UIImage? {
        let cacheKey = url.absoluteString as NSString
        
        // Memory
        if let cached = memoryCache.object(forKey: cacheKey) {
            return cached
        }
        
        // Disk
        if let diskImage = loadFromDisk(for: url) {
            memoryCache.setObject(diskImage, forKey: cacheKey)
            return diskImage
        }
        
        // Already downloading — wait for it
        if let existingTask = activeTasks[url] {
            return await existingTask.value
        }
        
        let task = Task<UIImage?, Never> { await download(from: url) }
        activeTasks[url] = task
        let result = await task.value
        activeTasks.removeValue(forKey: url)
        
        return result
    }
    
    // MARK: - Downloading
    
    private func download(from url: URL) async -> UIImage? {
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode),
              let image = UIImage(data: data) else {
            return nil
        }
        
        let cacheKey = url.absoluteString as NSString
        memoryCache.setObject(image, forKey: cacheKey)
        saveToDisk(data: data, for: url)
        
        return image
    }
    
    // MARK: - Disk Operations
    
    // SHA-256 for stable filenames. Swift's hashValue uses a random seed per
    // process, so the same URL gives a different hash on relaunch — useless
    // for a disk cache that needs to survive between sessions.
    private func diskPath(for url: URL) -> URL? {
        guard let directory = diskCacheDirectory else { return nil }
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let filename = digest.map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(filename)
    }
    
    private func loadFromDisk(for url: URL) -> UIImage? {
        guard let path = diskPath(for: url),
              let data = try? Data(contentsOf: path) else {
            return nil
        }
        return UIImage(data: data)
    }
    
    private func saveToDisk(data: Data, for url: URL) {
        guard let path = diskPath(for: url) else { return }
        try? data.write(to: path, options: .atomic)
    }
}

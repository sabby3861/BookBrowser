//
//  Endpoint.swift
//  BookBrowser
//
//  Created by Sanjay Kumar on 30/03/2026.
//

import Foundation
/// Produces a fully configured `URLRequest`
/// Adding a new endpoint is a static factory method.
struct Endpoint: Sendable {
    
    enum HTTPMethod: String, Sendable {
        case get = "GET"
        case post = "POST"
    }
    
    let method: HTTPMethod
    let path: String
    let queryItems: [URLQueryItem]
    let headers: [String: String]
    let timeoutInterval: TimeInterval
    
    private static let baseURL = "https://openlibrary.org"
    
    init(
        method: HTTPMethod = .get,
        path: String,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        timeoutInterval: TimeInterval = 30
    ) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.headers = headers
        self.timeoutInterval = timeoutInterval
    }
    
    var urlRequest: URLRequest? {
        var components = URLComponents(string: Self.baseURL)
        components?.path = path
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let url = components?.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadRevalidatingCacheData
        
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        
        return request
    }
}

// MARK: - Known Endpoints

extension Endpoint {
    
    static func scienceFictionBooks(limit: Int = 20) -> Endpoint {
        Endpoint(
            path: "/subjects/science_fiction.json",
            queryItems: [URLQueryItem(name: "limit", value: "\(limit)")]
        )
    }
}

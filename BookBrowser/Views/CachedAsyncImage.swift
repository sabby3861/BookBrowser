//
//  CachedAsyncImage.swift
//  BookBrowser
//
//  Created by Sanjay Kumar on 31/03/2026.
//

import SwiftUI

/// Drop-in replacement for `AsyncImage` that routes through our two-tier
/// `ImageCacheService` instead of SwiftUI's default (which re-downloads
/// on every appearance). Uses `.task(id:)` for automatic cancellation
/// when the URL changes during cell reuse.
struct CachedAsyncImage: View {
    
    let url: URL?
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Image(systemName: "book.closed.fill")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGray6))
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let url else {
            image = nil
            return
        }
        
        // Reset so a stale cover from a previously-bound URL doesn't
        // persist while the new image loads.
        image = nil
        isLoading = true
        defer { isLoading = false }
        
        let result = await ImageCacheService.shared.image(for: url)
        
        // Don't assign if cancelled — the new task will handle it.
        guard !Task.isCancelled else { return }
        
        image = result
    }
}

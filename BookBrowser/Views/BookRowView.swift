//
//  BookRowView.swift
//  BookBrowser
//
//  Created by Sanjay Kumar on 31/03/2026.
//

import SwiftUI

/// Displays a book's cover, title, and author.
/// Adapts layout from horizontal to vertical at accessibility text sizes.
struct BookRowView: View {
    
    let book: Work
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        AdaptiveHStack {
            coverImage
            bookInfo
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(book.title) by \(book.displayAuthor)")
    }
    
    private var coverImage: some View {
        CachedAsyncImage(url: book.coverURL)
            .scaledCoverFrame()
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
            .accessibilityHidden(true)
    }
    
    private var bookInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(book.title)
                .font(.headline)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
                .minimumScaleFactor(0.9)
            
            Text(book.displayAuthor)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .minimumScaleFactor(0.9)
        }
    }
}

#if DEBUG
extension Work {
    static let preview = Work(
        key: "/works/OL893415W",
        title: "Dune",
        authors: [Author(name: "Frank Herbert")],
        coverID: 8_231_856
    )
}

#Preview("Standard") {
    List {
        BookRowView(book: .preview)
    }
    .listStyle(.plain)
}

#Preview("Accessibility Size") {
    List {
        BookRowView(book: .preview)
    }
    .listStyle(.plain)
    .dynamicTypeSize(.accessibility3)
}
#endif

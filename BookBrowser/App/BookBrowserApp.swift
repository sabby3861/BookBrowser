//
//  BookBrowserApp.swift
//  BookBrowser
//
//  Created by Sanjay Kumar on 30/03/2026.
//

import SwiftUI

@main
struct BookBrowserApp: App {
    var body: some Scene {
        WindowGroup {
            BookListView(
                viewModel: BookListViewModel(
                    bookService: OpenLibraryBookService(),
                    cacheService: FileSystemCacheService<Work>(cacheFileName: "cached_books.json")
                )
            )
        }
    }
}

//
//  BookListView.swift
//  BookBrowser
//
//  Created by Sanjay Kumar on 31/03/2026.
//

import SwiftUI

struct BookListView: View {
    
    @StateObject var viewModel: BookListViewModel
    @State private var networkMonitor = NetworkMonitor()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                offlineBanner
                contentView
            }
            .navigationTitle("Sci-Fi Books")
            .animation(.easeInOut(duration: 0.3), value: showOfflineBanner)
        }
        .task {
            await viewModel.loadBooks()
        }
        .announceChange(for: viewModel.state) { state in
            switch state {
            case .loaded(let books):
                return "\(books.count) books loaded"
            case .error(let message):
                return message
            case .loading:
                return "Loading books"
            case .idle:
                return nil
            }
        }
    }
    
    // MARK: - Content Router
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingView
            
        case .loaded(let books):
            if books.isEmpty {
                emptyView
            } else {
                bookList(books)
            }
            
        case .error(let message):
            errorView(message)
        }
    }
    
    // MARK: - Offline Banner
    
    private var showOfflineBanner: Bool {
        // Don't show "Showing cached results" while actively refreshing —
        // the user just pulled to refresh, they know it's updating.
        guard !viewModel.isRefreshing else { return false }
        return !networkMonitor.isConnected || viewModel.dataSource == .cache
    }
    
    @ViewBuilder
    private var offlineBanner: some View {
        if showOfflineBanner {
            let bannerText = viewModel.dataSource == .cache
                ? "Showing cached results"
                : "No connection"
            
            HStack(spacing: 6) {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                Text(bannerText)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(bannerText)
            .accessibilityAddTraits(.isStaticText)
        }
    }
    
    // MARK: - State Views
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text("Loading books…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading books")
    }
    
    private func bookList(_ books: [Work]) -> some View {
        List(books) { book in
            BookRowView(book: book)
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refreshBooks()
        }
    }
    
    private var emptyView: some View {
        ContentUnavailableView {
            Label("No Books Found", systemImage: "books.vertical")
        } description: {
            Text("No science fiction books are available right now. Pull down to refresh.")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No books found. Pull down to refresh.")
    }
    
    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Unable to Load", systemImage: "wifi.slash")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task { await viewModel.loadBooks() }
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint("Double tap to retry loading books")
        }
    }
}

#Preview {
    BookListView(
        viewModel: BookListViewModel(
            bookService: OpenLibraryBookService(),
            cacheService: FileSystemCacheService<Work>(cacheFileName: "preview_books.json")
        )
    )
}

//
//  SearchView.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 06/09/25.
//
import SwiftUI

struct BooksSearchView: View {
    @StateObject private var viewModel = BooksViewModel()
    @EnvironmentObject var readingList: ReadingListViewModel
    
    @Binding var searchText: String
    
    // Recent Searches
    @State private var recentSearches: [String] = RecentSearchesStore.load()

    var body: some View {
        NavigationStack {
            ZStack {
                // Fundo animado
                AnimatedCirclesBackground()
                
                Group {
                    if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !recentSearches.isEmpty {
                        List {
                            Section(header: Text("Recentes")) {
                                ForEach(recentSearches, id: \.self) { term in
                                    Button {
                                        searchText = term
                                    } label: {
                                        HStack {
                                            Image(systemName: "clock.arrow.circlepath")
                                                .foregroundColor(.secondary)
                                            Text(term)
                                                .foregroundColor(.primary)
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        let term = recentSearches[index]
                                        RecentSearchesStore.remove(term)
                                    }
                                    recentSearches = RecentSearchesStore.load()
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Limpar") {
                                    RecentSearchesStore.clear()
                                    recentSearches = []
                                }
                            }
                        }
                    } else {
                        // Lista de livros
                        List {
                            ForEach(viewModel.books) { book in
                                NavigationLink(destination: BookDetailView(book: book)) {
                                    HStack(alignment: .top) {
                                        if let url = book.volumeInfo.imageLinks?.bestImageURL {
                                            AsyncImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                            } placeholder: {
                                                Color.gray
                                            }
                                            .frame(width: 50, height: 75)
                                            .cornerRadius(4)
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(book.volumeInfo.title)
                                                .bold()
                                                .lineLimit(4)
                                            if let authors = book.volumeInfo.authors {
                                                Text(authors.joined(separator: ", "))
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .listRowBackground(Color.secondary.opacity(0))
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Google Books")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .automatic, prompt: "Buscar livro")
            .task(id: searchText) {
                let ok = await viewModel.searchBooks(query: searchText)
                if ok {
                    RecentSearchesStore.add(searchText)
                    recentSearches = RecentSearchesStore.load()
                }
            }
            .onAppear {
                recentSearches = RecentSearchesStore.load()
            }
        }
    }
}

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
                                    BookRow(
                                        text: book.volumeInfo.title,
                                        author: book.volumeInfo.authors?.joined(separator: ", "),
                                        categories: book.volumeInfo.categories?.joined(separator: ", "),
                                        imageURL: book.volumeInfo.imageLinks?.bestImageURL
                                    )
                                }
                                .listRowBackground(LiquidGlassRowBackground())
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Pesquisa")
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

// Um fundo com efeito "liquid glass" usando materiais nativos, blur e borda translúcida
struct LiquidGlassRowBackground: View {
    var cornerRadius: CGFloat = 14
    var body: some View {
        ZStack {
            // Material translúcido
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    // Borda translúcida tipo vidro
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                )
                .background(
                    // Leve brilho/halo
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .blur(radius: 6)
                )
        }
        .compositingGroup() // melhora blending com material
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
        .padding(.vertical, 4)
    }
}

struct BookRow: View {
    var text: String?
    var author: String?
    var categories: String?
    var imageURL: URL? = nil
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Capa
            if let imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 50, height: 75)
                .cornerRadius(4)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 75)
                    .cornerRadius(4)
            }

            // Textos
            VStack(alignment: .leading, spacing: 4) {
                Text(text ?? "Sem título")
                    .bold()
                    .foregroundColor(.primary)
                    .lineLimit(3)
                
                HStack(spacing: 6) {
                    if let author, !author.isEmpty {
                        Text(author)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let categories, !categories.isEmpty {
                        Text("•")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(categories)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
//        .glassEffect()
        .padding(.vertical, 6)
    }
}

#Preview {
    ZStack {
        AnimatedCirclesBackground()
        List {
            BookRow(
                text: "Exemplo de Título",
                author: "Roberta Campos",
                categories: "Terror, Suspense",
                imageURL: URL(string: "https://books.google.com/books/content?id=xyz&printsec=frontcover&img=1&zoom=3")
            )
            BookRow(
                text: "Outro Livro com Título Longo para Testar Quebra de Linha",
                author: "Autor 1, Autor 2",
                categories: "Ficção, Aventura"
            )
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

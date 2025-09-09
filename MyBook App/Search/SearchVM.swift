//
//  SearchVM.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 06/09/25.
//
import SwiftUI
import Combine

@MainActor
class BooksViewModel: ObservableObject {
    @Published var books: [Volume] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func searchBooks(query: String) async -> Bool {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            books = []
            return false
        }
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=\(encodedQuery)") else {
            errorMessage = "URL inválida"
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
            books = decoded.items ?? []
            isLoading = false
            return true
        } catch {
            errorMessage = "Erro ao buscar livros: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
}

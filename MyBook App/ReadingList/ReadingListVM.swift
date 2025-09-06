//
//  ReadingListVM.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 06/09/25.
//

import SwiftUI
import Combine

@MainActor
class ReadingListViewModel: ObservableObject {
    @Published var savedBooks: [TrackedBook] = [] {
        didSet { saveBooks() }
    }
    
    private let storageKey = "savedBooks"
    
    init() { loadBooks() }
    
    func addBook(_ book: Volume) {
        if !savedBooks.contains(where: { $0.volume == book }) {
            savedBooks.append(TrackedBook(volume: book))
        }
    }
    
    func removeBook(_ book: Volume) {
        savedBooks.removeAll { $0.volume == book }
    }
    
    func isBookSaved(_ book: Volume) -> Bool {
        savedBooks.contains { $0.volume == book }
    }
    
    func updateProgress(for book: Volume, currentPage: Int) {
        if let index = savedBooks.firstIndex(where: { $0.volume == book }) {
            savedBooks[index].currentPage = currentPage
        }
    }
    
    private func saveBooks() {
        do {
            let data = try JSONEncoder().encode(savedBooks)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Erro ao salvar livros: \(error)")
        }
    }
    
    private func loadBooks() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            savedBooks = try JSONDecoder().decode([TrackedBook].self, from: data)
        } catch {
            print("Erro ao carregar livros: \(error)")
        }
    }
}


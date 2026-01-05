// ExploreViewModel.swift
import SwiftUI
import Combine

class ExploreViewModel: ObservableObject {
    @Published var featuredBooks: [Volume] = []
    @Published var trendingBooks: [Volume] = []
    @Published var newReleases: [Volume] = []
    @Published var recommendedBooks: [Volume] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let googleBooksService = GoogleBooksService()
    private var cancellables = Set<AnyCancellable>()
    
    // Categorias populares para recomendações
    private let popularCategories = [
        "fiction", "fantasy", "romance", "mystery",
        "science fiction", "biography", "history", "self-help"
    ]
    
    init() {
        loadAllCategories()
    }
    
    func loadAllCategories() {
        isLoading = true
        errorMessage = nil
        
        // Limpa os arrays antes de carregar
        featuredBooks = []
        trendingBooks = []
        newReleases = []
        recommendedBooks = []
        
        // Grupo de publishers para carregar em paralelo
        let publishers = Publishers.Zip4(
            fetchFeaturedBooks(),
            fetchTrendingBooks(),
            fetchNewReleases(),
            fetchRecommendedBooks()
        )
        
        publishers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Erro ao carregar: \(error.localizedDescription)"
                    print("❌ Erro: \(error)")
                }
            } receiveValue: { [weak self] (featured, trending, new, recommended) in
                self?.featuredBooks = featured
                self?.trendingBooks = trending
                self?.newReleases = new
                self?.recommendedBooks = recommended
                print("✅ Dados carregados: \(featured.count) destaque, \(trending.count) trending")
            }
            .store(in: &cancellables)
    }
    
    private func fetchFeaturedBooks() -> AnyPublisher<[Volume], Error> {
        // Livros em destaque - busca geral por livros populares
        return googleBooksService.searchBooks(query: "bestseller", maxResults: 10)
            .map { response in
                let books = response.items ?? []
                // Filtra livros com capa para melhor visualização
                return books.filter { $0.volumeInfo.imageLinks != nil }
            }
            .catch { error -> AnyPublisher<[Volume], Error> in
                print("Erro em featured: \(error)")
                return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func fetchTrendingBooks() -> AnyPublisher<[Volume], Error> {
        // Livros com alta avaliação
        return googleBooksService.fetchBestRatedBooks(maxResults: 10)
            .catch { error -> AnyPublisher<[Volume], Error> in
                print("Erro em trending: \(error)")
                return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func fetchNewReleases() -> AnyPublisher<[Volume], Error> {
        // Livros publicados recentemente
        return googleBooksService.fetchRecentBooks(maxResults: 10)
            .catch { error -> AnyPublisher<[Volume], Error> in
                print("Erro em new releases: \(error)")
                return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func fetchRecommendedBooks() -> AnyPublisher<[Volume], Error> {
        // Recomendações baseadas em categoria aleatória
        let randomCategory = popularCategories.randomElement() ?? "fiction"
        return googleBooksService.fetchBooksBySubject(randomCategory, maxResults: 10)
            .catch { error -> AnyPublisher<[Volume], Error> in
                print("Erro em recommended: \(error)")
                return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func searchByCategory(_ category: String) {
        isLoading = true
        errorMessage = nil
        
        googleBooksService.fetchBooksBySubject(category, maxResults: 20)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Erro: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] books in
                self?.featuredBooks = books
                print("✅ Busca por categoria '\(category)': \(books.count) livros encontrados")
            }
            .store(in: &cancellables)
    }
    
    func searchBooks(_ query: String) {
        isLoading = true
        errorMessage = nil
        
        googleBooksService.searchBooks(query: query, maxResults: 20)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Erro na busca: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] response in
                self?.featuredBooks = response.items ?? []
                print("✅ Busca por '\(query)': \(self?.featuredBooks.count ?? 0) resultados")
            }
            .store(in: &cancellables)
    }
    
    func refreshData() {
        loadAllCategories()
    }
}

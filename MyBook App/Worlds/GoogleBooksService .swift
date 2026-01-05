//
//  GoogleBooksService 2.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 05/01/26.
//


// GoogleBooksService.swift
import Foundation
import Combine

class GoogleBooksService {
    private let baseURL = "https://www.googleapis.com/books/v1/volumes"
    private let apiKey = "SUA_CHAVE_API_AQUI" // Coloque sua chave aqui
    
    func searchBooks(query: String, maxResults: Int = 20) -> AnyPublisher<GoogleBooksResponse, Error> {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)?q=\(encodedQuery)&maxResults=\(maxResults)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        print("🔍 Buscando: \(urlString)")
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: GoogleBooksResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // Buscar por categoria/subject
    func fetchBooksBySubject(_ subject: String, maxResults: Int = 20) -> AnyPublisher<[Volume], Error> {
        let query = "subject:\(subject)"
        return searchBooks(query: query, maxResults: maxResults)
            .map { $0.items ?? [] }
            .eraseToAnyPublisher()
    }
    
    // Buscar livros recentes
    func fetchRecentBooks(maxResults: Int = 20) -> AnyPublisher<[Volume], Error> {
        let currentYear = Calendar.current.component(.year, from: Date())
        let query = "inauthor:*&publishedDate:\(currentYear-1)-\(currentYear)"
        return searchBooks(query: query, maxResults: maxResults)
            .map { $0.items ?? [] }
            .eraseToAnyPublisher()
    }
    
    // Buscar best sellers (baseado em rating e reviews)
    func fetchBestRatedBooks(maxResults: Int = 20) -> AnyPublisher<[Volume], Error> {
        let query = "inauthor:*&orderBy=relevance"
        return searchBooks(query: query, maxResults: maxResults)
            .map { response in
                // Filtra livros com rating alto
                let books = response.items ?? []
                return books
                    .filter { $0.volumeInfo.averageRating ?? 0 >= 4.0 }
                    .sorted { ($0.volumeInfo.averageRating ?? 0) > ($1.volumeInfo.averageRating ?? 0) }
            }
            .eraseToAnyPublisher()
    }
    
    // Buscar por autor popular
    func fetchBooksByPopularAuthor(maxResults: Int = 20) -> AnyPublisher<[Volume], Error> {
        let popularAuthors = [
            "Stephen King", "J.K. Rowling", "George R.R. Martin", 
            "Agatha Christie", "Dan Brown", "John Green"
        ]
        let randomAuthor = popularAuthors.randomElement() ?? "Stephen King"
        let query = "inauthor:\"\(randomAuthor)\""
        return searchBooks(query: query, maxResults: maxResults)
            .map { $0.items ?? [] }
            .eraseToAnyPublisher()
    }
}
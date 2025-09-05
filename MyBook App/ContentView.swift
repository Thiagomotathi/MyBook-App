//
//  ContentView.swift
//  BookMory
//
//  Created by ThiagoMotaMachado on 26/07/25.
//

import SwiftUI
internal import Combine

// MARK: - Book Models
struct GoogleBooksResponse: Codable {
    let items: [Volume]?
}

struct Volume: Codable, Identifiable, Equatable {
    let id: String             // vem direto da API
    let volumeInfo: VolumeInfo
    
    static func == (lhs: Volume, rhs: Volume) -> Bool {
        lhs.id == rhs.id
    }
}

struct VolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let description: String?
    let imageLinks: ImageLinks?
    let pageCount: Int?
}

struct ImageLinks: Codable {
    let smallThumbnail: String?
    let thumbnail: String?
    let small: String?
    let medium: String?
    let large: String?
    let extraLarge: String?
}

extension ImageLinks {
    var bestImageURL: URL? {
        // ordem de prioridade
        let candidates = [extraLarge, large, medium, small, thumbnail, smallThumbnail]
        
        for link in candidates {
            if let link, let url = URL(string: link.replacingOccurrences(of: "http://", with: "https://")) {
                return url
            }
        }
        return nil
    }
}

struct TrackedBook: Codable, Identifiable, Equatable {
    var id = UUID()
    let volume: Volume
    var currentPage: Int = 0
    
    var progress: Double {
        guard let total = volume.volumeInfo.pageCount, total > 0 else { return 0 }
        return Double(currentPage) / Double(total)
    }
    
    static func == (lhs: TrackedBook, rhs: TrackedBook) -> Bool {
        lhs.volume == rhs.volume
    }
}

// MARK: - Books Search ViewModel
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

// MARK: - Reading List ViewModel
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

// MARK: - Recent Searches Helper
struct RecentSearchesStore {
    static let key = "recentSearches"
    static let maxCount = 10
    
    static func load() -> [String] {
        (UserDefaults.standard.stringArray(forKey: key) ?? [])
    }
    
    static func save(_ items: [String]) {
        UserDefaults.standard.set(items, forKey: key)
    }
    
    static func add(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var items = load()
        // remove duplicado (case-insensitive)
        items.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        items.insert(trimmed, at: 0)
        if items.count > maxCount { items = Array(items.prefix(maxCount)) }
        save(items)
    }
    
    static func remove(_ term: String) {
        var items = load()
        items.removeAll { $0.caseInsensitiveCompare(term) == .orderedSame }
        save(items)
    }
    
    static func clear() {
        save([])
    }
}

// MARK: - Views
// BooksSearchView: mostra "Recentes" como List com swipe-to-delete.
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
                                            if let authors = book.volumeInfo.authors {
                                                Text(authors.joined(separator: ", "))
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            if let description = book.volumeInfo.description {
                                                Text(description)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                    .lineLimit(3)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
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

struct AnimatedCirclesBackground: View {
    @State private var offsets: [CGSize] = Array(repeating: .zero, count: 3)
    
    let colors: [Color] = [.red, .blue, .green]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(offsets.indices, id: \.self) { index in
                    Circle()
                        .fill(colors[index].opacity(0.6))
                        .frame(width: CGFloat.random(in: 600...800),
                               height: CGFloat.random(in: 600...800))
                        .offset(offsets[index])
                        .blur(radius: 50)
                        .onAppear {
                            animateCircle(at: index, in: geo.size)
                        }
                }
            }
            .ignoresSafeArea()
        }
    }
    
    private func animateCircle(at index: Int, in size: CGSize) {
        let animationDuration = Double.random(in: 25...40)
        withAnimation(.linear(duration: animationDuration).repeatForever(autoreverses: true)) {
            offsets[index] = CGSize(
                width: CGFloat.random(in: -size.width/3...size.width/3),
                height: CGFloat.random(in: -size.height/3...size.height/3)
            )
        }
    }
}

#Preview {
    AnimatedCirclesBackground()
}

struct BookDetailView: View {
    let book: Volume
    @EnvironmentObject var readingList: ReadingListViewModel
    
    @State private var currentPage: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Capa
                if let url = book.volumeInfo.imageLinks?.bestImageURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 100, height: 150)
                    .cornerRadius(8)
                    .shadow(radius: 5)
                }
                
                // Título e autores
                Text(book.volumeInfo.title)
                    .font(.title2)
                    .bold()
                if let authors = book.volumeInfo.authors {
                    Text("por \(authors.joined(separator: ", "))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Progresso de leitura
                if let totalPages = book.volumeInfo.pageCount, totalPages > 0 {
                    if readingList.isBookSaved(book) {
                        VStack(alignment: .leading, spacing: 8) {
                            ProgressView(value: Double(currentPage), total: Double(totalPages))
                                .progressViewStyle(LinearProgressViewStyle())
                            
                            Text("Página \(currentPage) de \(totalPages)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Stepper("Atualizar página", value: $currentPage, in: 0...totalPages)
                                .onChange(of: currentPage) { newValue in
                                    readingList.updateProgress(for: book, currentPage: newValue)
                                }
                        }
                    }
                }
                
                HStack(spacing: 16) {
                    Button(action: {
                        if readingList.isBookSaved(book) {
                            readingList.removeBook(book)
                        } else {
                            readingList.addBook(book)
                        }
                    }) {
                        Text(readingList.isBookSaved(book) ? "Remover da Lista" : "Salvar na Lista")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(readingList.isBookSaved(book) ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    if readingList.isBookSaved(book) {
                        NavigationLink(destination: ReadingSessionView(book: book)) {
                            Text("Iniciar Leitura")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .padding()
            .onAppear {
                if let tracked = readingList.savedBooks.first(where: { $0.volume == book }) {
                    currentPage = tracked.currentPage
                }
            }
        }
        .navigationTitle("Detalhes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ReadingSessionView: View {
    let book: Volume
    @EnvironmentObject var readingList: ReadingListViewModel
    
    @State private var timerRunning: Bool = false
    @State private var timeElapsed: TimeInterval = 0
    @State private var timer: Timer? = nil
    
    // Controla o popup
    @State private var showingPagesAlert = false
    @State private var pagesReadInput: String = ""

    var totalPages: Int {
        book.volumeInfo.pageCount ?? 0
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(book.volumeInfo.title)
                .font(.title2)
                .bold()
            
            Text("Tempo de leitura: \(formatTime(timeElapsed))")
                .font(.subheadline)

            HStack(spacing: 16) {
                Button(timerRunning ? "Pausar" : "Retomar") {
                    timerRunning.toggle()
                    if timerRunning {
                        startTimer()
                    } else {
                        pauseTimer()
                    }
                }
                .padding()
                .background(timerRunning ? Color.orange : Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Encerrar Sessão") {
                    pauseTimer()
                    showingPagesAlert = true
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .alert("Quantas páginas você leu?", isPresented: $showingPagesAlert) {
            TextField("Páginas lidas", text: $pagesReadInput)
                .keyboardType(.numberPad)
            
            Button("Confirmar") {
                if let pages = Int(pagesReadInput), pages > 0 {
                    if let index = readingList.savedBooks.firstIndex(where: { $0.volume == book }) {
                        let current = readingList.savedBooks[index].currentPage
                        let totalPagesToAdd = min(pages, totalPages - current)
                        readingList.savedBooks[index].currentPage += totalPagesToAdd
                    }
                }
            }
            
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Insira o número de páginas lidas nesta sessão.")
        }
        .onDisappear {
            pauseTimer()
        }
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
        }
    }

    func pauseTimer() {
        timer?.invalidate()
        timer = nil
    }

    func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct ReadingListView: View {
    @EnvironmentObject var readingList: ReadingListViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(readingList.savedBooks) { trackedBook in
                    NavigationLink(destination: BookDetailView(book: trackedBook.volume)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(trackedBook.volume.volumeInfo.title)
                                    .font(.headline)

                                if let authors = trackedBook.volume.volumeInfo.authors {
                                    Text(authors.joined(separator: ", "))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                if let totalPages = trackedBook.volume.volumeInfo.pageCount, totalPages > 0 {
                                    VStack(alignment: .leading, spacing: 2) {
                                        ProgressView(value: trackedBook.progress)
                                            .progressViewStyle(LinearProgressViewStyle())
                                            .frame(maxWidth: 150)

                                        Text("Página \(trackedBook.currentPage) de \(totalPages)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }

                            Spacer()
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.map { readingList.savedBooks[$0].volume }
                        .forEach { readingList.removeBook($0) }
                }
            }
            .navigationTitle("Minha Lista")
        }
    }
}

// MARK: - Tabs Enum
enum Tabs: Hashable {
    case buscar
    case lista
}

// MARK: - Root Content
struct ContentView: View {
    @State private var selectedTab: Tabs = .buscar
    @State private var searchText: String = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Aba Minha Lista
            Tab("Leituras", systemImage: "books.vertical.fill", value: .lista) {
                ReadingListView()
            }
            Tab("Explorar", systemImage: "eyeglasses", value: .lista) {
                ReadingListView()
            }
            Tab("Perfil", systemImage: "person.fill", value: .lista) {
                ReadingListView()
            }
            
            // Aba Buscar com papel .search (expansão da Tab Bar com campo de busca)
            Tab(value: .buscar, role: .search) {
                BooksSearchView(searchText: $searchText)
            } label: {
                Label("Buscar", systemImage: "magnifyingglass")
            }
        }
        // Um único EnvironmentObject compartilhado entre todas as abas
        .environmentObject(sharedReadingList)
    }
    
    // Um único instance para todas as abas
    private var sharedReadingList: ReadingListViewModel {
        _sharedReadingList.wrappedValue
    }
    
    @State private var _sharedReadingList = State(initialValue: ReadingListViewModel())
}

//#Preview {
//    ContentView()
//}

//
//  ReadingSessionView.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 10/09/25.
//


import SwiftUI // teste 1
import Combine


struct BookCoverView: View {
    let book: Volume
    var onImageLoaded: ((UIImage) -> Void)? = nil

    var body: some View {
        Group {
            if let url = book.volumeInfo.imageLinks?.bestImageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .onAppear {
                                if let uiImage = image.asUIImage() {
                                    onImageLoaded?(uiImage)
                                }
                            }

                    case .empty:
                        loadingView

                    case .failure:
                        fallbackView

                    @unknown default:
                        fallbackView
                    }
                }
            } else {
                fallbackView
            }
        }
    }

    private var loadingView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(.secondary.opacity(0.3))
            ProgressView()
        }
    }

    private var fallbackView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(.tertiary)
            Image(systemName: "book.closed.fill")
                .resizable()
                .scaledToFit()
                .padding(24)
                .foregroundStyle(.secondary)
        }
    }
}

struct BookBackgroundView: View {
    @StateObject private var colorVM = ColorViewModel()
    let book: Volume
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    colorVM.backgroundColor,
                    Color(.systemBackground),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            
//            backgroundForCategory
//                .ignoresSafeArea()
            
        }
        .ignoresSafeArea()
    }
    
    private var backgroundForCategory: Image {
        // Pega a primeira categoria (se existir)
        let rawCategory = book.volumeInfo.categories?.first ?? ""
        let key = normalizeCategory(rawCategory)
        
        // Mapa de categorias (chaves normalizadas) -> nome do asset
        let map: [String: String] = [
            "fantasy": "bgFantasy",
            "romance": "bgRomance",
            "thriller": "bgFiction",
            "horror": "bgFiction",
            "sciencefiction": "bgFiction",
            "scifi": "bgFiction",
            "ficcao": "bgFiction",
            "fiction": "bgFiction",
            "juvenilefiction": "bgFiction",
            "nonfiction": "bgFiction",
            "naoficcao": "bgFiction",
            "history": "bgRomance",
            "historia": "bgRomance",
            "biography": "bgRomance",
            "biografia": "bgRomance",
            "poetry": "bgRomance",
            "poesia": "bgRomance",
            "children": "bgFantasy",
            "infantil": "bgFantasy",
            "comics": "bgFantasy",
            "quadrinhos": "bgFantasy"
        ]
        
        // tenta correspondência direta
        if let assetName = map[key] {
            return Image(assetName)
        }
        
        // fallback por palavras-chave comuns (ex.: "Fiction / Fantasy")
        let tokens = key.split { !$0.isLetter }.map(String.init)
        for token in tokens {
            if let assetName = map[token] {
                return Image(assetName)
            }
        }
        
        // fallback final
        return Image("bgRomance")
    }
    
    private func normalizeCategory(_ text: String) -> String {
        // remove acentos, espaços e pontuação, e coloca minúsculo
        let lowered = text.lowercased()
        let folding = lowered.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let lettersOnly = folding.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        return String(String.UnicodeScalarView(lettersOnly))
    }
}

struct ReadingSessionView: View {
    let book: Volume
    @EnvironmentObject var readingList: ReadingListViewModel
    
    @State private var timerRunning: Bool = false
    @State private var timeElapsed: TimeInterval = 0
    @State private var timer: Timer? = nil
    
    @State private var isCountingDown = false
    @State private var countdownValue: Int = 3
    @State private var countdownTimer: Timer? = nil
    
    // Controla o popup
    @State private var showingPagesAlert = false
    @State private var pagesReadInput: String = ""

    var totalPages: Int {
        book.volumeInfo.pageCount ?? 0
    }
    
    @State private var showButtons = false
    
    var body: some View {
        ZStack {
            VStack {
                Text("\(formatTime(timeElapsed))")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                
                VStack {
                    BookCoverView(book: book)
                        .opacity(showButtons ? 0.2 : 1.0)
                        .frame(width: 200, height: 300)
                        .clipped()
                        .cornerRadius(8)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                showButtons.toggle()
                            }
                        }
                        .padding(.bottom, 64)
                }
                .overlay {
                    if showButtons {
                        VStack(spacing: 16) {
                            Button() {
                                if timerRunning {
                                    pauseTimer()
                                    timerRunning = false
                                } else {
                                    startCountdown()
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.indigo)
                                    
                                    Image(systemName: timerRunning ? "pause.fill" : "play.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(40)
                                        .foregroundStyle(Color.white)
                                }
                                
                            }
                            
                            Button {
                                pauseTimer()
                                showingPagesAlert = true
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.storyRed)
                                    
                                    Image(systemName: "flag.checkered")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(40)
                                        .foregroundStyle(Color.white)
                                }
                            }
                        }
                        .padding()
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                BookBackgroundView(book: book)
                
            }
            
            // 🔹 BACKDROP clicável
            if showButtons {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            showButtons = false
                        }
                    }
            }
            
            
        }
        .navigationTitle("Timer")
//        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            print("📚 Categorias do livro:", book.volumeInfo.categories ?? [])
            startCountdown()
        }
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
    func startCountdown() {
        isCountingDown = true
        countdownValue = 5
        
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdownValue > 1 {
                countdownValue -= 1
            } else {
                countdownTimer?.invalidate()
                countdownTimer = nil
                isCountingDown = false
                startTimer()
                timerRunning = true
            }
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




//#Preview {
//    CounterView()
//}

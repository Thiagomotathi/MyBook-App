//
//  ReadingSessionView.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 10/09/25.
//


import SwiftUI // teste 1
import Combine


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
//
//  BookDetailView.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 06/09/25.
//
import SwiftUI

struct BookDetailView: View {
    let book: Volume
    @EnvironmentObject var readingList: ReadingListViewModel
    @State private var currentPage: Int = 0

    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 20) {
                // Capa e título
                HStack(alignment: .top, spacing: 16) {
                    if let url = book.volumeInfo.imageLinks?.bestImageURL {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: geo.size.width * 0.25, height: geo.size.height * 0.25)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.volumeInfo.title)
                            .font(.title2)
                            .bold()
                        if let authors = book.volumeInfo.authors {
                            Text("por \(authors.joined(separator: ", "))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Progresso de leitura
                if let totalPages = book.volumeInfo.pageCount, totalPages > 0,
                   readingList.isBookSaved(book) {
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
                    .padding(.horizontal)
                }

                Spacer()

                // Botões
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
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .frame(width: geo.size.width, height: geo.size.height)
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

//
//  BookPageView.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 06/09/25.
//
import SwiftUI

struct BookPageView: View {
    let tracked: TrackedBook
    
    // Estados de carregamento manual
    @State private var uiImage: UIImage?
    @State private var isLoading: Bool = false
    @State private var didTimeout: Bool = false
    @State private var loadError: Error?
    @State private var loadTask: Task<Void, Never>?
    
    private let imageLoadTimeout: TimeInterval = 3.0
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 16) {
                Spacer(minLength: 10)
                
                Group {
                    if let image = uiImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else if isLoading && !didTimeout {
                        ProgressView()
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.gray.opacity(0.35))
                            Image(systemName: "mountain.2.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.secondary)
                                .padding(geo.size.width * 0.1)
                        }
                    }
                }
                .frame(maxWidth: geo.size.width * 0.7, maxHeight: geo.size.height * 0.65)
                .cornerRadius(12)
                .shadow(radius: 10)
                
                Text(tracked.volume.volumeInfo.title)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 24)
                
                Spacer(minLength: 20)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(Color.black.opacity(0.3))
            .onAppear {
                startImageLoadIfNeeded()
            }
            .onChange(of: tracked.volume.volumeInfo.imageLinks?.bestImageURL) { _ in
                resetAndReload()
            }
            .onDisappear {
                loadTask?.cancel()
            }
        }
    }
    
    private func startImageLoadIfNeeded() {
        guard uiImage == nil else { return }
        guard let url = tracked.volume.volumeInfo.imageLinks?.bestImageURL else {
            isLoading = false
            didTimeout = true
            return
        }
        loadImage(with: url)
    }
    
    private func resetAndReload() {
        loadTask?.cancel()
        uiImage = nil
        loadError = nil
        didTimeout = false
        isLoading = false
        startImageLoadIfNeeded()
    }
    
    private func loadImage(with url: URL) {
        isLoading = true
        didTimeout = false
        loadError = nil
        
        loadTask = Task { @MainActor in
            do {
                try await withThrowingTaskGroup(of: UIImage?.self) { group in
                    group.addTask { await fetchImage(url: url) }
                    group.addTask {
                        try await timeoutAfter(seconds: imageLoadTimeout)
                        return nil
                    }
                    
                    if let first = try await group.next() {
                        if let img = first {
                            self.uiImage = img
                            self.isLoading = false
                            group.cancelAll()
                            return
                        } else {
                            self.didTimeout = true
                            self.isLoading = false
                            group.cancelAll()
                            return
                        }
                    }
                    
                    self.didTimeout = true
                    self.isLoading = false
                    group.cancelAll()
                }
            } catch is CancellationError { }
            catch {
                self.loadError = error
                self.isLoading = false
                self.didTimeout = true
            }
        }
    }
    
    private func timeoutAfter(seconds: TimeInterval) async throws {
        let nanos = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanos)
    }
    
    private func fetchImage(url: URL) async -> UIImage? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}

// MARK: - Preview
//struct BookPageView_Previews: PreviewProvider {
//    static var previews: some View {
//        let exampleVolume = Volume(
//            id: "1",
//            volumeInfo: VolumeInfo(
//                title: "Exemplo de Livro",
//                authors: ["Autor Exemplar"],
//                description: "Uma breve descrição de teste para visualização.",
//                imageLinks: ImageLinks(
//                    smallThumbnail: nil,
//                    thumbnail: nil,
//                    small: nil,
//                    medium: "https://via.placeholder.com/200x300",
//                    large: nil,
//                    extraLarge: nil
//                ),
//                pageCount: 100
//            )
//        )
//        let trackedBook = TrackedBook(volume: exampleVolume, currentPage: 0)
//        
//        BookPageView(tracked: trackedBook)
//            .previewLayout(.sizeThatFits)
//            .background(Color.gray.opacity(0.2))
//    }
//}


import SwiftUI

struct TikTokVerticalBooksSnapView: View {
    let books: [TrackedBook]
    @State var isShowingButtons: Bool = false
    @State private var currentIndex: Int? = 0
    @State private var backgroundColor: Color = Color.black.opacity(0.2)
    @State private var dominantColorCache: [UUID: Color] = [:]
    
    // Coleção invertida: o último adicionado aparece primeiro
    private var booksReversed: [TrackedBook] { Array(books.reversed()) }
    
    var onDetails: ((TrackedBook) -> Void)?
    var onRead: ((TrackedBook) -> Void)?

    // Tamanho fixo da capa (mantém 2:3)
    private let coverWidth: CGFloat = 300
    private var coverHeight: CGFloat { coverWidth * 1.5 } // 2:3 => h = w * 1.5

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backgroundColor.opacity(0.6)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.35), value: backgroundColor)

                ScrollView(.vertical) {
                    VStack {
                        ForEach(Array(booksReversed.enumerated()), id: \.element.id) { index, tracked in
                            VStack(spacing: 16) {
                                Spacer(minLength: 10)

                                // Barra de progresso do livro
                                if let total = tracked.volume.volumeInfo.pageCount, total > 0 {
                                    HStack {
                                        ProgressView(value: Double(tracked.currentPage), total: Double(total))
                                            .tint(.primary)

                                        // texto opcional (ex: "10 / 100")
                                        Text("\(tracked.currentPage) / \(total) páginas")
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                    }
                                    .padding(.horizontal, 32)
                                    
                                    
                                }

                                // Capa com tamanho fixo
                                Group {
                                    if let url = tracked.volume.volumeInfo.imageLinks?.bestImageURL {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .onAppear {
                                                    updateBackgroundIfNeeded(for: tracked, index: index, imageProvider: { image.asUIImage() })
                                                }
                                        } placeholder: {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                    .fill(Color.gray.opacity(0.35))
                                                ProgressView()
                                            }
                                        }
                                    } else {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .fill(Color.gray.opacity(0.35))
                                            Image(systemName: "book.closed.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundStyle(.secondary)
                                                .padding(40)
                                        }
                                    }
                                }
                                .clipped()
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.4), radius: 8)
                                .frame(maxWidth: .infinity, alignment: .top)
                                .padding(.horizontal, 32)

                                // Mostra os botões apenas quando este cartão está ativo
                                if (currentIndex ?? -1) == index {
                                    HStack(spacing: 20) {
                                        Button("Detalhes") { onDetails?(tracked) }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)

                                        Button("Ler") { onRead?(tracked) }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                    .padding(.horizontal, 32)
                                }

                                Spacer(minLength: 10)
                            }
                            .containerRelativeFrame(.vertical)
                            .frame(width: geo.size.width)
                            .background(Color.clear)
                            .id(index)
                        }
                    }
                    
                }
                .scrollIndicators(.hidden)
                .scrollTargetLayout() // habilita targets de snap
                .scrollTargetBehavior(.paging) // faz o snap por página
                .scrollBounceBehavior(.basedOnSize) // opcional
                .scrollPosition(id: $currentIndex) // rastreia a página atual (Binding<Int?>)
                .onChange(of: currentIndex) { _, newIndex in
                    guard let idx = newIndex, booksReversed.indices.contains(idx) else { return }
                    let tracked = booksReversed[idx]
                    updateBackgroundColor(for: tracked)
                }
                .onAppear {
                    // Definir cor inicial no primeiro item (mais recente), se existir
                    if let idx = currentIndex, booksReversed.indices.contains(idx) {
                        updateBackgroundColor(for: booksReversed[idx])
                    }
                }
            }
        }
    }
    
    // MARK: - Background Color Updating
    
    private func updateBackgroundIfNeeded(for tracked: TrackedBook, index: Int, imageProvider: () -> UIImage?) {
        guard (currentIndex ?? -1) == index else { return }
        if let cached = dominantColorCache[tracked.id] {
            backgroundColor = cached
            return
        }
        if let uiImage = imageProvider() {
            let color = Color(fromDominantOf: uiImage)
            dominantColorCache[tracked.id] = color
            backgroundColor = color
        } else {
            backgroundColor = Color.black.opacity(0.25)
        }
    }
    
    private func updateBackgroundColor(for tracked: TrackedBook) {
        if let cached = dominantColorCache[tracked.id] {
            backgroundColor = cached
            return
        }
        guard let url = tracked.volume.volumeInfo.imageLinks?.bestImageURL else {
            backgroundColor = Color.black.opacity(0.25)
            return
        }
        
        Task {
            if let uiImage = await fetchUIImage(url: url) {
                let color = Color(fromDominantOf: uiImage)
                await MainActor.run {
                    dominantColorCache[tracked.id] = color
                    backgroundColor = color
                }
            } else {
                await MainActor.run {
                    backgroundColor = Color.black.opacity(0.25)
                }
            }
        }
    }
    
    private func fetchUIImage(url: URL) async -> UIImage? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url, delegate: nil)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}

// MARK: - Helpers

private extension Image {
    func asUIImage() -> UIImage? {
        nil
    }
}

private extension Color {
    init(fromDominantOf image: UIImage) {
        let dominant = image.dominantColor() ?? UIColor.black.withAlphaComponent(0.25)
        self = Color(dominant)
    }
}

private extension UIImage {
    func dominantColor(sampleSize: CGSize = CGSize(width: 20, height: 20)) -> UIColor? {
        let size = sampleSize
        let cgSize = CGSize(width: max(1, Int(size.width)), height: max(1, Int(size.height)))
        let bitmapBytesPerRow = Int(cgSize.width) * 4
        let bitmapByteCount = Int(cgSize.height) * bitmapBytesPerRow
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        guard let context = CGContext(
            data: nil,
            width: Int(cgSize.width),
            height: Int(cgSize.height),
            bitsPerComponent: 8,
            bytesPerRow: bitmapBytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        context.interpolationQuality = .low
        let rect = CGRect(origin: .zero, size: cgSize)
        context.draw(self.cgImage ?? UIImageToCGImage(self), in: rect)
        
        guard let data = context.data else { return nil }
        let ptr = data.bindMemory(to: UInt8.self, capacity: bitmapByteCount)
        
        var rTotal: UInt64 = 0
        var gTotal: UInt64 = 0
        var bTotal: UInt64 = 0
        var aTotal: UInt64 = 0
        
        for y in 0..<Int(cgSize.height) {
            for x in 0..<Int(cgSize.width) {
                let offset = (y * Int(cgSize.width) + x) * 4
                let r = ptr[offset + 0]
                let g = ptr[offset + 1]
                let b = ptr[offset + 2]
                let a = ptr[offset + 3]
                rTotal += UInt64(r)
                gTotal += UInt64(g)
                bTotal += UInt64(b)
                aTotal += UInt64(a)
            }
        }
        
        let count = max(1, Int(cgSize.width) * Int(cgSize.height))
        let r = CGFloat(rTotal) / CGFloat(count) / 255.0
        let g = CGFloat(gTotal) / CGFloat(count) / 255.0
        let b = CGFloat(bTotal) / CGFloat(count) / 255.0
        let a = CGFloat(aTotal) / CGFloat(count) / 255.0
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

private func UIImageToCGImage(_ image: UIImage) -> CGImage {
    if let cg = image.cgImage {
        return cg
    }
    let context = CIContext(options: nil)
    if let ci = image.ciImage, let cg = context.createCGImage(ci, from: ci.extent) {
        return cg
    }
    let size = image.size
    UIGraphicsBeginImageContextWithOptions(size, false, 1)
    image.draw(in: CGRect(origin: .zero, size: size))
    let rendered = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return rendered?.cgImage ?? CGImage(width: 1, height: 1, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue), provider: CGDataProvider(data: Data([0,0,0,255]) as CFData)!, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
}

// Removido BookExample, pois agora usamos os dados reais.
// Preview com mock simples
#Preview {
    let exampleVolume = Volume(
        id: "1",
        volumeInfo: VolumeInfo(
            title: "Exemplo de Livro",
            authors: ["Autor Exemplar"],
            description: "Uma breve descrição.",
            imageLinks: ImageLinks(
                smallThumbnail: nil,
                thumbnail: nil,
                small: nil,
                medium: "https://via.placeholder.com/200x300",
                large: nil,
                extraLarge: nil
            ),
            pageCount: 100
        )
    )
    let tracked = TrackedBook(volume: exampleVolume, currentPage: 10)
    TikTokVerticalBooksSnapView(books: [tracked, tracked])
}


struct BookCard: View {
    let tracked: TrackedBook
    let index: Int
    @Binding var currentIndex: Int?
    var onDetails: ((TrackedBook) -> Void)?
    var onRead: ((TrackedBook) -> Void)?
    var updateBackgroundIfNeeded: (TrackedBook, Int, () -> UIImage?) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 10)

            if let total = tracked.volume.volumeInfo.pageCount, total > 0 {
                HStack {
                    ProgressView(value: Double(tracked.currentPage), total: Double(total))
                        .tint(.primary)
                    Text("\(tracked.currentPage) / \(total) páginas")
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 32)
            }

            Group {
                if let url = tracked.volume.volumeInfo.imageLinks?.bestImageURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .onAppear {
                                updateBackgroundIfNeeded(tracked, index, { image.asUIImage() })
                            }
                    } placeholder: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.gray.opacity(0.35))
                            ProgressView()
                        }
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.gray.opacity(0.35))
                        Image(systemName: "book.closed.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.secondary)
                            .padding(40)
                    }
                }
            }
            .clipped()
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.4), radius: 8)
            .padding(.horizontal, 32)

            if (currentIndex ?? -1) == index {
                HStack(spacing: 20) {
                    Button("Detalhes") { onDetails?(tracked) }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                    Button("Ler") { onRead?(tracked) }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 32)
            }

            Spacer(minLength: 10)
        }
        .id(tracked.id) // <- chave estável
    }
}

import SwiftUI



struct TikTokBooksView: View {
    @ObservedObject var viewModel = ReadingListViewModel()
    @StateObject private var colorVM = ColorViewModel()
    @State private var currentIndex: Int? = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // fundo dinâmico (cor dominante mais suave)
                colorVM.backgroundColor
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.35), value: colorVM.backgroundColor)
                
                // círculos animados usando a cor dominante com mais saturação e opacidade
                AnimatedCirclesBackground(
                    colors: circlesPalette(from: colorVM.backgroundColor),
                    agitation: .alto
                )
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.savedBooks.enumerated()), id: \.element.id) { index, book in
                            BookCardView(
                                Book: book,
                                HasDescription: false,
                                colorVM: colorVM,
                                isFocused: currentIndex == index
                            )
                            .frame(width: geo.size.width, height: geo.size.height) // cada card ocupa quase toda a tela
                            .id(index)
                        }
                    }
                }
                .scrollTargetLayout() // iOS 17+: habilita snap
                .scrollTargetBehavior(.paging) // snap vertical
                .scrollPosition(id: $currentIndex) // rastreia item central
                .onChange(of: currentIndex) { _, newIndex in
                    guard let idx = newIndex, viewModel.savedBooks.indices.contains(idx) else { return }
                    let book = viewModel.savedBooks[idx]
                    // atualiza fundo ao scrollar
                    colorVM.updateColor(for: book.id, url: book.volume.volumeInfo.imageLinks?.bestImageURL)
                }
                .onAppear {
                    // define cor inicial
                    if let idx = currentIndex, viewModel.savedBooks.indices.contains(idx) {
                        colorVM.updateColor(for: viewModel.savedBooks[idx].id, url: viewModel.savedBooks[idx].volume.volumeInfo.imageLinks?.bestImageURL)
                    }
                }
            }
        }
    }
    // Paleta derivada da cor dominante com ajustes em saturação, brilho e opacidade, retornando Colors
    private func circlesPalette(from base: Color) -> [Color] {
        func adjust(_ color: Color, saturation sMul: CGFloat, brightness bAdd: CGFloat, alpha a: CGFloat) -> Color {
            // Convert Color -> UIColor -> HSB
            let ui = UIColor(color)
            var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, aOrig: CGFloat = 0
            ui.getHue(&h, saturation: &s, brightness: &b, alpha: &aOrig)
            let newS = min(max(s * sMul, 0), 1)
            let newB = min(max(b + bAdd, 0), 1)
            let newA = min(max(a, 0), 1)
            return Color(UIColor(hue: h, saturation: newS, brightness: newB, alpha: newA))
        }
        
        let c1 = adjust(base, saturation: 1.4, brightness: 0.04, alpha: 0.55)
        let c2 = adjust(base, saturation: 1.25, brightness: -0.02, alpha: 0.5)
        let c3 = adjust(base, saturation: 1.15, brightness: 0.08, alpha: 0.45)
        return [c1, c2, c3]
    }
}


struct BookCardView: View {
    var Book: TrackedBook
    var HasDescription: Bool
    @ObservedObject var colorVM: ColorViewModel
    var isFocused: Bool
    
    private let coverAspectRatio: CGFloat = 2.0 / 2.5
    
    var body: some View {
        GeometryReader { geo in
            let maxCoverWidth = geo.size.width * 0.8
            
            VStack(spacing: 16) {
                
                // Barra de progresso acima da capa
                if let total = Book.volume.volumeInfo.pageCount, total > 0 {
                    HStack(spacing: 6) {
                        let progressValue = Double(Book.currentPage) / Double(total)
                        DashedRoundedProgressBar(
                            progress: progressValue,
                            height: 5,
                            cornerRadius: 6,
                            trackStrokeColor: .black.opacity(0.35),
                            fillColor: .white,
                            dashCount: 8 // ajuste aqui a quantidade de traços desejada
                        )
                        .frame(height: 10)
                        
                        Spacer()
                        
                        Text("\(Book.currentPage) / \(total) pag")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: maxCoverWidth)
                    .opacity(isFocused ? 1 : 0) // <- opacidade da barra de progresso + texto
                    .animation(.easeInOut(duration: 0.25), value: isFocused)
                }
                
                Group {
                    if let url = Book.volume.volumeInfo.imageLinks?.bestImageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .onAppear {
                                        // ✅ Atualiza cor dominante
                                        colorVM.updateColor(for: Book.id, image: image.asUIImage())
                                    }
                            case .empty:
                                // Placeholder sem fundo cinza: só traço pontilhado + spinner
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.secondary)
                                    
                                    ProgressView()
                                }
                            case .failure(_):
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.tertiary)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        // Placeholder sem imagem: traço pontilhado preto + ícone
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [6, 6]))
                                .foregroundStyle(.black)
                            Image(systemName: "book.closed.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.secondary)
                                .padding(24)
                        }
                    }
                }
                .frame(maxWidth: maxCoverWidth)
                .aspectRatio(coverAspectRatio, contentMode: .fit)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                
                Text(Book.volume.volumeInfo.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 24)
                    .opacity(isFocused ? 1 : 0) // <- opacidade do título
                    .animation(.easeInOut(duration: 0.25), value: isFocused)
                
                if HasDescription {
                    Text(Book.volume.volumeInfo.description ?? "sem descrição")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 24)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct DashedRoundedProgressBar: View {
    var progress: Double
    var height: CGFloat = 5
    var cornerRadius: CGFloat = 6
    var trackStrokeColor: Color = .black.opacity(0.25)
    var fillColor: Color = .primary
    var dashCount: Int = 10
    
    var body: some View {
        GeometryReader { geo in
            let clamped = max(0, min(1, progress))
            let totalWidth = geo.size.width
            
            // cálculos dos traços
            let minSpacing = height + 5
            let totalSpacing = max(0, CGFloat(dashCount - 1)) * minSpacing
            let dashWidth = max(1, (totalWidth - totalSpacing) / CGFloat(max(1, dashCount)))
            let spacing = max(0, (totalWidth - dashWidth * CGFloat(max(1, dashCount))) / CGFloat(max(1, dashCount - 1)))
            
            ZStack(alignment: .leading) {
                // Fundo com traços
                HStack(spacing: spacing) {
                    ForEach(0..<max(1, dashCount), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(trackStrokeColor)
                            .frame(width: dashWidth, height: height)
                    }
                }
                
                // Linha contínua representando progresso
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(fillColor)
                    .frame(width: totalWidth * clamped, height: height)
            }
        }
        .frame(height: height)
        .accessibilityLabel("Progresso")
        .accessibilityValue("\(Int((max(0, min(1, progress)) * 100).rounded())) por cento")
        .animation(.easeInOut(duration: 0.25), value: progress)
    }
}


extension Image {
    func asUIImage() -> UIImage? {
        let controller = UIHostingController(rootView: self.resizable())
        let view = controller.view
        
        let targetSize = CGSize(width: 100, height: 150)
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { ctx in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}




#Preview("TikTokBooksView") {
    TikTokBooksView()
}

#Preview("BookCardView") {
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
            pageCount: 100,
            publisher: nil,
            publishedDate: nil,
            categories: nil,
            language: nil,
            previewLink: nil,
            averageRating: nil,
            ratingsCount: nil,
            industryIdentifiers: nil,
        )
    )
    
    BookCardView(Book: TrackedBook(volume: exampleVolume, currentPage: 10), HasDescription: false, colorVM: ColorViewModel(), isFocused: true)
}

import SwiftUI

struct TikTokBooksView: View {
    @ObservedObject var viewModel = ReadingListViewModel()
    @StateObject private var colorVM = ColorViewModel()
    @State private var currentIndex: Int? = 0
    @State private var circleScale: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // fundo dinâmico (cor dominante mais suave)
                colorVM.backgroundColor
                    .ignoresSafeArea()
                
                LinearGradient(
                    colors: [
                        colorVM.backgroundColor,
                        Color(.systemBackground).opacity(0.5),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.35), value: colorVM.backgroundColor)
                
                // Capa do livro no fundo com baixa opacidade
                if let currentIndex = currentIndex,
                   viewModel.savedBooks.indices.contains(currentIndex) {
                    let currentBook = viewModel.savedBooks[currentIndex]
                    
                    ZStack {
                        // Fundo para a imagem
//                        Color.black.opacity(0.2)
                        
                        // Imagem da capa
                        if let url = currentBook.volume.volumeInfo.imageLinks?.bestImageURL {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .ignoresSafeArea()
                                    .frame(width: geo.size.width)
                                    
//                                    .blur(radius: 10)
                            } placeholder: {
                                // Placeholder enquanto carrega
                                Rectangle()
                                    .fill(colorVM.backgroundColor)
                            }
                        } else {
                            // Se não tem imagem, usa a cor de fundo
                            Rectangle()
                                .fill(colorVM.backgroundColor)
                        }
                    }
                    .opacity(0.04) // Baixa opacidade
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.35), value: currentIndex)
                }
                
                VStack {
                    SimpleYellowSphereView()
                        .ignoresSafeArea()
                        .scaleEffect(circleScale)
                        .blendMode(.hardLight)
                        .opacity(0.4)
                    
                    // BookCoverView removido ou mantido conforme necessidade
                    // BookCoverView(book: book)
                }
                .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.savedBooks.enumerated()), id: \.element.id) { index, book in
                            BookCardView(
                                colorVM: colorVM,
                                Book: book,
                                HasDescription: false,
                                isFocused: currentIndex == index
                            )
                            .frame(width: geo.size.width, height: geo.size.height)
                            .scaleEffect(0.8)
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
                    
                    animateCircle()
                }
                .onAppear {
                    // define cor inicial
                    if let idx = currentIndex, viewModel.savedBooks.indices.contains(idx) {
                        let book = viewModel.savedBooks[idx]
                        colorVM.updateColor(for: book.id, url: book.volume.volumeInfo.imageLinks?.bestImageURL)
                        
                        animateCircle()
                    }
                }
            }
        }
    }
    
    func animateCircle() {
        // cresce rápido
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            circleScale = 0
        }

        // volta suavemente
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                circleScale = 1.5
            }
        }
    }
}

struct BookCardView: View {
    @ObservedObject var viewModel = ReadingListViewModel()
    @ObservedObject var colorVM: ColorViewModel
    var Book: TrackedBook
    var HasDescription: Bool
    var isFocused: Bool
    
    @State private var showActionButtons = false // Controla visibilidade dos botões
    @State private var showScheduleSheet = false // Controla a sheet de agendamento
    @State private var showReadingSessionSheet = false // Nova sheet para a sessão de leitura
    
    private let coverAspectRatio: CGFloat = 2.0 / 2.5
    
    var body: some View {
        GeometryReader { geo in
            let maxCoverWidth = geo.size.width * 0.8
            
            ZStack {
                VStack(spacing: 16) {
                    // Barra de progresso acima da capa
                    if let total = Book.volume.volumeInfo.pageCount, total > 0 {
                        HStack(spacing: 6) {
                            let progressValue = Double(Book.currentPage) / Double(total)
                            DashedRoundedProgressBar(
                                progress: progressValue,
                                height: 5,
                                cornerRadius: 6,
                                trackStrokeColor: .white.opacity(0.35),
                                fillColor: .white,
                                dashCount: 8
                            )
                            .frame(height: 10)
                            
                            Spacer()
                            
                            Text("\(Book.currentPage) / \(total) pag")
                                .font(.caption)
                                .bold()
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal)
                        .frame(maxWidth: maxCoverWidth)
                        .opacity(isFocused ? 1 : 0)
                        .animation(.easeInOut(duration: 0.25), value: isFocused)
                    }
                    
                    BookCoverView(book: Book.volume) { uiImage in
                        colorVM.updateColor(for: Book.id, image: uiImage)
                    }
                    .frame(maxWidth: maxCoverWidth)
                    .aspectRatio(coverAspectRatio, contentMode: .fit)
                    .cornerRadius(10)
                    .opacity( showActionButtons ? 0.8 : 1)
                    .shadow(
                        color: Color.black.opacity(0.15),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showActionButtons.toggle()
                        }
                    }
                    
                    if HasDescription {
                        Text(Book.volume.volumeInfo.description ?? "sem descrição")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 24)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                
                // Overlay com botões de ação
                if showActionButtons {
                    Color.clear
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showActionButtons = false
                            }
                        }
                    
                    // Container dos botões
                    VStack(spacing: 16) {
                        // Botão 1: Ler
                        Button {
                            showReadingSessionSheet = true
                        } label: {
                            Text("Ler")
                                .font(.title)
                                .frame(maxWidth: .infinity, maxHeight: 80)
                                .glassEffect(.regular)
                                .foregroundStyle(Color(.label))
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            showActionButtons = false
                        })
                        
                        // Botão 2: Agendar
                        Button {
                            showScheduleSheet = true
                        } label: {
                            Text("Agendar")
                                .font(.title)
                                .frame(maxWidth: .infinity, maxHeight: 80)
                                .glassEffect(.regular)
                                .foregroundStyle(Color(.label))
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showActionButtons = false
                            }
                        })
                    }
                    .padding(.horizontal, 40)
                    .frame(maxWidth: geo.size.width * 0.85)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showScheduleSheet) {
            ScheduleReadingSheet(book: Book)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        // ADICIONE ESTA SHEET AQUI ↓↓↓
        .sheet(isPresented: $showReadingSessionSheet) {
            ReadingSessionSheet(book: Book.volume)
                .interactiveDismissDisabled(true) // Desativa o fechamento por arraste
        }
    }
}

// Sheet para agendar a leitura
struct ScheduleReadingSheet: View {
    @Environment(\.dismiss) var dismiss
    let book: TrackedBook
    
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var dailyPages: Int = 10
    @State private var showingConfirmation = false
    
    private var pagesPerDayNeeded: Int {
        guard let totalPages = book.volume.volumeInfo.pageCount,
              totalPages > 0 else { return 0 }
        
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        let daysCount = max(1, days)
        return Int(ceil(Double(totalPages) / Double(daysCount)))
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Header gradiente
                VStack(spacing: 0) {
                    ZStack {
                        LinearGradient(
                            colors: [Color.indigo, Color(.systemBackground)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
                
                // Conteúdo
                ScrollView {
                    VStack(spacing: 16) {
                        Text("\(max(1, pagesPerDayNeeded)) PÁG / Dia")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        
                        // Retângulo que se estende até embaixo
                        VStack(spacing: 0) {
                            ZStack {
                                Rectangle()
                                    .fill(Color(.systemBackground))
                                    .frame(maxHeight: .infinity)
                                    .cornerRadius(20)
//                                    .padding(.horizontal)
                                
                                Form {
                                    // Cartão: Livro Selecionado
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Livro Selecionado")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        
                                        HStack(spacing: 16) {
                                            if let url = book.volume.volumeInfo.imageLinks?.bestImageURL {
                                                AsyncImage(url: url) { image in
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 60, height: 90)
                                                        .cornerRadius(8)
                                                } placeholder: {
                                                    Rectangle()
                                                        .fill(Color.gray.opacity(0.3))
                                                        .frame(width: 60, height: 90)
                                                        .cornerRadius(8)
                                                }
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(book.volume.volumeInfo.title)
                                                    .font(.headline)
                                                    .lineLimit(2)
                                                
                                                if let authors = book.volume.volumeInfo.authors {
                                                    Text(authors.joined(separator: ", "))
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                if let pages = book.volume.volumeInfo.pageCount {
                                                    Text("\(pages) páginas")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            Spacer()
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Período de Leitura")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        
                                        VStack(spacing: 12) {
                                            HStack {
                                                Text("Data de Início")
                                                Spacer()
                                                DatePicker("", selection: $startDate, in: Date()..., displayedComponents: .date)
                                                    .labelsHidden()
                                            }
                                            .padding(12)
                                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                                            
                                            HStack {
                                                Text("Data de Término")
                                                Spacer()
                                                DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                                                    .labelsHidden()
                                            }
                                            .padding(12)
                                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Duração: \(durationInDays) dias")
                                                .font(.callout)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.top, 4)
                                        
                                        if pagesPerDayNeeded > 50 {
                                            Text("Considerando \(pagesPerDayNeeded) páginas por dia. Talvez seja necessário ajustar as datas.")
                                                .font(.footnote)
                                                .foregroundColor(.orange)
                                                .padding(.top, 2)
                                        }
                                    }
                                }
                                .scrollContentBackground(.hidden)
                            }
                        }
                        .frame(minHeight: UIScreen.main.bounds.height * 0.8) // Garante altura mínima
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Agendar Leitura")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Botão padrão de cancelar
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", systemImage: "xmark") {
                        dismiss()
                    }
                }
                // Botão padrão de salvar
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar", systemImage: "checkmark") {
                        saveSchedule()
                    }
                    .disabled(endDate <= startDate)
                }
            }
            .alert("Agendamento Salvo", isPresented: $showingConfirmation) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Sua leitura de \"\(book.volume.volumeInfo.title)\" foi agendada de \(formatDate(startDate)) até \(formatDate(endDate)).")
            }
        }
        .tint(.blue)
    }
    
    private var durationInDays: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        return max(1, days)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: date)
    }
    
    private func saveSchedule() {
        print("Agendamento salvo:")
        print("Livro: \(book.volume.volumeInfo.title)")
        print("Início: \(startDate)")
        print("Fim: \(endDate)")
        print("Páginas por dia: \(dailyPages)")
        
        showingConfirmation = true
    }
}
// Extensão para adicionar dias a uma data
struct ReadingSessionSheet: View {
    let book: Volume
    @EnvironmentObject var readingList: ReadingListViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var timerRunning: Bool = false
    @State private var timeElapsed: TimeInterval = 0
    @State private var timer: Timer? = nil
    
    // Controla o popup
    @State private var showingPagesAlert = false
    @State private var pagesReadInput: String = ""
    
    var totalPages: Int {
        book.volumeInfo.pageCount ?? 0
    }
    
    @State private var showActionButtons = false
    @StateObject private var colorVM = ColorViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Capa do livro no fundo com baixa opacidade
                ZStack {
                    // Imagem da capa
                    if let url = book.volumeInfo.imageLinks?.bestImageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .blur(radius: 20)
                            case .empty:
                                Color.black.opacity(0.05)
                            case .failure(_):
                                Color.black.opacity(0.05)
                            @unknown default:
                                Color.black.opacity(0.05)
                            }
                        }
                    } else {
                        Color.black.opacity(0.05)
                    }
                }
//                .opacity(0.15)
                .ignoresSafeArea()
                
                // Gradiente suave por cima
                LinearGradient(
                    colors: [
                        Color(.orange),
                        Color(.systemBackground).opacity(0.3),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Conteúdo principal
                VStack(spacing: 0) {
                    // Timer no topo
                    Text("\(formatTime(timeElapsed))")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .padding(.top, 50)
                        .padding(.bottom, 30)
                    
                    Spacer()
                    
                    // Conteúdo central com capa - EXATAMENTE como BookCardView
                    VStack {
                        BookCoverView(book: book)
                            .opacity(showActionButtons ? 0.8 : 1.0)
                            .clipped()
                            .cornerRadius(10)
                            .padding(32)
                            .shadow(
                                color: Color.black.opacity(0.15),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showActionButtons.toggle()
                                }
                            }
                    }
                    .overlay {
                        // Container dos botões de ação (EXATAMENTE como BookCardView)
                        if showActionButtons {
                            VStack(spacing: 16) {
                                // Botão 1: Play/Pause
                                Button(action: {
                                    toggleTimer()
                                }) {
                                    Text(timerRunning ? "Pausar" : "Continuar")
                                        .font(.title)
                                        .frame(maxWidth: .infinity, maxHeight: 80)
                                        .glassEffect(.regular)
                                        .foregroundStyle(Color(.label))
                                }
                                .simultaneousGesture(TapGesture().onEnded {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showActionButtons = false
                                    }
                                })
                                
                                // Botão 2: Finalizar Sessão
                                Button(action: {
                                    pauseTimer()
                                    showingPagesAlert = true
                                }) {
                                    Text("Finalizar")
                                        .font(.title)
                                        .frame(maxWidth: .infinity, maxHeight: 80)
                                        .glassEffect(.regular)
                                        .foregroundStyle(Color(.label))
                                }
                                .simultaneousGesture(TapGesture().onEnded {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showActionButtons = false
                                    }
                                })
                            }
                            .padding(.horizontal, 48)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // 🔹 BACKDROP clicável (para fechar botões de ação) - Igual BookCardView
                if showActionButtons {
                    Color.clear
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showActionButtons = false
                            }
                        }
                }
            }
            .navigationTitle("Sessão de Leitura")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Botão de fechar - abre o alerta
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") {
                        showingPagesAlert = true
                    }
                    .foregroundColor(.storyRed)
                }
            }
            .onAppear {
                print("📚 Categorias do livro:", book.volumeInfo.categories ?? [])
                // Inicia o timer automaticamente quando a sheet abre
                startTimer()
                timerRunning = true
            }
            .alert("Quantas páginas você leu?", isPresented: $showingPagesAlert) {
                TextField("Páginas lidas", text: $pagesReadInput)
                    .keyboardType(.numberPad)
                
                Button("Salvar e Sair") {
                    savePagesAndDismiss()
                }
                
                Button("Cancelar", role: .cancel) {
                    // Se clicou em "Fechar" na toolbar, fecha sem salvar
                    if pagesReadInput.isEmpty {
                        dismiss()
                    }
                }
            } message: {
                Text("Insira o número de páginas lidas nesta sessão (\(formatTime(timeElapsed))).")
            }
            .onDisappear {
                pauseTimer()
            }
        }
        .interactiveDismissDisabled() // Impede fechamento por arraste
    }
    
    // MARK: - Funções do Timer
    
    func toggleTimer() {
        if timerRunning {
            pauseTimer()
        } else {
            startTimer()
        }
        timerRunning.toggle()
    }
    
    func startTimer() {
        // Inicia sem contagem regressiva
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
        }
    }
    
    func pauseTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Funções de Dados
    
    func savePagesAndDismiss() {
        if let pages = Int(pagesReadInput), pages > 0 {
            if let index = readingList.savedBooks.firstIndex(where: { $0.volume == book }) {
                let current = readingList.savedBooks[index].currentPage
                let totalPagesToAdd = min(pages, totalPages - current)
                readingList.savedBooks[index].currentPage += totalPagesToAdd
            }
        }
        dismiss()
    }
}

extension Date {
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
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

// Utilitário: cartão vítreo reaproveitando seu LiquidGlassRowBackground
private struct CardGlass<Content: View>: View {
    var cornerRadius: CGFloat = 16
    @ViewBuilder var content: Content
    
    var body: some View {
        ZStack {
            // Fundo "vidro" similar ao LiquidGlassRowBackground
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                )
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .blur(radius: 6)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(16)
        }
    }
}

// Utilitário: cantos arredondados seletivos para o header
private struct RoundedCorner: Shape {
    var radius: CGFloat = 16
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview("Schedule Sheet") {
    let exampleVolume = Volume(
        id: "1",
        volumeInfo: VolumeInfo(
            title: "Exemplo de Livro Muito Interessante",
            authors: ["Autor Exemplar", "Outro Autor"],
            description: "Uma breve descrição.",
            imageLinks: ImageLinks(
                smallThumbnail: nil,
                thumbnail: nil,
                small: nil,
                medium: "https://via.placeholder.com/200x300",
                large: nil,
                extraLarge: nil
            ),
            pageCount: 350,
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
    
    ScheduleReadingSheet(book: TrackedBook(volume: exampleVolume, currentPage: 10))
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
    
    BookCardView(colorVM: ColorViewModel(), Book: TrackedBook(volume: exampleVolume, currentPage: 10), HasDescription: false, isFocused: true)
}

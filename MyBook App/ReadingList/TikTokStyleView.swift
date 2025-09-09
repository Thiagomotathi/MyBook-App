import SwiftUI

struct TikTokStyleView: View {
    let colors: [Color] = [.red, .green, .blue, .orange, .purple, .pink]
    
    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    ForEach(0..<20) { index in
                        GeometryReader { itemGeo in
                            Rectangle()
                                .fill(colors[index % colors.count])
                                .frame(width: geo.size.width, height: geo.size.width * 3)
                                .overlay(
                                    Text("Item \(index)")
                                        .font(.largeTitle)
                                        .foregroundColor(.white)
                                )
                                // Efeito central fixo estilo TikTok
                                .scaleEffect(computeScale(proxy: itemGeo, geo: geo))
                                .animation(.easeOut, value: computeScale(proxy: itemGeo, geo: geo))
                        }
                        .frame(height: geo.size.width * 3)
                    }
                }
                .padding(.vertical, geo.size.height / 2) // para centralizar o primeiro e último item
            }
        }
    }
    
    // Função para calcular escala e simular "fix position"
    func computeScale(proxy: GeometryProxy, geo: GeometryProxy) -> CGFloat {
        let itemCenter = proxy.frame(in: .global).midY
        let screenCenter = geo.size.height / 2
        let diff = abs(itemCenter - screenCenter)
        
        // Retorna escala menor quanto mais longe do centro
        return max(0.8, 1 - (diff / geo.size.height) * 0.5)
    }
}

struct TikTokStyleView_Previews: PreviewProvider {
    static var previews: some View {
        TikTokStyleView()
    }
}

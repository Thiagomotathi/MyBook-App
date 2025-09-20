//
//  AnimatedCirclesBackground.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 06/09/25.
//
import SwiftUI

struct AnimatedCirclesBackground: View {
    enum AgitationLevel {
        case baixo
        case alto
        
        // Fator de amplitude relativo ao tamanho da tela
        var amplitudeFactor: CGFloat {
            switch self {
            case .baixo: return 1.0 / 2.0   // menos agitado
            case .alto:  return 1.0 / 1.0   // mais agitado
            }
        }
    }
    
    // Opcionais, com fallback interno
    var colors: [Color]? = nil
    var agitation: AgitationLevel? = nil
    
    @State private var offsets: [CGSize] = Array(repeating: .zero, count: 3)
    
    // Defaults internos
    private var defaultColors: [Color] { [.red, .blue, .green] }
    private var defaultAgitation: AgitationLevel { .baixo }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(offsets.indices, id: \.self) { index in
                    Circle()
                        .fill(colorForIndex(index).opacity(0.6))
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
    
    private func colorForIndex(_ index: Int) -> Color {
        let palette = colors ?? defaultColors
        guard !palette.isEmpty else { return .clear }
        return palette[index % palette.count]
    }
    
    private func animateCircle(at index: Int, in size: CGSize) {
        let level = agitation ?? defaultAgitation
        let animationDuration = Double.random(in: 25...40)
        let amplitudeW = size.width * level.amplitudeFactor
        let amplitudeH = size.height * level.amplitudeFactor
        
        withAnimation(.linear(duration: animationDuration).repeatForever(autoreverses: true)) {
            offsets[index] = CGSize(
                width: CGFloat.random(in: -amplitudeW...amplitudeW),
                height: CGFloat.random(in: -amplitudeH...amplitudeH)
            )
        }
    }
}

#Preview {
    VStack {
        // Uso padrão (sem passar nada)
        AnimatedCirclesBackground()
            .opacity(0.5)
        
        // Exemplo customizado (opcionais podem ser fornecidas quando quiser)
        // AnimatedCirclesBackground(colors: [.pink, .purple, .mint], agitation: .alto)
        //     .opacity(0.5)
    }
}

//
//  AnimatedCirclesBackground.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 06/09/25.
//
import SwiftUI


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

//
//  PersonView.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 06/09/25.
//
import SwiftUI

struct PersonView: View {
    var body: some View {
        ZStack {
            // círculos animados usando a cor dominante com mais saturação e opacidade
            AnimatedCirclesBackground(colors: [.red, .blue, .yellow], agitation: .baixo, hasBackground: true, backgroundColor: .storyGreen)
            
            VStack {
                Spacer()
                
                Image("Dunes")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(2)
                    .offset(y: 70)
            }
            .ignoresSafeArea()
            
            Text("PersonView")
        }
        
    }
}

#Preview {
    PersonView()
}

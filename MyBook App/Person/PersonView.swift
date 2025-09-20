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
            AnimatedCirclesBackground(
                agitation: .alto
            )
            
            Text("PersonView")
        }
        
    }
}

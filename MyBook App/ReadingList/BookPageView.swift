//
//  BookPageView.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 06/09/25.
//
import SwiftUI

struct BookPageView: View {
    let tracked: TrackedBook
    let pageSize: CGSize
    
    var body: some View {
        ZStack {
            // Transparente para deixar o background animado visível
            Color.clear
            
            VStack(spacing: 16) {
                Spacer(minLength: 10)
                
                if let url = tracked.volume.volumeInfo.imageLinks?.bestImageURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(maxWidth: pageSize.width * 0.7, maxHeight: pageSize.height * 0.65)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                }
                
                Text(tracked.volume.volumeInfo.title)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 24)
                
                Spacer(minLength: 20)
            }
            .frame(width: pageSize.width, height: pageSize.height)
        }
    }
}

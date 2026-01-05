//
//  ReadingActivityAttributes.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 05/01/26.
//


import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Atributos da Atividade
struct ReadingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timeElapsed: TimeInterval
        var isRunning: Bool
        var pagesRead: Int
    }
    
    var bookTitle: String
    var bookAuthor: String?
    var totalPages: Int
    var currentPage: Int
    var coverImageData: Data?
}

// MARK: - Live Activity View
struct ReadingActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReadingActivityAttributes.self) { context in
            // Lock screen/banner UI
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Capa do livro (se disponível)
                    if let imageData = context.attributes.coverImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 70)
                            .cornerRadius(6)
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 70)
                            .overlay(
                                Image(systemName: "book.fill")
                                    .foregroundColor(.white)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.bookTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if let author = context.attributes.bookAuthor {
                            Text(author)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                        
                        Text("Páginas: \(context.attributes.currentPage)/\(context.attributes.totalPages)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Timer
                    VStack(alignment: .trailing) {
                        Text(formatTime(context.state.timeElapsed))
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        
                        HStack {
                            Circle()
                                .fill(context.state.isRunning ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                            
                            Text(context.state.isRunning ? "Lendo" : "Pausado")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                // Barra de progresso
                ProgressView(value: Double(context.attributes.currentPage), 
                           total: Double(context.attributes.totalPages))
                    .tint(.blue)
                    .scaleEffect(x: 1, y: 0.8, anchor: .center)
            }
            .padding()
            .background(Color.black.opacity(0.9))
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(context.attributes.bookTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(formatTime(context.state.timeElapsed))
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        VStack(alignment: .leading) {
                            if let author = context.attributes.bookAuthor {
                                Text(author)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(1)
                            }
                            
                            Text("Página \(context.attributes.currentPage) de \(context.attributes.totalPages)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // Status do timer
                        HStack {
                            Circle()
                                .fill(context.state.isRunning ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                            
                            Text(context.state.isRunning ? "Lendo" : "Pausado")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                // Compact leading (esquerda)
                Image(systemName: "book.fill")
                    .foregroundColor(.blue)
            } compactTrailing: {
                // Compact trailing (direita)
                Text(formatTime(context.state.timeElapsed, compact: true))
                    .font(.caption)
                    .bold()
                    .foregroundColor(.white)
            } minimal: {
                // Minimal (apenas um ícone)
                Image(systemName: context.state.isRunning ? "book.fill" : "book.closed.fill")
                    .foregroundColor(context.state.isRunning ? .green : .orange)
            }
        }
    }
    
    private func formatTime(_ interval: TimeInterval, compact: Bool = false) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        if compact {
            if hours > 0 {
                return String(format: "%dh", hours)
            } else if minutes > 0 {
                return String(format: "%dm", minutes)
            } else {
                return String(format: "%ds", seconds)
            }
        } else {
            if hours > 0 {
                return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%02d:%02d", minutes, seconds)
            }
        }
    }
}
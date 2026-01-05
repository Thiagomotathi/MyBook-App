//
//  ReadingActivityManager.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 05/01/26.
//


import ActivityKit
import UIKit

@MainActor
class ReadingActivityManager {
    static let shared = ReadingActivityManager()
    
    private var currentActivity: Activity<ReadingActivityAttributes>?
    
    // Iniciar Live Activity
    func startActivity(book: Volume, currentPage: Int, timeElapsed: TimeInterval, isRunning: Bool) async {
        // Verifica se o dispositivo suporta Live Activities
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities não estão habilitadas")
            return
        }
        
        // Para qualquer atividade existente
        await endActivity()
        
        // Prepara os atributos
        let attributes = ReadingActivityAttributes(
            bookTitle: book.volumeInfo.title,
            bookAuthor: book.volumeInfo.authors?.first,
            totalPages: book.volumeInfo.pageCount ?? 0,
            currentPage: currentPage,
            coverImageData: await loadCoverImageData(for: book)
        )
        
        let initialState = ReadingActivityAttributes.ContentState(
            timeElapsed: timeElapsed,
            isRunning: isRunning,
            pagesRead: 0
        )
        
        do {
            // Cria a atividade
            currentActivity = try Activity.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
            
            print("✅ Live Activity iniciada: \(book.volumeInfo.title)")
        } catch {
            print("❌ Erro ao iniciar Live Activity: \(error.localizedDescription)")
        }
    }
    
    // Atualizar Live Activity
    func updateActivity(timeElapsed: TimeInterval, isRunning: Bool, currentPage: Int? = nil) async {
        guard let activity = currentActivity else { return }
        
        var updatedState = activity.contentState
        updatedState.timeElapsed = timeElapsed
        updatedState.isRunning = isRunning
        
        if let currentPage = currentPage {
            var updatedAttributes = activity.attributes
            updatedAttributes.currentPage = currentPage
        }
        
        do {
            await activity.update(using: updatedState)
            print("🔄 Live Activity atualizada")
        } catch {
            print("❌ Erro ao atualizar Live Activity: \(error.localizedDescription)")
        }
    }
    
    // Finalizar Live Activity
    func endActivity() async {
        guard let activity = currentActivity else { return }
        
        let finalState = ReadingActivityAttributes.ContentState(
            timeElapsed: activity.contentState.timeElapsed,
            isRunning: false,
            pagesRead: activity.contentState.pagesRead
        )
        
        do {
            await activity.end(using: finalState, dismissalPolicy: .default)
            currentActivity = nil
            print("⏹️ Live Activity finalizada")
        } catch {
            print("❌ Erro ao finalizar Live Activity: \(error.localizedDescription)")
        }
    }
    
    // Carregar imagem da capa
    private func loadCoverImageData(for book: Volume) async -> Data? {
        guard let url = book.volumeInfo.imageLinks?.bestImageURL else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            // Comprime a imagem para economizar espaço
            if let image = UIImage(data: data),
               let compressedData = image.jpegData(compressionQuality: 0.3) {
                return compressedData
            }
            return data
        } catch {
            print("❌ Erro ao carregar imagem: \(error.localizedDescription)")
            return nil
        }
    }
}
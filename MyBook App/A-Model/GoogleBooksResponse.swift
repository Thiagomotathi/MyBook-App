//
//  GoogleBooksResponse.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 06/09/25.
//
import SwiftUI
import Combine

struct GoogleBooksResponse: Codable {
    let items: [Volume]?
}

struct Volume: Codable, Identifiable, Equatable {
    let id: String             // vem direto da API
    let volumeInfo: VolumeInfo
    
    static func == (lhs: Volume, rhs: Volume) -> Bool {
        lhs.id == rhs.id
    }
}

struct VolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let description: String?
    let imageLinks: ImageLinks?
    let pageCount: Int?
}

struct ImageLinks: Codable {
    let smallThumbnail: String?
    let thumbnail: String?
    let small: String?
    let medium: String?
    let large: String?
    let extraLarge: String?
}

extension ImageLinks {
    var bestImageURL: URL? {
        // ordem de prioridade
        let candidates = [extraLarge, large, medium, small, thumbnail, smallThumbnail]
        
        for link in candidates {
            if let link, let url = URL(string: link.replacingOccurrences(of: "http://", with: "https://")) {
                return url
            }
        }
        return nil
    }
}

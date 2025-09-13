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
    let publisher: String?
    let publishedDate: String?
    let categories: [String]?
    let language: String?
    let previewLink: String?
    let averageRating: Double?
    let ratingsCount: Int?
    let industryIdentifiers: [IndustryIdentifier]?
}

struct IndustryIdentifier: Codable {
    let type: String   // ex: "ISBN_10" ou "ISBN_13"
    let identifier: String
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
        // ordem de prioridade (mantida)
        let candidates = [extraLarge, large, medium, small, thumbnail, smallThumbnail]
        
        for var link in candidates.compactMap({ $0 }) {
            // força HTTPS
            link = link.replacingOccurrences(of: "http://", with: "https://")
            
            // se a URL tiver zoom, força para 3
            if link.contains("zoom=") {
                link = link.replacingOccurrences(of: "zoom=1", with: "zoom=3")
                link = link.replacingOccurrences(of: "zoom=2", with: "zoom=3")
            }
            
            if let url = URL(string: link) {
                return url
            }
        }
        return nil
    }
}


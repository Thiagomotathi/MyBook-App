//
//  ReadigListModel.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 06/09/25.
//
import Foundation
import Combine

struct TrackedBook: Codable, Identifiable, Equatable {
    var id = UUID()
    let volume: Volume
    var currentPage: Int = 0
    
    var progress: Double {
        guard let total = volume.volumeInfo.pageCount, total > 0 else { return 0 }
        return Double(currentPage) / Double(total)
    }
    
    static func == (lhs: TrackedBook, rhs: TrackedBook) -> Bool {
        lhs.volume == rhs.volume
    }
}

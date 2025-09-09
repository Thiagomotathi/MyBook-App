//
//  RecentSearchesStore.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 06/09/25.
//
import SwiftUI

struct RecentSearchesStore {
    static let key = "recentSearches"
    static let maxCount = 10
    
    static func load() -> [String] {
        (UserDefaults.standard.stringArray(forKey: key) ?? [])
    }
    
    static func save(_ items: [String]) {
        UserDefaults.standard.set(items, forKey: key)
    }
    
    static func add(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var items = load()
        // remove duplicado (case-insensitive)
        items.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        items.insert(trimmed, at: 0)
        if items.count > maxCount { items = Array(items.prefix(maxCount)) }
        save(items)
    }
    
    static func remove(_ term: String) {
        var items = load()
        items.removeAll { $0.caseInsensitiveCompare(term) == .orderedSame }
        save(items)
    }
    
    static func clear() {
        save([])
    }
}

//
//  MyBook_AppApp.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 04/09/25.
//

import SwiftUI

// MARK: - Tabs Enum
enum Tabs: Hashable {
    case buscar
    case lista
}

@main
struct MyBook_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

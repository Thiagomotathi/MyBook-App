//
//  MyBook_AppApp.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 04/09/25.
//

import SwiftUI

// MARK: - Tabs Enum
enum Tabs: Hashable {
    case leituras
    case explorar
    case perfil
    case buscar
}

@main
struct MyBook_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


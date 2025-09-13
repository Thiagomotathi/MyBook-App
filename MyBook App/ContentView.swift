//
//  ContentView.swift
//  BookMory
//
//  Created by ThiagoMotaMachado on 26/07/25.
//

import SwiftUI // teste 1
import Combine


struct ContentView: View {
    @State private var selectedTab: Tabs = .leituras
    @State private var searchText: String = ""
    @State private var _sharedReadingList = State(initialValue: ReadingListViewModel())
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Leituras", systemImage: "books.vertical.fill", value: .leituras) {
                ReadingListView()
            }
            Tab("Explorar", systemImage: "eyeglasses", value: .explorar) {
                WorldView()
            }
            Tab("Perfil", systemImage: "person.fill", value: .perfil) {
                PersonView()
            }
            
            Tab(value: .buscar, role: .search) {
                BooksSearchView(searchText: $searchText)
            } label: {
                Label("Buscar", systemImage: "magnifyingglass")
            }
        }
        .environmentObject(sharedReadingList) //está visível para todos
    }
    
    private var sharedReadingList: ReadingListViewModel {
        _sharedReadingList.wrappedValue
    }
}


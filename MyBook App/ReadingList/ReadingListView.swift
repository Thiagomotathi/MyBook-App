//
//  ReadingListView.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 06/09/25.
//
import SwiftUI

struct ReadingListView: View {
    @EnvironmentObject var readingList: ReadingListViewModel

    var body: some View {
        GeometryReader { geo in
            NavigationView {
                ZStack {
                    Color.clear
                    
                    if readingList.savedBooks.isEmpty {
                        Text("Nenhum livro salvo ainda")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        TikTokBooksView()
                            .background(Color(.systemBackground))
                    }
                }
                .navigationTitle("Você está lendo")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

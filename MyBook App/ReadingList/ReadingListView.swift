//
//  ReadingListView.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 06/09/25.
//
import SwiftUI

struct ReadingListView: View {
    @EnvironmentObject var readingList: ReadingListViewModel
    @State private var currentIndex: Int = 0
    @GestureState private var dragOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let height = proxy.size.height
                let width = proxy.size.width
                
                ZStack {
                    AnimatedCirclesBackground()
                    
                    if readingList.savedBooks.isEmpty {
                        Text("Nenhum livro salvo ainda")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        // Vertical paging manual
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(Array(readingList.savedBooks.enumerated()), id: \.element.id) { index, tracked in
                                    NavigationLink {
                                        BookDetailView(book: tracked.volume)
                                    } label: {
                                        BookPageView(tracked: tracked, pageSize: CGSize(width: width, height: height))
                                            .frame(width: width, height: height)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .content.offset(y: -CGFloat(currentIndex) * height + dragOffset)
                        .gesture(
                            DragGesture()
                                .updating($dragOffset) { value, state, _ in
                                    state = value.translation.height
                                }
                                .onEnded { value in
                                    let threshold = height * 0.25
                                    var newIndex = currentIndex
                                    
                                    if value.translation.height < -threshold {
                                        newIndex = min(currentIndex + 1, max(0, readingList.savedBooks.count - 1))
                                    } else if value.translation.height > threshold {
                                        newIndex = max(currentIndex - 1, 0)
                                    }
                                    
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                        currentIndex = newIndex
                                    }
                                }
                        )
                        .animation(.easeInOut(duration: 0.2), value: currentIndex)
                        .ignoresSafeArea()
                    }
                }
            }
            .navigationTitle("Você está lendo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

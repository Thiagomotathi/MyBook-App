////
////  BookCoverView.swift
////  MyBook App
////
////  Created by ThiagoMotaMachado on 03/01/26.
////
//import SwiftUI
//
//
//struct BookCoverView: View {
//    let book: Volume
//    var showsControls: Bool = false
//
//    var onPlayPause: (() -> Void)? = nil
//    var onFinish: (() -> Void)? = nil
//
//    @State private var showButtons = false
//
//    var body: some View {
//        ZStack {
//            cover
//
//            if showsControls && showButtons {
//                controls
//            }
//
//            if showsControls && showButtons {
//                backdrop
//            }
//        }
//    }
//
//    // MARK: - Capa
//    private var cover: some View {
//        Group {
//            if let url = book.volumeInfo.imageLinks?.bestImageURL {
//                AsyncImage(url: url) { phase in
//                    switch phase {
//                    case .success(let image):
//                        image
//                            .resizable()
//                            .scaledToFit()
//
//                    case .empty:
//                        loadingView
//
//                    default:
//                        fallbackView
//                    }
//                }
//            } else {
//                fallbackView
//            }
//        }
//        .onTapGesture {
//            guard showsControls else { return }
//            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
//                showButtons.toggle()
//            }
//        }
//    }
//
//    // MARK: - Botões
//    private var controls: some View {
//        VStack(spacing: 16) {
//            Button(action: { onPlayPause?() }) {
//                controlButton(
//                    color: .indigo,
//                    systemName: "play.fill"
//                )
//            }
//
//            Button(action: { onFinish?() }) {
//                controlButton(
//                    color: .storyRed,
//                    systemName: "flag.checkered"
//                )
//            }
//        }
//        .padding()
//        .transition(.scale.combined(with: .opacity))
//    }
//
//    private func controlButton(color: Color, systemName: String) -> some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 8)
//                .fill(color)
//
//            Image(systemName: systemName)
//                .resizable()
//                .scaledToFit()
//                .padding(40)
//                .foregroundStyle(.white)
//        }
//    }
//
//    // MARK: - Backdrop
//    private var backdrop: some View {
//        Color.black.opacity(0.001)
//            .ignoresSafeArea()
//            .onTapGesture {
//                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
//                    showButtons = false
//                }
//            }
//    }
//
//    // MARK: - Placeholders
//    private var loadingView: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 10)
//                .fill(.secondary.opacity(0.3))
//            ProgressView()
//        }
//    }
//
//    private var fallbackView: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 10)
//                .fill(.tertiary)
//            Image(systemName: "book.closed.fill")
//                .resizable()
//                .scaledToFit()
//                .padding(24)
//                .foregroundStyle(.secondary)
//        }
//    }
//}

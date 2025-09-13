//
//  ColorViewModel.swift
//  MyBook App
//
//  Created by ThiagoMotaMachado on 13/09/25.
//
import SwiftUI
import Combine

@MainActor
class ColorViewModel: ObservableObject {
    @Published var backgroundColor: Color = Color.black.opacity(0.25)
    private var cache: [UUID: Color] = [:]
    
    /// Atualiza com base em um `UIImage`
    func updateColor(for id: UUID, image: UIImage?) {
        if let cached = cache[id] {
            backgroundColor = cached
            return
        }
        
        guard let uiImage = image else {
            backgroundColor = Color.black.opacity(0.25)
            return
        }
        
        let color = Color(fromDominantOf: uiImage)
        cache[id] = color
        backgroundColor = color
    }
    
    /// Atualiza com base em URL
    func updateColor(for id: UUID, url: URL?) {
        if let cached = cache[id] {
            backgroundColor = cached
            return
        }
        
        guard let url else {
            backgroundColor = Color.black.opacity(0.25)
            return
        }
        
        Task {
            if let uiImage = await Self.fetchUIImage(url: url) {
                let color = Color(fromDominantOf: uiImage)
                cache[id] = color
                backgroundColor = color
            } else {
                backgroundColor = Color.black.opacity(0.25)
            }
        }
    }
    
    // Helper: fetch image
    private static func fetchUIImage(url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}

extension Color {
    init(fromDominantOf image: UIImage) {
        let dominant = image.dominantColor() ?? UIColor.black.withAlphaComponent(0.25)
        self = Color(dominant)
    }
}

extension UIImage {
    func dominantColor(sampleSize: CGSize = CGSize(width: 20, height: 20)) -> UIColor? {
        let cgSize = CGSize(width: max(1, Int(sampleSize.width)),
                            height: max(1, Int(sampleSize.height)))
        let bytesPerRow = Int(cgSize.width) * 4
        let byteCount = Int(cgSize.height) * bytesPerRow
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        guard let context = CGContext(
            data: nil,
            width: Int(cgSize.width),
            height: Int(cgSize.height),
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        context.interpolationQuality = .low
        let rect = CGRect(origin: .zero, size: cgSize)
        context.draw(self.cgImage!, in: rect)
        
        guard let data = context.data else { return nil }
        let ptr = data.bindMemory(to: UInt8.self, capacity: byteCount)
        
        var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0, a: UInt64 = 0
        
        for y in 0..<Int(cgSize.height) {
            for x in 0..<Int(cgSize.width) {
                let offset = (y * Int(cgSize.width) + x) * 4
                r += UInt64(ptr[offset + 0])
                g += UInt64(ptr[offset + 1])
                b += UInt64(ptr[offset + 2])
                a += UInt64(ptr[offset + 3])
            }
        }
        
        let count = max(1, Int(cgSize.width) * Int(cgSize.height))
        return UIColor(
            red: CGFloat(r) / CGFloat(count) / 255.0,
            green: CGFloat(g) / CGFloat(count) / 255.0,
            blue: CGFloat(b) / CGFloat(count) / 255.0,
            alpha: CGFloat(a) / CGFloat(count) / 255.0
        )
    }
}

